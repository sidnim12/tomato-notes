create table if not exists public.focus_sessions (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  task text not null check (char_length(task) between 1 and 500),
  minutes integer not null check (minutes between 1 and 180),
  status text not null check (status in ('complete', 'failed')),
  started_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists focus_sessions_user_id_idx
  on public.focus_sessions using btree (user_id);

create index if not exists focus_sessions_started_at_idx
  on public.focus_sessions using btree (started_at desc);

alter table public.focus_sessions enable row level security;

revoke all on table public.focus_sessions from anon, authenticated;
grant select, insert, update, delete on table public.focus_sessions to authenticated;

drop policy if exists "Users read their own sessions" on public.focus_sessions;
create policy "Users read their own sessions"
  on public.focus_sessions for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users create their own sessions" on public.focus_sessions;
create policy "Users create their own sessions"
  on public.focus_sessions for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users update their own sessions" on public.focus_sessions;
create policy "Users update their own sessions"
  on public.focus_sessions for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users delete their own sessions" on public.focus_sessions;
create policy "Users delete their own sessions"
  on public.focus_sessions for delete to authenticated
  using ((select auth.uid()) = user_id);

create table if not exists public.developer_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.developer_members enable row level security;
revoke all on table public.developer_members from anon, authenticated;
grant select on table public.developer_members to authenticated;

drop policy if exists "Developers can verify their own membership" on public.developer_members;
create policy "Developers can verify their own membership"
  on public.developer_members for select to authenticated
  using ((select auth.uid()) = user_id);

create table if not exists public.app_issues (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reporter_email text not null,
  title text not null check (char_length(title) between 5 and 160),
  description text not null check (char_length(description) between 10 and 5000),
  device text check (char_length(device) <= 240),
  category text not null default 'bug' check (category in ('bug', 'feature', 'feedback')),
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists app_issues_reporter_id_idx on public.app_issues (reporter_id);
create index if not exists app_issues_status_idx on public.app_issues (status, created_at desc);

alter table public.app_issues enable row level security;
revoke all on table public.app_issues from anon, authenticated;
grant select, insert, update, delete on table public.app_issues to authenticated;

drop policy if exists "Signed-in users can submit issues" on public.app_issues;
create policy "Signed-in users can submit issues"
  on public.app_issues for insert to authenticated
  with check ((select auth.uid()) = reporter_id);

drop policy if exists "Developers can read issues" on public.app_issues;
create policy "Developers can read issues"
  on public.app_issues for select to authenticated
  using (exists (select 1 from public.developer_members d where d.user_id = (select auth.uid())));

drop policy if exists "Developers can update issues" on public.app_issues;
create policy "Developers can update issues"
  on public.app_issues for update to authenticated
  using (exists (select 1 from public.developer_members d where d.user_id = (select auth.uid())))
  with check (exists (select 1 from public.developer_members d where d.user_id = (select auth.uid())));

drop policy if exists "Developers can delete issues" on public.app_issues;
create policy "Developers can delete issues"
  on public.app_issues for delete to authenticated
  using (exists (select 1 from public.developer_members d where d.user_id = (select auth.uid())));

-- After your owner account is created, promote it from the SQL Editor:
-- insert into public.developer_members (user_id)
-- select id from auth.users where email = 'YOUR_EMAIL';
