const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

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

async function runMigration(filePath, migrationNum) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`Migration ${migrationNum}: ${path.basename(filePath)}`);
  console.log('='.repeat(60));
  
  try {
    const sql = fs.readFileSync(filePath, 'utf8');
    await client.query(sql);
    console.log(`✓ Migration ${migrationNum} applied successfully`);
    return { success: true, migration: migrationNum, file: path.basename(filePath) };
  } catch (error) {
    console.error(`✗ Migration ${migrationNum} failed`);
    console.error(`Error: ${error.message}`);
    return { success: false, migration: migrationNum, file: path.basename(filePath), error: error.message };
  }
}

async function main() {
  const results = [];
  
  try {
    await client.connect();
    console.log('Connected to staging database');
    
    // Migration files 2-4 (Migration 1 already applied)
    const migrations = [
      { num: 2, file: 'supabase/migrations/20260316_enrichment_jobs_typed_columns.sql' },
      { num: 3, file: 'supabase/migrations/20260316_enrichment_jobs_rpc_update.sql' },
      { num: 4, file: 'supabase/migrations/20260316000001_add_google_amenities_table.sql' }
    ];
    
    for (const { num, file } of migrations) {
      const result = await runMigration(file, num);
      results.push(result);
      
      if (!result.success) {
        console.error('\nMigration chain halted due to error');
        break;
      }
    }
    
    console.log('\n' + '='.repeat(60));
    console.log('MIGRATION SUMMARY');
    console.log('='.repeat(60));
    results.forEach(r => {
      const status = r.success ? '✓' : '✗';
      console.log(`${status} Migration ${r.migration}: ${r.file}`);
      if (r.error) {
        console.log(`  Error: ${r.error}`);
      }
    });
    
    const successCount = results.filter(r => r.success).length;
    console.log(`\nCompleted: ${successCount}/${results.length} migrations`);
    
  } catch (error) {
    console.error('Fatal error:', error.message);
  } finally {
    await client.end();
    console.log('Database connection closed');
  }
}

main();
