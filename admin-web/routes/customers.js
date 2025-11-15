const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { query } = require('../config/database');

// All routes require authentication
router.use(requireAuth);

// List all customers
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = 20;
    const offset = (page - 1) * limit;
    
    const result = await pool.query(
      `SELECT c.*, COUNT(d.device_id) as device_count
       FROM customers c
       LEFT JOIN devices d ON c.customer_id = d.customer_id
       GROUP BY c.customer_id
       ORDER BY c.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    
    const countResult = await pool.query('SELECT COUNT(*) FROM customers');
    const totalCustomers = parseInt(countResult.rows[0].count);
    const totalPages = Math.ceil(totalCustomers / limit);
    
    res.render('customers/list', {
      title: 'Customers',
      customers: result.rows,
      currentPage: page,
      totalPages,
      totalCustomers
    });
  } catch (error) {
    console.error('Error fetching customers:', error);
    res.status(500).render('error', {
      title: 'Error',
      message: 'Failed to load customers',
      error: {}
    });
  }
});

// View customer details
router.get('/:customerId', async (req, res) => {
  try {
    const { customerId } = req.params;
    
    const customerResult = await pool.query(
      'SELECT * FROM customers WHERE customer_id = $1',
      [customerId]
    );
    
    if (customerResult.rows.length === 0) {
      return res.status(404).render('404', { title: 'Customer Not Found' });
    }
    
    const devicesResult = await pool.query(
      'SELECT * FROM devices WHERE customer_id = $1 ORDER BY registration_date DESC',
      [customerId]
    );
    
    const paymentsResult = await pool.query(
      `SELECT t.* FROM transactions t
       JOIN devices d ON t.device_id = d.device_id
       WHERE d.customer_id = $1
       ORDER BY t.timestamp DESC
       LIMIT 10`,
      [customerId]
    );
    
    res.render('customers/detail', {
      title: 'Customer Details',
      customer: customerResult.rows[0],
      devices: devicesResult.rows,
      recentPayments: paymentsResult.rows
    });
  } catch (error) {
    console.error('Error fetching customer details:', error);
    res.status(500).render('error', {
      title: 'Error',
      message: 'Failed to load customer details',
      error: {}
    });
  }
});

module.exports = router;
