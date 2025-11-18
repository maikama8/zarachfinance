const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Device = require('../models/Device');
const Payment = require('../models/Payment');
const { authenticateApiKey } = require('../middleware/auth');

// Get payment status
router.get('/status/:deviceId', authenticateApiKey, async (req, res) => {
  try {
    const device = await Device.findOne({ deviceId: req.params.deviceId });
    
    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    const status = device.updatePaymentStatus();
    await device.save();

    const lastPayment = device.paymentHistory
      .filter(p => p.status === 'completed')
      .sort((a, b) => b.date - a.date)[0];

    res.json({
      isPaymentOverdue: status.isPaymentOverdue,
      isFullyPaid: status.isFullyPaid,
      lastPaymentDate: lastPayment ? lastPayment.date.getTime() : 0,
      nextPaymentDate: device.paymentSchedule
        .filter(s => s.status === 'pending')
        .sort((a, b) => a.dueDate - b.dueDate)[0]?.dueDate.getTime() || 0,
      remainingBalance: status.remainingBalance,
      overdueAmount: device.paymentSchedule
        .filter(s => s.status === 'overdue')
        .reduce((sum, s) => sum + s.amount, 0)
    });
  } catch (error) {
    console.error('Error getting payment status:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Process payment
router.post('/process', 
  authenticateApiKey,
  [
    body('deviceId').notEmpty(),
    body('amount').isFloat({ min: 0.01 }),
    body('paymentMethod').notEmpty(),
    body('transactionReference').notEmpty()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { deviceId, amount, paymentMethod, transactionReference } = req.body;

      // Check if transaction reference already exists
      const existingPayment = await Payment.findOne({ transactionReference });
      if (existingPayment) {
        return res.status(400).json({ 
          success: false,
          message: 'Transaction reference already used' 
        });
      }

      const device = await Device.findOne({ deviceId });
      if (!device) {
        return res.status(404).json({ 
          success: false,
          message: 'Device not found' 
        });
      }

      // Create payment record
      const payment = new Payment({
        deviceId,
        amount,
        paymentMethod,
        transactionReference,
        status: 'pending'
      });

      // Process payment (in production, integrate with payment gateway)
      // For now, simulate successful payment
      payment.status = 'completed';
      payment.transactionId = `TXN${Date.now()}${Math.random().toString(36).substr(2, 9)}`;
      payment.processedAt = new Date();
      await payment.save();

      // Update device payment
      device.paidAmount += amount;
      device.remainingBalance = device.totalAmount - device.paidAmount;
      
      // Update payment schedule
      let remainingAmount = amount;
      for (let scheduleItem of device.paymentSchedule) {
        if (scheduleItem.status === 'pending' || scheduleItem.status === 'overdue') {
          if (remainingAmount >= scheduleItem.amount) {
            scheduleItem.status = 'paid';
            remainingAmount -= scheduleItem.amount;
          } else {
            break;
          }
        }
      }

      // Add to payment history
      device.paymentHistory.push({
        date: new Date(),
        amount,
        status: 'completed',
        transactionId: payment.transactionId,
        paymentMethod
      });

      device.isFullyPaid = device.remainingBalance <= 0;
      if (!device.isFullyPaid && !device.paymentSchedule.some(s => s.status === 'overdue')) {
        device.isLocked = false;
      }

      await device.save();

      res.json({
        success: true,
        transactionId: payment.transactionId,
        message: 'Payment processed successfully',
        newBalance: device.remainingBalance
      });
    } catch (error) {
      console.error('Error processing payment:', error);
      res.status(500).json({ 
        success: false,
        message: 'Payment processing failed' 
      });
    }
  }
);

// Get payment history
router.get('/history/:deviceId', authenticateApiKey, async (req, res) => {
  try {
    const device = await Device.findOne({ deviceId: req.params.deviceId });
    
    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    const history = device.paymentHistory
      .sort((a, b) => b.date - a.date)
      .map(p => ({
        date: p.date.getTime(),
        amount: p.amount,
        status: p.status,
        transactionId: p.transactionId
      }));

    res.json(history);
  } catch (error) {
    console.error('Error getting payment history:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get payment schedule
router.get('/schedule/:deviceId', authenticateApiKey, async (req, res) => {
  try {
    const device = await Device.findOne({ deviceId: req.params.deviceId });
    
    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }

    const schedule = device.paymentSchedule.map(s => ({
      dueDate: s.dueDate.getTime(),
      amount: s.amount,
      status: s.status
    }));

    res.json({
      schedule,
      totalAmount: device.totalAmount,
      paidAmount: device.paidAmount,
      remainingAmount: device.remainingBalance
    });
  } catch (error) {
    console.error('Error getting payment schedule:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;

