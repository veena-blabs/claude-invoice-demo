// src/db/connection.ts
// PostgreSQL connection pool

import { Pool } from 'pg';

// BUG (critical): No check that DATABASE_URL is set — Pool silently uses wrong defaults
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // BUG (warning): No max pool size set — defaults to 10, could exhaust DB connections under load
});

export const db = {
  query: async (text: string, params?: any[]) => {
    // BUG (warning): No connection timeout — queries can hang indefinitely
    const result = await pool.query(text, params);
    return result.rows;
  },
};
