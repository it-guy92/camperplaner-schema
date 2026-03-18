CREATE TABLE IF NOT EXISTS cleanup_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action TEXT NOT NULL,
    details JSONB,
    records_affected INTEGER DEFAULT 0,
    executed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION cleanup_expired_google_data()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_photos_deleted INTEGER := 0;
    v_reviews_deleted INTEGER := 0;
    v_records_cleared INTEGER := 0;
BEGIN
    UPDATE campsites_cache
    SET 
        google_photos = NULL,
        google_reviews = NULL,
        google_data_fetched_at = NULL,
        google_data_expires_at = NULL
    WHERE google_data_expires_at < NOW()
    AND (google_photos IS NOT NULL OR google_reviews IS NOT NULL);
    
    GET DIAGNOSTICS v_records_cleared = ROW_COUNT;
    
    INSERT INTO cleanup_log (action, details, records_affected)
    VALUES (
        'google_data_cleanup',
        jsonb_build_object(
            'photos_cleared', v_photos_deleted,
            'reviews_cleared', v_reviews_deleted,
            'records_affected', v_records_cleared
        ),
        v_records_cleared
    );
    
    RETURN jsonb_build_object(
        'success', true,
        'records_cleared', v_records_cleared,
        'executed_at', NOW()
    );
END;
$$;

SELECT cron.schedule(
    'cleanup-google-data',
    '0 3 * * *',
    $$SELECT cleanup_expired_google_data()$$
);
