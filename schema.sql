-- Future Axis Investor Ledger — database setup
-- Run in Supabase: SQL Editor → New query → paste everything → Run.
-- Safe to run again: it upgrades an earlier setup without losing data.

------------------------------------------------------------------------
-- 1. MEMBERS — who may use the system
--    role:   admin (manages users + edits) | cfo (all admin rights except users) | editor (edits) | viewer (reads)
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
alter table public.members add  constraint members_role_check   check (role in ('admin','cfo','editor','viewer'));
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
create policy "editors insert records" on public.records for insert to authenticated with check (public.member_role() in ('admin','cfo','editor'));
create policy "editors update records" on public.records for update to authenticated using (public.member_role() in ('admin','cfo','editor')) with check (public.member_role() in ('admin','cfo','editor'));
create policy "editors delete records" on public.records for delete to authenticated using (public.member_role() in ('admin','cfo','editor'));

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

------------------------------------------------------------------------
-- 8. ACTIVITY LOG — every add / change / delete, written by the database
--    itself (the app can read it but can never edit or delete it)
------------------------------------------------------------------------
create table if not exists public.audit_log (
  id          bigserial primary key,
  at          timestamptz not null default now(),
  user_id     uuid default auth.uid(),
  user_email  text,
  action      text not null,               -- insert | update | delete | event
  collection  text,
  record_id   text,
  old_data    jsonb,
  new_data    jsonb,
  detail      text,
  category    text not null default 'data' -- data | event | auth (sign-ins: admins only)
);
create index if not exists audit_log_at  on public.audit_log (at desc);
create index if not exists audit_log_rec on public.audit_log (collection, record_id);
alter table public.audit_log enable row level security;
drop policy if exists "full read log" on public.audit_log;
create policy "full read log" on public.audit_log for select to authenticated
  using (public.member_role() in ('admin','cfo') and (category <> 'auth' or public.is_admin()));

create or replace function public.current_email() returns text
language sql stable security definer set search_path = public as $$
  select coalesce((select email from public.members where user_id = auth.uid()),
                  (select email from auth.users where id = auth.uid()))
$$;

create or replace function public.log_record_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if coalesce(current_setting('fa.skip_audit', true), '') = 'on' then return null; end if;
  if tg_op = 'UPDATE' and (old.data - 'updatedAt' - 'createdAt') = (new.data - 'updatedAt' - 'createdAt') then return null; end if;   -- re-saved, nothing changed
  insert into public.audit_log (user_id, user_email, action, collection, record_id, old_data, new_data)
  values (auth.uid(), public.current_email(), lower(tg_op),
          coalesce(new.collection, old.collection), coalesce(new.id, old.id),
          case when tg_op <> 'INSERT' then old.data end,
          case when tg_op <> 'DELETE' then new.data end);
  return null;
end $$;
drop trigger if exists records_audit on public.records;
create trigger records_audit after insert or update or delete on public.records
  for each row execute function public.log_record_change();

-- events the app reports (sign-in, email sent, statement uploaded, …)
create or replace function public.log_event(p_action text, p_detail text default null, p_category text default 'event')
returns void language plpgsql security definer set search_path = public as $$
begin
  if public.member_role() is null then raise exception 'Not allowed'; end if;
  insert into public.audit_log (user_id, user_email, action, detail, category)
  values (auth.uid(), public.current_email(), 'event',
          left(coalesce(p_action,'') || coalesce(': ' || p_detail, ''), 2000),
          case when p_category = 'auth' then 'auth' else 'event' end);
end $$;

------------------------------------------------------------------------
-- 9. BACKUPS — full copies of all business data, kept inside Supabase.
--    A daily copy is taken automatically (scheduled, or at the first
--    sign-in of the day). Daily copies are kept 30 days; manual ones until deleted.
------------------------------------------------------------------------
create table if not exists public.backups (
  id             bigserial primary key,
  taken_at       timestamptz not null default now(),
  taken_by       uuid,
  taken_by_email text,
  kind           text not null default 'manual',  -- manual | daily | before restore | before start again
  label          text,
  row_count      int not null default 0,
  size_bytes     bigint not null default 0,
  data           jsonb not null default '[]'::jsonb
);
create index if not exists backups_taken on public.backups (taken_at desc);
alter table public.backups enable row level security;
drop policy if exists "full read backups" on public.backups;
create policy "full read backups" on public.backups for select to authenticated
  using (public.member_role() in ('admin','cfo'));

create or replace function public.take_backup(p_kind text default 'manual', p_label text default null)
returns bigint language plpgsql security definer set search_path = public as $$
declare v_id bigint; v_rows jsonb; v_n int;
begin
  if auth.uid() is not null and coalesce(public.member_role(),'') not in ('admin','cfo') and p_kind <> 'daily' then
    raise exception 'Only Admin or CFO can take backups'; end if;
  select coalesce(jsonb_agg(jsonb_build_object('collection', collection, 'id', id, 'data', data) order by collection, id), '[]'::jsonb), count(*)
    into v_rows, v_n from public.records;
  insert into public.backups (taken_by, taken_by_email, kind, label, row_count, size_bytes, data)
  values (auth.uid(), public.current_email(), p_kind, nullif(trim(coalesce(p_label,'')),''), v_n, octet_length(v_rows::text), v_rows)
  returning id into v_id;
  delete from public.backups where kind <> 'manual' and taken_at < now() - interval '30 days';
  if p_kind <> 'daily' then
    insert into public.audit_log (user_id, user_email, action, detail, category)
    values (auth.uid(), public.current_email(), 'event', 'Backup taken: #' || v_id || ' (' || p_kind || ', ' || v_n || ' records)', 'event');
  end if;
  return v_id;
