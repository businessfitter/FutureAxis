-- Future Axis Investor Ledger — database setup
-- Run in Supabase: SQL Editor → New query → paste everything → Run.
-- Safe to run again: it upgrades an earlier setup without losing data.

------------------------------------------------------------------------
-- 1. MEMBERS — who may use the system
--    role:   admin (manages users + edits) | editor (edits) | viewer (reads)
--    status: pending (waiting for approval) | active | disabled
------------------------------------------------------------------------
create table if not exists public.members (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  role       text not null default 'viewer',
  created_at timestamptz not null default now()
);
-- existing rows (from an earlier setup) stay active; new rows start pending
alter table public.members add column if not exists status text not null default 'active';
alter table public.members alter column status set default 'pending';
alter table public.members add column if not exists email        text;
alter table public.members add column if not exists full_name    text;
alter table public.members add column if not exists requested_at timestamptz not null default now();
alter table public.members add column if not exists decided_by   uuid;
alter table public.members add column if not exists decided_at   timestamptz;
alter table public.members add column if not exists must_reset   boolean not null default false;
alter table public.members alter column role set default 'viewer';
alter table public.members drop constraint if exists members_role_check;
alter table public.members add  constraint members_role_check   check (role in ('admin','editor','viewer'));
alter table public.members drop constraint if exists members_status_check;
alter table public.members add  constraint members_status_check check (status in ('pending','active','disabled'));

-- every existing login gets a members row (pending) and an email on file
insert into public.members (user_id, email, full_name, status, role)
select u.id, u.email, coalesce(u.raw_user_meta_data->>'full_name',''), 'pending', 'viewer'
from auth.users u on conflict (user_id) do nothing;
update public.members m set email = u.email from auth.users u where u.id = m.user_id and m.email is null;

-- if there is no active admin yet, the earliest member becomes admin
update public.members set role = 'admin', status = 'active'
where user_id = (
  select user_id from public.members
  order by (status = 'active') desc, (role = 'editor') desc, created_at asc limit 1)
and not exists (select 1 from public.members where role = 'admin' and status = 'active');

------------------------------------------------------------------------
-- 2. HELPER FUNCTIONS
------------------------------------------------------------------------
create or replace function public.member_role() returns text
language sql stable security definer set search_path = public as $$
  select role from public.members where user_id = auth.uid() and status = 'active'
$$;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.members
                 where user_id = auth.uid() and role = 'admin' and status = 'active')
$$;

-- called by the app after a user replaces a temporary password
create or replace function public.password_changed() returns void
language sql security definer set search_path = public as $$
  update public.members set must_reset = false where user_id = auth.uid()
$$;
grant execute on function public.password_changed() to authenticated;

------------------------------------------------------------------------
-- 3. NEW SIGN-UPS ARRIVE AS PENDING (the very first one becomes admin)
------------------------------------------------------------------------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
declare has_admin boolean;
begin
  select exists (select 1 from public.members where role = 'admin' and status = 'active') into has_admin;
  insert into public.members (user_id, email, full_name, role, status, requested_at)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''),
          case when has_admin then 'viewer'  else 'admin'  end,
          case when has_admin then 'pending' else 'active' end, now())
  on conflict (user_id) do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- never allow the last active admin to be removed, disabled or demoted
create or replace function public.keep_one_admin() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.role = 'admin' and old.status = 'active'
     and (tg_op = 'DELETE' or new.role <> 'admin' or new.status <> 'active')
     and not exists (select 1 from public.members
                     where role = 'admin' and status = 'active' and user_id <> old.user_id) then
    raise exception 'At least one active admin is required. Make someone else admin first.';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end $$;
drop trigger if exists members_keep_admin on public.members;
create trigger members_keep_admin before update or delete on public.members
  for each row execute function public.keep_one_admin();

------------------------------------------------------------------------
-- 4. MEMBERS SECURITY — people see their own row; admins manage all
------------------------------------------------------------------------
alter table public.members enable row level security;
drop policy if exists "members read own row"   on public.members;
drop policy if exists "members read"           on public.members;
drop policy if exists "admins insert members"  on public.members;
drop policy if exists "admins update members"  on public.members;
drop policy if exists "admins delete members"  on public.members;
create policy "members read"          on public.members for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy "admins insert members" on public.members for insert to authenticated with check (public.is_admin());
create policy "admins update members" on public.members for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins delete members" on public.members for delete to authenticated using (public.is_admin());

------------------------------------------------------------------------
-- 5. RECORDS — ventures, placements, ledger entries and settings
------------------------------------------------------------------------
create table if not exists public.records (
  collection text not null,
  id         text not null,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid(),
  primary key (collection, id)
);
alter table public.records enable row level security;

drop policy if exists "members read records"   on public.records;
drop policy if exists "editors insert records" on public.records;
drop policy if exists "editors update records" on public.records;
drop policy if exists "editors delete records" on public.records;
create policy "members read records"   on public.records for select to authenticated using (public.member_role() is not null);
create policy "editors insert records" on public.records for insert to authenticated with check (public.member_role() in ('admin','editor'));
create policy "editors update records" on public.records for update to authenticated using (public.member_role() in ('admin','editor')) with check (public.member_role() in ('admin','editor'));
create policy "editors delete records" on public.records for delete to authenticated using (public.member_role() in ('admin','editor'));

create or replace function public.touch_record() returns trigger
language plpgsql as $$
begin new.updated_at := now(); new.updated_by := auth.uid(); return new; end $$;
drop trigger if exists records_touch on public.records;
create trigger records_touch before insert or update on public.records
  for each row execute function public.touch_record();

------------------------------------------------------------------------
-- 6. LIVE UPDATES between users
------------------------------------------------------------------------
do $$ begin alter publication supabase_realtime add table public.records;
exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table public.members;
exception when duplicate_object then null; end $$;

------------------------------------------------------------------------
-- 7. READABLE VIEWS for reporting in SQL / Excel (optional)
------------------------------------------------------------------------
create or replace view public.v_ventures with (security_invoker = true) as
  select id, data->>'code' as code, data->>'name' as name, data->>'nature' as nature,
         data->>'contact' as contact_person, (data->>'rate')::numeric as expected_rate,
         data->>'status' as status from public.records where collection = 'businesses';
create or replace view public.v_placements with (security_invoker = true) as
  select id, data->>'code' as code, data->>'investor' as investor, data->>'bizId' as venture_id,
         (data->>'amount')::numeric as amount, (data->>'rate')::numeric as agreed_rate,
         (data->>'date')::date as placement_date from public.records where collection = 'placements';
create or replace view public.v_ledger with (security_invoker = true) as
  select id, (data->>'date')::date as entry_date, data->>'type' as type, data->>'bizId' as venture_id,
         data->>'placementId' as placement_id, (data->>'amount')::numeric as amount, data->>'ref' as reference
  from public.records where collection = 'ledger';
