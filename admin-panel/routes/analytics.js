const express = require('express');
const router = express.Router();
const Device = require('../models/Device');
const Customer = require('../models/Customer');
const Payment = require('../models/Payment');
const Analytics = require('../models/Analytics');
const FinancingPlan = require('../models/FinancingPlan');
const AuditLog = require('../models/AuditLog');
const { authenticate } = require('../middleware/auth');

// Get dashboard statistics
router.get('/dashboard', authenticate, async (req, res) => {
  try {
    const now = new Date();
    const today = new Date(now.setHours(0, 0, 0, 0));
    
    const [
      totalDevices,
      activeDevices,
      lockedDevices,
      offlineDevices,
      totalCustomers,
      todayRevenue,
      totalRevenue,
      overduePayments,
      devices
    ] = await Promise.all([
      Device.countDocuments(),
      Device.countDocuments({ status: 'active', isLocked: false }),
      Device.countDocuments({ isLocked: true }),
      Device.countDocuments({ lastSeen: { $lt: new Date(Date.now() - 24 * 60 * 60 * 1000) } }),
      Customer.countDocuments(),
      Payment.aggregate([
        { $match: { createdAt: { $gte: today }, status: 'completed' } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]),
      Payment.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]),
      Device.aggregate([
        { $unwind: '$paymentSchedule' },
        { $match: { 'paymentSchedule.status': 'overdue' } },
        { $group: { _id: null, total: { $sum: '$paymentSchedule.amount' } } }
      ]),
      Device.find().select('locations').limit(100)
    ]);

    // Calculate compliance rate
    const paidDevices = await Device.countDocuments({ isFullyPaid: true });
    const complianceRate = totalDevices > 0 ? (paidDevices / totalDevices) * 100 : 0;

    // Get device locations for map
    const locations = devices
      .filter(d => d.locations && d.locations.length > 0)
      .map(d => ({
        deviceId: d.deviceId,
        location: d.locations[d.locations.length - 1]
      }));

    res.json({
      totalDevices,
      activeDevices,
      lockedDevices,
      offlineDevices,
      totalCustomers,
      todayRevenue: todayRevenue[0]?.total || 0,
      totalRevenue: totalRevenue[0]?.total || 0,
      overdueAmount: overduePayments[0]?.total || 0,
      complianceRate: Math.round(complianceRate * 100) / 100,
      locations
    });
  } catch (error) {
    console.error('Error getting dashboard stats:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get payment compliance analytics
router.get('/compliance', authenticate, async (req, res) => {
  try {
    const { period = '30' } = req.query;
    const daysAgo = new Date(Date.now() - period * 24 * 60 * 60 * 1000);

    const devices = await Device.find({ createdAt: { $gte: daysAgo } });
    
    const complianceData = {
      total: devices.length,
      fullyPaid: devices.filter(d => d.isFullyPaid).length,
      onTrack: devices.filter(d => !d.isLocked && !d.isFullyPaid).length,
      overdue: devices.filter(d => d.isLocked).length,
      complianceRate: 0
    };

    complianceData.complianceRate = complianceData.total > 0
      ? ((complianceData.fullyPaid + complianceData.onTrack) / complianceData.total) * 100
      : 0;

    // Regional data
    const regionalData = await Device.aggregate([
      {
        $group: {
          _id: '$address.state',
          deviceCount: { $sum: 1 },
          fullyPaid: { $sum: { $cond: ['$isFullyPaid', 1, 0] } },
          overdue: { $sum: { $cond: ['$isLocked', 1, 0] } }
        }
      },
      {
        $project: {
          region: '$_id',
          deviceCount: 1,
          complianceRate: {
            $multiply: [
              { $divide: [{ $subtract: ['$deviceCount', '$overdue'] }, '$deviceCount'] },
              100
            ]
          },
          revenue: 0 // Can be calculated from payments
        }
      }
    ]);

    res.json({
      overall: complianceData,
      regional: regionalData
    });
  } catch (error) {
    console.error('Error getting compliance analytics:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get revenue analytics
router.get('/revenue', authenticate, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const match = { status: 'completed' };
    
    if (startDate || endDate) {
      match.createdAt = {};
      if (startDate) match.createdAt.$gte = new Date(startDate);
      if (endDate) match.createdAt.$lte = new Date(endDate);
    }

    const dailyRevenue = await Payment.aggregate([
      { $match: match },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          total: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    const monthlyRevenue = await Payment.aggregate([
      { $match: match },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m', date: '$createdAt' } },
          total: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    const totalRevenue = await Payment.aggregate([
      { $match: match },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    res.json({
      daily: dailyRevenue,
      monthly: monthlyRevenue,
      total: totalRevenue[0]?.total || 0
    });
  } catch (error) {
    console.error('Error getting revenue analytics:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get plan performance
router.get('/plans', authenticate, async (req, res) => {
  try {
    const plans = await FinancingPlan.find({ isActive: true });
    
    const planPerformance = await Promise.all(
      plans.map(async (plan) => {
        const devices = await Device.find({ financingPlanId: plan._id });
        const active = devices.filter(d => !d.isLocked && !d.isFullyPaid).length;
        const completed = devices.filter(d => d.isFullyPaid).length;
        const defaults = devices.filter(d => d.isLocked).length;
        
        return {
          planId: plan._id,
          planName: plan.name,
          totalAssigned: devices.length,
          activeDevices: active,
          completedPayments: completed,
          defaultRate: devices.length > 0 ? (defaults / devices.length) * 100 : 0,
          completionRate: devices.length > 0 ? (completed / devices.length) * 100 : 0
        };
      })
    );

    res.json(planPerformance);
  } catch (error) {
    console.error('Error getting plan performance:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Generate daily analytics
router.post('/generate-daily', authenticate, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Check if already generated
    const existing = await Analytics.findOne({ date: today });
    if (existing) {
      return res.json({ message: 'Analytics already generated for today', data: existing });
    }

    // Calculate metrics
    const metrics = await calculateDailyMetrics(today);
    
    const analytics = new Analytics({
      date: today,
      metrics
    });

    await analytics.save();
    res.json({ success: true, data: analytics });
  } catch (error) {
    console.error('Error generating daily analytics:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

async function calculateDailyMetrics(date) {
  const [
    totalDevices,
    activeDevices,
    lockedDevices,
    offlineDevices,
    totalCustomers,
    activeCustomers,
    payments,
    devices
  ] = await Promise.all([
    Device.countDocuments(),
    Device.countDocuments({ status: 'active', isLocked: false }),
    Device.countDocuments({ isLocked: true }),
    Device.countDocuments({ lastSeen: { $lt: new Date(Date.now() - 24 * 60 * 60 * 1000) } }),
    Customer.countDocuments(),
    Customer.countDocuments({ 'assignedDevices.0': { $exists: true } }),
    Payment.aggregate([
      { $match: { createdAt: { $gte: date }, status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
    ]),
    Device.find()
  ]);

  const totalRevenue = payments[0]?.total || 0;
  const dailyCollection = payments[0]?.total || 0;
  
  const overdueAmount = devices.reduce((sum, device) => {
    const overdue = device.paymentSchedule.filter(s => s.status === 'overdue');
    return sum + overdue.reduce((s, item) => s + item.amount, 0);
  }, 0);

  const paidDevices = devices.filter(d => d.isFullyPaid).length;
  const complianceRate = devices.length > 0 ? (paidDevices / devices.length) * 100 : 0;

  return {
    totalDevices,
    activeDevices,
    lockedDevices,
    offlineDevices,
    totalCustomers,
    activeCustomers,
    totalRevenue,
    dailyCollection,
    overdueAmount,
    paymentComplianceRate: complianceRate,
    deviceRecoveryRate: 0, // Can be calculated from recovered devices
    avgPaymentTime: 0, // Can be calculated from payment timestamps
    defaultRate: devices.length > 0 ? (lockedDevices / devices.length) * 100 : 0
  };
}

module.exports = router;

