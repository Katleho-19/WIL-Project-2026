-- =====================================================================
-- Phehello Secondary School - Online Enrolment System
-- Supabase schema for the Flutter parent app (follows SRS Part D ERD).
--
-- Run in: Supabase Dashboard > SQL Editor.  Safe to re-run.
--
-- IMPORTANT: the shared project may already contain an EARLIER prototype
-- version of these tables (different column names, e.g. applications.learner_name).
-- That older shape is incompatible with this app. Because only test data
-- exists, the simplest fix is to uncomment the DROP block below ONCE,
-- run the script, then comment it out again. Coordinate with the
-- ASP.NET team first: they read the same tables.
-- =====================================================================

-- ---- OPTIONAL: reset old prototype tables (TEST DATA ONLY) ----------
-- drop table if exists public.confirmation_letters cascade;
-- drop table if exists public.notifications cascade;
-- drop table if exists public.application_notes cascade;
-- drop table if exists public.application_status_history cascade;
-- drop table if exists public.payments cascade;
-- drop table if exists public.application_documents cascade;
-- drop table if exists public.applications cascade;
-- drop table if exists public.learner_medical_info cascade;
-- drop table if exists public.learners cascade;
-- drop table if exists public.school_payment_records cascade;
-- drop table if exists public.profiles cascade;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------- tables
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text,
  phone_number text,
  relationship_to_learner text,
  occupation text,
  role text not null default 'Parent'
    check (role in ('Parent','Financial Clerk','Administrator')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.learners (
  learner_id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles(id),
  first_name text not null,
  middle_name text,
  surname text not null,
  initials text,
  other_names text,
  id_number text,
  date_of_birth date,
  gender text,
  student_number text,
  previous_school_name text,
  highest_grade_passed text,
  year_grade_passed text,
  previous_grade_passed text,
  school_history_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.learner_medical_info (
  medical_info_id uuid primary key default gen_random_uuid(),
  learner_id uuid not null unique references public.learners(learner_id),
  medical_aid_name text,
  medical_aid_number text,
  medical_aid_main_member text,
  doctor_name text,
  doctor_address text,
  medical_condition text,
  siblings_at_school text
);

create table if not exists public.applications (
  application_id uuid primary key default gen_random_uuid(),
  reference_number text unique,
  learner_id uuid not null references public.learners(learner_id),
  submitted_by uuid not null references public.profiles(id),
  reviewed_by uuid references public.profiles(id),
  grade_applied_for text,
  application_date date not null default current_date,
  status text not null default 'Pending Admin Review'
    check (status in ('Pending Admin Review','Corrections Requested','Approved','Rejected')),
  payment_verification_status text not null default 'Pending'
    check (payment_verification_status in ('Pending','Verified','Rejected')),
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.application_documents (
  document_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(application_id),
  document_type text not null,
  file_name text not null,
  storage_path text not null,
  uploaded_by uuid references public.profiles(id),
  uploaded_at timestamptz not null default now(),
  verification_status text,
  verified_by uuid references public.profiles(id),
  verified_at timestamptz
);

create table if not exists public.school_payment_records (
  school_payment_record_id uuid primary key default gen_random_uuid(),
  payment_reference text not null unique,
  learner_name text,
  learner_id_number text,
  amount numeric(10,2),
  payment_date date,
  payment_method text,
  created_at timestamptz not null default now()
);

create table if not exists public.payments (
  payment_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(application_id),
  school_payment_record_id uuid references public.school_payment_records(school_payment_record_id),
  verified_by uuid references public.profiles(id),
  payment_reference text not null,
  amount numeric(10,2),
  proof_file_name text,
  proof_storage_path text,
  verification_status text not null default 'Pending'
    check (verification_status in ('Pending','Verified','Rejected')),
  verified_at timestamptz,
  verification_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.application_notes (
  note_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(application_id),
  created_by uuid references public.profiles(id),
  note_text text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.application_status_history (
  status_history_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(application_id),
  changed_by uuid references public.profiles(id),
  old_status text,
  new_status text not null,
  change_reason text,
  changed_at timestamptz not null default now()
);

create table if not exists public.confirmation_letters (
  confirmation_letter_id uuid primary key default gen_random_uuid(),
  application_id uuid not null unique references public.applications(application_id),
  learner_id uuid references public.learners(learner_id),
  generated_by uuid references public.profiles(id),
  learner_name text,
  learner_id_number text,
  student_number text,
  file_name text,
  storage_path text,
  generated_at timestamptz not null default now()
);

create table if not exists public.notifications (
  notification_id uuid primary key default gen_random_uuid(),
  application_id uuid references public.applications(application_id),
  recipient_id uuid not null references public.profiles(id),
  notification_type text not null default 'system',
  title text,
  message text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- Columns the Flutter app needs that are not in the SRS ERD (additive).
alter table public.profiles add column if not exists phone_number text;
alter table public.profiles add column if not exists relationship_to_learner text;
alter table public.profiles add column if not exists occupation text;
alter table public.learners add column if not exists initials text;
alter table public.learners add column if not exists other_names text;
alter table public.learners add column if not exists school_history_notes text;
alter table public.learner_medical_info add column if not exists siblings_at_school text;
alter table public.applications add column if not exists reference_number text;
alter table public.applications add column if not exists grade_applied_for text;
alter table public.notifications add column if not exists title text;
alter table public.notifications add column if not exists created_at timestamptz not null default now();

create sequence if not exists public.application_reference_seq start 1;

-- ------------------------------------------------------------- helpers
create or replace function public.app_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.app_role() in ('Administrator','Financial Clerk'), false)
$$;

-- New auth user -> profile (role Parent) + welcome message.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''), 'Parent')
  on conflict (id) do nothing;

  insert into public.notifications (recipient_id, notification_type, title, message)
  values (new.id, 'system', 'System Message',
          'Welcome to the Phehello Secondary School enrolment portal.');
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep applications.payment_verification_status in sync with payments
-- (SRS Decision 3: Verified > Pending > Rejected).
create or replace function public.sync_application_payment_status()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_app uuid := coalesce(new.application_id, old.application_id);
  v_status text;
begin
  select case
           when bool_or(verification_status = 'Verified') then 'Verified'
           when bool_or(verification_status = 'Pending') then 'Pending'
           else 'Rejected'
         end
    into v_status
    from public.payments where application_id = v_app;
  update public.applications
     set payment_verification_status = coalesce(v_status, 'Pending'),
         updated_at = now()
   where application_id = v_app;
  return null;
end $$;

drop trigger if exists trg_sync_payment_status on public.payments;
create trigger trg_sync_payment_status
  after insert or update of verification_status on public.payments
  for each row execute function public.sync_application_payment_status();

-- Tell the parent when staff change the application status (FR8 -> IR3).
create or replace function public.notify_status_change()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status
     and new.status in ('Approved','Rejected','Corrections Requested') then
    insert into public.notifications
      (application_id, recipient_id, notification_type, title, message)
    values (new.application_id, new.submitted_by, 'status_update', 'Application Update',
            'Your application ' || coalesce(new.reference_number, '') ||
            ' is now: ' || new.status || '.');
  end if;
  return new;
end $$;

drop trigger if exists trg_notify_status_change on public.applications;
create trigger trg_notify_status_change
  after update of status on public.applications
  for each row execute function public.notify_status_change();

-- ----------------------------------------------- Flutter RPC functions
-- Whole submission in ONE transaction (FR2, FR3, FR4, FR15, FR14).
create or replace function public.submit_enrolment(p_payload jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_app uuid := (p_payload->>'application_id')::uuid;
  v_learner uuid := gen_random_uuid();
  v_ref text;
  v_doc jsonb;
  l jsonb := p_payload->'learner';
  m jsonb := p_payload->'medical';
  g jsonb := p_payload->'guardian';
  pay jsonb := p_payload->'payment';
begin
  if v_uid is null then raise exception 'Please log in again.'; end if;
  if v_app is null then raise exception 'Missing application id.'; end if;
  if exists (select 1 from public.applications where application_id = v_app) then
    raise exception 'This application was already submitted.';
  end if;
  if jsonb_array_length(coalesce(p_payload->'documents', '[]'::jsonb)) < 3 then
    raise exception 'Please upload the required supporting documents.';
  end if;
  if coalesce(pay->>'proof_storage_path','') = '' then
    raise exception 'Please upload your proof of payment.';
  end if;

  update public.profiles set
    full_name = coalesce(nullif(g->>'full_name',''), full_name),
    phone_number = coalesce(nullif(g->>'phone_number',''), phone_number),
    relationship_to_learner = coalesce(nullif(g->>'relationship_to_learner',''), relationship_to_learner),
    updated_at = now()
  where id = v_uid;

  insert into public.learners (learner_id, parent_id, first_name, middle_name, surname,
    initials, other_names, id_number, date_of_birth, gender, previous_school_name,
    highest_grade_passed, year_grade_passed, school_history_notes)
  values (v_learner, v_uid, l->>'first_name', nullif(l->>'middle_name',''), l->>'surname',
    nullif(l->>'initials',''), nullif(l->>'other_names',''), nullif(l->>'id_number',''),
    nullif(l->>'date_of_birth','')::date, nullif(l->>'gender',''),
    nullif(l->>'previous_school_name',''), nullif(l->>'highest_grade_passed',''),
    nullif(l->>'year_grade_passed',''), nullif(l->>'school_history_notes',''));

  insert into public.learner_medical_info (learner_id, medical_aid_name, medical_aid_number,
    medical_aid_main_member, doctor_name, doctor_address, siblings_at_school)
  values (v_learner, nullif(m->>'medical_aid_name',''), nullif(m->>'medical_aid_number',''),
    nullif(m->>'medical_aid_main_member',''), nullif(m->>'doctor_name',''),
    nullif(m->>'doctor_address',''), nullif(m->>'siblings_at_school',''));

  v_ref := 'PH' || to_char(now(), 'YYYY') || '-' ||
           lpad(nextval('public.application_reference_seq')::text, 3, '0');

  insert into public.applications (application_id, reference_number, learner_id, submitted_by,
    grade_applied_for, status, payment_verification_status)
  values (v_app, v_ref, v_learner, v_uid, p_payload->>'grade_applied_for',
    'Pending Admin Review', 'Pending');

  for v_doc in select * from jsonb_array_elements(p_payload->'documents') loop
    insert into public.application_documents (application_id, document_type, file_name,
      storage_path, uploaded_by)
    values (v_app, v_doc->>'document_type', v_doc->>'file_name', v_doc->>'storage_path', v_uid);
  end loop;

  insert into public.payments (application_id, payment_reference, amount, proof_file_name,
    proof_storage_path, verification_status)
  values (v_app, pay->>'payment_reference', (pay->>'amount')::numeric,
    pay->>'proof_file_name', pay->>'proof_storage_path', 'Pending');

  insert into public.application_status_history (application_id, changed_by, new_status, change_reason)
  values (v_app, v_uid, 'Pending Admin Review', 'Application submitted by parent');

  insert into public.notifications (application_id, recipient_id, notification_type, title, message)
  values (v_app, v_uid, 'status_update', 'Application Received',
    'Your application ' || v_ref || ' was received and is waiting for payment verification and review.');

  return jsonb_build_object('application_id', v_app, 'reference_number', v_ref);
end $$;

-- Replace a document after "Corrections Requested".
create or replace function public.replace_document(p_payload jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_app uuid := (p_payload->>'application_id')::uuid;
  v_status text;
begin
  select status into v_status from public.applications
   where application_id = v_app and submitted_by = v_uid;
  if v_status is null then raise exception 'Application not found.'; end if;
  if v_status not in ('Pending Admin Review','Corrections Requested') then
    raise exception 'This application can no longer be changed.';
  end if;
  update public.application_documents
     set file_name = p_payload->>'file_name',
         storage_path = p_payload->>'storage_path',
         uploaded_by = v_uid, uploaded_at = now()
   where application_id = v_app and document_type = p_payload->>'document_type';
  if not found then
    insert into public.application_documents (application_id, document_type, file_name, storage_path, uploaded_by)
    values (v_app, p_payload->>'document_type', p_payload->>'file_name', p_payload->>'storage_path', v_uid);
  end if;
end $$;

-- New proof of payment after a rejection: NEW row, history kept (SRS Decision 1).
create or replace function public.resubmit_payment_proof(p_payload jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_app uuid := (p_payload->>'application_id')::uuid;
begin
  if not exists (select 1 from public.applications where application_id = v_app and submitted_by = v_uid) then
    raise exception 'Application not found.';
  end if;
  insert into public.payments (application_id, payment_reference, amount, proof_file_name,
    proof_storage_path, verification_status)
  values (v_app, p_payload->>'payment_reference', (p_payload->>'amount')::numeric,
    p_payload->>'proof_file_name', p_payload->>'proof_storage_path', 'Pending');
end $$;

-- Parent sends a "Corrections Requested" application back for review.
create or replace function public.resubmit_for_review(p_application_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid();
begin
  update public.applications set status = 'Pending Admin Review', updated_at = now()
   where application_id = p_application_id and submitted_by = v_uid
     and status = 'Corrections Requested';
  if not found then raise exception 'This application is not waiting for corrections.'; end if;
  insert into public.application_status_history (application_id, changed_by, old_status, new_status, change_reason)
  values (p_application_id, v_uid, 'Corrections Requested', 'Pending Admin Review', 'Corrections resubmitted by parent');
end $$;

grant execute on function public.submit_enrolment(jsonb) to authenticated;
grant execute on function public.replace_document(jsonb) to authenticated;
grant execute on function public.resubmit_payment_proof(jsonb) to authenticated;
grant execute on function public.resubmit_for_review(uuid) to authenticated;

-- ------------------------------------------------- Row Level Security
alter table public.profiles enable row level security;
alter table public.learners enable row level security;
alter table public.learner_medical_info enable row level security;
alter table public.applications enable row level security;
alter table public.application_documents enable row level security;
alter table public.payments enable row level security;
alter table public.application_notes enable row level security;
alter table public.application_status_history enable row level security;
alter table public.confirmation_letters enable row level security;
alter table public.notifications enable row level security;
alter table public.school_payment_records enable row level security;

-- Parents: own data only (NFR2). Parents NEVER read application_notes
-- or school_payment_records.
drop policy if exists profiles_self_select on public.profiles;
create policy profiles_self_select on public.profiles for select
  using (id = auth.uid() or public.is_staff());
drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid() and role = public.app_role());

drop policy if exists learners_parent_select on public.learners;
create policy learners_parent_select on public.learners for select
  using (parent_id = auth.uid() or public.is_staff());

drop policy if exists medical_parent_select on public.learner_medical_info;
create policy medical_parent_select on public.learner_medical_info for select
  using (exists (select 1 from public.learners l where l.learner_id = learner_medical_info.learner_id
                 and l.parent_id = auth.uid()) or public.app_role() = 'Administrator');

drop policy if exists applications_select on public.applications;
create policy applications_select on public.applications for select
  using (submitted_by = auth.uid() or public.is_staff());

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

drop policy if exists notifications_select on public.notifications;
create policy notifications_select on public.notifications for select
  using (recipient_id = auth.uid());
drop policy if exists notifications_update on public.notifications;
create policy notifications_update on public.notifications for update
  using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

-- Staff policies (starting point for the ASP.NET app; adjust with that team).
drop policy if exists admin_update_applications on public.applications;
create policy admin_update_applications on public.applications for update
  using (public.app_role() = 'Administrator');
drop policy if exists clerk_update_payments on public.payments;
create policy clerk_update_payments on public.payments for update
  using (public.app_role() = 'Financial Clerk');
drop policy if exists admin_notes_all on public.application_notes;
create policy admin_notes_all on public.application_notes for all
  using (public.app_role() = 'Administrator') with check (public.app_role() = 'Administrator');
drop policy if exists admin_notifications_insert on public.notifications;
create policy admin_notifications_insert on public.notifications for insert
  with check (public.app_role() = 'Administrator');
drop policy if exists admin_history_insert on public.application_status_history;
create policy admin_history_insert on public.application_status_history for insert
  with check (public.app_role() = 'Administrator');
drop policy if exists admin_letters_all on public.confirmation_letters;
create policy admin_letters_all on public.confirmation_letters for all
  using (public.app_role() = 'Administrator') with check (public.app_role() = 'Administrator');
drop policy if exists clerk_school_records on public.school_payment_records;
create policy clerk_school_records on public.school_payment_records for select
  using (public.app_role() = 'Financial Clerk');

-- ----------------------------------------------------------- Storage
-- Private bucket; files live under  <user id>/<application id>/...
insert into storage.buckets (id, name, public)
values ('enrolment-documents', 'enrolment-documents', false)
on conflict (id) do update set public = false;

drop policy if exists "parents upload own files" on storage.objects;
create policy "parents upload own files" on storage.objects for insert to authenticated
  with check (bucket_id = 'enrolment-documents'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "parents read own files" on storage.objects;
create policy "parents read own files" on storage.objects for select to authenticated
  using (bucket_id = 'enrolment-documents'
         and ((storage.foldername(name))[1] = auth.uid()::text or public.is_staff()));


create or replace function public.delete_application(p_application_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_learner uuid;
begin
  if v_uid is null then raise exception 'Please log in again.'; end if;

  select learner_id into v_learner
    from public.applications
   where application_id = p_application_id and submitted_by = v_uid;
  if v_learner is null then raise exception 'Application not found.'; end if;

  delete from public.notifications              where application_id = p_application_id;
  delete from public.confirmation_letters       where application_id = p_application_id;
  delete from public.application_notes          where application_id = p_application_id;
  delete from public.application_status_history where application_id = p_application_id;
  delete from public.payments                   where application_id = p_application_id;
  delete from public.application_documents      where application_id = p_application_id;
  delete from public.applications               where application_id = p_application_id;

  delete from public.learner_medical_info where learner_id = v_learner;
  delete from public.learners
   where learner_id = v_learner
     and not exists (select 1 from public.applications where learner_id = v_learner);
end $$;

grant execute on function public.delete_application(uuid) to authenticated;

-- Parents may delete files in their own folder (<user id>/...).
drop policy if exists "parents delete own files" on storage.objects;
create policy "parents delete own files" on storage.objects for delete to authenticated
  using (bucket_id = 'enrolment-documents'
         and (storage.foldername(name))[1] = auth.uid()::text);

-- Confirmation-letter PDFs can be deleted only once their application is gone.
create or replace function public.application_exists(p_id text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.applications where application_id::text = p_id)
$$;

drop policy if exists "delete orphaned letters" on storage.objects;
create policy "delete orphaned letters" on storage.objects for delete to authenticated
  using (bucket_id = 'enrolment-documents'
         and (storage.foldername(name))[1] = 'confirmation-letters'
         and not public.application_exists(split_part(storage.filename(name), '.', 1)));