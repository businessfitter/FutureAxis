-- Make the "businessfitter" account an active Admin.
-- Run AFTER schema.sql: Supabase → SQL Editor → New query → paste → Run.
-- The account must already exist under Authentication → Users.
-- If its email does not start with "businessfitter", replace the pattern
-- below with the exact email, e.g.  where email = 'name@example.com'

insert into public.members (user_id, email, full_name, role, status)
select id, email, 'Business Fitter', 'admin', 'active'
from auth.users where email ilike 'businessfitter%'
on conflict (user_id) do update set role = 'admin', status = 'active', must_reset = false;

-- Check: the businessfitter row should show role = admin, status = active
select email, role, status from public.members order by role, email;
