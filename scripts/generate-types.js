#!/usr/bin/env node
const { PostgresMeta } = require('@supabase/postgres-meta');
const fs = require('fs');
const path = require('path');

// Load environment variables
const envPath = path.join(__dirname, '..', '.env.local');
if (fs.existsSync(envPath)) {
  const envTxt = fs.readFileSync(envPath, 'utf8');
  for(const line of envTxt.split(/\r?\n/)){ 
    const m = line.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/); 
    if(m) process.env[m[1]] = m[2].replace(/^['\"]|['\"]$/g,''); 
  }
}

const DB_PASSWORD = process.env.SUPABASE_DB_PASSWORD;
const DB_PORT = process.env.SUPABASE_DB_PORT || '5432';
const DB_NAME = process.env.SUPABASE_DB_NAME || 'postgres';
const DB_USER = process.env.SUPABASE_DB_USER || 'postgres';
const DIRECT_DB_URL = process.env.SUPABASE_DB_URL || process.env.DATABASE_URL;

function inferDbHostFromApiUrl(apiUrl) {
  if (!apiUrl) return null;

  try {
    const { hostname } = new URL(apiUrl);
    const supabaseRefMatch = hostname.match(/^([a-z0-9-]+)\.supabase\.co$/i);

    if (supabaseRefMatch) {
      return `db.${supabaseRefMatch[1]}.supabase.co`;
    }

    return `db.${hostname}`;
  } catch {
    return null;
  }
}

const DB_HOST = process.env.SUPABASE_DB_HOST || inferDbHostFromApiUrl(process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL);
const DB_SSLMODE = process.env.SUPABASE_DB_SSLMODE || (DB_HOST?.endsWith('.supabase.co') ? 'require' : 'disable');

if (!DB_PASSWORD) {
  console.error('Error: SUPABASE_DB_PASSWORD must be set in .env.local');
  process.exit(1);
}

const connectionString = DIRECT_DB_URL
  ? DIRECT_DB_URL
  : DB_HOST
    ? `postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSLMODE}`
    : null;

if (!connectionString) {
  console.error('Error: set SUPABASE_DB_URL/DATABASE_URL or SUPABASE_DB_HOST (or a valid SUPABASE_URL/NEXT_PUBLIC_SUPABASE_URL) together with SUPABASE_DB_PASSWORD');
  process.exit(1);
}

console.log('Connecting to database...');

const pgMeta = new PostgresMeta({ connectionString });

(async () => {
  try {
    console.log('Fetching tables...');
    const { data: tables, error: tablesError } = await pgMeta.tables.list({ 
      includeColumns: true,
      includedSchemas: ['public']
    });
    
    if (tablesError) throw tablesError;
    
    console.log('Fetching views...');
    const { data: views, error: viewsError } = await pgMeta.views.list({ 
      includeColumns: true,
      includedSchemas: ['public']
    });
    
    if (viewsError) throw viewsError;
    
    console.log('Fetching enums...');
    const { data: enums, error: enumsError } = await pgMeta.types.list({
      includeArrayTypes: false,
      includeSystemSchemas: false
    });
    
    if (enumsError) throw enumsError;
    
    const enumTypes = (enums || []).filter(t => t.enums && t.enums.length > 0);
    
    // Generate TypeScript
    const ts = generateTypes(tables, views || [], enumTypes);
    
    const outputPath = path.join(__dirname, '..', 'generated', 'database.types.ts');
    fs.writeFileSync(outputPath, ts);
    
    console.log('\n✓ Types written to:', outputPath);
    console.log('  Tables:', tables.length);
    console.log('  Views:', views?.length || 0);
    console.log('  Enums:', enumTypes.length);
    
  } catch(e) {
    console.error('Error:', e.message);
    process.exit(1);
  } finally {
    await pgMeta.end();
  }
})();

function generateTypes(tables, views, enums) {
  let output = `export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]\n\n`;
  
  // Add enum types
  for (const enumType of enums) {
    const name = toPascalCase(enumType.name);
    const values = enumType.enums || [];
    if (values.length > 0) {
      output += `export type ${name} = ${values.map(v => `'${v}'`).join(' | ')}\n\n`;
    }
  }
  
  output += `export interface Database {\n  public: {\n    Tables: {\n`;
  
  // Add tables
  for (const table of tables) {
    output += `      ${table.name}: {\n        Row: {\n`;
    for (const column of table.columns || []) {
      const type = mapPostgresType(column.data_type, column.enum_values);
      const nullable = column.is_nullable ? ' | null' : '';
      output += `          ${column.name}: ${type}${nullable}\n`;
    }
    output += `        }\n        Insert: {\n`;
    for (const column of table.columns || []) {
      const type = mapPostgresType(column.data_type, column.enum_values);
      const nullable = column.is_nullable ? ' | null' : '';
      const optional = column.column_default || column.is_nullable ? '?' : '';
      output += `          ${column.name}${optional}: ${type}${nullable}\n`;
    }
    output += `        }\n        Update: {\n`;
    for (const column of table.columns || []) {
      const type = mapPostgresType(column.data_type, column.enum_values);
      const nullable = column.is_nullable ? ' | null' : '';
      output += `          ${column.name}?: ${type}${nullable}\n`;
    }
    output += `        }\n      }\n`;
  }
  
  output += `    }\n    Views: {\n`;
  
  // Add views
  for (const view of views) {
    output += `      ${view.name}: {\n        Row: {\n`;
    for (const column of view.columns || []) {
      const type = mapPostgresType(column.data_type, column.enum_values);
      const nullable = column.is_nullable ? ' | null' : '';
      output += `          ${column.name}: ${type}${nullable}\n`;
    }
    output += `        }\n      }\n`;
  }
  
  output += `    }\n    Functions: {\n      [_ in never]: never\n    }\n    Enums: {\n`;
  
  // Add enums
  for (const enumType of enums) {
    const name = enumType.name;
    const values = enumType.enums || [];
    if (values.length > 0) {
      output += `      ${name}: ${values.map(v => `'${v}'`).join(' | ')}\n`;
    }
  }
  
  output += `    }\n  }\n}\n`;
  
  return output;
}

function toPascalCase(str) {
  return str.split('_').map(s => s.charAt(0).toUpperCase() + s.slice(1)).join('');
}

function mapPostgresType(pgType, enumValues) {
  if (enumValues && enumValues.length > 0) {
    return enumValues.map(v => `'${v}'`).join(' | ');
  }
  
  switch(pgType) {
    case 'uuid':
    case 'text':
    case 'character varying':
    case 'char':
    case 'bpchar':
    case 'name':
      return 'string';
    case 'integer':
    case 'bigint':
    case 'smallint':
    case 'serial':
    case 'bigserial':
      return 'number';
    case 'numeric':
    case 'decimal':
    case 'real':
    case 'double precision':
      return 'number';
    case 'boolean':
      return 'boolean';
    case 'timestamp with time zone':
    case 'timestamp without time zone':
    case 'date':
    case 'time':
      return 'string';
    case 'json':
    case 'jsonb':
      return 'Json';
    case 'ARRAY':
      return 'unknown[]';
    case 'USER-DEFINED':
      return 'string';
    default:
      if (pgType.startsWith('_')) {
        return 'unknown[]';
      }
      return 'unknown';
  }
}
