const express = require('express');
const { Pool } = require('pg');

const router = express.Router();
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME
});

// Criar tabela de ações (se não existir)
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

// Listar todas as ações
router.get('/', async (req, res) => {
  try {
    const client = await pool.connect();
    
    const query = `
      SELECT id, symbol, name, price, quantity, created_at 
      FROM actions 
      ORDER BY created_at DESC
    `;
    
    const result = await client.query(query);
    client.release();

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows
    });

  } catch (err) {
    console.error('Get actions error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Buscar ação por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const client = await pool.connect();
    const query = `
      SELECT id, symbol, name, price, quantity, created_at 
      FROM actions 
      WHERE id = $1
    `;
    
    const result = await client.query(query, [id]);
    client.release();

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Action not found' });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });

  } catch (err) {
    console.error('Get action by ID error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Criar nova ação
router.post('/', async (req, res) => {
  const { symbol, name, price, quantity } = req.body;

  if (!symbol || !name || !price || !quantity) {
    return res.status(400).json({ 
      error: 'All fields are required: symbol, name, price, quantity' 
    });
  }

  try {
    const client = await pool.connect();
    
    const query = `
      INSERT INTO actions (symbol, name, price, quantity) 
      VALUES ($1, $2, $3, $4) 
      RETURNING id, symbol, name, price, quantity, created_at
    `;
    
    const result = await client.query(query, [symbol, name, price, quantity]);
    client.release();

    res.status(201).json({
      success: true,
      message: 'Action created successfully',
      data: result.rows[0]
    });

  } catch (err) {
    console.error('Create action error:', err);
    
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Action with this symbol already exists' });
    }
    
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Atualizar ação
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { symbol, name, price, quantity } = req.body;

  if (!symbol || !name || !price || !quantity) {
    return res.status(400).json({ 
      error: 'All fields are required: symbol, name, price, quantity' 
    });
  }

  try {
    const client = await pool.connect();
    
    const query = `
      UPDATE actions 
      SET symbol = $2, name = $3, price = $4, quantity = $5, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING id, symbol, name, price, quantity, created_at, updated_at
    `;
    
    const result = await client.query(query, [id, symbol, name, price, quantity]);
    client.release();

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Action not found' });
    }

    res.json({
      success: true,
      message: 'Action updated successfully',
      data: result.rows[0]
    });

  } catch (err) {
    console.error('Update action error:', err);
    
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Action with this symbol already exists' });
    }
    
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Deletar ação
router.delete('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const client = await pool.connect();
    
    const query = `
      DELETE FROM actions 
      WHERE id = $1
      RETURNING id, symbol
    `;
    
    const result = await client.query(query, [id]);
    client.release();

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Action not found' });
    }

    res.json({
      success: true,
      message: 'Action deleted successfully',
      deleted: {
        id: result.rows[0].id,
        symbol: result.rows[0].symbol
      }
    });

  } catch (err) {
    console.error('Delete action error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Adicionar ação de exemplo (para teste)
router.post('/example', async (req, res) => {
  const examples = [
    { symbol: 'VALE3', name: 'Vale S.A.', price: 68.50, quantity: 1000 },
    { symbol: 'PETR4', name: 'Petrobrás', price: 32.75, quantity: 2000 },
    { symbol: 'ITUB4', name: 'Itaú Unibanco', price: 29.80, quantity: 1500 },
    { symbol: 'BBDC4', name: 'Bradesco', price: 13.45, quantity: 3000 },
    { symbol: 'ABEV3', name: 'Ambev S.A.', price: 12.90, quantity: 2500 }
  ];

  try {
    const inserted = [];

    for (const action of examples) {
      const query = `
        INSERT INTO actions (symbol, name, price, quantity) 
        VALUES ($1, $2, $3, $4) 
        ON CONFLICT (symbol) DO NOTHING
      `;
      
      await pool.query(query, [
        action.symbol,
        action.name,
        action.price.toFixed(2),
        action.quantity
      ]);
      inserted.push(action.symbol);
    }

    res.json({
      success: true,
      message: `Created/Updated ${inserted.length} example actions`,
      symbols: inserted
    });

  } catch (err) {
    console.error('Add example actions error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;