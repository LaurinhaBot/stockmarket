const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');

const router = express.Router();
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});

// Criar tabela de usuários (executar apenas uma vez)
const createUsersTable = async () => {
  const createTableSQL = `
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      username VARCHAR(255) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
  `;
  try {
    await pool.query(createTableSQL);
    console.log('✅ Users table created');
  } catch (err) {
    console.error('❌ Error creating users table:', err);
  }
};

// Criar usuário de administrador inicial
const createAdminUser = async () => {
  const password = 'admin123';
  const salt = await bcrypt.genSalt(parseInt(process.env.BCRYPT_ROUNDS || 10));
  const passwordHash = await bcrypt.hash(password, salt);
  const adminUsername = 'admin';
  
  const insertAdminSQL = `
    INSERT INTO users (username, password_hash) 
    VALUES ($1, $2)
    ON CONFLICT DO NOTHING
  `;
  
  try {
    await pool.query(insertAdminSQL, [adminUsername, passwordHash]);
    console.log('✅ Admin user created (username: admin, password: admin123)');
  } catch (err) {
    console.error('❌ Error creating admin user:', err);
  }
};

// Inicializar tabela de usuários
createUsersTable();

// Criar tabela de ações
const createActionsTable = async () => {
  const createTableSQL = `
    CREATE TABLE IF NOT EXISTS actions (
      id SERIAL PRIMARY KEY,
      symbol VARCHAR(50) UNIQUE NOT NULL,
      name VARCHAR(255) NOT NULL,
      price DECIMAL(10, 2) NOT NULL,
      quantity INTEGER NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    CREATE INDEX IF NOT EXISTS idx_actions_symbol ON actions(symbol);
  `;
  try {
    await pool.query(createTableSQL);
    console.log('✅ Actions table created');
  } catch (err) {
    console.error('❌ Error creating actions table:', err);
  }
};

createActionsTable();

// Login
router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  try {
    const client = await pool.connect();
    
    // Buscar usuário por username
    const userQuery = 'SELECT * FROM users WHERE username = $1';
    const user = await client.query(userQuery, [username]);

    if (user.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const userRow = user.rows[0];

    // Verificar senha
    const isValidPassword = await bcrypt.compare(password, userRow.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Gerar JWT
    const jwtSecret = process.env.JWT_SECRET || 'default_jwt_secret';
    const jwtExpiresIn = process.env.JWT_EXPIRES_IN || '1h';

    const token = jwt.sign(
      { 
        userId: userRow.id, 
        username: userRow.username 
      },
      jwtSecret,
      { expiresIn: jwtExpiresIn }
    );

    client.release();

    res.json({
      token,
      expiresIn: jwtExpiresIn,
      user: {
        id: userRow.id,
        username: userRow.username,
        createdAt: userRow.created_at
      }
    });

  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Logout (simples - apenas invalida token)
router.post('/logout', (req, res) => {
  res.json({ message: 'Logged out successfully' });
});

// Verificar se está logado
router.get('/me', async (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const jwtSecret = process.env.JWT_SECRET || 'default_jwt_secret';
    const decoded = jwt.verify(token, jwtSecret);

    // Buscar informações do usuário
    const client = await pool.connect();
    const userQuery = 'SELECT id, username, created_at FROM users WHERE id = $1';
    const user = await client.query(userQuery, [decoded.userId]);

    client.release();

    if (user.rows.length === 0) {
      return res.status(401).json({ error: 'User not found' });
    }

    res.json({
      user: {
        id: user.rows[0].id,
        username: user.rows[0].username,
        createdAt: user.rows[0].created_at
      }
    });

  } catch (err) {
    console.error('Me endpoint error:', err);
    res.status(401).json({ error: 'Invalid or expired token' });
  }
});

module.exports = router;