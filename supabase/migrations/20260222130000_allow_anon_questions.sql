-- To allow anonymous questions when user is not logged in
DROP POLICY IF EXISTS "Authenticated users can insert questions" ON questions;
CREATE POLICY "Users and Guests can insert questions"
  ON questions FOR INSERT WITH CHECK (true);
