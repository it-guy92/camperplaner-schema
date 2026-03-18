const { Client } = require('pg');
const fs = require('fs');

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
    
    const dropFunctions = `
      DROP FUNCTION IF EXISTS enqueue_enrichment_job(bigint, enrichment_job_type_enum, smallint, timestamp with time zone, jsonb, jsonb, interval, integer);
      DROP FUNCTION IF EXISTS complete_enrichment_job(bigint, text, jsonb);
      DROP FUNCTION IF EXISTS fail_enrichment_job(bigint, text, text, integer, jsonb);
      DROP FUNCTION IF EXISTS heartbeat_enrichment_job(bigint, text, integer);
      DROP FUNCTION IF EXISTS claim_enrichment_jobs(text, integer, integer);
    `;
    
    console.log('Dropping existing functions with old signatures...');
    await client.query(dropFunctions);
    console.log('✓ Functions dropped\n');
    
    console.log('Applying RPC migration with new signatures...');
    const sql = fs.readFileSync('supabase/migrations/20260316_enrichment_jobs_rpc_update.sql', 'utf8');
    await client.query(sql);
    console.log('✓ RPC migration applied successfully!\n');
    
    console.log('Verifying new functions...');
    const result = await client.query(`
      SELECT p.proname AS function_name
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public'
      AND p.proname IN ('enqueue_enrichment_job', 'claim_enrichment_jobs', 
                        'complete_enrichment_job', 'fail_enrichment_job', 
                        'heartbeat_enrichment_job')
      ORDER BY p.proname;
    `);
    
    console.log('\nFunctions now available:');
    result.rows.forEach(row => {
      console.log(`  ✓ ${row.function_name}`);
    });
    
  } catch (error) {
    console.error('Error:', error.message);
    console.error(error.stack);
    process.exit(1);
  } finally {
    await client.end();
    console.log('\nDatabase connection closed');
  }
}

main();
