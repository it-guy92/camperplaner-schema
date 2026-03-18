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

async function main() {
  try {
    await client.connect();
    console.log('='.repeat(70));
    console.log('FINAL MIGRATION VERIFICATION - ALL 4 MIGRATIONS');
    console.log('='.repeat(70));
    
    let allPassed = true;
    
    // Migration 1: Source Family Tables
    console.log('\n--- Migration 1: source_family_tables ---');
    const m1_tables = await client.query(`
      SELECT table_name FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN (
        'place_llm_enrichments', 'place_llm_facts', 'place_llm_sources',
        'place_llm_evidence_markers', 'place_source_evidence_runs',
        'place_evidence_sources', 'place_evidence_markers',
        'place_google_sources', 'place_google_reviews',
        'place_google_photos', 'place_google_types'
      );
    `);
    const m1Expected = 11;
    const m1Actual = m1_tables.rows.length;
    console.log(`✓ Tables: ${m1Actual}/${m1Expected}`);
    m1_tables.rows.forEach(r => console.log(`    - ${r.table_name}`));
    if (m1Actual !== m1Expected) allPassed = false;
    
    // Check place_enrichment columns
    const m1_cols = await client.query(`
      SELECT COUNT(*) as count FROM information_schema.columns 
      WHERE table_name = 'place_enrichment' 
      AND column_name IN ('source_evidence', 'evidence_markers', 'collection_status', 
                          'failure_classification', 'provider_attempts', 'job_cost_usd', 
                          'enrichment_schema_version');
    `);
    console.log(`✓ New columns on place_enrichment: ${m1_cols.rows[0].count}/7`);
    if (m1_cols.rows[0].count !== 7) allPassed = false;
    
    // Migration 2: Typed Columns
    console.log('\n--- Migration 2: enrichment_jobs_typed_columns ---');
    const m2_cols = await client.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'enrichment_jobs' 
      AND column_name IN ('classification', 'source_state', 'worker_id', 'attempt_number', 
                          'last_error_code', 'last_error_message', 'canonical_place_id', 'metadata');
    `);
    console.log(`✓ Typed columns: ${m2_cols.rows.length}/8`);
    m2_cols.rows.forEach(r => console.log(`    - ${r.column_name}`));
    if (m2_cols.rows.length !== 8) allPassed = false;
    
    // Migration 3: RPC Functions
    console.log('\n--- Migration 3: enrichment_jobs_rpc_update ---');
    const m3_funcs = await client.query(`
      SELECT proname FROM pg_proc 
      WHERE proname IN ('enqueue_enrichment_job', 'claim_enrichment_jobs', 
                        'complete_enrichment_job', 'fail_enrichment_job', 
                        'heartbeat_enrichment_job')
      ORDER BY proname;
    `);
    console.log(`✓ RPC functions: ${m3_funcs.rows.length}/5`);
    m3_funcs.rows.forEach(r => console.log(`    - ${r.proname}`));
    if (m3_funcs.rows.length !== 5) allPassed = false;
    
    // Check enum type exists
    const m3_enum = await client.query(`
      SELECT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'enrichment_job_type_enum');
    `);
    console.log(`✓ enrichment_job_type_enum: ${m3_enum.rows[0].exists ? 'EXISTS' : 'NOT FOUND'}`);
    if (!m3_enum.rows[0].exists) allPassed = false;
    
    // Migration 4: Google Amenities Table
    console.log('\n--- Migration 4: add_google_amenities_table ---');
    const m4_table = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'place_google_amenities'
      );
    `);
    console.log(`✓ place_google_amenities table: ${m4_table.rows[0].exists ? 'EXISTS' : 'NOT FOUND'}`);
    if (!m4_table.rows[0].exists) allPassed = false;
    
    const m4_indexes = await client.query(`
      SELECT COUNT(*) as count FROM pg_indexes 
      WHERE tablename = 'place_google_amenities';
    `);
    console.log(`✓ Indexes on place_google_amenities: ${m4_indexes.rows[0].count}`);
    
    // Check RLS
    const m4_rls = await client.query(`
      SELECT relrowsecurity FROM pg_class WHERE relname = 'place_google_amenities';
    `);
    if (m4_rls.rows.length > 0) {
      console.log(`✓ RLS enabled: ${m4_rls.rows[0].relrowsecurity}`);
    }
    
    // Check policies
    const m4_policies = await client.query(`
      SELECT policyname FROM pg_policies WHERE tablename = 'place_google_amenities';
    `);
    console.log(`✓ Policies: ${m4_policies.rows.length}`);
    m4_policies.rows.forEach(r => console.log(`    - ${r.policyname}`));
    
    console.log('\n' + '='.repeat(70));
    if (allPassed) {
      console.log('✓ ALL MIGRATIONS VERIFIED SUCCESSFULLY');
    } else {
      console.log('✗ SOME MIGRATIONS INCOMPLETE');
    }
    console.log('='.repeat(70));
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

main();
