-- Campsite Prices Table for User-Generated Pricing
-- Priority: 1. User prices, 2. OSM prices, 3. Estimated categories

-- Create campsite_prices table
CREATE TABLE IF NOT EXISTS campsite_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    osm_place_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    price_per_night NUMERIC(6,2) NOT NULL CHECK (price_per_night >= 0 AND price_per_night <= 500),
    price_type TEXT DEFAULT 'per_night' CHECK (price_type IN ('per_night', 'entry_fee')),
    currency TEXT DEFAULT 'EUR' CHECK (currency IN ('EUR', 'CHF', 'USD', 'GBP')),
    rating NUMERIC(2,1) CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(osm_place_id, user_id)
);

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_campsite_prices_place_id ON campsite_prices(osm_place_id);
CREATE INDEX IF NOT EXISTS idx_campsite_prices_user_id ON campsite_prices(user_id);

-- Enable RLS
ALTER TABLE campsite_prices ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can read prices
CREATE POLICY "Public read access" ON campsite_prices
    FOR SELECT USING (true);

-- Policy: Users can insert their own prices
CREATE POLICY "Users can insert own prices" ON campsite_prices
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own prices
CREATE POLICY "Users can update own prices" ON campsite_prices
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can delete their own prices
CREATE POLICY "Users can delete own prices" ON campsite_prices
    FOR DELETE USING (auth.uid() = user_id);

-- Add columns to campsites_cache for price source tracking
ALTER TABLE campsites_cache 
    ADD COLUMN IF NOT EXISTS price_source TEXT DEFAULT 'estimated',
    ADD COLUMN IF NOT EXISTS user_price_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS user_price_avg NUMERIC(6,2);

-- Create function to update campsite price stats
CREATE OR REPLACE FUNCTION update_campsite_price_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE campsites_cache cc
    SET 
        user_price_count = (
            SELECT COUNT(*) 
            FROM campsite_prices cp 
            WHERE cp.osm_place_id = cc.place_id
        ),
        user_price_avg = (
            SELECT AVG(cp.price_per_night)::NUMERIC(6,2)
            FROM campsite_prices cp 
            WHERE cp.osm_place_id = cc.place_id
        ),
        price_source = CASE
            WHEN (
                SELECT COUNT(*) 
                FROM campsite_prices cp 
                WHERE cp.osm_place_id = cc.place_id
            ) > 0 THEN 'user'
            WHEN cc.estimated_price IS NOT NULL THEN 'osm'
            ELSE 'estimated'
        END
    WHERE cc.place_id = NEW.osm_place_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update stats when prices change
DROP TRIGGER IF EXISTS trigger_update_campsite_price_stats ON campsite_prices;
CREATE TRIGGER trigger_update_campsite_price_stats
    AFTER INSERT OR UPDATE OR DELETE ON campsite_prices
    FOR EACH ROW EXECUTE FUNCTION update_campsite_price_stats();

-- Create view to easily get aggregated prices
CREATE OR REPLACE VIEW campsite_price_summary AS
SELECT 
    cp.osm_place_id,
    COUNT(*) as price_count,
    AVG(cp.price_per_night)::NUMERIC(6,2) as avg_price,
    MIN(cp.price_per_night)::NUMERIC(6,2) as min_price,
    MAX(cp.price_per_night)::NUMERIC(6,2) as max_price,
    AVG(cp.rating)::NUMERIC(2,1) as avg_rating,
    COUNT(cp.review_text) FILTER (WHERE cp.review_text IS NOT NULL) as review_count
FROM campsite_prices cp
GROUP BY cp.osm_place_id;

COMMENT ON TABLE campsite_prices IS 'User-submitted prices for campsites/POIs. Priority: User > OSM > Estimated';
COMMENT ON TABLE campsites_cache IS 'Extended with price_source, user_price_count, user_price_avg for pricing system';
