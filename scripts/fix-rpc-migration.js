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
    
    // Drop existing functions to allow recreation with new signatures
    console.log('Dropping existing RPC functions...');
    
    const dropFunctions = `
      DROP FUNCTION IF EXISTS enqueue_enrichment_job(INTEGER, enrichment_job_type_enum, INTEGER, JSONB, JSONB, TEXT, INTEGER, TIMESTAMPTZ);
      DROP FUNCTION IF EXISTS enqueue_enrichment_job(INTEGER, enrichment_job_type_enum, INTEGER, JSONB, JSONB, TEXT, INTEGER, TIMESTAMPTZ, TEXT, TEXT, UUID, JSONB);
      DROP FUNCTION IF EXISTS claim_enrichment_jobs(TEXT, INTEGER, INTEGER);
      DROP FUNCTION IF EXISTS complete_enrichment_job(INTEGER, TEXT, JSONB);
      DROP FUNCTION IF EXISTS fail_enrichment_job(INTEGER, TEXT, TEXT, JSONB, INTEGER);
      DROP FUNCTION IF EXISTS heartbeat_enrichment_job(INTEGER, TEXT, INTEGER);
    `;
    
    await client.query(dropFunctions);
    console.log('✓ Existing functions dropped\n');
    
    // Now apply the RPC migration
    console.log('Applying RPC migration...');
    const sql = fs.readFileSync('supabase/migrations/20260316_enrichment_jobs_rpc_update.sql', 'utf8');
    await client.query(sql);
    console.log('✓ RPC migration applied successfully\n');
    
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await client.end();
    console.log('Database connection closed');
  }
}

main();
