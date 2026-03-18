-- Fix RLS Policies for app_errors table
-- Run this SQL in your Supabase SQL Editor

-- ============================================
-- DROP EXISTING POLICIES
-- ============================================
DROP POLICY IF EXISTS "Authenticated users can insert errors" ON app_errors;
DROP POLICY IF EXISTS "Admins can view all errors" ON app_errors;
DROP POLICY IF EXISTS "Admins can update errors" ON app_errors;
DROP POLICY IF EXISTS "Service role can access errors" ON app_errors;

-- ============================================
-- NEW POLICIES - Allow anonymous error reporting
-- ============================================

-- Anyone can INSERT errors (critical for error tracking!)
CREATE POLICY "Anyone can insert errors"
  ON app_errors FOR INSERT
  WITH CHECK (true);

-- Only authenticated admins can SELECT errors
CREATE POLICY "Admins can view all errors"
  ON app_errors FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- Only authenticated admins can UPDATE errors
CREATE POLICY "Admins can update errors"
  ON app_errors FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- Service role can access everything (for server-side operations)
CREATE POLICY "Service role can access errors"
  ON app_errors FOR ALL
  USING (auth.role() = 'service_role');
