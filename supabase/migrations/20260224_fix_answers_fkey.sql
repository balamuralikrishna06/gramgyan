-- 1. Drop the incorrect Foreign Key constraint to auth.users
ALTER TABLE public.answers DROP CONSTRAINT IF EXISTS answers_user_id_fkey;

-- 2. Add Foreign Key constraint to public.users
ALTER TABLE public.answers
  ADD CONSTRAINT answers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
