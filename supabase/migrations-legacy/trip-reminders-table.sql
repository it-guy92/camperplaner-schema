-- Travel reminders table
CREATE TABLE IF NOT EXISTS trip_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID REFERENCES trips(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  reminder_days_before INTEGER CHECK (reminder_days_before IN (3, 7, 14)) NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL,
  last_sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(trip_id, reminder_days_before)
);

-- Enable RLS
ALTER TABLE trip_reminders ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Users can view their own reminders" ON trip_reminders
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own reminders" ON trip_reminders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reminders" ON trip_reminders
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reminders" ON trip_reminders
  FOR DELETE USING (auth.uid() = user_id);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_trip_reminders_user_id ON trip_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_trip_reminders_trip_id ON trip_reminders(trip_id);
