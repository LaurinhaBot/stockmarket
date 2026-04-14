require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Pool } = require('pg');

// Importar rotas
const authRoutes = require('./routes/auth');
const actionRoutes = require('./routes/actions');

// Configurar aplicação
const app = express();

// Middleware
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS.split(','),
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
}));

app.use(helmet());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging
if (process.env.LOG_LEVEL === 'debug') {
  app.use(morgan('dev'));
}

// Configurar conexão com PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
});

// Testar conexão
pool.on('connect', () => {
  console.log('✅ PostgreSQL connection established');
});

pool.on('error', (err) => {
  console.error('❌ PostgreSQL connection error:', err);
});

// Rotas
app.get('/', (req, res) => {
  res.json({
    message: 'BovespaTrade API v1.0',
    endpoints: {
      auth: '/api/auth/login',
      auth: '/api/auth/logout',
      actions: '/api/actions',
      actions: '/api/actions/:id'
    }
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/actions', actionRoutes);

// Erro handler global
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: err.message
  });
});

// Graceful shutdown
const server = app;

process.on('SIGINT', async () => {
  await pool.end();
  console.log('Database connection closed');
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await pool.end();
  console.log('Database connection closed');
  process.exit(0);
});

// Iniciar servidor
const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`
  🚀 BovespaTrade Backend Server
     Port: ${PORT}
     Environment: ${process.env.NODE_ENV}
     Database: ${process.env.DB_HOST}:${process.env.DB_PORT}
  `);
});

module.exports = { app, pool };