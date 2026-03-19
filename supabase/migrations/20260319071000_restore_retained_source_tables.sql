SET lock_timeout = '10s';
SET statement_timeout = '15min';

CREATE TABLE IF NOT EXISTS osm_source (
    id bigserial PRIMARY KEY,
    place_id bigint NOT NULL,
    osm_type text NOT NULL,
    osm_id bigint NOT NULL,
    osm_version integer,
    tags jsonb NOT NULL DEFAULT '{}'::jsonb,
    raw_name text,
    source_snapshot_date timestamptz,
    imported_at timestamptz NOT NULL DEFAULT now(),
    first_seen_at timestamptz NOT NULL DEFAULT now(),
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    last_import_run_id bigint,
    geometry_kind text,
    geometry_hash text,
    centroid geometry,
    geom geometry,
    osm_timestamp timestamptz,
    osmium_unique_id text,
    first_seen_snapshot_id text,
    last_seen_snapshot_id text,
    is_current boolean NOT NULL DEFAULT true,
    source_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT fk_osm_source_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS place_llm_enrichments (
    id bigserial PRIMARY KEY,
    place_id bigint NOT NULL,
    job_id bigint,
    provider text NOT NULL,
    model text NOT NULL,
    prompt_version text,
    summary_de text,
    confidence numeric(3,2) CHECK (confidence >= 0 AND confidence <= 1),
    hallucination_risk numeric(3,2) CHECK (hallucination_risk >= 0 AND hallucination_risk <= 1),
    token_input integer,
    token_output integer,
    cost_usd numeric(10,4),
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    started_at timestamptz,
    completed_at timestamptz,
    is_current boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid DEFAULT auth.uid(),
    CONSTRAINT fk_place_llm_enrichments_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS place_google_sources (
    id bigserial PRIMARY KEY,
    place_id bigint NOT NULL,
    google_place_id text NOT NULL,
    name text,
    formatted_address text,
    phone text,
    website text,
    rating numeric(2,1) CHECK (rating >= 0 AND rating <= 5),
    review_count integer DEFAULT 0 CHECK (review_count >= 0),
    business_status text,
    lat numeric(10,8),
    lon numeric(11,8),
    raw_payload jsonb,
    fetched_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz,
    is_current boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_google_sources_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    CONSTRAINT uq_place_google_sources_place_google_id UNIQUE (place_id, google_place_id)
);

CREATE TABLE IF NOT EXISTS place_google_reviews (
    id bigserial PRIMARY KEY,
    google_source_id bigint NOT NULL,
    author_name text,
    rating integer CHECK (rating >= 1 AND rating <= 5),
    language_code text,
    review_text text,
    review_time timestamptz,
    relative_time_description text,
    google_review_id text,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_google_reviews_source FOREIGN KEY (google_source_id) REFERENCES place_google_sources(id) ON DELETE CASCADE,
    CONSTRAINT uq_google_reviews_source_review_id UNIQUE (google_source_id, google_review_id)
);

CREATE TABLE IF NOT EXISTS place_google_photos (
    id bigserial PRIMARY KEY,
    google_source_id bigint NOT NULL,
    photo_reference text NOT NULL,
    width integer,
    height integer,
    attribution text,
    google_photo_id text,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_google_photos_source FOREIGN KEY (google_source_id) REFERENCES place_google_sources(id) ON DELETE CASCADE,
    CONSTRAINT uq_google_photos_source_photo_ref UNIQUE (google_source_id, photo_reference)
);

CREATE INDEX IF NOT EXISTS idx_osm_source_place_id ON osm_source(place_id);
CREATE INDEX IF NOT EXISTS idx_osm_source_is_current ON osm_source(is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_osm_source_osm_id ON osm_source(osm_id);

CREATE INDEX IF NOT EXISTS idx_llm_enrichments_place_id ON place_llm_enrichments(place_id);
CREATE INDEX IF NOT EXISTS idx_llm_enrichments_status ON place_llm_enrichments(status);
CREATE INDEX IF NOT EXISTS idx_llm_enrichments_is_current ON place_llm_enrichments(is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_llm_enrichments_place_is_current ON place_llm_enrichments(place_id, is_current) WHERE is_current = true;

CREATE INDEX IF NOT EXISTS idx_google_sources_place_id ON place_google_sources(place_id);
CREATE INDEX IF NOT EXISTS idx_google_sources_google_place_id ON place_google_sources(google_place_id);
CREATE INDEX IF NOT EXISTS idx_google_sources_is_current ON place_google_sources(is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_google_sources_place_is_current ON place_google_sources(place_id, is_current) WHERE is_current = true;
CREATE INDEX IF NOT EXISTS idx_google_sources_expires_at ON place_google_sources(expires_at) WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_google_reviews_source_id ON place_google_reviews(google_source_id);
CREATE INDEX IF NOT EXISTS idx_google_reviews_rating ON place_google_reviews(rating) WHERE rating IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_google_reviews_time ON place_google_reviews(review_time DESC) WHERE review_time IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_google_photos_source_id ON place_google_photos(google_source_id);

ALTER TABLE osm_source ENABLE ROW LEVEL SECURITY;
ALTER TABLE place_llm_enrichments ENABLE ROW LEVEL SECURITY;
ALTER TABLE place_google_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE place_google_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE place_google_photos ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='osm_source' AND policyname='Service role can manage OSM sources') THEN
        EXECUTE 'CREATE POLICY "Service role can manage OSM sources" ON osm_source FOR ALL USING (false) WITH CHECK (false)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='place_llm_enrichments' AND policyname='Service role can manage LLM enrichments') THEN
        EXECUTE 'CREATE POLICY "Service role can manage LLM enrichments" ON place_llm_enrichments FOR ALL USING (false) WITH CHECK (false)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='place_google_sources' AND policyname='Service role can manage Google sources') THEN
        EXECUTE 'CREATE POLICY "Service role can manage Google sources" ON place_google_sources FOR ALL USING (false) WITH CHECK (false)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='place_google_reviews' AND policyname='Service role can manage Google reviews') THEN
        EXECUTE 'CREATE POLICY "Service role can manage Google reviews" ON place_google_reviews FOR ALL USING (false) WITH CHECK (false)';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='place_google_photos' AND policyname='Service role can manage Google photos') THEN
        EXECUTE 'CREATE POLICY "Service role can manage Google photos" ON place_google_photos FOR ALL USING (false) WITH CHECK (false)';
    END IF;
END
$$;

INSERT INTO osm_source (
    id,
    place_id,
    osm_type,
    osm_id,
    osm_version,
    tags,
    raw_name,
    source_snapshot_date,
    imported_at,
    first_seen_at,
    last_seen_at,
    osm_timestamp,
    is_current,
    source_metadata
)
SELECT
    COALESCE(pop.osm_source_id, pop.id),
    pop.place_id,
    COALESCE(pop.osm_type, 'node'),
    COALESCE(pop.osm_id, pop.place_id),
    pop.osm_version,
    jsonb_strip_nulls(jsonb_build_object(
        'name', pop.name,
        'place_type', pop.place_type,
        'source_place_type', pop.source_place_type,
        'city', pop.city,
        'country_code', pop.country_code
    )),
    pop.name,
    pop.source_updated_at,
    COALESCE(pop.created_at, now()),
    COALESCE(pop.created_at, now()),
    COALESCE(pop.updated_at, now()),
    pop.osm_timestamp,
    COALESCE(pop.is_current, true),
    jsonb_build_object('restored_from', 'place_osm_properties', 'property_row_id', pop.id)
FROM place_osm_properties pop
WHERE pop.osm_id IS NOT NULL OR pop.osm_source_id IS NOT NULL
ON CONFLICT (id) DO NOTHING;

INSERT INTO place_llm_enrichments (
    id,
    place_id,
    provider,
    model,
    summary_de,
    confidence,
    status,
    completed_at,
    is_current,
    created_at,
    updated_at
)
SELECT
    COALESCE(plp.llm_enrichment_id, plp.id),
    plp.place_id,
    COALESCE(NULLIF(plp.provider, ''), 'restored'),
    COALESCE(NULLIF(plp.model, ''), 'restored'),
    plp.summary_de,
    plp.trust_score,
    'completed',
    COALESCE(plp.source_updated_at, plp.updated_at, plp.created_at),
    COALESCE(plp.is_current, true),
    COALESCE(plp.created_at, now()),
    COALESCE(plp.updated_at, now())
FROM place_llm_properties plp
ON CONFLICT (id) DO NOTHING;

INSERT INTO place_google_sources (
    id,
    place_id,
    google_place_id,
    name,
    formatted_address,
    phone,
    website,
    rating,
    review_count,
    business_status,
    lat,
    lon,
    raw_payload,
    fetched_at,
    expires_at,
    is_current,
    created_at,
    updated_at
)
SELECT
    COALESCE(pgp.google_source_id, pgp.id),
    pgp.place_id,
    COALESCE(NULLIF(pgp.google_place_id, ''), 'restored-' || pgp.id::text),
    pgp.name,
    pgp.address,
    pgp.phone,
    pgp.website,
    pgp.rating,
    COALESCE(pgp.review_count, 0),
    pgp.business_status,
    pgp.source_lat,
    pgp.source_lon,
    jsonb_strip_nulls(jsonb_build_object(
        'source_categories', pgp.source_categories,
        'source_place_type', pgp.source_place_type,
        'description', pgp.description
    )),
    COALESCE(pgp.source_updated_at, pgp.created_at, now()),
    pgp.expires_at,
    COALESCE(pgp.is_current, true),
    COALESCE(pgp.created_at, now()),
    COALESCE(pgp.updated_at, now())
FROM place_google_properties pgp
ON CONFLICT (id) DO NOTHING;

INSERT INTO place_google_reviews (
    google_source_id,
    author_name,
    rating,
    language_code,
    review_text,
    review_time,
    relative_time_description,
    google_review_id,
    created_at
)
SELECT
    gs.id,
    r.item ->> 'author_name',
    CASE
        WHEN (r.item ->> 'rating') ~ '^[0-9]+$' THEN (r.item ->> 'rating')::integer
        ELSE NULL
    END,
    COALESCE(r.item ->> 'language_code', r.item ->> 'language'),
    COALESCE(r.item ->> 'review_text', r.item ->> 'text'),
    CASE
        WHEN (r.item ->> 'time') ~ '^[0-9]+$' THEN to_timestamp((r.item ->> 'time')::bigint)
        ELSE NULL
    END,
    r.item ->> 'relative_time_description',
    COALESCE(NULLIF(r.item ->> 'google_review_id', ''), NULLIF(r.item ->> 'id', ''), md5(gs.id::text || r.item::text)),
    now()
FROM campsites_cache cc
JOIN LATERAL (
    SELECT pgs.id
    FROM place_google_sources pgs
    WHERE pgs.place_id = CASE WHEN cc.place_id ~ '^[0-9]+$' THEN cc.place_id::bigint ELSE NULL END
    ORDER BY pgs.is_current DESC, pgs.updated_at DESC, pgs.id DESC
    LIMIT 1
) gs ON true
JOIN LATERAL jsonb_array_elements(COALESCE(cc.google_reviews, '[]'::jsonb)) AS r(item) ON true
ON CONFLICT (google_source_id, google_review_id) DO NOTHING;

INSERT INTO place_google_photos (
    google_source_id,
    photo_reference,
    width,
    height,
    attribution,
    google_photo_id,
    created_at
)
SELECT
    gs.id,
    COALESCE(NULLIF(p.item ->> 'photo_reference', ''), NULLIF(p.item ->> 'name', ''), md5(gs.id::text || p.item::text)),
    CASE WHEN (p.item ->> 'width') ~ '^[0-9]+$' THEN (p.item ->> 'width')::integer ELSE NULL END,
    CASE WHEN (p.item ->> 'height') ~ '^[0-9]+$' THEN (p.item ->> 'height')::integer ELSE NULL END,
    COALESCE(p.item ->> 'attribution', p.item ->> 'html_attributions'),
    p.item ->> 'google_photo_id',
    now()
FROM campsites_cache cc
JOIN LATERAL (
    SELECT pgs.id
    FROM place_google_sources pgs
    WHERE pgs.place_id = CASE WHEN cc.place_id ~ '^[0-9]+$' THEN cc.place_id::bigint ELSE NULL END
    ORDER BY pgs.is_current DESC, pgs.updated_at DESC, pgs.id DESC
    LIMIT 1
) gs ON true
JOIN LATERAL jsonb_array_elements(COALESCE(cc.google_photos, '[]'::jsonb)) AS p(item) ON true
ON CONFLICT (google_source_id, photo_reference) DO NOTHING;

SELECT setval(pg_get_serial_sequence('osm_source', 'id'), COALESCE((SELECT MAX(id) FROM osm_source), 1), true);
SELECT setval(pg_get_serial_sequence('place_llm_enrichments', 'id'), COALESCE((SELECT MAX(id) FROM place_llm_enrichments), 1), true);
SELECT setval(pg_get_serial_sequence('place_google_sources', 'id'), COALESCE((SELECT MAX(id) FROM place_google_sources), 1), true);
SELECT setval(pg_get_serial_sequence('place_google_reviews', 'id'), COALESCE((SELECT MAX(id) FROM place_google_reviews), 1), true);
SELECT setval(pg_get_serial_sequence('place_google_photos', 'id'), COALESCE((SELECT MAX(id) FROM place_google_photos), 1), true);