end $$;

-- one automatic copy per day (Dubai time); any approved member's first sign-in triggers it
create or replace function public.take_daily_backup() returns bigint
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and public.member_role() is null then raise exception 'Not allowed'; end if;
  if exists (select 1 from public.backups where kind = 'daily'
             and (taken_at at time zone 'Asia/Dubai')::date = (now() at time zone 'Asia/Dubai')::date) then
    return null; end if;
  return public.take_backup('daily', null);
end $$;

create or replace function public._restore_rows(p_rows jsonb, p_label text)
returns int language plpgsql security definer set search_path = public as $$
declare v_n int;
begin
  if coalesce(public.member_role(),'') not in ('admin','cfo') then raise exception 'Only Admin or CFO can restore'; end if;
  if jsonb_typeof(p_rows) <> 'array' then raise exception 'Backup file is not in the expected format'; end if;
  if exists (select 1 from jsonb_array_elements(p_rows) e
             where coalesce(e->>'collection','') = '' or coalesce(e->>'id','') = '' or jsonb_typeof(e->'data') <> 'object') then
    raise exception 'Backup file is not in the expected format'; end if;
  perform public.take_backup('before restore', 'Automatic copy before restoring ' || p_label);
  perform set_config('fa.skip_audit', 'on', true);
  delete from public.records;
  insert into public.records (collection, id, data)
    select distinct on (e->>'collection', e->>'id') e->>'collection', e->>'id', e->'data' from jsonb_array_elements(p_rows) e;
  get diagnostics v_n = row_count;
  perform set_config('fa.skip_audit', 'off', true);
  insert into public.audit_log (user_id, user_email, action, detail, category)
  values (auth.uid(), public.current_email(), 'event', 'Restored ' || p_label || ' (' || v_n || ' records)', 'event');
  return v_n;
end $$;

create or replace function public.restore_backup(p_id bigint) returns int
language plpgsql security definer set search_path = public as $$
declare v_rows jsonb; v_at timestamptz;
begin
  select data, taken_at into v_rows, v_at from public.backups where id = p_id;
  if v_rows is null then raise exception 'Backup not found'; end if;
  return public._restore_rows(v_rows, 'backup #' || p_id || ' of ' || to_char(v_at at time zone 'Asia/Dubai', 'DD Mon YYYY HH24:MI'));
end $$;

create or replace function public.restore_from_file(p_rows jsonb, p_name text default 'file') returns int
language sql security definer set search_path = public as $$
  select public._restore_rows(p_rows, 'from file ' || coalesce(p_name,'file'))
$$;

create or replace function public.delete_backup(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
begin
  if coalesce(public.member_role(),'') not in ('admin','cfo') then raise exception 'Only Admin or CFO can delete backups'; end if;
  delete from public.backups where id = p_id;
  insert into public.audit_log (user_id, user_email, action, detail, category)
  values (auth.uid(), public.current_email(), 'event', 'Backup #' || p_id || ' deleted', 'event');
end $$;

-- Start again: takes a backup first, then clears the business data (settings, users and email history are kept)
create or replace function public.start_again() returns int
language plpgsql security definer set search_path = public as $$
declare v_n int; v_id bigint;
begin
  if coalesce(public.member_role(),'') not in ('admin','cfo') then raise exception 'Only Admin or CFO can do this'; end if;
  v_id := public.take_backup('before start again', 'Automatic copy before Start again');
  perform set_config('fa.skip_audit', 'on', true);
  delete from public.records where collection in ('bankLines','ledger','placements','businesses','shareholders','bankAccounts','suppliers');
  get diagnostics v_n = row_count;
  perform set_config('fa.skip_audit', 'off', true);
  insert into public.audit_log (user_id, user_email, action, detail, category)
  values (auth.uid(), public.current_email(), 'event', 'Start again: ' || v_n || ' records deleted (backup #' || v_id || ' taken first)', 'event');
  return v_n;
end $$;

-- only signed-in members may call these (never anonymous visitors)
do $$ declare f text; begin
  foreach f in array array['public.log_event(text,text,text)','public.take_backup(text,text)','public.take_daily_backup()',
    'public._restore_rows(jsonb,text)','public.restore_backup(bigint)','public.restore_from_file(jsonb,text)',
    'public.delete_backup(bigint)','public.start_again()','public.current_email()'] loop
    execute 'revoke execute on function ' || f || ' from public, anon';
    execute 'grant execute on function ' || f || ' to authenticated';
  end loop;
end $$;
revoke execute on function public._restore_rows(jsonb,text) from authenticated;

-- daily backup at 02:00 Dubai time even if nobody signs in (needs pg_cron; skipped quietly if unavailable)
do $$ begin
  create extension if not exists pg_cron;
  perform cron.schedule('future-axis-daily-backup', '0 22 * * *', 'select public.take_daily_backup()');
exception when others then
  raise notice 'Scheduled backups not enabled (%). A daily backup is still taken at the first sign-in each day.', sqlerrm;
end $$;
