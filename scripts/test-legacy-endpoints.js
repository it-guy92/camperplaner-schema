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

async function testLegacyEndpoints() {
  const results = {
    timestamp: new Date().toISOString(),
    tests: []
  };
  
  try {
    await client.connect();
    console.log('Connected to staging database\n');
    console.log('=== LEGACY ADMIN ENDPOINT TESTS ===\n');
    
    // Find a test place
    const placeResult = await client.query(`
      SELECT id, name 
      FROM places 
      LIMIT 1
    `);
    
    if (placeResult.rows.length === 0) {
      throw new Error('No places found for testing');
    }
    
    const testPlace = placeResult.rows[0];
    console.log(`Using test place: ${testPlace.name} (ID: ${testPlace.id})\n`);
    
    // Test 1: Legacy enqueue via RPC
    console.log('1. Testing legacy enqueue (RPC call)...');
    try {
      const enqueueResult = await client.query(`
        SELECT * FROM enqueue_enrichment_job(
          $1::INTEGER, 
          'enrich_llm'::enrichment_job_type_enum,
          10,
          '{"test": true}'::JSONB,
          '{"origin": "test"}'::JSONB,
          '24 hours',
          3
        )
      `, [testPlace.id]);
      
      if (enqueueResult.rows.length > 0) {
        const job = enqueueResult.rows[0];
        console.log(`   ✓ Job enqueued successfully`);
        console.log(`     Job ID: ${job.id}`);
        console.log(`     Status: ${job.status}`);
        console.log(`     Place ID: ${job.place_id}`);
        results.tests.push({ 
          name: 'Legacy enqueue (RPC)', 
          passed: true, 
          jobId: job.id,
          status: job.status 
        });
        
        // Store job ID for cleanup
        results.enqueuedJobId = job.id;
      } else {
        throw new Error('No job returned from enqueue');
      }
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'Legacy enqueue (RPC)', passed: false, error: e.message });
    }
    
    // Test 2: Query enrichment_jobs with new columns
    console.log('\n2. Testing enrichment_jobs query with new columns...');
    try {
      const jobResult = await client.query(`
        SELECT id, place_id, status, classification, source_state, 
               worker_id, attempt_number, last_error_code, 
               last_error_message, canonical_place_id, metadata
        FROM enrichment_jobs 
        WHERE place_id = $1
        ORDER BY created_at DESC
        LIMIT 1
      `, [testPlace.id]);
      
      if (jobResult.rows.length > 0) {
        const job = jobResult.rows[0];
        console.log(`   ✓ Job queryable with new columns`);
        console.log(`     Job ID: ${job.id}`);
        console.log(`     Classification: ${job.classification || 'null'}`);
        console.log(`     Attempt Number: ${job.attempt_number}`);
        results.tests.push({ 
          name: 'enrichment_jobs new columns queryable', 
          passed: true,
          jobId: job.id 
        });
      } else {
        console.log(`   ✗ No jobs found`);
        results.tests.push({ name: 'enrichment_jobs new columns queryable', passed: false, error: 'No jobs found' });
      }
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'enrichment_jobs new columns queryable', passed: false, error: e.message });
    }
    
    // Test 3: Legacy read - query place_enrichment with new columns
    console.log('\n3. Testing legacy read (place_enrichment with new columns)...');
    try {
      const enrichmentResult = await client.query(`
        SELECT id, place_id, summary_de, collection_status, 
               failure_classification, enrichment_schema_version
        FROM place_enrichment 
        WHERE place_id = $1
        ORDER BY created_at DESC
        LIMIT 1
      `, [testPlace.id]);
      
      console.log(`   ✓ place_enrichment queryable`);
      console.log(`     Found ${enrichmentResult.rows.length} enrichment records`);
      if (enrichmentResult.rows.length > 0) {
        const enrich = enrichmentResult.rows[0];
        console.log(`     Collection Status: ${enrich.collection_status || 'null'}`);
        console.log(`     Schema Version: ${enrich.enrichment_schema_version || 'null'}`);
      }
      results.tests.push({ 
        name: 'Legacy read (place_enrichment)', 
        passed: true,
        recordsFound: enrichmentResult.rows.length 
      });
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'Legacy read (place_enrichment)', passed: false, error: e.message });
    }
    
    // Test 4: New schema read - place_llm_enrichments
    console.log('\n4. Testing new schema read (place_llm_enrichments)...');
    try {
      const llmResult = await client.query(`
        SELECT id, place_id, provider, model, status, is_current
        FROM place_llm_enrichments 
        WHERE place_id = $1
        LIMIT 1
      `, [testPlace.id]);
      
      console.log(`   ✓ place_llm_enrichments queryable`);
      console.log(`     Found ${llmResult.rows.length} LLM enrichment records`);
      results.tests.push({ 
        name: 'New schema read (place_llm_enrichments)', 
        passed: true,
        recordsFound: llmResult.rows.length 
      });
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'New schema read (place_llm_enrichments)', passed: false, error: e.message });
    }
    
    // Test 5: Test claim_enrichment_jobs RPC
    console.log('\n5. Testing claim_enrichment_jobs RPC...');
    try {
      const claimResult = await client.query(`
        SELECT * FROM claim_enrichment_jobs('test-worker-001', 1, 300)
      `);
      
      console.log(`   ✓ claim_enrichment_jobs works`);
      console.log(`     Claimed ${claimResult.rows.length} jobs`);
      if (claimResult.rows.length > 0) {
        const job = claimResult.rows[0];
        console.log(`     Job ID: ${job.id}`);
        console.log(`     Worker ID: ${job.worker_id}`);
        console.log(`     Status: ${job.status}`);
      }
      results.tests.push({ 
        name: 'claim_enrichment_jobs RPC', 
        passed: true,
        jobsClaimed: claimResult.rows.length 
      });
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'claim_enrichment_jobs RPC', passed: false, error: e.message });
    }
    
    // Summary
    console.log('\n=== LEGACY ENDPOINT TEST SUMMARY ===');
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

testLegacyEndpoints().then(results => {
  require('fs').writeFileSync('.sisyphus/evidence/task-11-legacy-endpoints.json', JSON.stringify(results, null, 2));
  console.log('\nResults saved to .sisyphus/evidence/task-11-legacy-endpoints.json');
});
