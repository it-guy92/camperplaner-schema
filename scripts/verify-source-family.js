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

async function verifySourceFamilyReconstruction() {
  const results = {
    timestamp: new Date().toISOString(),
    tests: []
  };
  
  try {
    await client.connect();
    console.log('Connected to staging database\n');
    console.log('=== SOURCE-FAMILY RECONSTRUCTION TESTS ===\n');
    
    // Test 1: Verify we can insert and query place_llm_enrichments
    console.log('1. Testing place_llm_enrichments INSERT/SELECT...');
    try {
      // Insert test record
      const insertResult = await client.query(`
        INSERT INTO place_llm_enrichments 
        (place_id, provider, model, summary_de, confidence, status, is_current)
        VALUES 
        (16690, 'openai', 'gpt-4', 'Test camping description', 0.95, 'completed', true)
        RETURNING id
      `);
      
      const enrichmentId = insertResult.rows[0].id;
      console.log(`   ✓ Inserted LLM enrichment record (ID: ${enrichmentId})`);
      
      // Query it back
      const queryResult = await client.query(`
        SELECT * FROM place_llm_enrichments WHERE id = $1
      `, [enrichmentId]);
      
      if (queryResult.rows.length === 1) {
        const record = queryResult.rows[0];
        console.log(`   ✓ Record retrievable`);
        console.log(`     Provider: ${record.provider}`);
        console.log(`     Model: ${record.model}`);
        console.log(`     Status: ${record.status}`);
        results.tests.push({ 
          name: 'place_llm_enrichments INSERT/SELECT', 
          passed: true,
          enrichmentId: enrichmentId 
        });
        results.testEnrichmentId = enrichmentId;
      }
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'place_llm_enrichments INSERT/SELECT', passed: false, error: e.message });
    }
    
    // Test 2: Verify we can insert and query place_llm_facts
    console.log('\n2. Testing place_llm_facts INSERT/SELECT...');
    try {
      if (results.testEnrichmentId) {
        const insertResult = await client.query(`
          INSERT INTO place_llm_facts 
          (llm_enrichment_id, field_name, value_text, value_type, confidence, provenance_kind)
          VALUES 
          ($1, 'has_wifi', 'true', 'boolean', 0.9, 'llm_extracted'),
          ($1, 'rating', '4.5', 'number', 0.85, 'llm_extracted')
          RETURNING id
        `, [results.testEnrichmentId]);
        
        console.log(`   ✓ Inserted ${insertResult.rows.length} fact records`);
        
        const queryResult = await client.query(`
          SELECT * FROM place_llm_facts WHERE llm_enrichment_id = $1
        `, [results.testEnrichmentId]);
        
        console.log(`   ✓ Retrieved ${queryResult.rows.length} facts`);
        queryResult.rows.forEach(fact => {
          console.log(`     ${fact.field_name}: ${fact.value_text} (${fact.value_type})`);
        });
        
        results.tests.push({ 
          name: 'place_llm_facts INSERT/SELECT', 
          passed: true,
          factsInserted: insertResult.rows.length 
        });
      } else {
        throw new Error('No enrichment ID available from previous test');
      }
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'place_llm_facts INSERT/SELECT', passed: false, error: e.message });
    }
    
    // Test 3: Verify we can insert and query place_google_sources
    console.log('\n3. Testing place_google_sources INSERT/SELECT...');
    try {
      const insertResult = await client.query(`
        INSERT INTO place_google_sources 
        (place_id, google_place_id, name, formatted_address, rating, review_count, is_current)
        VALUES 
        (16690, 'ChIJ_test_123', 'Camping Muralt', 'Muralt, Switzerland', 4.5, 127, true)
        RETURNING id
      `);
      
      const googleSourceId = insertResult.rows[0].id;
      console.log(`   ✓ Inserted Google source record (ID: ${googleSourceId})`);
      
      const queryResult = await client.query(`
        SELECT * FROM place_google_sources WHERE id = $1
      `, [googleSourceId]);
      
      if (queryResult.rows.length === 1) {
        const record = queryResult.rows[0];
        console.log(`   ✓ Record retrievable`);
        console.log(`     Name: ${record.name}`);
        console.log(`     Rating: ${record.rating}`);
        console.log(`     Reviews: ${record.review_count}`);
        results.tests.push({ 
          name: 'place_google_sources INSERT/SELECT', 
          passed: true,
          googleSourceId: googleSourceId 
        });
        results.testGoogleSourceId = googleSourceId;
      }
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'place_google_sources INSERT/SELECT', passed: false, error: e.message });
    }
    
    // Test 4: Verify JOIN between parent and child tables
    console.log('\n4. Testing JOIN reconstruction (place_llm_enrichments + facts)...');
    try {
      const joinResult = await client.query(`
        SELECT 
          e.id as enrichment_id,
          e.provider,
          e.model,
          e.summary_de,
          f.id as fact_id,
          f.field_name,
          f.value_text,
          f.confidence as fact_confidence
        FROM place_llm_enrichments e
        LEFT JOIN place_llm_facts f ON f.llm_enrichment_id = e.id
        WHERE e.place_id = 16690 AND e.is_current = true
      `);
      
      console.log(`   ✓ JOIN query successful`);
      console.log(`     Retrieved ${joinResult.rows.length} rows`);
      
      if (joinResult.rows.length > 0) {
        console.log(`     Enrichment: ${joinResult.rows[0].provider}/${joinResult.rows[0].model}`);
        const facts = joinResult.rows.filter(r => r.fact_id !== null);
        console.log(`     With ${facts.length} associated facts`);
      }
      
      results.tests.push({ 
        name: 'JOIN reconstruction', 
        passed: true,
        rowsRetrieved: joinResult.rows.length 
      });
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'JOIN reconstruction', passed: false, error: e.message });
    }
    
    // Test 5: Test evidence collection tables
    console.log('\n5. Testing place_source_evidence_runs INSERT/SELECT...');
    try {
      const insertResult = await client.query(`
        INSERT INTO place_source_evidence_runs 
        (place_id, attempt_number, collection_status, trusted_source_count)
        VALUES 
        (16690, 1, 'completed', 5)
        RETURNING id
      `);
      
      const evidenceRunId = insertResult.rows[0].id;
      console.log(`   ✓ Inserted evidence run record (ID: ${evidenceRunId})`);
      
      const queryResult = await client.query(`
        SELECT * FROM place_source_evidence_runs WHERE id = $1
      `, [evidenceRunId]);
      
      if (queryResult.rows.length === 1) {
        const record = queryResult.rows[0];
        console.log(`   ✓ Record retrievable`);
        console.log(`     Status: ${record.collection_status}`);
        console.log(`     Trusted sources: ${record.trusted_source_count}`);
        results.tests.push({ 
          name: 'place_source_evidence_runs INSERT/SELECT', 
          passed: true,
          evidenceRunId: evidenceRunId 
        });
      }
    } catch (e) {
      console.log(`   ✗ Error: ${e.message}`);
      results.tests.push({ name: 'place_source_evidence_runs INSERT/SELECT', passed: false, error: e.message });
    }
    
    // Summary
    console.log('\n=== SOURCE-FAMILY RECONSTRUCTION SUMMARY ===');
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

verifySourceFamilyReconstruction().then(results => {
  require('fs').writeFileSync('.sisyphus/evidence/task-11-source-family-reconstruction.json', JSON.stringify(results, null, 2));
  console.log('\nResults saved to .sisyphus/evidence/task-11-source-family-reconstruction.json');
});
