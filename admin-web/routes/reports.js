const express = require('express');
const router = express.Router();
const { requireAuth } = require('../middleware/auth');
const { query } = require('../config/database');

router.use(requireAuth);

// Reports dashboard
router.get('/', async (req, res) => {
  try {
    res.render('reports/index', {
      title: 'Reports'
    });
  } catch (error) {
    console.error('Error loading reports:', error);
    res.status(500).render('error', {
      title: 'Error',
      message: 'Failed to load reports',
      error: {}
    });
  }
});

// Payment report
router.get('/payments', async (req, res) => {
  try {
    const startDate = req.query.start_date || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const endDate = req.query.end_date || new Date().toISOString().split('T')[0];
    
    const result = await pool.query(
      `SELECT 
        DATE(timestamp) as date,
        COUNT(*) as transaction_count,
        SUM(CASE WHEN status = 'SUCCESS' THEN amount ELSE 0 END) as total_amount,
        COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) as successful_count,
        COUNT(CASE WHEN status = 'FAILED' THEN 1 END) as failed_count
       FROM transactions
       WHERE timestamp >= $1 AND timestamp <= $2
       GROUP BY DATE(timestamp)
       ORDER BY date DESC`,
      [startDate, endDate + ' 23:59:59']
    );
    
    res.render('reports/payments', {
      title: 'Payment Report',
      data: result.rows,
      startDate,
      endDate
    });
  } catch (error) {
    console.error('Error generating payment report:', error);
    res.status(500).render('error', {
      title: 'Error',
      message: 'Failed to generate report',
      error: {}
    });
  }
});

// Device report
router.get('/devices', async (req, res) => {
  try {
    const stats = await pool.query(`
      SELECT 
        status,
        COUNT(*) as count
      FROM devices
      GROUP BY status
    `);
    
    const byManufacturer = await pool.query(`
      SELECT 
        manufacturer,
        COUNT(*) as count
      FROM devices
      GROUP BY manufacturer
      ORDER BY count DESC
      LIMIT 10
    `);
    
    res.render('reports/devices', {
      title: 'Device Report',
      statusStats: stats.rows,
      manufacturerStats: byManufacturer.rows
    });
  } catch (error) {
    console.error('Error generating device report:', error);
    res.status(500).render('error', {
      title: 'Error',
      message: 'Failed to generate report',
      error: {}
    });
  }
});

module.exports = router;
