const { Client } = require('pg');

// Load environment variables
const DB_HOST = process.env.SUPABASE_DB_HOST;
const DB_PASSWORD = process.env.SUPABASE_DB_PASSWORD;

if (!DB_HOST || !DB_PASSWORD) {
  console.error('Error: SUPABASE_DB_HOST and SUPABASE_DB_PASSWORD must be set');
  process.exit(1);
}

const client = new Client({
  host: DB_HOST,
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: DB_PASSWORD,
  ssl: { rejectUnauthorized: false }
});

async function fixRPC() {
  try {
    await client.connect();
    console.log('Connected to staging database\n');
    
    // Fix the enqueue function to work with existing schema
    const fixSQL = `
CREATE OR REPLACE FUNCTION enqueue_enrichment_job(
    p_place_id INTEGER,
    p_job_type enrichment_job_type_enum,
    p_priority INTEGER DEFAULT 0,
    p_payload JSONB DEFAULT '{}',
    p_context JSONB DEFAULT '{}',
    p_freshness_window TEXT DEFAULT '24 hours',
    p_max_attempts INTEGER DEFAULT 3,
    p_run_after TIMESTAMPTZ DEFAULT NOW(),
    p_classification TEXT DEFAULT NULL,
    p_source_state TEXT DEFAULT NULL,
    p_canonical_place_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS enrichment_jobs
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_freshness_bucket TIMESTAMPTZ;
    v_job enrichment_jobs;
BEGIN
    -- Calculate freshness bucket as timestamp
    v_freshness_bucket := NOW() + (p_freshness_window)::INTERVAL;

    INSERT INTO enrichment_jobs (
        place_id,
        job_type,
        priority,
        payload,
        context,
        freshness_bucket,
        max_attempts,
        run_after,
        status,
        attempts,
        created_at,
        updated_at,
        classification,
        source_state,
        canonical_place_id,
        metadata
    ) VALUES (
        p_place_id,
        p_job_type,
        p_priority,
        p_payload,
        p_context,
        v_freshness_bucket,
        p_max_attempts,
        p_run_after,
        'queued',
        0,
        NOW(),
        NOW(),
        p_classification,
        p_source_state,
        p_canonical_place_id,
        COALESCE(p_metadata, '{}')
    )
    RETURNING * INTO v_job;

    RETURN v_job;
END;
$$;
`;

    console.log('Fixing enqueue_enrichment_job function...');
    await client.query(fixSQL);
    console.log('✓ Function updated successfully\n');
    
  } catch (error) {
    console.error('Error:', error.message);
    console.error(error.stack);
  } finally {
    await client.end();
    console.log('Database connection closed');
  }
}

fixRPC();
