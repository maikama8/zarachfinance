const express = require('express');
const router = express.Router();
const { query } = require('../config/database');
const { requireAuth } = require('../middleware/auth');
const axios = require('axios');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

// List all devices
router.get('/', async (req, res) => {
  try {
    const { status, search } = req.query;
    
    let query = `
      SELECT d.*, c.name as customer_name, c.phone,
             ps.total_amount, ps.paid_amount, ps.remaining_amount
      FROM devices d
      LEFT JOIN customers c ON d.customer_id = c.customer_id
      LEFT JOIN payment_schedules ps ON d.device_id = ps.device_id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (status) {
      params.push(status);
      query += ` AND d.status = $${params.length}`;
    }
    
    if (search) {
      params.push(`%${search}%`);
      query += ` AND (d.imei LIKE $${params.length} OR c.name LIKE $${params.length} OR c.phone LIKE $${params.length})`;
    }
    
    query += ' ORDER BY d.registration_date DESC';
    
    const result = await pool.query(query, params);
    
    res.render('devices/list', {
      title: 'Devices',
      devices: result.rows,
      filters: { status, search }
    });
  } catch (error) {
    console.error('List devices error:', error);
    res.status(500).render('error', { title: 'Error', message: 'Failed to load devices' });
  }
});

// Device detail
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const device = await pool.query(`
      SELECT d.*, c.name as customer_name, c.phone, c.email,
             ps.total_amount, ps.paid_amount, ps.remaining_amount, ps.frequency
      FROM devices d
      LEFT JOIN customers c ON d.customer_id = c.customer_id
      LEFT JOIN payment_schedules ps ON d.device_id = ps.device_id
      WHERE d.device_id = $1
    `, [id]);
    
    if (device.rows.length === 0) {
      return res.status(404).render('404', { title: 'Device Not Found' });
    }
    
    // Get payment history
    const payments = await pool.query(`
      SELECT * FROM transactions
      WHERE device_id = $1
      ORDER BY timestamp DESC
      LIMIT 20
    `, [id]);
    
    // Get location history
    const locations = await pool.query(`
      SELECT * FROM device_locations
      WHERE device_id = $1
      ORDER BY timestamp DESC
      LIMIT 10
    `, [id]);
    
    res.render('devices/detail', {
      title: 'Device Details',
      device: device.rows[0],
      payments: payments.rows,
      locations: locations.rows
    });
  } catch (error) {
    console.error('Device detail error:', error);
    res.status(500).render('error', { title: 'Error', message: 'Failed to load device details' });
  }
});

// Lock device
router.post('/:id/lock', async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    
    await pool.query(
      'UPDATE devices SET status = $1 WHERE device_id = $2',
      ['LOCKED', id]
    );
    
    // Log action
    await pool.query(
      `INSERT INTO audit_logs (event, device_id, user_id, data)
       VALUES ($1, $2, $3, $4)`,
      ['DEVICE_LOCKED', id, req.session.user.id, JSON.stringify({ reason })]
    );
    
    res.json({ success: true, message: 'Device locked successfully' });
  } catch (error) {
    console.error('Lock device error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Unlock device
router.post('/:id/unlock', async (req, res) => {
  try {
    const { id } = req.params;
    
    await pool.query(
      'UPDATE devices SET status = $1 WHERE device_id = $2',
      ['ACTIVE', id]
    );
    
    // Log action
    await pool.query(
      `INSERT INTO audit_logs (event, device_id, user_id, data)
       VALUES ($1, $2, $3, $4)`,
      ['DEVICE_UNLOCKED', id, req.session.user.id, JSON.stringify({})]
    );
    
    res.json({ success: true, message: 'Device unlocked successfully' });
  } catch (error) {
    console.error('Unlock device error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Generate release code
router.post('/:id/generate-release-code', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Check if device is paid off
    const device = await pool.query(`
      SELECT d.*, ps.remaining_amount
      FROM devices d
      LEFT JOIN payment_schedules ps ON d.device_id = ps.device_id
      WHERE d.device_id = $1
    `, [id]);
    
    if (device.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Device not found' });
    }
    
    if (device.rows[0].remaining_amount > 0) {
      return res.status(400).json({ success: false, error: 'Payment not completed' });
    }
    
    // Generate release code
    const code = generateReleaseCode();
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + 7);
    
    await pool.query(`
      INSERT INTO release_codes (code, device_id, customer_id, expiry_date, generated_by)
      VALUES ($1, $2, $3, $4, $5)
    `, [code, id, device.rows[0].customer_id, expiryDate, req.session.user.username]);
    
    // Update device status
    await pool.query(
      'UPDATE devices SET release_eligible = TRUE, release_code_generated_date = NOW() WHERE device_id = $1',
      [id]
    );
    
    res.json({ success: true, code, expiryDate });
  } catch (error) {
    console.error('Generate release code error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Helper function to generate release code
function generateReleaseCode() {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // Exclude similar characters
  let code = '';
  for (let i = 0; i < 12; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
    if ((i + 1) % 4 === 0 && i < 11) code += '-';
  }
  return code;
}

module.exports = router;
