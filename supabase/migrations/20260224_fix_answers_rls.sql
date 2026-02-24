-- 1. Enable RLS on the answers table if not already enabled
ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;

-- 2. Allow any authenticated user to view answers
CREATE POLICY "Anyone can view answers"
  ON public.answers
  FOR SELECT
  USING (true);

-- 3. Allow authenticated users to insert answers (used during the approval process by admins/system)
CREATE POLICY "Authenticated users can insert answers"
  ON public.answers
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- 4. Allow users to update their own answers (optional but good practice)
CREATE POLICY "Users can update their own answers"
  ON public.answers
  FOR UPDATE
  USING (auth.uid() = user_id);

-- 5. Allow users to delete their own answers
CREATE POLICY "Users can delete their own answers"
  ON public.answers
  FOR DELETE
  USING (auth.uid() = user_id);
