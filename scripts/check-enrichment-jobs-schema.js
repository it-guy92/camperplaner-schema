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

async function checkSchema() {
  try {
    await client.connect();
    
    console.log('Checking enrichment_jobs columns...\n');
    const result = await client.query(`
      SELECT column_name, data_type, udt_name
      FROM information_schema.columns
      WHERE table_name = 'enrichment_jobs'
      ORDER BY ordinal_position
    `);
    
    console.log('Column Name | Data Type | UDT Name');
    console.log('------------|-----------|----------');
    result.rows.forEach(row => {
      console.log(`${row.column_name.padEnd(11)} | ${row.data_type.padEnd(9)} | ${row.udt_name}`);
    });
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await client.end();
  }
}

checkSchema();
