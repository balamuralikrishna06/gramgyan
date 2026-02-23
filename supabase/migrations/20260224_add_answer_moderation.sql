-- 1. Add question_id to knowledge_submissions (allows treating it as an answer)
ALTER TABLE public.knowledge_submissions
  ADD COLUMN IF NOT EXISTS question_id uuid REFERENCES public.questions(id) ON DELETE CASCADE;

-- 2. Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  question_id uuid REFERENCES public.questions(id) ON DELETE CASCADE,
  is_read boolean DEFAULT false,
  created_at timestamp DEFAULT now()
);

-- 3. Enable RLS on notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 4. Notification Policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Note: System/Admin functions will insert into notifications, so no insert policy directly for users.
