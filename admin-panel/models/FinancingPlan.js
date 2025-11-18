const mongoose = require('mongoose');

const financingPlanSchema = new mongoose.Schema({
  planId: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  description: String,
  totalAmount: { type: Number, required: true },
  downPayment: { type: Number, default: 0 },
  paymentFrequency: { type: String, enum: ['daily', 'weekly', 'monthly'], required: true },
  paymentAmount: { type: Number, required: true },
  duration: { type: Number, required: true }, // in days
  interestRate: { type: Number, default: 0 },
  gracePeriod: { type: Number, default: 0 }, // in days
  lateFee: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  applicableDevices: [String], // Device models or categories
  minCreditScore: { type: Number, default: 0 },
  maxCreditScore: { type: Number, default: 100 },
  performance: {
    totalAssigned: { type: Number, default: 0 },
    activeDevices: { type: Number, default: 0 },
    completedPayments: { type: Number, default: 0 },
    defaultRate: { type: Number, default: 0 },
    avgCompletionTime: Number // in days
  },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

financingPlanSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('FinancingPlan', financingPlanSchema);

