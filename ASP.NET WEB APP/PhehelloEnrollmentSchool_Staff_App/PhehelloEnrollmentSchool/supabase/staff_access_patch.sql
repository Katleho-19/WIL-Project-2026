-- =====================================================================
-- Phehello - staff web app (ASP.NET) access patch
-- Run ONCE in Supabase > SQL Editor. Safe to run again (idempotent).
--
-- It assumes the Flutter app's supabase/schema.sql has already been applied
-- (it provides public.app_role(), public.is_staff() and the base policies).
-- It only ADDS what the ASP.NET app needs and tightens the Financial Clerk's
-- file access (SRS NFR6: the clerk may only see payment information).
-- =====================================================================

-- 0. Helpers (same definitions as the Flutter schema; harmless if present) -----
create or replace function public.app_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.app_role() in ('Administrator','Financial Clerk'), false)
$$;

-- 1. notifications.notification_type ------------------------------------------
-- The Flutter app uses message / reminder / status_update / system. Older copies of the
-- database only allowed 'Correction Requested', 'Deadline Reminder', ... which would make
-- every staff message or status change fail. Allow both vocabularies.
do $$
declare c record;
begin
  for c in
    select conname from pg_constraint
    where conrelid = 'public.notifications'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%notification_type%'
  loop
    execute format('alter table public.notifications drop constraint %I', c.conname);
  end loop;

  alter table public.notifications
    add constraint notifications_notification_type_check
    check (notification_type in (
      'message','reminder','status_update','system',
      'Correction Requested','Application Approved','Application Rejected','Deadline Reminder','General'));
end $$;

-- 2. Tell the parent when the status changes (Flutter "Notifications" tab) ----
create or replace function public.notify_status_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status
     and new.status in ('Approved','Rejected','Corrections Requested') then
    insert into public.notifications
      (application_id, recipient_id, notification_type, title, message)
    values (new.application_id, new.submitted_by, 'status_update', 'Application Update',
            'Your application ' || coalesce(to_jsonb(new)->>'reference_number', '') ||
            ' is now: ' || new.status || '.');
  end if;
  return new;
end $$;

drop trigger if exists trg_notify_status_change on public.applications;
create trigger trg_notify_status_change
  after update of status on public.applications
  for each row execute function public.notify_status_change();

-- 3. Keep applications.payment_verification_status in sync with payments ------
create or replace function public.sync_application_payment_status()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_app uuid := coalesce(new.application_id, old.application_id);
  v_status text;
begin
  select case
           when bool_or(verification_status = 'Verified') then 'Verified'
           when bool_or(verification_status = 'Pending')  then 'Pending'
           else 'Rejected'
         end
    into v_status
    from public.payments where application_id = v_app;
  update public.applications
     set payment_verification_status = coalesce(v_status, 'Pending'), updated_at = now()
   where application_id = v_app;
  return null;
end $$;

drop trigger if exists trg_sync_payment_status on public.payments;
create trigger trg_sync_payment_status
  after insert or update of verification_status on public.payments
  for each row execute function public.sync_application_payment_status();

-- 4. Table policies the staff app relies on -----------------------------------
alter table public.profiles                   enable row level security;
alter table public.learners                   enable row level security;
alter table public.applications               enable row level security;
alter table public.application_documents      enable row level security;
alter table public.payments                   enable row level security;
alter table public.application_notes          enable row level security;
alter table public.application_status_history enable row level security;
alter table public.confirmation_letters       enable row level security;
alter table public.notifications              enable row level security;
alter table public.school_payment_records     enable row level security;

-- Staff can read the profile / learner / application rows they work with.
drop policy if exists staff_profiles_select on public.profiles;
create policy staff_profiles_select on public.profiles for select
  using (id = auth.uid() or public.is_staff());

drop policy if exists staff_learners_select on public.learners;
create policy staff_learners_select on public.learners for select
  using (parent_id = auth.uid() or public.is_staff());

drop policy if exists applications_select on public.applications;
create policy applications_select on public.applications for select
  using (submitted_by = auth.uid() or public.is_staff());

-- Only the Administrator sees supporting documents (clerk = payments only).
drop policy if exists documents_select on public.application_documents;
create policy documents_select on public.application_documents for select
  using (exists (select 1 from public.applications a
                 where a.application_id = application_documents.application_id
                   and a.submitted_by = auth.uid())
         or public.app_role() = 'Administrator');

drop policy if exists payments_select on public.payments;
create policy payments_select on public.payments for select
  using (exists (select 1 from public.applications a
                 where a.application_id = payments.application_id
                   and a.submitted_by = auth.uid())
         or public.is_staff());

