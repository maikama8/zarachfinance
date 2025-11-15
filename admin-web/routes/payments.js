const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { query } = require('../config/database');

router.use(requireAuth);

// List all payments
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = 50;
    const offset = (page - 1) * limit;
    const status = req.query.status || 'all';
    
    let query = `
      SELECT t.*, d.device_model, c.name as customer_name, c.phone
      FROM transactions t
      JOIN devices d ON t.device_id = d.device_id
      JOIN customers c ON d.customer_id = c.customer_id
    `;
    
    const params = [];
    if (status !== 'all') {
      query += ' WHERE t.status = $1';
      params.push(status);
    }
    
    query += ` ORDER BY t.timestamp DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);
    
    const result = await pool.query(query, params);
    
    const countQuery = status !== 'all' 
      ? 'SELECT COUNT(*) FROM transactions WHERE status = $1'
      : 'SELECT COUNT(*) FROM transactions';
    const countParams = status !== 'all' ? [status] : [];
    const countResult = await pool.query(countQuery, countParams);
    const totalPayments = parseInt(countResult.rows[0].count);
    const totalPages = Math.ceil(totalPayments / limit);
    
    res.render('payments/list', {
      title: 'Payments',
      payments: result.rows,
      currentPage: page,
      totalPages,
      totalPayments,
      filterStatus: status
    });
  } catch (error) {
    console.error('Error fetching payments:', error);
    res.status(500).render('error', {
      title: 'Error',
      message: 'Failed to load payments',
      error: {}
    });
  }
});

// View payment details
router.get('/:transactionId', async (req, res) => {
  try {
    const { transactionId } = req.params;
    
    const result = await pool.query(
      `SELECT t.*, d.*, c.name as customer_name, c.phone, c.email
       FROM transactions t
       JOIN devices d ON t.device_id = d.device_id
       JOIN customers c ON d.customer_id = c.customer_id
       WHERE t.transaction_id = $1`,
      [transactionId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).render('404', { title: 'Payment Not Found' });
    }
    
    res.render('payments/detail', {
      title: 'Payment Details',
      payment: result.rows[0]
    });
  } catch (error) {
    console.error('Error fetching payment details:', error);
    res.status(500).render('error', {
      title: 'Error',
      message: 'Failed to load payment details',
      error: {}
    });
  }
});

module.exports = router;
