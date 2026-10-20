-- Optional TEST data only (fictional - NFR3). Run after schema.sql.
-- Parent test accounts are created through the app's Register screen
-- (or Authentication > Users in the dashboard), not by SQL.

insert into public.school_payment_records
  (payment_reference, learner_name, learner_id_number, amount, payment_date, payment_method)
values
  ('TEST-REF-001', 'Test Learner One', '1205145000084', 200.00, current_date, 'EFT'),
  ('TEST-REF-002', 'Test Learner Two', '1103125000081', 200.00, current_date, 'EFT')
on conflict (payment_reference) do nothing;
