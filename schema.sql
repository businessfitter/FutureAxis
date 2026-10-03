-- Future Axis Investor Ledger — database setup
-- Run once in Supabase: SQL Editor → New query → paste → Run.

-- 1. Members: who may use the system, and whether they can edit.
create table if not exists public.members (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  role       text not null default 'editor' check (role in ('editor','viewer')),
  created_at timestamptz not null default now()
);
alter table public.members enable row level security;
drop policy if exists "members read own row" on public.members;
create policy "members read own row" on public.members
  for select to authenticated using (user_id = auth.uid());

-- 2. Records: ventures, placements, ledger entries and settings.
--    collection = 'businesses' | 'placements' | 'ledger' | 'config'
create table if not exists public.records (
  collection text not null,
  id         text not null,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid(),
  primary key (collection, id)
);
alter table public.records enable row level security;

create or replace function public.member_role() returns text
language sql stable security definer set search_path = public as $$
  select role from public.members where user_id = auth.uid()
$$;

drop policy if exists "members read records"  on public.records;
drop policy if exists "editors insert records" on public.records;
drop policy if exists "editors update records" on public.records;
drop policy if exists "editors delete records" on public.records;
create policy "members read records"   on public.records for select to authenticated using (public.member_role() is not null);
create policy "editors insert records" on public.records for insert to authenticated with check (public.member_role() = 'editor');
create policy "editors update records" on public.records for update to authenticated using (public.member_role() = 'editor') with check (public.member_role() = 'editor');
create policy "editors delete records" on public.records for delete to authenticated using (public.member_role() = 'editor');

-- 3. Stamp who changed each record.
create or replace function public.touch_record() returns trigger
language plpgsql as $$
begin new.updated_at := now(); new.updated_by := auth.uid(); return new; end $$;
drop trigger if exists records_touch on public.records;
create trigger records_touch before insert or update on public.records
  for each row execute function public.touch_record();

-- 4. Live updates between users.
do $$ begin
  alter publication supabase_realtime add table public.records;
exception when duplicate_object then null; end $$;

-- 5. Readable views for reporting in SQL / Excel (optional).
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