drop policy if exists history_select on public.application_status_history;
create policy history_select on public.application_status_history for select
  using (exists (select 1 from public.applications a
                 where a.application_id = application_status_history.application_id
                   and a.submitted_by = auth.uid())
         or public.app_role() = 'Administrator');

-- Administrator decides applications; Financial Clerk decides payments.
drop policy if exists admin_update_applications on public.applications;
create policy admin_update_applications on public.applications for update
  using (public.app_role() = 'Administrator') with check (public.app_role() = 'Administrator');

drop policy if exists clerk_update_payments on public.payments;
create policy clerk_update_payments on public.payments for update
  using (public.app_role() = 'Financial Clerk') with check (public.app_role() = 'Financial Clerk');

drop policy if exists admin_history_insert on public.application_status_history;
create policy admin_history_insert on public.application_status_history for insert
  with check (public.app_role() = 'Administrator');

drop policy if exists admin_notes_all on public.application_notes;
create policy admin_notes_all on public.application_notes for all
  using (public.app_role() = 'Administrator') with check (public.app_role() = 'Administrator');

drop policy if exists admin_letters_all on public.confirmation_letters;
create policy admin_letters_all on public.confirmation_letters for all
  using (public.app_role() = 'Administrator') with check (public.app_role() = 'Administrator');

drop policy if exists clerk_school_records on public.school_payment_records;
create policy clerk_school_records on public.school_payment_records for select
  using (public.app_role() = 'Financial Clerk');

-- Administrator assigns the unique student number (PH2026/001 ...) on the learner row.
drop policy if exists admin_update_learners on public.learners;
create policy admin_update_learners on public.learners for update
  using (public.app_role() = 'Administrator') with check (public.app_role() = 'Administrator');

-- Messages & reminders: Administrator sends any; Financial Clerk may only send payment messages.
drop policy if exists admin_notifications_insert on public.notifications;
create policy admin_notifications_insert on public.notifications for insert
  with check (public.app_role() = 'Administrator');

drop policy if exists clerk_notifications_insert on public.notifications;
create policy clerk_notifications_insert on public.notifications for insert
  with check (public.app_role() = 'Financial Clerk' and notification_type = 'message');

-- "Recent Messages" panel: the Administrator can read messages/reminders staff sent.
drop policy if exists admin_notifications_select on public.notifications;
create policy admin_notifications_select on public.notifications for select
  using (public.app_role() = 'Administrator' and notification_type in ('message','reminder'));

-- 5. Storage (private bucket 'enrolment-documents') ----------------------------
insert into storage.buckets (id, name, public)
values ('enrolment-documents', 'enrolment-documents', false)
on conflict (id) do update set public = false;

-- Parents: own folder only (<user id>/...).
drop policy if exists "parents read own files" on storage.objects;
create policy "parents read own files" on storage.objects for select to authenticated
  using (bucket_id = 'enrolment-documents' and (storage.foldername(name))[1] = auth.uid()::text);

-- Administrator reads every file. Financial Clerk reads payment proofs ONLY.
drop policy if exists "admin reads all files" on storage.objects;
create policy "admin reads all files" on storage.objects for select to authenticated
  using (bucket_id = 'enrolment-documents' and public.app_role() = 'Administrator');

drop policy if exists "clerk reads payment proofs" on storage.objects;
create policy "clerk reads payment proofs" on storage.objects for select to authenticated
  using (bucket_id = 'enrolment-documents'
         and public.app_role() = 'Financial Clerk'
         and name like '%/payment-proofs/%');

-- Administrator writes confirmation letters to confirmation-letters/<application id>.pdf
drop policy if exists "admin writes letters" on storage.objects;
create policy "admin writes letters" on storage.objects for insert to authenticated
  with check (bucket_id = 'enrolment-documents' and public.app_role() = 'Administrator'
              and (storage.foldername(name))[1] = 'confirmation-letters');

drop policy if exists "admin updates letters" on storage.objects;
create policy "admin updates letters" on storage.objects for update to authenticated
  using (bucket_id = 'enrolment-documents' and public.app_role() = 'Administrator'
         and (storage.foldername(name))[1] = 'confirmation-letters');

-- A parent may read the letter of their own application.
drop policy if exists "parents read own letter" on storage.objects;
create policy "parents read own letter" on storage.objects for select to authenticated
  using (bucket_id = 'enrolment-documents'
         and (storage.foldername(name))[1] = 'confirmation-letters'
         and exists (select 1 from public.applications a
                     where a.application_id::text = split_part(storage.filename(name), '.', 1)
                       and a.submitted_by = auth.uid()));
