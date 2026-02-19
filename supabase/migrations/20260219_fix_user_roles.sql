-- Migration: Correcting User Roles Table
-- The app uses 'users' table for profiles, not 'profiles'.
-- 1. Add role column to 'users' table.
-- 2. Drop redundant 'profiles' table if empty.

-- 1. Add role column to 'users' table
alter table users 
add column if not exists role text default 'farmer';

-- 2. Drop redundant profiles table (if it was created by previous migration and is empty)
-- We'll keep it just in case, or drop it if we are sure. 
-- Let's just focus on 'users' table since config points there.

-- 3. Update RLS policies to use 'users' table for role checks
create or replace function public.is_admin_or_expert()
returns boolean as $$
declare
  _role text;
begin
  -- Check 'users' table instead of 'profiles'
  select role into _role from users where id = auth.uid();
  return _role in ('admin', 'expert');
end;
$$ language plpgsql security definer;

-- 4. Manual Admin Assignment (Run this in SQL Editor with your User ID)
-- REPLACE 'YOUR_USER_ID' with your actual UUID (e.g. 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11')
-- update users set role = 'admin' where id = 'YOUR_USER_ID';
