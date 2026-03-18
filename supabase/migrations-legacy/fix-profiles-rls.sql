-- Fix RLS policies for profiles table
-- Allow users to read their own profile
CREATE POLICY "Users can read own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Allow service role full access
CREATE POLICY "Service role full access"
ON profiles FOR ALL
USING (true)
WITH CHECK (true);
