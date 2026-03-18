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
    
    // Check existing functions
    const result = await client.query(`
      SELECT 
        p.proname AS function_name,
        pg_get_function_identity_arguments(p.oid) AS arguments,
        p.proargtypes::regtype[]::text AS arg_types
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'public'
      AND p.proname LIKE '%enrichment%'
      ORDER BY p.proname;
    `);
    
    console.log('Existing enrichment functions:');
    console.log('================================');
    result.rows.forEach(row => {
      console.log(`${row.function_name}(${row.arguments})`);
    });
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

main();
