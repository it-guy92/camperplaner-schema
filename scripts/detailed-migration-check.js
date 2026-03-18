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
    console.log('DETAILED MIGRATION VERIFICATION\n');
    
    // Check enrichment_jobs columns added by Migration 2
    console.log('--- Migration 2: enrichment_jobs typed columns ---');
    const columns = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'enrichment_jobs'
      ORDER BY ordinal_position;
    `);
    
    const expectedCols = ['classification', 'source_state', 'worker_id', 'attempt_number', 
                          'last_error_code', 'last_error_message', 'canonical_place_id', 'metadata'];
    
    console.log('All columns in enrichment_jobs:');
    columns.rows.forEach(r => {
      const isNew = expectedCols.includes(r.column_name);
      console.log(`  ${isNew ? '✓' : ' '} ${r.column_name} (${r.data_type})`);
    });
    
    // Check indexes
    const indexes = await client.query(`
      SELECT indexname FROM pg_indexes 
      WHERE tablename = 'enrichment_jobs' 
      AND indexname LIKE 'idx_enrichment_jobs_%';
    `);
    console.log('\nNew indexes:');
    indexes.rows.forEach(r => console.log(`  ✓ ${r.indexname}`));
    
    // Check Migration 3: RPC functions
    console.log('\n--- Migration 3: RPC Functions ---');
    const functions = await client.query(`
      SELECT proname, pg_get_function_result(oid) as result
      FROM pg_proc 
      WHERE proname LIKE '%enrichment%'
      ORDER BY proname;
    `);
    console.log('Enrichment-related functions:');
    functions.rows.forEach(r => console.log(`  ${r.proname}`));
    
    // Check triggers
    const triggers = await client.query(`
      SELECT tgname FROM pg_trigger 
      WHERE tgrelid = 'enrichment_jobs'::regclass;
    `);
    console.log('\nTriggers on enrichment_jobs:');
    triggers.rows.forEach(r => console.log(`  ${r.tgname}`));
    
    // Check Migration 4: place_google_amenities
    console.log('\n--- Migration 4: place_google_amenities table ---');
    const amenitiesCols = await client.query(`
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'place_google_amenities'
      ORDER BY ordinal_position;
    `);
    console.log('Columns in place_google_amenities:');
    amenitiesCols.rows.forEach(r => console.log(`  - ${r.column_name}`));
    
    // Check RLS on place_google_amenities
    const rls = await client.query(`
      SELECT relrowsecurity FROM pg_class 
      WHERE relname = 'place_google_amenities';
    `);
    if (rls.rows.length > 0) {
      console.log(`\nRLS enabled: ${rls.rows[0].relrowsecurity}`);
    }
    
    const policies = await client.query(`
      SELECT policyname FROM pg_policies 
      WHERE tablename = 'place_google_amenities';
    `);
    console.log('Policies:');
    policies.rows.forEach(r => console.log(`  - ${r.policyname}`));
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

main();
