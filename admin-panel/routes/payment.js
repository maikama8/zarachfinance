const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Device = require('../models/Device');
const Payment = require('../models/Payment');
const PaymentGateway = require('../models/PaymentGateway');
const paymentGatewayService = require('../services/paymentGateway');
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

    const nextPayment = device.paymentSchedule
      .filter(s => s.status === 'pending')
      .sort((a, b) => a.dueDate - b.dueDate)[0];

    res.json({
      isPaymentOverdue: status.isPaymentOverdue,
      isFullyPaid: status.isFullyPaid,
      lastPaymentDate: lastPayment ? lastPayment.date.getTime() : 0,
      nextPaymentDate: nextPayment?.dueDate.getTime() || 0,
      nextPaymentAmount: nextPayment?.amount || null,
      remainingBalance: status.remainingBalance,
      overdueAmount: device.paymentSchedule
        .filter(s => s.status === 'overdue')
        .reduce((sum, s) => sum + s.amount, 0),
      paymentFrequency: device.paymentFrequency
    });
  } catch (error) {
    console.error('Error getting payment status:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Initialize payment (for gateway integration)
router.post('/initialize', 
  authenticateApiKey,
  [
    body('deviceId').notEmpty(),
    body('amount').isFloat({ min: 0.01 }),
    body('email').isEmail()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { deviceId, amount, email } = req.body;

      const device = await Device.findOne({ deviceId });
      if (!device) {
        return res.status(404).json({ 
          success: false,
          message: 'Device not found' 
        });
      }

      // Get active payment gateway
      const activeGateway = await paymentGatewayService.getActiveGateway();
      
      // Generate unique reference
      const reference = `ZAR${Date.now()}${Math.random().toString(36).substr(2, 9).toUpperCase()}`;

      // Initialize payment with gateway
      const paymentInit = await paymentGatewayService.initializePayment(
        activeGateway.gateway,
        amount,
        email,
        reference,
        {
          deviceId,
          customerName: device.customerName,
          customerPhone: device.customerPhone,
          description: `Payment for ${device.customerName} - Device ${deviceId}`
        }
      );

      // Create pending payment record
      const payment = new Payment({
        deviceId,
        amount,
        paymentMethod: activeGateway.gateway,
        transactionReference: reference,
        status: 'pending'
      });
      await payment.save();

      res.json({
        success: true,
        authorizationUrl: paymentInit.authorizationUrl,
        reference: reference,
        gateway: activeGateway.gateway
      });
    } catch (error) {
      console.error('Error initializing payment:', error);
      res.status(500).json({ 
        success: false,
        message: error.message || 'Payment initialization failed' 
      });
    }
  }
);

// Verify payment
router.post('/verify', 
  authenticateApiKey,
  [
    body('reference').notEmpty(),
    body('deviceId').notEmpty()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { reference, deviceId } = req.body;

      const device = await Device.findOne({ deviceId });
      if (!device) {
        return res.status(404).json({ 
          success: false,
          message: 'Device not found' 
        });
      }

      const payment = await Payment.findOne({ transactionReference: reference });
      if (!payment) {
        return res.status(404).json({ 
          success: false,
          message: 'Payment not found' 
        });
      }

      // Get active gateway
      const activeGateway = await paymentGatewayService.getActiveGateway();
      
      // Verify payment with gateway
      const verification = await paymentGatewayService.verifyPayment(
        activeGateway.gateway,
        reference
      );

      if (verification.success) {
        // Update payment record
        payment.status = 'completed';
        payment.transactionId = reference;
        payment.processedAt = new Date();
        await payment.save();

        // Update device payment
        device.paidAmount += payment.amount;
        device.remainingBalance = device.totalAmount - device.paidAmount;
        
        // Update payment schedule
        let remainingAmount = payment.amount;
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
          amount: payment.amount,
          status: 'completed',
          transactionId: payment.transactionId,
          paymentMethod: payment.paymentMethod
        });

        device.isFullyPaid = device.remainingBalance <= 0;
        if (!device.isFullyPaid && !device.paymentSchedule.some(s => s.status === 'overdue')) {
          device.isLocked = false;
        }

        await device.save();

        res.json({
          success: true,
          transactionId: payment.transactionId,
          message: 'Payment verified and processed successfully',
          newBalance: device.remainingBalance
        });
      } else {
        payment.status = 'failed';
        await payment.save();

        res.json({
          success: false,
          message: verification.message || 'Payment verification failed'
        });
      }
    } catch (error) {
      console.error('Error verifying payment:', error);
      res.status(500).json({ 
        success: false,
        message: error.message || 'Payment verification failed' 
      });
    }
  }
);

// Process payment (legacy - for direct payments without gateway)
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
        status: 'completed'
      });

      payment.transactionId = transactionReference;
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

// Webhook for payment gateways
router.post('/webhook/:gateway', async (req, res) => {
  try {
    const { gateway } = req.params;
    const gatewayConfig = await PaymentGateway.findOne({ gateway, isActive: true });
    
    if (!gatewayConfig) {
      return res.status(404).json({ message: 'Gateway not found' });
    }

    // Verify webhook signature (implement based on gateway)
    // For now, process the webhook
    const reference = gateway === 'paystack' 
      ? req.body.data?.reference 
      : req.body.data?.tx_ref;

    if (!reference) {
      return res.status(400).json({ message: 'Invalid webhook data' });
    }

    const payment = await Payment.findOne({ transactionReference: reference });
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    // Verify payment
    const verification = await paymentGatewayService.verifyPayment(gateway, reference);
    
    if (verification.success && payment.status === 'pending') {
      // Process payment (same logic as verify endpoint)
      const device = await Device.findOne({ deviceId: payment.deviceId });
      if (device) {
        device.paidAmount += payment.amount;
        device.remainingBalance = device.totalAmount - device.paidAmount;
        
        let remainingAmount = payment.amount;
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

        device.paymentHistory.push({
          date: new Date(),
          amount: payment.amount,
          status: 'completed',
          transactionId: payment.transactionId,
          paymentMethod: payment.paymentMethod
        });

        device.isFullyPaid = device.remainingBalance <= 0;
        if (!device.isFullyPaid && !device.paymentSchedule.some(s => s.status === 'overdue')) {
          device.isLocked = false;
        }

        await device.save();
        
        // Emit real-time update
        const socketUtils = require('../utils/socket');
        socketUtils.emitPaymentUpdate(device.deviceId, {
          isLocked: device.isLocked,
          isFullyPaid: device.isFullyPaid,
          remainingBalance: device.remainingBalance,
          paidAmount: device.paidAmount
        });
      }

      payment.status = 'completed';
      payment.processedAt = new Date();
      await payment.save();
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ message: 'Webhook processing failed' });
  }
});

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
      remainingAmount: device.remainingBalance,
      paymentFrequency: device.paymentFrequency
    });
  } catch (error) {
    console.error('Error getting payment schedule:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
