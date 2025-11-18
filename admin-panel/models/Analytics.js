const mongoose = require('mongoose');

const analyticsSchema = new mongoose.Schema({
  date: { type: Date, required: true, unique: true },
  metrics: {
    totalDevices: { type: Number, default: 0 },
    activeDevices: { type: Number, default: 0 },
    lockedDevices: { type: Number, default: 0 },
    offlineDevices: { type: Number, default: 0 },
    totalCustomers: { type: Number, default: 0 },
    activeCustomers: { type: Number, default: 0 },
    totalRevenue: { type: Number, default: 0 },
    dailyCollection: { type: Number, default: 0 },
    overdueAmount: { type: Number, default: 0 },
    paymentComplianceRate: { type: Number, default: 0 },
    deviceRecoveryRate: { type: Number, default: 0 },
    avgPaymentTime: { type: Number, default: 0 }, // in hours
    defaultRate: { type: Number, default: 0 }
  },
  regionalData: [{
    region: String,
    deviceCount: Number,
    complianceRate: Number,
    revenue: Number
  }],
  planPerformance: [{
    planId: { type: mongoose.Schema.Types.ObjectId, ref: 'FinancingPlan' },
    activeDevices: Number,
    completionRate: Number,
    defaultRate: Number
  }],
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Analytics', analyticsSchema);

