const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Device = require('../models/Device');
const Payment = require('../models/Payment');
const PaymentGateway = require('../models/PaymentGateway');
const AuditLog = require('../models/AuditLog');
const { authenticate } = require('../middleware/auth');

// Get all devices (admin only)
router.get('/devices', authenticate, async (req, res) => {
  try {
    const { status, search, page = 1, limit = 50 } = req.query;
    const query = {};
    
    if (status) {
      if (status === 'locked') query.isLocked = true;
      else if (status === 'active') query.isLocked = false;
      else if (status === 'offline') {
        const dayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
        query.lastSeen = { $lt: dayAgo };
      }
    }
    
    if (search) {
      query.$or = [
        { deviceId: { $regex: search, $options: 'i' } },
        { customerName: { $regex: search, $options: 'i' } },
        { customerPhone: { $regex: search, $options: 'i' } }
      ];
    }

    const devices = await Device.find(query)
      .select('-locations -paymentHistory')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Device.countDocuments(query);

    res.json({
      devices,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      total
    });
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
    body('totalAmount').isFloat({ min: 0 }),
    body('paymentFrequency').isIn(['daily', 'weekly', 'monthly']),
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
        imei,
        model,
        manufacturer,
        purchaseDate,
        customerName,
        customerPhone,
        storeContact,
        storePhone,
        totalAmount,
        paymentFrequency,
        paymentSchedule,
        financingPlanId
      } = req.body;

      // Generate release code
      const crypto = require('crypto');
      const releaseCode = crypto.randomBytes(8).toString('hex').toUpperCase();

      const device = new Device({
        deviceId,
        imei,
        model,
        manufacturer,
        purchaseDate: purchaseDate ? new Date(purchaseDate) : undefined,
        customerName,
        customerPhone,
        storeContact,
        storePhone,
        totalAmount,
        remainingBalance: totalAmount,
        paymentFrequency: paymentFrequency || 'daily',
        paymentSchedule: paymentSchedule.map(s => ({
          dueDate: new Date(s.dueDate),
          amount: s.amount,
          status: 'pending'
        })),
        financingPlanId,
        releaseCode
      });

      await device.save();

      // Audit log
      await AuditLog.create({
        action: 'create_device',
        userId: req.user.id,
        userEmail: req.user.email,
        userRole: req.user.role,
        resourceType: 'device',
        resourceId: device._id.toString(),
        ipAddress: req.ip,
        userAgent: req.get('user-agent')
      });

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

// Update device
router.put('/devices/:deviceId', authenticate, async (req, res) => {
  try {
    const device = await Device.findOne({ deviceId: req.params.deviceId });
    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    const updates = req.body;
    if (updates.paymentSchedule) {
      updates.paymentSchedule = updates.paymentSchedule.map(s => ({
        dueDate: new Date(s.dueDate),
        amount: s.amount,
        status: s.status || 'pending'
      }));
    }

    Object.assign(device, updates);
    await device.save();

    // Audit log
    await AuditLog.create({
      action: 'update_device',
      userId: req.user.id,
      userEmail: req.user.email,
      userRole: req.user.role,
      resourceType: 'device',
      resourceId: device._id.toString(),
      changes: updates,
      ipAddress: req.ip,
      userAgent: req.get('user-agent')
    });

    res.json(device);
  } catch (error) {
    console.error('Error updating device:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Bulk device operations
router.post('/devices/bulk', authenticate, async (req, res) => {
  try {
    const { operation, deviceIds, data } = req.body;
    
    if (!['lock', 'unlock', 'update', 'delete'].includes(operation)) {
      return res.status(400).json({ message: 'Invalid operation' });
    }

    const devices = await Device.find({ deviceId: { $in: deviceIds } });
    
    for (const device of devices) {
      switch (operation) {
        case 'lock':
          device.isLocked = true;
          break;
        case 'unlock':
          device.isLocked = false;
          break;
        case 'update':
          Object.assign(device, data);
          break;
        case 'delete':
          await Device.findByIdAndDelete(device._id);
          continue;
      }
      await device.save();
      
      // Emit real-time update
      const socketUtils = require('../utils/socket');
      socketUtils.emitDeviceUpdate(device.deviceId, {
        type: 'bulk_operation',
        operation,
        isLocked: device.isLocked
      });
    }

    // Audit log
    await AuditLog.create({
      action: `bulk_${operation}_devices`,
      userId: req.user.id,
      userEmail: req.user.email,
      userRole: req.user.role,
      resourceType: 'device',
      resourceId: deviceIds.join(','),
      ipAddress: req.ip,
      userAgent: req.get('user-agent')
    });

    res.json({ success: true, affected: devices.length });
  } catch (error) {
    console.error('Error in bulk operation:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// CSV upload for bulk device registration
router.post('/devices/upload-csv', authenticate, async (req, res) => {
  try {
    // TODO: Implement CSV parsing and bulk device creation
    // For now, return a placeholder
    res.json({ message: 'CSV upload feature - to be implemented' });
  } catch (error) {
    console.error('Error uploading CSV:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Payment Gateway Configuration Routes
router.get('/payment-gateway', authenticate, async (req, res) => {
  try {
    const gateways = await PaymentGateway.find();
    res.json(gateways);
  } catch (error) {
    console.error('Error getting payment gateways:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.put('/payment-gateway/:gateway',
  authenticate,
  [
    body('publicKey').notEmpty(),
    body('secretKey').notEmpty()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { publicKey, secretKey, webhookSecret } = req.body;
      
      const gateway = await PaymentGateway.findOneAndUpdate(
        { gateway: req.params.gateway },
        {
          publicKey,
          secretKey,
          webhookSecret,
          updatedAt: Date.now()
        },
        { upsert: true, new: true }
      );

      res.json(gateway);
    } catch (error) {
      console.error('Error updating payment gateway:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

router.post('/payment-gateway/:gateway/activate', authenticate, async (req, res) => {
  try {
    // Deactivate all gateways first
    await PaymentGateway.updateMany({}, { isActive: false });
    
    // Activate the selected gateway
    const gateway = await PaymentGateway.findOneAndUpdate(
      { gateway: req.params.gateway },
      { isActive: true },
      { new: true }
    );

    if (!gateway) {
      return res.status(404).json({ message: 'Gateway not found' });
    }

    res.json({ success: true, gateway });
  } catch (error) {
    console.error('Error activating gateway:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get audit logs
router.get('/audit-logs', authenticate, async (req, res) => {
  try {
    const { limit = 50, page = 1, action, resourceType } = req.query;
    const query = {};
    
    if (action) query.action = action;
    if (resourceType) query.resourceType = resourceType;

    const AuditLog = require('../models/AuditLog');
    const logs = await AuditLog.find(query)
      .populate('userId', 'name email role')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ timestamp: -1 });

    const total = await AuditLog.countDocuments(query);

    res.json({
      logs,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      total
    });
  } catch (error) {
    console.error('Error getting audit logs:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// User management routes
router.get('/users', authenticate, async (req, res) => {
  try {
    // Only admins can manage users
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const Admin = require('../models/Admin');
    const users = await Admin.find().select('-password');
    res.json(users);
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.post('/users',
  authenticate,
  [
    body('email').isEmail(),
    body('name').notEmpty(),
    body('password').isLength({ min: 6 }),
    body('role').isIn(['admin', 'manager', 'agent'])
  ],
  async (req, res) => {
    try {
      if (req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Access denied' });
      }

      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const Admin = require('../models/Admin');
      const { email, name, password, role, permissions } = req.body;

      const admin = new Admin({
        email,
        name,
        password,
        role,
        permissions: permissions || {}
      });

      await admin.save();

      res.status(201).json({ success: true, user: admin });
    } catch (error) {
      if (error.code === 11000) {
        return res.status(400).json({ message: 'Email already exists' });
      }
      console.error('Error creating user:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

module.exports = router;
