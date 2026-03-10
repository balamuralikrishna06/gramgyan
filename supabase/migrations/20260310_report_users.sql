-- ─────────────────────────────────────────────
-- Migration: 20260310_report_users
-- Creates the report_users table for the
-- GramGyan Admin Report Generator feature.
-- ─────────────────────────────────────────────

create table if not exists report_users (
  id          uuid        primary key default uuid_generate_v4(),
  name        text        not null,
  email       text        not null,
  position    text        not null,
  created_at  timestamptz not null default now()
);

-- Enable RLS
alter table report_users enable row level security;

-- Policy: Only admins can select rows
create policy "report_users_select_admin"
  on report_users
  for select
  using (
    exists (
      select 1 from users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
  );

-- Policy: Only admins can insert rows
create policy "report_users_insert_admin"
  on report_users
  for insert
  with check (
    exists (
      select 1 from users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
  );

-- Policy: Only admins can delete rows
create policy "report_users_delete_admin"
  on report_users
  for delete
  using (
    exists (
      select 1 from users
      where users.id = auth.uid()
        and users.role = 'admin'
    )
  );
