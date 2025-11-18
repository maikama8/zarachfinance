const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Customer = require('../models/Customer');
const Device = require('../models/Device');
const SupportTicket = require('../models/SupportTicket');
const AuditLog = require('../models/AuditLog');
const { authenticate } = require('../middleware/auth');

// Get all customers
router.get('/', authenticate, async (req, res) => {
  try {
    const { search, page = 1, limit = 50 } = req.query;
    const query = {};
    
    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
        { customerId: { $regex: search, $options: 'i' } }
      ];
    }

    const customers = await Customer.find(query)
      .populate('assignedDevices')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });

    const total = await Customer.countDocuments(query);

    res.json({
      customers,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      total
    });
  } catch (error) {
    console.error('Error getting customers:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get customer by ID
router.get('/:id', authenticate, async (req, res) => {
  try {
    const customer = await Customer.findById(req.params.id)
      .populate('assignedDevices')
      .populate('supportTickets');
    
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    res.json(customer);
  } catch (error) {
    console.error('Error getting customer:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create new customer
router.post('/',
  authenticate,
  [
    body('firstName').notEmpty(),
    body('lastName').notEmpty(),
    body('email').isEmail(),
    body('phone').notEmpty()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { firstName, lastName, email, phone, address, kycData } = req.body;
      
      // Generate customer ID
      const customerId = `CUST${Date.now()}${Math.random().toString(36).substr(2, 5).toUpperCase()}`;

      const customer = new Customer({
        customerId,
        firstName,
        lastName,
        email,
        phone,
        address,
        kycData
      });

      await customer.save();

      // Audit log
      await AuditLog.create({
        action: 'create_customer',
        userId: req.user.id,
        userEmail: req.user.email,
        userRole: req.user.role,
        resourceType: 'customer',
        resourceId: customer._id.toString(),
        ipAddress: req.ip,
        userAgent: req.get('user-agent')
      });

      res.status(201).json(customer);
    } catch (error) {
      console.error('Error creating customer:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// Update customer
router.put('/:id', authenticate, async (req, res) => {
  try {
    const customer = await Customer.findById(req.params.id);
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    const updates = req.body;
    Object.assign(customer, updates);
    await customer.save();

    // Audit log
    await AuditLog.create({
      action: 'update_customer',
      userId: req.user.id,
      userEmail: req.user.email,
      userRole: req.user.role,
      resourceType: 'customer',
      resourceId: customer._id.toString(),
      changes: updates,
      ipAddress: req.ip,
      userAgent: req.get('user-agent')
    });

    res.json(customer);
  } catch (error) {
    console.error('Error updating customer:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Assign device to customer
router.post('/:id/devices', authenticate, async (req, res) => {
  try {
    const { deviceId } = req.body;
    const customer = await Customer.findById(req.params.id);
    const device = await Device.findById(deviceId);

    if (!customer || !device) {
      return res.status(404).json({ message: 'Customer or device not found' });
    }

    if (!customer.assignedDevices.includes(deviceId)) {
      customer.assignedDevices.push(deviceId);
      await customer.save();
    }

    device.customerId = customer._id;
    await device.save();

    res.json({ success: true, customer, device });
  } catch (error) {
    console.error('Error assigning device:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get customer payment history
router.get('/:id/payments', authenticate, async (req, res) => {
  try {
    const customer = await Customer.findById(req.params.id);
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    // Get payments from all assigned devices
    const devices = await Device.find({ customerId: customer._id });
    const payments = devices.flatMap(device => 
      device.paymentHistory.map(payment => ({
        ...payment.toObject(),
        deviceId: device.deviceId,
        deviceModel: device.model
      }))
    ).sort((a, b) => b.date - a.date);

    res.json(payments);
  } catch (error) {
    console.error('Error getting customer payments:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Send communication to customer
router.post('/:id/communicate', authenticate, async (req, res) => {
  try {
    const { type, message } = req.body;
    const customer = await Customer.findById(req.params.id);

    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    customer.communicationHistory.push({
      type,
      message,
      sentAt: new Date()
    });

    await customer.save();

    // TODO: Implement actual SMS/Email sending
    // For now, just log it

    res.json({ success: true, message: 'Communication sent' });
  } catch (error) {
    console.error('Error sending communication:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;

