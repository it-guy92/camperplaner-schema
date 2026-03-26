SET lock_timeout = '10s';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type
        WHERE typnamespace = 'public'::regnamespace
          AND typname = 'media_source_enum'
    ) THEN
        CREATE TYPE public.media_source_enum AS ENUM (
            'own',
            'wikimedia',
            'mapillary'
        );
    END IF;
END $$;

COMMENT ON TYPE public.media_source_enum IS
'Source of a place media asset: own upload, Wikimedia, or Mapillary.';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type
        WHERE typnamespace = 'public'::regnamespace
          AND typname = 'media_review_status_enum'
    ) THEN
        CREATE TYPE public.media_review_status_enum AS ENUM (
            'pending',
            'approved',
            'rejected'
        );
    END IF;
END $$;

COMMENT ON TYPE public.media_review_status_enum IS
'Current moderation status of a place media asset.';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type
        WHERE typnamespace = 'public'::regnamespace
          AND typname = 'media_visibility_status_enum'
    ) THEN
        CREATE TYPE public.media_visibility_status_enum AS ENUM (
            'internal',
            'public'
        );
    END IF;
END $$;

COMMENT ON TYPE public.media_visibility_status_enum IS
'Visibility of a place media asset in product surfaces.';

CREATE TABLE IF NOT EXISTS public.place_media_assets (
    id bigserial PRIMARY KEY,
    place_id bigint NOT NULL,
    source public.media_source_enum NOT NULL,
    source_asset_id text DEFAULT NULL,
    review_status public.media_review_status_enum NOT NULL DEFAULT 'pending',
    visibility_status public.media_visibility_status_enum NOT NULL DEFAULT 'internal',
    is_hero boolean NOT NULL DEFAULT false,
    sort_order integer NOT NULL DEFAULT 0,
    title text DEFAULT NULL,
    caption text DEFAULT NULL,
    author_name text DEFAULT NULL,
    license_type text DEFAULT NULL,
    license_url text DEFAULT NULL,
    attribution_text text DEFAULT NULL,
    source_url text DEFAULT NULL,
    viewer_url text DEFAULT NULL,
    thumbnail_url text DEFAULT NULL,
    storage_bucket text DEFAULT NULL,
    storage_object_path text DEFAULT NULL,
    storage_original_filename text DEFAULT NULL,
    mime_type text DEFAULT NULL,
    byte_size bigint DEFAULT NULL,
    width integer DEFAULT NULL,
    height integer DEFAULT NULL,
    captured_at timestamptz DEFAULT NULL,
    imported_at timestamptz NOT NULL DEFAULT now(),
    lat numeric DEFAULT NULL,
    lon numeric DEFAULT NULL,
    distance_to_place_meters integer DEFAULT NULL,
    match_confidence numeric(3,2) DEFAULT NULL,
    uploaded_by_user_id uuid DEFAULT NULL,
    rights_confirmed_at timestamptz DEFAULT NULL,
    rights_snapshot_version text DEFAULT NULL,
    reviewed_by_user_id uuid DEFAULT NULL,
    reviewed_at timestamptz DEFAULT NULL,
    review_reason_code text DEFAULT NULL,
    review_notes text DEFAULT NULL,
    source_metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT fk_place_media_assets_place
        FOREIGN KEY (place_id) REFERENCES public.places(id) ON DELETE CASCADE,
    CONSTRAINT chk_place_media_assets_match_confidence
        CHECK (match_confidence IS NULL OR match_confidence BETWEEN 0 AND 1),
    CONSTRAINT chk_place_media_assets_own_storage
        CHECK (
            source <> 'own'
            OR (storage_bucket IS NOT NULL AND storage_object_path IS NOT NULL)
        ),
    CONSTRAINT chk_place_media_assets_external_ref
        CHECK (
            source NOT IN ('wikimedia', 'mapillary')
            OR (
                source_asset_id IS NOT NULL
                AND (source_url IS NOT NULL OR viewer_url IS NOT NULL)
            )
        ),
    CONSTRAINT chk_place_media_assets_hero_public_approved
        CHECK (
            NOT is_hero
            OR (
                review_status = 'approved'
                AND visibility_status = 'public'
            )
        )
);

COMMENT ON TABLE public.place_media_assets IS
'Canonical place media assets spanning own uploads, Wikimedia references, and Mapillary references.';
COMMENT ON COLUMN public.place_media_assets.place_id IS 'Reference to places.id.';
COMMENT ON COLUMN public.place_media_assets.source IS 'Source family of the asset.';
COMMENT ON COLUMN public.place_media_assets.source_asset_id IS 'External asset identifier for non-owned sources.';
COMMENT ON COLUMN public.place_media_assets.review_status IS 'Current moderation state.';
COMMENT ON COLUMN public.place_media_assets.visibility_status IS 'Public visibility gate.';
COMMENT ON COLUMN public.place_media_assets.is_hero IS 'Whether this asset is explicitly marked as the place hero image.';
COMMENT ON COLUMN public.place_media_assets.sort_order IS 'Editorial sort order within the place asset list.';
COMMENT ON COLUMN public.place_media_assets.attribution_text IS 'Persisted attribution snapshot required for display.';
COMMENT ON COLUMN public.place_media_assets.storage_bucket IS 'Supabase Storage bucket for owned assets.';
COMMENT ON COLUMN public.place_media_assets.storage_object_path IS 'Supabase Storage object path for owned assets.';
COMMENT ON COLUMN public.place_media_assets.distance_to_place_meters IS 'Distance between the asset capture point and the place, mainly for Mapillary.';
COMMENT ON COLUMN public.place_media_assets.match_confidence IS 'Confidence score for external asset matching, from 0 to 1.';
COMMENT ON COLUMN public.place_media_assets.source_metadata IS 'Source-specific non-operational metadata.';

CREATE UNIQUE INDEX IF NOT EXISTS uniq_place_media_assets_one_hero
    ON public.place_media_assets(place_id)
    WHERE is_hero = true;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_place_media_assets_storage
    ON public.place_media_assets(storage_bucket, storage_object_path)
    WHERE storage_bucket IS NOT NULL AND storage_object_path IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uniq_place_media_assets_external_per_place
    ON public.place_media_assets(place_id, source, source_asset_id)
    WHERE source_asset_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_place_media_assets_place_id
    ON public.place_media_assets(place_id);

CREATE INDEX IF NOT EXISTS idx_place_media_assets_public
    ON public.place_media_assets(place_id, review_status, visibility_status, source, sort_order);

CREATE INDEX IF NOT EXISTS idx_place_media_assets_mapillary
    ON public.place_media_assets(place_id, source, distance_to_place_meters)
    WHERE source = 'mapillary';

ALTER TABLE public.place_media_assets ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'place_media_assets'
          AND policyname = 'Service role can manage place media assets'
    ) THEN
        EXECUTE 'CREATE POLICY "Service role can manage place media assets" ON public.place_media_assets FOR ALL USING (auth.role() = ''service_role'') WITH CHECK (auth.role() = ''service_role'')';
    END IF;
END $$;
