-- Fix knowledge_posts Foreign Key
-- Since the app uses Firebase Auth, Supabase's auth.users is not perfectly synced.
-- public.users uses its own UUIDs. knowledge_posts should reference public.users(id) instead.

-- 1. Drop the incorrect Foreign Key constraints to auth.users
ALTER TABLE public.knowledge_posts DROP CONSTRAINT IF EXISTS knowledge_posts_user_id_fkey;
ALTER TABLE public.knowledge_posts DROP CONSTRAINT IF EXISTS knowledge_posts_verified_by_fkey;

-- 2. Add Foreign Key constraints to public.users
ALTER TABLE public.knowledge_posts
  ADD CONSTRAINT knowledge_posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE public.knowledge_posts
  ADD CONSTRAINT knowledge_posts_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES public.users(id) ON DELETE SET NULL;
