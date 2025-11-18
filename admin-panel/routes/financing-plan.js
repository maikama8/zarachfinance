const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const FinancingPlan = require('../models/FinancingPlan');
const Device = require('../models/Device');
const { authenticate } = require('../middleware/auth');
const AuditLog = require('../models/AuditLog');

// Get all financing plans
router.get('/', authenticate, async (req, res) => {
  try {
    const { active } = req.query;
    const query = active !== undefined ? { isActive: active === 'true' } : {};
    
    const plans = await FinancingPlan.find(query).sort({ createdAt: -1 });
    res.json(plans);
  } catch (error) {
    console.error('Error getting financing plans:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get plan by ID
router.get('/:id', authenticate, async (req, res) => {
  try {
    const plan = await FinancingPlan.findById(req.params.id);
    if (!plan) {
      return res.status(404).json({ message: 'Plan not found' });
    }
    res.json(plan);
  } catch (error) {
    console.error('Error getting financing plan:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create new financing plan
router.post('/',
  authenticate,
  [
    body('name').notEmpty(),
    body('totalAmount').isFloat({ min: 0 }),
    body('paymentFrequency').isIn(['daily', 'weekly', 'monthly']),
    body('paymentAmount').isFloat({ min: 0 }),
    body('duration').isInt({ min: 1 })
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const {
        name,
        description,
        totalAmount,
        downPayment,
        paymentFrequency,
        paymentAmount,
        duration,
        interestRate,
        gracePeriod,
        lateFee,
        applicableDevices
      } = req.body;

      // Generate plan ID
      const planId = `PLAN${Date.now()}${Math.random().toString(36).substr(2, 5).toUpperCase()}`;

      const plan = new FinancingPlan({
        planId,
        name,
        description,
        totalAmount,
        downPayment: downPayment || 0,
        paymentFrequency,
        paymentAmount,
        duration,
        interestRate: interestRate || 0,
        gracePeriod: gracePeriod || 0,
        lateFee: lateFee || 0,
        applicableDevices: applicableDevices || []
      });

      await plan.save();

      // Audit log
      await AuditLog.create({
        action: 'create_financing_plan',
        userId: req.user.id,
        userEmail: req.user.email,
        userRole: req.user.role,
        resourceType: 'plan',
        resourceId: plan._id.toString(),
        ipAddress: req.ip,
        userAgent: req.get('user-agent')
      });

      res.status(201).json(plan);
    } catch (error) {
      console.error('Error creating financing plan:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// Update financing plan
router.put('/:id', authenticate, async (req, res) => {
  try {
    const plan = await FinancingPlan.findById(req.params.id);
    if (!plan) {
      return res.status(404).json({ message: 'Plan not found' });
    }

    const updates = req.body;
    Object.assign(plan, updates);
    await plan.save();

    // Audit log
    await AuditLog.create({
      action: 'update_financing_plan',
      userId: req.user.id,
      userEmail: req.user.email,
      userRole: req.user.role,
      resourceType: 'plan',
      resourceId: plan._id.toString(),
      changes: updates,
      ipAddress: req.ip,
      userAgent: req.get('user-agent')
    });

    res.json(plan);
  } catch (error) {
    console.error('Error updating financing plan:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update plan performance metrics
router.post('/:id/update-performance', authenticate, async (req, res) => {
  try {
    const plan = await FinancingPlan.findById(req.params.id);
    if (!plan) {
      return res.status(404).json({ message: 'Plan not found' });
    }

    const devices = await Device.find({ financingPlanId: plan._id });
    
    plan.performance = {
      totalAssigned: devices.length,
      activeDevices: devices.filter(d => !d.isLocked && !d.isFullyPaid).length,
      completedPayments: devices.filter(d => d.isFullyPaid).length,
      defaultRate: devices.length > 0 
        ? (devices.filter(d => d.isLocked).length / devices.length) * 100 
        : 0,
      avgCompletionTime: 0 // Can be calculated from payment history
    };

    await plan.save();
    res.json(plan);
  } catch (error) {
    console.error('Error updating plan performance:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;

