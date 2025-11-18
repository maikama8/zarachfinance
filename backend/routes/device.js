const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Device = require('../models/Device');
const { authenticateApiKey } = require('../middleware/auth');

// Report device location
router.post('/location',
  authenticateApiKey,
  [
    body('deviceId').notEmpty(),
    body('latitude').isFloat(),
    body('longitude').isFloat(),
    body('timestamp').isNumeric(),
    body('accuracy').optional().isFloat()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { deviceId, latitude, longitude, timestamp, accuracy } = req.body;

      const device = await Device.findOne({ deviceId });
      if (!device) {
        return res.status(404).json({ message: 'Device not found' });
      }

      device.locations.push({
        latitude,
        longitude,
        timestamp: new Date(timestamp),
        accuracy
      });

      // Keep only last 100 locations
      if (device.locations.length > 100) {
        device.locations = device.locations.slice(-100);
      }

      await device.save();

      res.json({ success: true, message: 'Location recorded' });
    } catch (error) {
      console.error('Error reporting location:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// Get device status
router.get('/status/:deviceId', authenticateApiKey, async (req, res) => {
  try {
    const device = await Device.findOne({ deviceId: req.params.deviceId });
    
    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    device.lastSeen = new Date();
    await device.save();

    res.json({
      deviceId: device.deviceId,
      isLocked: device.isLocked,
      lastSeen: device.lastSeen.getTime(),
      appVersion: device.appVersion || 'unknown'
    });
  } catch (error) {
    console.error('Error getting device status:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Report device status
router.post('/report',
  authenticateApiKey,
  [
    body('deviceId').notEmpty(),
    body('isLocked').isBoolean(),
    body('appVersion').notEmpty()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { deviceId, isLocked, appVersion, batteryLevel, isCharging } = req.body;

      const device = await Device.findOne({ deviceId });
      if (!device) {
        return res.status(404).json({ message: 'Device not found' });
      }

      device.isLocked = isLocked;
      device.appVersion = appVersion;
      device.lastSeen = new Date();
      await device.save();

      res.json({ success: true });
    } catch (error) {
      console.error('Error reporting device status:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

module.exports = router;

