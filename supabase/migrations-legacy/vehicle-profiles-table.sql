-- Vehicle profiles table for storing user vehicle configurations
CREATE TABLE IF NOT EXISTS vehicle_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  max_speed NUMERIC DEFAULT 130,
  height NUMERIC DEFAULT 3.5,
  weight NUMERIC DEFAULT 3500,
  fuel_consumption NUMERIC DEFAULT 10,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE vehicle_profiles ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can view their own vehicle profiles" ON vehicle_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own vehicle profiles" ON vehicle_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own vehicle profiles" ON vehicle_profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own vehicle profiles" ON vehicle_profiles
  FOR DELETE USING (auth.uid() = user_id);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_vehicle_profiles_user_id ON vehicle_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_profiles_user_default ON vehicle_profiles(user_id) WHERE is_default = true;
