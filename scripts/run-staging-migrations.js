const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Staging database connection
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

async function runMigration(filePath) {
  console.log(`\n========================================`);
  console.log(`Running migration: ${path.basename(filePath)}`);
  console.log(`========================================\n`);
  
  try {
    const sql = fs.readFileSync(filePath, 'utf8');
    await client.query(sql);
    console.log(`✓ Migration applied successfully: ${path.basename(filePath)}`);
    return { success: true, file: path.basename(filePath) };
  } catch (error) {
    console.error(`✗ Migration failed: ${path.basename(filePath)}`);
    console.error(`Error: ${error.message}`);
    return { success: false, file: path.basename(filePath), error: error.message };
  }
}

async function main() {
  const results = [];
  
  try {
    await client.connect();
    console.log('Connected to staging database');
    
    // Migration files in order
    const migrations = [
      'supabase/migrations/20260316_add_source_family_tables.sql',
      'supabase/migrations/20260316_enrichment_jobs_typed_columns.sql',
      'supabase/migrations/20260316_enrichment_jobs_rpc_update.sql',
      'supabase/migrations/20260316000001_add_google_amenities_table.sql'
    ];
    
    for (const migration of migrations) {
      const result = await runMigration(migration);
      results.push(result);
      
      if (!result.success) {
        console.error('\nMigration chain halted due to error');
        break;
      }
    }
    
    console.log('\n========================================');
    console.log('Migration Summary');
    console.log('========================================');
    results.forEach(r => {
      const status = r.success ? '✓' : '✗';
      console.log(`${status} ${r.file}`);
      if (r.error) {
        console.log(`  Error: ${r.error}`);
      }
    });
    
  } catch (error) {
    console.error('Fatal error:', error.message);
  } finally {
    await client.end();
    console.log('\nDatabase connection closed');
  }
}

main();
