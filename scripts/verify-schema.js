const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Load environment variables from .env.local
const envPath = path.join(__dirname, '..', '.env.local');
if (fs.existsSync(envPath)) {
  const envTxt = fs.readFileSync(envPath, 'utf8');
  for(const line of envTxt.split(/\r?\n/)){ 
    const m = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/); 
    if(m) process.env[m[1]] = m[2].replace(/^['"]|['"]$/g,''); 
  }
}

const DB_HOST = process.env.SUPABASE_DB_HOST;
const DB_PASSWORD = process.env.SUPABASE_DB_PASSWORD;

if (!DB_HOST || !DB_PASSWORD) {
  console.error('Error: SUPABASE_DB_HOST and SUPABASE_DB_PASSWORD must be set in .env.local');
  console.error('Example:');
  console.error('  SUPABASE_DB_HOST=db.xxx.supabase.co');
  console.error('  SUPABASE_DB_PASSWORD=your_password');
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

async function verifySchema() {
  const results = {
    timestamp: new Date().toISOString(),
    tests: []
  };
  
  try {
    await client.connect();
    console.log('Connected to staging database\n');
    console.log('=== SCHEMA VERIFICATION ===\n');
    
    // Test 1: Check new source-family tables exist
    console.log('1. Checking new source-family tables...');
    const tableResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN (
        'place_llm_enrichments',
        'place_llm_facts',
        'place_llm_sources',
        'place_llm_evidence_markers',
        'place_source_evidence_runs',
        'place_evidence_sources',
        'place_evidence_markers',
        'place_google_sources',
        'place_google_reviews',
        'place_google_photos',
        'place_google_types'
      )
      ORDER BY table_name;
    `);
    
    const expectedTables = [
      'place_llm_enrichments', 'place_llm_facts', 'place_llm_sources', 
      'place_llm_evidence_markers', 'place_source_evidence_runs', 
      'place_evidence_sources', 'place_evidence_markers',
      'place_google_sources', 'place_google_reviews', 
      'place_google_photos', 'place_google_types'
    ];
    
    const foundTables = tableResult.rows.map(r => r.table_name);
    const allTablesExist = expectedTables.every(t => foundTables.includes(t));
    
    console.log(`   Expected: ${expectedTables.length} tables`);
    console.log(`   Found: ${foundTables.length} tables`);
    foundTables.forEach(t => console.log(`   ✓ ${t}`));
    results.tests.push({ name: 'Source-family tables exist', passed: allTablesExist, found: foundTables.length, expected: expectedTables.length });
    
    // Test 2: Check new columns in place_enrichment
    console.log('\n2. Checking new columns in place_enrichment...');
    const columnResult = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'place_enrichment' 
      AND column_name IN (
        'source_evidence', 'evidence_markers', 'collection_status', 
        'failure_classification', 'provider_attempts', 'job_cost_usd', 
        'enrichment_schema_version'
      )
      ORDER BY ordinal_position;
    `);
    
    const expectedColumns = [
      'source_evidence', 'evidence_markers', 'collection_status',
      'failure_classification', 'provider_attempts', 'job_cost_usd',
      'enrichment_schema_version'
    ];
    
    const foundColumns = columnResult.rows.map(r => r.column_name);
    const allColumnsExist = expectedColumns.every(c => foundColumns.includes(c));
    
    console.log(`   Expected: ${expectedColumns.length} columns`);
    console.log(`   Found: ${foundColumns.length} columns`);
    foundColumns.forEach(c => console.log(`   ✓ ${c}`));
    results.tests.push({ name: 'place_enrichment new columns', passed: allColumnsExist, found: foundColumns.length, expected: expectedColumns.length });
    
    // Test 3: Check new columns in enrichment_jobs
    console.log('\n3. Checking new columns in enrichment_jobs...');
    const jobColumnResult = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'enrichment_jobs' 
      AND column_name IN (
        'classification', 'source_state', 'worker_id', 
        'attempt_number', 'last_error_code', 'last_error_message', 
        'canonical_place_id', 'metadata'
      )
      ORDER BY ordinal_position;
    `);
    
    const expectedJobColumns = [
      'classification', 'source_state', 'worker_id', 'attempt_number',
      'last_error_code', 'last_error_message', 'canonical_place_id', 'metadata'
    ];
    
    const foundJobColumns = jobColumnResult.rows.map(r => r.column_name);
    const allJobColumnsExist = expectedJobColumns.every(c => foundJobColumns.includes(c));
    
    console.log(`   Expected: ${expectedJobColumns.length} columns`);
    console.log(`   Found: ${foundJobColumns.length} columns`);
    foundJobColumns.forEach(c => console.log(`   ✓ ${c}`));
    results.tests.push({ name: 'enrichment_jobs new columns', passed: allJobColumnsExist, found: foundJobColumns.length, expected: expectedJobColumns.length });
    
    // Test 4: Query place_llm_enrichments through PostgREST (simulated)
    console.log('\n4. Testing place_llm_enrichments queryable...');
    try {
      const llmResult = await client.query('SELECT * FROM place_llm_enrichments LIMIT 1');
      console.log(`   ✓ Table queryable (returned ${llmResult.rows.length} rows)`);
      results.tests.push({ name: 'place_llm_enrichments queryable', passed: true, rows: llmResult.rows.length });
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'place_llm_enrichments queryable', passed: false, error: e.message });
    }
    
    // Test 5: Query enrichment_jobs classification column
    console.log('\n5. Testing enrichment_jobs classification column...');
    try {
      const classResult = await client.query('SELECT classification FROM enrichment_jobs LIMIT 1');
      console.log(`   ✓ Column queryable (returned ${classResult.rows.length} rows)`);
      results.tests.push({ name: 'enrichment_jobs classification column', passed: true, rows: classResult.rows.length });
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'enrichment_jobs classification column', passed: false, error: e.message });
    }
    
    // Test 6: Check RPC functions
    console.log('\n6. Checking RPC functions...');
    const rpcResult = await client.query(`
      SELECT p.proname AS function_name
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public'
      AND p.proname IN ('enqueue_enrichment_job', 'claim_enrichment_jobs', 
                        'complete_enrichment_job', 'fail_enrichment_job', 
                        'heartbeat_enrichment_job')
      ORDER BY p.proname;
    `);
    
    const expectedFunctions = [
      'claim_enrichment_jobs', 'complete_enrichment_job', 'enqueue_enrichment_job',
      'fail_enrichment_job', 'heartbeat_enrichment_job'
    ];
    
    const foundFunctions = rpcResult.rows.map(r => r.function_name);
    const allFunctionsExist = expectedFunctions.every(f => foundFunctions.includes(f));
    
    console.log(`   Expected: ${expectedFunctions.length} functions`);
    console.log(`   Found: ${foundFunctions.length} functions`);
    foundFunctions.forEach(f => console.log(`   ✓ ${f}`));
    results.tests.push({ name: 'RPC functions exist', passed: allFunctionsExist, found: foundFunctions.length, expected: expectedFunctions.length });
    
    // Summary
    console.log('\n=== VERIFICATION SUMMARY ===');
    const allPassed = results.tests.every(t => t.passed);
    results.tests.forEach(t => {
      const status = t.passed ? '✓' : '✗';
      console.log(`${status} ${t.name}`);
    });
    
    console.log(`\nOverall: ${allPassed ? 'ALL TESTS PASSED' : 'SOME TESTS FAILED'}`);
    results.overall = allPassed ? 'PASSED' : 'FAILED';
    
  } catch (error) {
    console.error('Fatal error:', error.message);
    results.error = error.message;
  } finally {
    await client.end();
    console.log('\nDatabase connection closed');
  }
  
  return results;
}

verifySchema().then(results => {
  require('fs').writeFileSync('.sisyphus/evidence/task-11-schema-verification.json', JSON.stringify(results, null, 2));
  console.log('\nResults saved to .sisyphus/evidence/task-11-schema-verification.json');
});
