-- Staff accounts
-- 1. Supabase > Authentication > Users > "Add user" (tick "Auto Confirm User").
--    Create one user for the Administrator and one for the Financial Clerk.
-- 2. Run the statements below with the real email addresses. New users start as 'Parent'.
--    The role stored here is the ONLY thing that decides what a person can do in the staff app.

update public.profiles
   set role = 'Administrator', full_name = 'Replace With Administrator Name'
 where email = 'administrator@example.com';

update public.profiles
   set role = 'Financial Clerk', full_name = 'Replace With Clerk Name'
 where email = 'clerk@example.com';

-- Check:
select email, full_name, role from public.profiles where role in ('Administrator','Financial Clerk');
