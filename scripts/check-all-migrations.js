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
    console.log('Connected to staging database\n');
    console.log('=' .repeat(60));
    console.log('MIGRATION STATUS CHECK');
    console.log('=' .repeat(60));
    
    // Migration 1: place_llm_enrichments table (already confirmed)
    console.log('\n--- Migration 1: source_family_tables ---');
    const m1_tables = await client.query(`
      SELECT COUNT(*) as count FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name LIKE 'place_llm_%';
    `);
    console.log(`✓ Tables created: ${m1_tables.rows[0].count}/5`);
    
    // Migration 2: enrichment_jobs typed columns
    console.log('\n--- Migration 2: enrichment_jobs_typed_columns ---');
    const m2_columns = await client.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'enrichment_jobs' 
      AND column_name IN ('job_type', 'status', 'priority', 'worker_id', 'place_id');
    `);
    console.log(`Columns found: ${m2_columns.rows.length}/5`);
    m2_columns.rows.forEach(r => console.log(`  - ${r.column_name}`));
    
    // Check if job_type has proper constraint
    const m2_constraint = await client.query(`
      SELECT conname FROM pg_constraint 
      WHERE conrelid = 'enrichment_jobs'::regclass 
      AND conname LIKE '%job_type%';
    `);
    console.log(`✓ job_type constraint: ${m2_constraint.rows.length > 0 ? 'YES' : 'NO'}`);
    
    // Migration 3: RPC update
    console.log('\n--- Migration 3: enrichment_jobs_rpc_update ---');
    const m3_function = await client.query(`
      SELECT proname FROM pg_proc 
      WHERE proname = 'claim_enrichment_job_v2';
    `);
    console.log(`✓ claim_enrichment_job_v2 function: ${m3_function.rows.length > 0 ? 'EXISTS' : 'NOT FOUND'}`);
    
    const m3_triggers = await client.query(`
      SELECT tgname FROM pg_trigger 
      WHERE tgrelid = 'enrichment_jobs'::regclass 
      AND tgname = 'trg_enrichment_jobs_check_freshness';
    `);
    console.log(`✓ Freshness check trigger: ${m3_triggers.rows.length > 0 ? 'EXISTS' : 'NOT FOUND'}`);
    
    // Migration 4: google_amenities table
    console.log('\n--- Migration 4: add_google_amenities_table ---');
    const m4_table = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'place_google_amenities'
      );
    `);
    console.log(`✓ place_google_amenities table: ${m4_table.rows[0].exists ? 'EXISTS' : 'NOT FOUND'}`);
    
    const m4_indexes = await client.query(`
      SELECT indexname FROM pg_indexes 
      WHERE tablename = 'place_google_amenities';
    `);
    console.log(`  Indexes: ${m4_indexes.rows.length}`);
    m4_indexes.rows.forEach(r => console.log(`    - ${r.indexname}`));
    
    console.log('\n' + '='.repeat(60));
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

main();
