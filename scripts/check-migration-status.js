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
    
    // Check if place_llm_enrichments table exists
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'place_llm_enrichments'
      );
    `);
    
    console.log('place_llm_enrichments table exists:', tableCheck.rows[0].exists);
    
    // Check policies on place_llm_enrichments
    const policyCheck = await client.query(`
      SELECT policyname FROM pg_policies 
      WHERE tablename = 'place_llm_enrichments';
    `);
    
    console.log('\nExisting policies on place_llm_enrichments:');
    policyCheck.rows.forEach(row => console.log('  -', row.policyname));
    
    // Check new columns on place_enrichment
    const columnCheck = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'place_enrichment' 
      AND column_name IN ('source_evidence', 'evidence_markers', 'collection_status', 
                          'failure_classification', 'provider_attempts', 'job_cost_usd', 
                          'enrichment_schema_version')
      ORDER BY ordinal_position;
    `);
    
    console.log('\nNew columns on place_enrichment:');
    columnCheck.rows.forEach(row => console.log('  -', row.column_name));
    
    // Check all new tables
    const tablesCheck = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN (
        'place_llm_enrichments', 'place_llm_facts', 'place_llm_sources',
        'place_llm_evidence_markers', 'place_source_evidence_runs',
        'place_evidence_sources', 'place_evidence_markers',
        'place_google_sources', 'place_google_reviews',
        'place_google_photos', 'place_google_types'
      )
      ORDER BY table_name;
    `);
    
    console.log('\nNew tables created:');
    tablesCheck.rows.forEach(row => console.log('  ✓', row.table_name));
    
    const expectedTables = 11;
    console.log(`\nProgress: ${tablesCheck.rows.length}/${expectedTables} tables`);
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

main();
