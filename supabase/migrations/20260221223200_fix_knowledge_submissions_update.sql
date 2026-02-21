-- 5. Create new RLS policy that allows Anon updates (since Flutter uses anon key with Firebase Auth)
-- This is required to allow the Admin Dashboard to change the moderation_status to 'approved' or 'rejected'.
CREATE POLICY "Allow public updates"
  ON public.knowledge_submissions FOR UPDATE
  USING (true);
