-- Add missing columns to 'questions' table for full discussion feature support
ALTER TABLE questions
  ADD COLUMN IF NOT EXISTS crop text DEFAULT 'General',
  ADD COLUMN IF NOT EXISTS category text DEFAULT 'Crops',
  ADD COLUMN IF NOT EXISTS farmer_name text DEFAULT 'Farmer',
  ADD COLUMN IF NOT EXISTS location text DEFAULT 'Unknown',
  ADD COLUMN IF NOT EXISTS audio_url text,
  ADD COLUMN IF NOT EXISTS reply_count int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS karma int DEFAULT 0;

-- Add missing columns to 'answers' table
ALTER TABLE answers
  ADD COLUMN IF NOT EXISTS farmer_name text DEFAULT 'Farmer',
  ADD COLUMN IF NOT EXISTS karma int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_verified boolean DEFAULT false;

-- Enable RLS policies for questions
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view questions" ON questions;
CREATE POLICY "Anyone can view questions"
  ON questions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert questions" ON questions;
CREATE POLICY "Authenticated users can insert questions"
  ON questions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Enable RLS policies for answers
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view answers" ON answers;
CREATE POLICY "Anyone can view answers"
  ON answers FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert answers" ON answers;
CREATE POLICY "Authenticated users can insert answers"
  ON answers FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own answers" ON answers;
CREATE POLICY "Users can update their own answers"
  ON answers FOR UPDATE USING (auth.uid() = user_id);

-- Helper function to atomically increment reply_count on a question
CREATE OR REPLACE FUNCTION increment_reply_count(q_id uuid)
RETURNS void
LANGUAGE sql
AS $$
  UPDATE questions SET reply_count = reply_count + 1 WHERE id = q_id;
$$;

-- Helper function to atomically increment karma on an answer
CREATE OR REPLACE FUNCTION increment_answer_karma(a_id uuid, points int)
RETURNS void
LANGUAGE sql
AS $$
  UPDATE answers SET karma = karma + points WHERE id = a_id;
$$;
