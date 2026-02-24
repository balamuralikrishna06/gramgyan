-- Since the app uses Firebase Auth, Supabase's auth.users is not practically synced for all users.
-- The user IDs stored in `questions.user_id` belong to `public.users(id)`.

-- 1. Drop the incorrect Foreign Key constraint to auth.users (or old public.users constraint)
ALTER TABLE public.questions DROP CONSTRAINT IF EXISTS questions_user_id_fkey;
ALTER TABLE public.questions DROP CONSTRAINT IF EXISTS questions_user_id_fkey1;

-- 2. Add the correct Foreign Key constraint pointing to public.users
ALTER TABLE public.questions 
  ADD CONSTRAINT questions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
