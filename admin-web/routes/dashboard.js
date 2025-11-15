const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { requireAuth } = require('../middleware/auth');
const { requireAuth } = require('../middleware/auth');

// All dashboard routes require authentication
router.use(requireAuth);

// Dashboard home
router.get('/', requireAuth, async (req, res) => {
  try {
    // Get statistics
    const stats = await pool.query(`
      SELECT 
        (SELECT COUNT(*) FROM devices WHERE status = 'ACTIVE') as active_devices,
        (SELECT COUNT(*) FROM devices WHERE status = 'LOCKED') as locked_devices,
        (SELECT COUNT(*) FROM devices WHERE status = 'PAID_OFF') as paid_off_devices,
        (SELECT COUNT(*) FROM customers) as total_customers,
        (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE status = 'SUCCESS' AND DATE(timestamp) = CURRENT_DATE) as today_payments,
        (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE status = 'SUCCESS' AND DATE(timestamp) >= DATE_TRUNC('month', CURRENT_DATE)) as month_payments,
        (SELECT COUNT(*) FROM transactions WHERE status = 'PENDING') as pending_payments,
        (SELECT COUNT(*) FROM installments WHERE status = 'OVERDUE') as overdue_payments
    `);

    // Get recent devices
    const recentDevices = await pool.query(`
      SELECT d.*, c.name as customer_name
      FROM devices d
      LEFT JOIN customers c ON d.customer_id = c.customer_id
      ORDER BY d.registration_date DESC
      LIMIT 10
    `);

    // Get recent payments
    const recentPayments = await pool.query(`
      SELECT t.*, d.device_model, c.name as customer_name
      FROM transactions t
      LEFT JOIN devices d ON t.device_id = d.device_id
      LEFT JOIN customers c ON d.customer_id = c.customer_id
      ORDER BY t.timestamp DESC
      LIMIT 10
    `);

    res.render('dashboard', {
      title: 'Dashboard',
      stats: stats.rows[0],
      recentDevices: recentDevices.rows,
      recentPayments: recentPayments.rows
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).render('error', {
      title: 'Error',
      message: 'Failed to load dashboard'
    });
  }
});

module.exports = router;
