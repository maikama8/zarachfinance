const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Device = require('../models/Device');
const { authenticate } = require('../middleware/auth');

// Get policy for device
router.get('/policy/:deviceId', async (req, res) => {
  try {
    const device = await Device.findOne({ deviceId: req.params.deviceId });
    
    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    res.json({
      lockPolicy: device.policy,
      paymentSchedule: device.paymentSchedule.map(s => ({
        dueDate: s.dueDate.getTime(),
        amount: s.amount,
        status: s.status
      })),
      customMessage: device.customMessage
    });
  } catch (error) {
    console.error('Error getting policy:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Unlock device manually
router.post('/unlock',
  authenticate,
  [
    body('deviceId').notEmpty(),
    body('adminToken').notEmpty(),
    body('reason').optional()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { deviceId, reason } = req.body;

      const device = await Device.findOne({ deviceId });
      if (!device) {
        return res.status(404).json({ 
          success: false,
          message: 'Device not found' 
        });
      }

      device.isLocked = false;
      await device.save();

      res.json({
        success: true,
        message: 'Device unlocked successfully'
      });
    } catch (error) {
      console.error('Error unlocking device:', error);
      res.status(500).json({ 
        success: false,
        message: 'Failed to unlock device' 
      });
    }
  }
);

// Send custom message to device
router.post('/message',
  authenticate,
  [
    body('deviceId').notEmpty(),
    body('message').notEmpty()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { deviceId, message } = req.body;

      const device = await Device.findOne({ deviceId });
      if (!device) {
        return res.status(404).json({ message: 'Device not found' });
      }

      device.customMessage = message;
      await device.save();

      res.json({ success: true, message: 'Message sent to device' });
    } catch (error) {
      console.error('Error sending message:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// Get all devices (admin only)
router.get('/devices', authenticate, async (req, res) => {
  try {
    const devices = await Device.find()
      .select('-locations -paymentHistory')
      .sort({ createdAt: -1 });

    res.json(devices);
  } catch (error) {
    console.error('Error getting devices:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get device details
router.get('/devices/:deviceId', authenticate, async (req, res) => {
  try {
    const device = await Device.findOne({ deviceId: req.params.deviceId });
    
    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    res.json(device);
  } catch (error) {
    console.error('Error getting device details:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create new device
router.post('/devices',
  authenticate,
  [
    body('deviceId').notEmpty(),
    body('customerName').notEmpty(),
    body('customerPhone').notEmpty(),
    body('storeContact').notEmpty(),
    body('storePhone').notEmpty(),
    body('totalAmount').isFloat({ min: 0.01 }),
    body('paymentSchedule').isArray().notEmpty()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const {
        deviceId,
        customerName,
        customerPhone,
        storeContact,
        storePhone,
        totalAmount,
        paymentSchedule
      } = req.body;

      // Generate release code
      const crypto = require('crypto');
      const releaseCode = crypto.randomBytes(8).toString('hex').toUpperCase();

      const device = new Device({
        deviceId,
        customerName,
        customerPhone,
        storeContact,
        storePhone,
        totalAmount,
        remainingBalance: totalAmount,
        paymentSchedule: paymentSchedule.map(s => ({
          dueDate: new Date(s.dueDate),
          amount: s.amount,
          status: 'pending'
        })),
        releaseCode
      });

      await device.save();

      res.status(201).json({
        success: true,
        device,
        releaseCode
      });
    } catch (error) {
      if (error.code === 11000) {
        return res.status(400).json({ message: 'Device ID already exists' });
      }
      console.error('Error creating device:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// Update device policy
router.put('/devices/:deviceId/policy',
  authenticate,
  [
    body('lockOnOverdue').optional().isBoolean(),
    body('lockDelayHours').optional().isInt({ min: 0 }),
    body('allowEmergencyCalls').optional().isBoolean()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const device = await Device.findOne({ deviceId: req.params.deviceId });
      if (!device) {
        return res.status(404).json({ message: 'Device not found' });
      }

      if (req.body.lockOnOverdue !== undefined) {
        device.policy.lockOnOverdue = req.body.lockOnOverdue;
      }
      if (req.body.lockDelayHours !== undefined) {
        device.policy.lockDelayHours = req.body.lockDelayHours;
      }
      if (req.body.allowEmergencyCalls !== undefined) {
        device.policy.allowEmergencyCalls = req.body.allowEmergencyCalls;
      }

      await device.save();

      res.json({ success: true, policy: device.policy });
    } catch (error) {
      console.error('Error updating policy:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

module.exports = router;

