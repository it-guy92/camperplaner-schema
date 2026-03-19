SET lock_timeout = '10s';
SET statement_timeout = '15min';

ALTER TABLE IF EXISTS place_google_reviews
    ADD COLUMN IF NOT EXISTS google_property_id bigint;

ALTER TABLE IF EXISTS place_google_photos
    ADD COLUMN IF NOT EXISTS google_property_id bigint;

UPDATE place_google_reviews r
SET google_property_id = gp.id
FROM place_google_properties gp
WHERE r.google_property_id IS NULL
  AND gp.google_source_id = r.google_source_id;

UPDATE place_google_photos p
SET google_property_id = gp.id
FROM place_google_properties gp
WHERE p.google_property_id IS NULL
  AND gp.google_source_id = p.google_source_id;

UPDATE place_google_reviews r
SET google_property_id = gp.id
FROM place_google_sources gs
JOIN LATERAL (
    SELECT pgp.id
    FROM place_google_properties pgp
    WHERE pgp.place_id = gs.place_id
    ORDER BY pgp.is_current DESC, pgp.updated_at DESC, pgp.id DESC
    LIMIT 1
) gp ON true
WHERE r.google_property_id IS NULL
  AND r.google_source_id = gs.id;

UPDATE place_google_photos p
SET google_property_id = gp.id
FROM place_google_sources gs
JOIN LATERAL (
    SELECT pgp.id
    FROM place_google_properties pgp
    WHERE pgp.place_id = gs.place_id
    ORDER BY pgp.is_current DESC, pgp.updated_at DESC, pgp.id DESC
    LIMIT 1
) gp ON true
WHERE p.google_property_id IS NULL
  AND p.google_source_id = gs.id;

DO $$
DECLARE
    missing_reviews bigint;
    missing_photos bigint;
BEGIN
    SELECT COUNT(*) INTO missing_reviews
    FROM place_google_reviews
    WHERE google_property_id IS NULL;

    SELECT COUNT(*) INTO missing_photos
    FROM place_google_photos
    WHERE google_property_id IS NULL;

    IF missing_reviews > 0 OR missing_photos > 0 THEN
        RAISE EXCEPTION 'Cannot drop place_google_sources: unresolved google_property_id mappings (reviews=%, photos=%)', missing_reviews, missing_photos;
    END IF;
END
$$;

ALTER TABLE IF EXISTS place_google_reviews
    ALTER COLUMN google_property_id SET NOT NULL;

ALTER TABLE IF EXISTS place_google_photos
    ALTER COLUMN google_property_id SET NOT NULL;

ALTER TABLE IF EXISTS place_google_reviews
    DROP CONSTRAINT IF EXISTS fk_google_reviews_source,
    DROP CONSTRAINT IF EXISTS uq_google_reviews_source_review_id;

ALTER TABLE IF EXISTS place_google_photos
    DROP CONSTRAINT IF EXISTS fk_google_photos_source,
    DROP CONSTRAINT IF EXISTS uq_google_photos_source_photo_ref;

ALTER TABLE IF EXISTS place_google_reviews
    ADD CONSTRAINT fk_google_reviews_property
        FOREIGN KEY (google_property_id) REFERENCES place_google_properties(id) ON DELETE CASCADE,
    ADD CONSTRAINT uq_google_reviews_property_review_id
        UNIQUE (google_property_id, google_review_id);

ALTER TABLE IF EXISTS place_google_photos
    ADD CONSTRAINT fk_google_photos_property
        FOREIGN KEY (google_property_id) REFERENCES place_google_properties(id) ON DELETE CASCADE,
    ADD CONSTRAINT uq_google_photos_property_photo_ref
        UNIQUE (google_property_id, photo_reference);

DROP INDEX IF EXISTS idx_google_reviews_source_id;
DROP INDEX IF EXISTS idx_google_photos_source_id;

CREATE INDEX IF NOT EXISTS idx_google_reviews_property_id
    ON place_google_reviews(google_property_id);

CREATE INDEX IF NOT EXISTS idx_google_photos_property_id
    ON place_google_photos(google_property_id);

ALTER TABLE IF EXISTS place_google_reviews
    DROP COLUMN IF EXISTS google_source_id;

ALTER TABLE IF EXISTS place_google_photos
    DROP COLUMN IF EXISTS google_source_id;

DROP TABLE IF EXISTS place_llm_enrichments;
DROP TABLE IF EXISTS place_google_sources;
