const { Pool } = require('pg');
const { v4: uuidv4 } = require('uuid');

// Database connection configuration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://localhost:5432/weau',
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

// Test connection
pool.on('connect', () => {
  console.log('Connected to PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('Database connection error:', err);
});

// Initialize schema
async function initSchema() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        google_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        avatar TEXT,
        tracking_enabled BOOLEAN DEFAULT true,
        visibility_level TEXT DEFAULT 'friends', -- 'public', 'friends', 'none'
        precision_level TEXT DEFAULT 'exact', -- 'exact', 'city'
        last_lat DOUBLE PRECISION,
        last_lng DOUBLE PRECISION,
        last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS invitations (
        id TEXT PRIMARY KEY,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'declined'
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(sender_id, receiver_id)
      );

      CREATE TABLE IF NOT EXISTS friends (
        user_id TEXT NOT NULL,
        friend_id TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (user_id, friend_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE
      );
    `);
    console.log('Database schema initialized successfully');
  } catch (err) {
    console.error('Error initializing schema:', err);
  }
}

// Initialize schema on startup
initSchema();

// Helper functions to execute queries
const db = {
  query: (text, params) => pool.query(text, params),
  end: () => pool.end(),
};

module.exports = db;