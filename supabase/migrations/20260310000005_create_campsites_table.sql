CREATE TABLE campsites (
    place_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    source_type TEXT NOT NULL CHECK (source_type IN ('osm', 'user', 'scraped', 'wikidata')),
    osm_id TEXT,
    osm_tags JSONB DEFAULT '{}'::jsonb,
    website TEXT,
    opening_hours TEXT,
    contact_phone TEXT,
    contact_email TEXT,
    scraped_website_url TEXT,
    scraped_at TIMESTAMPTZ,
    scraped_price_info JSONB,
    scraped_data_source TEXT CHECK (scraped_data_source IN ('website', 'user', 'osm')),
    description TEXT,
    description_source TEXT CHECK (description_source IN ('osm', 'wikidata', 'google_reviews', 'llm_osm', 'llm_enhanced', 'user')),
    description_generated_at TIMESTAMPTZ,
    description_version INTEGER DEFAULT 1,
    estimated_price NUMERIC(6,2),
    price_source TEXT DEFAULT 'estimated' CHECK (price_source IN ('user', 'osm', 'estimated')),
    user_price_count INTEGER DEFAULT 0,
    user_price_avg NUMERIC(6,2),
    place_types TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_campsites_location ON campsites USING GIST(location);
CREATE INDEX idx_campsites_source_type ON campsites(source_type);
CREATE INDEX idx_campsites_place_types ON campsites USING GIN(place_types);

ALTER TABLE campsites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access" ON campsites FOR SELECT USING (true);
CREATE POLICY "Service role full access" ON campsites FOR ALL USING (auth.role() = 'service_role');

DROP TRIGGER IF EXISTS update_campsites_updated_at ON campsites;
CREATE TRIGGER update_campsites_updated_at
    BEFORE UPDATE ON campsites
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
