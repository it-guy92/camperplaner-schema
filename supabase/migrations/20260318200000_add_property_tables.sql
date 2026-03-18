-- ============================================================================
-- Migration: Add Property Tables (OSM, Google, LLM, User)
-- Date: 2026-03-18
-- Purpose: Phase 2 - Add aligned property tables with shared columns,
--          source-specific columns, current-row semantics, and proper indexes
-- ============================================================================

-- Lock timeout to prevent long-running DDL from blocking concurrent queries
SET lock_timeout = '5s';

-- ============================================================================
-- PART 1: Create place_osm_properties
-- ============================================================================

CREATE TABLE IF NOT EXISTS place_osm_properties (
    -- 1.1 Infrastructure / Row Identity
    id bigserial PRIMARY KEY,
    place_id bigint NOT NULL,
    is_current boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    source_updated_at timestamptz DEFAULT NULL,

    -- 1.2 Identity / Content
    name text DEFAULT NULL,
    description text DEFAULT NULL,
    place_type text DEFAULT NULL,
    source_place_type text DEFAULT NULL,
    source_categories text[] DEFAULT NULL,

    -- 1.3 Address / Location
    country_code text DEFAULT NULL,
    region text DEFAULT NULL,
    city text DEFAULT NULL,
    postcode text DEFAULT NULL,
    address text DEFAULT NULL,
    source_lat numeric DEFAULT NULL,
    source_lon numeric DEFAULT NULL,

    -- 1.4 Contact / Operations
    website text DEFAULT NULL,
    phone text DEFAULT NULL,
    email text DEFAULT NULL,
    opening_hours text DEFAULT NULL,
    fee_info text DEFAULT NULL,

    -- 1.5 Generic Flags
    wheelchair_accessible boolean DEFAULT NULL,
    family_friendly boolean DEFAULT NULL,
    pets_allowed boolean DEFAULT NULL,
    indoor boolean DEFAULT NULL,
    outdoor boolean DEFAULT NULL,
    entry_fee_required boolean DEFAULT NULL,
    reservation_required boolean DEFAULT NULL,
    overnight_stay_allowed boolean DEFAULT NULL,

    -- 1.6 General Facilities
    has_parking boolean DEFAULT NULL,
    has_restrooms boolean DEFAULT NULL,
    has_drinking_water boolean DEFAULT NULL,
    has_wifi boolean DEFAULT NULL,
    has_shop boolean DEFAULT NULL,
    has_restaurant boolean DEFAULT NULL,
    has_cafe boolean DEFAULT NULL,

    -- 1.7 Camping Permissions
    caravan_allowed boolean DEFAULT NULL,
    motorhome_allowed boolean DEFAULT NULL,
    tent_allowed boolean DEFAULT NULL,

    -- 1.8 Camping Facilities
    has_electricity boolean DEFAULT NULL,
    has_fresh_water boolean DEFAULT NULL,
    has_shower boolean DEFAULT NULL,
    has_laundry boolean DEFAULT NULL,
    has_dishwashing_area boolean DEFAULT NULL,

    -- 1.9 Disposal / Utilities
    has_grey_water_disposal boolean DEFAULT NULL,
    has_black_water_disposal boolean DEFAULT NULL,
    has_chemical_toilet_disposal boolean DEFAULT NULL,
    has_dump_station boolean DEFAULT NULL,
    has_waste_disposal boolean DEFAULT NULL,
    has_recycling boolean DEFAULT NULL,

    -- 1.10 Leisure
    has_bbq_area boolean DEFAULT NULL,
    has_fire_pit boolean DEFAULT NULL,
    has_playground boolean DEFAULT NULL,
    has_pool boolean DEFAULT NULL,
    has_beach boolean DEFAULT NULL,

    -- 1.11 Nudism
    nudism_allowed boolean DEFAULT NULL,
    nudism_only boolean DEFAULT NULL,

    -- 1.12 Attraction / Museum
    has_guided_tours boolean DEFAULT NULL,
    has_audio_guide boolean DEFAULT NULL,
    has_visitor_center boolean DEFAULT NULL,
    has_lockers boolean DEFAULT NULL,
    photography_allowed boolean DEFAULT NULL,

    -- 2.1 OSM-Specific Columns
    osm_source_id bigint DEFAULT NULL,
    osm_id bigint DEFAULT NULL,
    osm_type text DEFAULT NULL,
    osm_version integer DEFAULT NULL,
    osm_timestamp timestamptz DEFAULT NULL,

    -- Foreign key to places table
    CONSTRAINT fk_osm_properties_place
        FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

COMMENT ON TABLE place_osm_properties IS
    'OSM property data - Aligned property table with shared columns and OSM-specific fields';
COMMENT ON COLUMN place_osm_properties.place_id IS 'Reference to places.id';
COMMENT ON COLUMN place_osm_properties.is_current IS 'Whether this is the current/valid property row';
COMMENT ON COLUMN place_osm_properties.source_updated_at IS 'Timestamp of last source data update';
COMMENT ON COLUMN place_osm_properties.osm_source_id IS 'FK to osm_source.id';
COMMENT ON COLUMN place_osm_properties.osm_id IS 'OSM object ID';
COMMENT ON COLUMN place_osm_properties.osm_type IS 'OSM object type (node/way/relation)';
COMMENT ON COLUMN place_osm_properties.osm_version IS 'OSM version number';
COMMENT ON COLUMN place_osm_properties.osm_timestamp IS 'OSM last edit timestamp';

-- ============================================================================
-- PART 2: Create place_google_properties
-- ============================================================================

CREATE TABLE IF NOT EXISTS place_google_properties (
    -- 1.1 Infrastructure / Row Identity
    id bigserial PRIMARY KEY,
    place_id bigint NOT NULL,
    is_current boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    source_updated_at timestamptz DEFAULT NULL,

    -- 1.2 Identity / Content
    name text DEFAULT NULL,
    description text DEFAULT NULL,
    place_type text DEFAULT NULL,
    source_place_type text DEFAULT NULL,
    source_categories text[] DEFAULT NULL,

    -- 1.3 Address / Location
    country_code text DEFAULT NULL,
    region text DEFAULT NULL,
    city text DEFAULT NULL,
    postcode text DEFAULT NULL,
    address text DEFAULT NULL,
    source_lat numeric DEFAULT NULL,
    source_lon numeric DEFAULT NULL,

    -- 1.4 Contact / Operations
    website text DEFAULT NULL,
    phone text DEFAULT NULL,
    email text DEFAULT NULL,
    opening_hours text DEFAULT NULL,
    fee_info text DEFAULT NULL,

    -- 1.5 Generic Flags
    wheelchair_accessible boolean DEFAULT NULL,
    family_friendly boolean DEFAULT NULL,
    pets_allowed boolean DEFAULT NULL,
    indoor boolean DEFAULT NULL,
    outdoor boolean DEFAULT NULL,
    entry_fee_required boolean DEFAULT NULL,
    reservation_required boolean DEFAULT NULL,
    overnight_stay_allowed boolean DEFAULT NULL,

    -- 1.6 General Facilities
    has_parking boolean DEFAULT NULL,
    has_restrooms boolean DEFAULT NULL,
    has_drinking_water boolean DEFAULT NULL,
    has_wifi boolean DEFAULT NULL,
    has_shop boolean DEFAULT NULL,
    has_restaurant boolean DEFAULT NULL,
    has_cafe boolean DEFAULT NULL,

    -- 1.7 Camping Permissions
    caravan_allowed boolean DEFAULT NULL,
    motorhome_allowed boolean DEFAULT NULL,
    tent_allowed boolean DEFAULT NULL,

    -- 1.8 Camping Facilities
    has_electricity boolean DEFAULT NULL,
    has_fresh_water boolean DEFAULT NULL,
    has_shower boolean DEFAULT NULL,
    has_laundry boolean DEFAULT NULL,
    has_dishwashing_area boolean DEFAULT NULL,

    -- 1.9 Disposal / Utilities
    has_grey_water_disposal boolean DEFAULT NULL,
    has_black_water_disposal boolean DEFAULT NULL,
    has_chemical_toilet_disposal boolean DEFAULT NULL,
    has_dump_station boolean DEFAULT NULL,
    has_waste_disposal boolean DEFAULT NULL,
    has_recycling boolean DEFAULT NULL,

    -- 1.10 Leisure
    has_bbq_area boolean DEFAULT NULL,
    has_fire_pit boolean DEFAULT NULL,
    has_playground boolean DEFAULT NULL,
    has_pool boolean DEFAULT NULL,
    has_beach boolean DEFAULT NULL,

    -- 1.11 Nudism
    nudism_allowed boolean DEFAULT NULL,
    nudism_only boolean DEFAULT NULL,

    -- 1.12 Attraction / Museum
    has_guided_tours boolean DEFAULT NULL,
    has_audio_guide boolean DEFAULT NULL,
    has_visitor_center boolean DEFAULT NULL,
    has_lockers boolean DEFAULT NULL,
    photography_allowed boolean DEFAULT NULL,

    -- 2.2 Google-Specific Columns
    google_source_id bigint DEFAULT NULL,
    google_place_id text DEFAULT NULL,
    rating numeric DEFAULT NULL,
    review_count integer DEFAULT NULL,
    business_status text DEFAULT NULL,
    expires_at timestamptz DEFAULT NULL,

    -- Foreign key to places table
    CONSTRAINT fk_google_properties_place
        FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

COMMENT ON TABLE place_google_properties IS
    'Google property data - Aligned property table with shared columns and Google-specific fields';
COMMENT ON COLUMN place_google_properties.place_id IS 'Reference to places.id';
COMMENT ON COLUMN place_google_properties.is_current IS 'Whether this is the current/valid property row';
COMMENT ON COLUMN place_google_properties.source_updated_at IS 'Timestamp of last source data update';
COMMENT ON COLUMN place_google_properties.google_source_id IS 'FK to place_google_sources.id';
COMMENT ON COLUMN place_google_properties.google_place_id IS 'Google Places API ID';
COMMENT ON COLUMN place_google_properties.rating IS 'Google rating (0-5)';
COMMENT ON COLUMN place_google_properties.review_count IS 'Number of Google reviews';
COMMENT ON COLUMN place_google_properties.business_status IS 'Business status enum';
COMMENT ON COLUMN place_google_properties.expires_at IS 'Cache expiration time';

-- ============================================================================
-- PART 3: Create place_llm_properties
-- ============================================================================

CREATE TABLE IF NOT EXISTS place_llm_properties (
    -- 1.1 Infrastructure / Row Identity
    id bigserial PRIMARY KEY,
    place_id bigint NOT NULL,
    is_current boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    source_updated_at timestamptz DEFAULT NULL,

    -- 1.2 Identity / Content
    name text DEFAULT NULL,
    description text DEFAULT NULL,
    place_type text DEFAULT NULL,
    source_place_type text DEFAULT NULL,
    source_categories text[] DEFAULT NULL,

    -- 1.3 Address / Location
    country_code text DEFAULT NULL,
    region text DEFAULT NULL,
    city text DEFAULT NULL,
    postcode text DEFAULT NULL,
    address text DEFAULT NULL,
    source_lat numeric DEFAULT NULL,
    source_lon numeric DEFAULT NULL,

    -- 1.4 Contact / Operations
    website text DEFAULT NULL,
    phone text DEFAULT NULL,
    email text DEFAULT NULL,
    opening_hours text DEFAULT NULL,
    fee_info text DEFAULT NULL,

    -- 1.5 Generic Flags
    wheelchair_accessible boolean DEFAULT NULL,
    family_friendly boolean DEFAULT NULL,
    pets_allowed boolean DEFAULT NULL,
    indoor boolean DEFAULT NULL,
    outdoor boolean DEFAULT NULL,
    entry_fee_required boolean DEFAULT NULL,
    reservation_required boolean DEFAULT NULL,
    overnight_stay_allowed boolean DEFAULT NULL,

    -- 1.6 General Facilities
    has_parking boolean DEFAULT NULL,
    has_restrooms boolean DEFAULT NULL,
    has_drinking_water boolean DEFAULT NULL,
    has_wifi boolean DEFAULT NULL,
    has_shop boolean DEFAULT NULL,
    has_restaurant boolean DEFAULT NULL,
    has_cafe boolean DEFAULT NULL,

    -- 1.7 Camping Permissions
    caravan_allowed boolean DEFAULT NULL,
    motorhome_allowed boolean DEFAULT NULL,
    tent_allowed boolean DEFAULT NULL,

    -- 1.8 Camping Facilities
    has_electricity boolean DEFAULT NULL,
    has_fresh_water boolean DEFAULT NULL,
    has_shower boolean DEFAULT NULL,
    has_laundry boolean DEFAULT NULL,
    has_dishwashing_area boolean DEFAULT NULL,

    -- 1.9 Disposal / Utilities
    has_grey_water_disposal boolean DEFAULT NULL,
    has_black_water_disposal boolean DEFAULT NULL,
    has_chemical_toilet_disposal boolean DEFAULT NULL,
    has_dump_station boolean DEFAULT NULL,
    has_waste_disposal boolean DEFAULT NULL,
    has_recycling boolean DEFAULT NULL,

    -- 1.10 Leisure
    has_bbq_area boolean DEFAULT NULL,
    has_fire_pit boolean DEFAULT NULL,
    has_playground boolean DEFAULT NULL,
    has_pool boolean DEFAULT NULL,
    has_beach boolean DEFAULT NULL,

    -- 1.11 Nudism
    nudism_allowed boolean DEFAULT NULL,
    nudism_only boolean DEFAULT NULL,

    -- 1.12 Attraction / Museum
    has_guided_tours boolean DEFAULT NULL,
    has_audio_guide boolean DEFAULT NULL,
    has_visitor_center boolean DEFAULT NULL,
    has_lockers boolean DEFAULT NULL,
    photography_allowed boolean DEFAULT NULL,

    -- 2.3 LLM-Specific Columns
    llm_enrichment_id bigint DEFAULT NULL,
    provider text DEFAULT NULL,
    model text DEFAULT NULL,
    summary_de text DEFAULT NULL,
    trust_score numeric DEFAULT NULL,
    source_urls jsonb DEFAULT NULL,

    -- Foreign key to places table
    CONSTRAINT fk_llm_properties_place
        FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

COMMENT ON TABLE place_llm_properties IS
    'LLM property data - Aligned property table with shared columns and LLM-specific fields';
COMMENT ON COLUMN place_llm_properties.place_id IS 'Reference to places.id';
COMMENT ON COLUMN place_llm_properties.is_current IS 'Whether this is the current/valid property row';
COMMENT ON COLUMN place_llm_properties.source_updated_at IS 'Timestamp of last source data update';
COMMENT ON COLUMN place_llm_properties.llm_enrichment_id IS 'FK to place_llm_enrichments.id';
COMMENT ON COLUMN place_llm_properties.provider IS 'LLM provider (openai/anthropic)';
COMMENT ON COLUMN place_llm_properties.model IS 'Model identifier';
COMMENT ON COLUMN place_llm_properties.summary_de IS 'German-language summary';
COMMENT ON COLUMN place_llm_properties.trust_score IS 'Trust score (0-1)';
COMMENT ON COLUMN place_llm_properties.source_urls IS 'Array of source URLs';

-- ============================================================================
-- PART 4: Create place_user_properties
-- ============================================================================

CREATE TABLE IF NOT EXISTS place_user_properties (
    -- 1.1 Infrastructure / Row Identity
    id bigserial PRIMARY KEY,
    place_id bigint NOT NULL,
    is_current boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    source_updated_at timestamptz DEFAULT NULL,

    -- 1.2 Identity / Content
    name text DEFAULT NULL,
    description text DEFAULT NULL,
    place_type text DEFAULT NULL,
    source_place_type text DEFAULT NULL,
    source_categories text[] DEFAULT NULL,

    -- 1.3 Address / Location
    country_code text DEFAULT NULL,
    region text DEFAULT NULL,
    city text DEFAULT NULL,
    postcode text DEFAULT NULL,
    address text DEFAULT NULL,
    source_lat numeric DEFAULT NULL,
    source_lon numeric DEFAULT NULL,

    -- 1.4 Contact / Operations
    website text DEFAULT NULL,
    phone text DEFAULT NULL,
    email text DEFAULT NULL,
    opening_hours text DEFAULT NULL,
    fee_info text DEFAULT NULL,

    -- 1.5 Generic Flags
    wheelchair_accessible boolean DEFAULT NULL,
    family_friendly boolean DEFAULT NULL,
    pets_allowed boolean DEFAULT NULL,
    indoor boolean DEFAULT NULL,
    outdoor boolean DEFAULT NULL,
    entry_fee_required boolean DEFAULT NULL,
    reservation_required boolean DEFAULT NULL,
    overnight_stay_allowed boolean DEFAULT NULL,

    -- 1.6 General Facilities
    has_parking boolean DEFAULT NULL,
    has_restrooms boolean DEFAULT NULL,
    has_drinking_water boolean DEFAULT NULL,
    has_wifi boolean DEFAULT NULL,
    has_shop boolean DEFAULT NULL,
    has_restaurant boolean DEFAULT NULL,
    has_cafe boolean DEFAULT NULL,

    -- 1.7 Camping Permissions
    caravan_allowed boolean DEFAULT NULL,
    motorhome_allowed boolean DEFAULT NULL,
    tent_allowed boolean DEFAULT NULL,

    -- 1.8 Camping Facilities
    has_electricity boolean DEFAULT NULL,
    has_fresh_water boolean DEFAULT NULL,
    has_shower boolean DEFAULT NULL,
    has_laundry boolean DEFAULT NULL,
    has_dishwashing_area boolean DEFAULT NULL,

    -- 1.9 Disposal / Utilities
    has_grey_water_disposal boolean DEFAULT NULL,
    has_black_water_disposal boolean DEFAULT NULL,
    has_chemical_toilet_disposal boolean DEFAULT NULL,
    has_dump_station boolean DEFAULT NULL,
    has_waste_disposal boolean DEFAULT NULL,
    has_recycling boolean DEFAULT NULL,

    -- 1.10 Leisure
    has_bbq_area boolean DEFAULT NULL,
    has_fire_pit boolean DEFAULT NULL,
    has_playground boolean DEFAULT NULL,
    has_pool boolean DEFAULT NULL,
    has_beach boolean DEFAULT NULL,

    -- 1.11 Nudism
    nudism_allowed boolean DEFAULT NULL,
    nudism_only boolean DEFAULT NULL,

    -- 1.12 Attraction / Museum
    has_guided_tours boolean DEFAULT NULL,
    has_audio_guide boolean DEFAULT NULL,
    has_visitor_center boolean DEFAULT NULL,
    has_lockers boolean DEFAULT NULL,
    photography_allowed boolean DEFAULT NULL,

    -- 2.4 User-Specific Columns
    user_id uuid NOT NULL,

    -- Foreign key to places table
    CONSTRAINT fk_user_properties_place
        FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

COMMENT ON TABLE place_user_properties IS
    'User property data - Aligned property table with shared columns and user-specific fields';
COMMENT ON COLUMN place_user_properties.place_id IS 'Reference to places.id';
COMMENT ON COLUMN place_user_properties.is_current IS 'Whether this is the current/valid property row';
COMMENT ON COLUMN place_user_properties.source_updated_at IS 'Timestamp of last source data update';
COMMENT ON COLUMN place_user_properties.user_id IS 'User who submitted correction';

-- ============================================================================
-- PART 5: Create Partial Unique Indexes for Current-Row Semantics
-- ============================================================================

-- OSM: One current row per place_id
CREATE UNIQUE INDEX IF NOT EXISTS uidx_osm_properties_place_current
    ON place_osm_properties(place_id)
    WHERE is_current = true;

-- Google: One current row per place_id
CREATE UNIQUE INDEX IF NOT EXISTS uidx_google_properties_place_current
    ON place_google_properties(place_id)
    WHERE is_current = true;

-- LLM: One current row per place_id
CREATE UNIQUE INDEX IF NOT EXISTS uidx_llm_properties_place_current
    ON place_llm_properties(place_id)
    WHERE is_current = true;

-- User: One current row per (place_id, user_id)
CREATE UNIQUE INDEX IF NOT EXISTS uidx_user_properties_place_user_current
    ON place_user_properties(place_id, user_id)
    WHERE is_current = true;

-- ============================================================================
-- PART 6: Create Indexes for Common Query Patterns
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 6.1 Indexes for place_osm_properties
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_osm_properties_place_id
    ON place_osm_properties(place_id);

CREATE INDEX IF NOT EXISTS idx_osm_properties_is_current
    ON place_osm_properties(is_current)
    WHERE is_current = true;

CREATE INDEX IF NOT EXISTS idx_osm_properties_osm_id
    ON place_osm_properties(osm_id)
    WHERE osm_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_osm_properties_place_current
    ON place_osm_properties(place_id, is_current)
    WHERE is_current = true;

-- ----------------------------------------------------------------------------
-- 6.2 Indexes for place_google_properties
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_google_properties_place_id
    ON place_google_properties(place_id);

CREATE INDEX IF NOT EXISTS idx_google_properties_is_current
    ON place_google_properties(is_current)
    WHERE is_current = true;

CREATE INDEX IF NOT EXISTS idx_google_properties_google_place_id
    ON place_google_properties(google_place_id)
    WHERE google_place_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_google_properties_expires
    ON place_google_properties(expires_at)
    WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_google_properties_place_current
    ON place_google_properties(place_id, is_current)
    WHERE is_current = true;

-- ----------------------------------------------------------------------------
-- 6.3 Indexes for place_llm_properties
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_llm_properties_place_id
    ON place_llm_properties(place_id);

CREATE INDEX IF NOT EXISTS idx_llm_properties_is_current
    ON place_llm_properties(is_current)
    WHERE is_current = true;

CREATE INDEX IF NOT EXISTS idx_llm_properties_provider
    ON place_llm_properties(provider)
    WHERE provider IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_llm_properties_place_current
    ON place_llm_properties(place_id, is_current)
    WHERE is_current = true;

-- ----------------------------------------------------------------------------
-- 6.4 Indexes for place_user_properties
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_user_properties_place_id
    ON place_user_properties(place_id);

CREATE INDEX IF NOT EXISTS idx_user_properties_user_id
    ON place_user_properties(user_id);

CREATE INDEX IF NOT EXISTS idx_user_properties_user_current
    ON place_user_properties(user_id, is_current)
    WHERE is_current = true;

CREATE INDEX IF NOT EXISTS idx_user_properties_place_user_current
    ON place_user_properties(place_id, user_id, is_current)
    WHERE is_current = true;

-- ============================================================================
-- PART 7: Create Auto-Update Triggers for updated_at
-- ============================================================================

-- Apply to all property tables
DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'place_osm_properties',
        'place_google_properties',
        'place_llm_properties',
        'place_user_properties'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_%I_updated_at ON %I;',
            tbl, tbl
        );
        EXECUTE format(
            'CREATE TRIGGER trg_%I_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW
             EXECUTE FUNCTION update_updated_at_column();',
            tbl, tbl
        );
    END LOOP;
END;
$$;

-- ============================================================================
-- PART 8: Enable Row Level Security
-- ============================================================================

-- Enable RLS on all property tables
ALTER TABLE place_osm_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE place_google_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE place_llm_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE place_user_properties ENABLE ROW LEVEL SECURITY;

-- Create restrictive policies (service role only for now)
-- These can be relaxed later when user access patterns are defined

CREATE POLICY "Service role can manage OSM properties"
    ON place_osm_properties FOR ALL
    USING (false)
    WITH CHECK (false);

CREATE POLICY "Service role can manage Google properties"
    ON place_google_properties FOR ALL
    USING (false)
    WITH CHECK (false);

CREATE POLICY "Service role can manage LLM properties"
    ON place_llm_properties FOR ALL
    USING (false)
    WITH CHECK (false);

CREATE POLICY "Service role can manage User properties"
    ON place_user_properties FOR ALL
    USING (false)
    WITH CHECK (false);

-- ============================================================================
-- PART 9: Verification Queries (for post-migration validation)
-- ============================================================================

-- Uncomment to verify after migration:
--
-- -- Check all property tables exist
-- SELECT table_name
-- FROM information_schema.tables
-- WHERE table_schema = 'public'
-- AND table_name IN (
--     'place_osm_properties',
--     'place_google_properties',
--     'place_llm_properties',
--     'place_user_properties'
-- )
-- ORDER BY table_name;
--
-- -- Check column counts per table
-- SELECT table_name, COUNT(*) as column_count
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
-- AND table_name IN (
--     'place_osm_properties',
--     'place_google_properties',
--     'place_llm_properties',
--     'place_user_properties'
-- )
-- GROUP BY table_name
-- ORDER BY table_name;
--
-- -- Check partial unique indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'public'
-- AND indexname IN (
--     'uidx_osm_properties_place_current',
--     'uidx_google_properties_place_current',
--     'uidx_llm_properties_place_current',
--     'uidx_user_properties_place_user_current'
-- )
-- ORDER BY indexname;
--
-- -- Check foreign keys
-- SELECT
--     tc.table_name,
--     kcu.column_name,
--     ccu.table_name AS foreign_table_name,
--     ccu.column_name AS foreign_column_name
-- FROM information_schema.table_constraints tc
-- JOIN information_schema.key_column_usage kcu
--     ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.constraint_column_usage ccu
--     ON ccu.constraint_name = tc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY'
-- AND tc.table_name IN (
--     'place_osm_properties',
--     'place_google_properties',
--     'place_llm_properties',
--     'place_user_properties'
-- )
-- ORDER BY tc.table_name;
