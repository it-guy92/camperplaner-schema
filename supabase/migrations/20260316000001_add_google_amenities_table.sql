-- ============================================================================
-- Migration: Add Google Source Amenities Table
-- Date: 2026-03-16
-- Purpose: Complete source-family coverage for Google fields
--          Add normalized amenities child table per Normalization Guardrails
-- ============================================================================

-- ----------------------------------------------------------------------------
-- place_google_amenities: Normalized amenity facts from Google Places API
-- ----------------------------------------------------------------------------
-- Per Normalization Guardrails:
-- - Amenities must be stored authoritatively in normalized source-specific rows
-- - has_* booleans are treated as derived/read-model projection only
-- - This table stores individual amenity facts for matching/reconstruction
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS place_google_amenities (
    id bigserial PRIMARY KEY,
    google_source_id bigint NOT NULL,
    
    -- Amenity identification
    amenity_key text NOT NULL,
    -- Standardized amenity keys (e.g., 'electricity', 'water', 'wifi', 'shower', 
    -- 'restrooms', 'laundry', 'dump_station', 'pet_friendly', 'accessibility')
    
    -- Value and type
    value_text text,
    value_boolean boolean,
    value_numeric numeric,
    value_type text NOT NULL DEFAULT 'boolean' 
        CHECK (value_type IN ('boolean', 'string', 'number', 'range')),
    
    -- Source information from Google
    google_feature_type text,
    -- Original Google Places API feature/type that indicated this amenity
    -- (e.g., 'lodging', 'rv_park', 'campground', specific amenity types)
    
    -- Confidence and verification
    is_verified boolean NOT NULL DEFAULT false,
    -- Whether this amenity was explicitly confirmed vs inferred from types
    
    confidence_score numeric(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    -- Confidence in this amenity being present (1.0 = explicitly listed, lower = inferred)
    
    -- Metadata
    source_section text,
    -- Which part of Google response this came from: 'types', 'editorial_summary',
    -- 'reviews', 'primary_type', etc.
    
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    
    -- Foreign key to parent table
    CONSTRAINT fk_google_amenities_source 
        FOREIGN KEY (google_source_id) REFERENCES place_google_sources(id) ON DELETE CASCADE,
    
    -- Ensure unique amenity per source
    CONSTRAINT uq_google_amenities_source_key 
        UNIQUE (google_source_id, amenity_key)
);

COMMENT ON TABLE place_google_amenities IS 
    'Normalized amenity facts from Google Places API - Per Amenity Facts Pattern. Stores authoritative amenity data as individual facts for matching, not as has_* booleans or JSONB blobs.';

COMMENT ON COLUMN place_google_amenities.google_source_id IS 
    'Reference to place_google_sources.id';
COMMENT ON COLUMN place_google_amenities.amenity_key IS 
    'Standardized amenity identifier (e.g., electricity, water, wifi, shower, restrooms, laundry, dump_station)';
COMMENT ON COLUMN place_google_amenities.value_boolean IS 
    'Boolean value when amenity is a simple yes/no feature';
COMMENT ON COLUMN place_google_amenities.value_text IS 
    'Text value for descriptive amenities (e.g., "24-hour", "seasonal", "hot")';
COMMENT ON COLUMN place_google_amenities.value_numeric IS 
    'Numeric value for quantified amenities (e.g., number of showers, amp rating for electricity)';
COMMENT ON COLUMN place_google_amenities.google_feature_type IS 
    'Original Google Places type that indicated this amenity';
COMMENT ON COLUMN place_google_amenities.is_verified IS 
    'Whether explicitly confirmed in Google data vs inferred from place types';
COMMENT ON COLUMN place_google_amenities.confidence_score IS 
    'Confidence level: 1.0 = explicit mention, lower = inferred from types/categories';
COMMENT ON COLUMN place_google_amenities.source_section IS 
    'Which part of Google response provided this amenity info';

-- ----------------------------------------------------------------------------
-- Indexes for common query patterns
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_google_amenities_source_id 
    ON place_google_amenities(google_source_id);

CREATE INDEX IF NOT EXISTS idx_google_amenities_key 
    ON place_google_amenities(amenity_key);

CREATE INDEX IF NOT EXISTS idx_google_amenities_verified 
    ON place_google_amenities(is_verified) WHERE is_verified = true;

CREATE INDEX IF NOT EXISTS idx_google_amenities_confidence 
    ON place_google_amenities(confidence_score) WHERE confidence_score IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_google_amenities_source_key_lookup 
    ON place_google_amenities(google_source_id, amenity_key, is_verified, confidence_score);

-- ----------------------------------------------------------------------------
-- Auto-update trigger for updated_at
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_place_google_amenities_updated_at ON place_google_amenities;
CREATE TRIGGER trg_place_google_amenities_updated_at
    BEFORE UPDATE ON place_google_amenities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- Row Level Security
-- ----------------------------------------------------------------------------
ALTER TABLE place_google_amenities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage Google amenities"
    ON place_google_amenities FOR ALL
    USING (false)
    WITH CHECK (false);

-- ----------------------------------------------------------------------------
-- Verification Query (uncomment to verify after migration):
-- ----------------------------------------------------------------------------
-- SELECT table_name, column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'place_google_amenities'
-- ORDER BY ordinal_position;
