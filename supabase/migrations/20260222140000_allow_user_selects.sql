-- Allow guests or auth users to read profiles from users table for mapping
DROP POLICY IF EXISTS "Anyone can view users" ON users;
CREATE POLICY "Anyone can view users"
  ON users FOR SELECT USING (true);
