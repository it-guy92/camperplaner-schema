-- Campsite Reviews Table
-- Stores user ratings and comments for camping places

CREATE TABLE IF NOT EXISTS campsite_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  place_id TEXT NOT NULL,
  place_name TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Unique constraint: one review per user per place
  CONSTRAINT unique_user_place_review UNIQUE (user_id, place_id)
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_campsite_reviews_place_id ON campsite_reviews(place_id);
CREATE INDEX IF NOT EXISTS idx_campsite_reviews_user_id ON campsite_reviews(user_id);

-- Enable RLS
ALTER TABLE campsite_reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Anyone can read reviews for a place
CREATE POLICY "Anyone can read campsite reviews"
  ON campsite_reviews FOR SELECT
  USING (true);

-- Users can insert their own reviews
CREATE POLICY "Users can insert their own reviews"
  ON campsite_reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own reviews
CREATE POLICY "Users can update their own reviews"
  ON campsite_reviews FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own reviews
CREATE POLICY "Users can delete their own reviews"
  ON campsite_reviews FOR DELETE
  USING (auth.uid() = user_id);

-- View for aggregated review stats per place
CREATE OR REPLACE VIEW campsite_review_summary AS
SELECT 
  place_id,
  place_name,
  COUNT(*) as review_count,
  AVG(rating)::NUMERIC(2,1) as avg_rating,
  MIN(rating) as min_rating,
  MAX(rating) as max_rating
FROM campsite_reviews
GROUP BY place_id, place_name;
