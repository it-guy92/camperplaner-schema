-- ============================================
-- MIGRATION: Fix campsite_prices FK
-- Issue: user_id references auth.users instead of profiles
-- Fix: Change FK to reference profiles(id)
-- ============================================

-- Drop existing FK constraint (if exists)
ALTER TABLE campsite_prices 
DROP CONSTRAINT IF EXISTS campsite_prices_user_id_fkey;

-- Create new FK constraint to profiles table
ALTER TABLE campsite_prices 
ADD CONSTRAINT campsite_prices_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- Add comment for documentation
COMMENT ON CONSTRAINT campsite_prices_user_id_fkey ON campsite_prices IS 
  'Fixed FK: Now correctly references profiles(id) instead of auth.users(id)';

-- ============================================
-- VERIFICATION
-- ============================================
-- Run this to verify after applying:
-- SELECT conname, pg_get_constraintdef(oid) 
-- FROM pg_constraint 
-- WHERE conrelid = 'campsite_prices'::regclass AND contype = 'f';
