-- Remove Foreign Key constraint linking public.users to auth.users
-- This is necessary because we are using Firebase Auth and generating our own UUIDs
-- which won't exist in Supabase's auth.users table.

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;
