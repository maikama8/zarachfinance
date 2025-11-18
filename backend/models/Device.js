const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema({
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
  timestamp: { type: Date, default: Date.now },
  accuracy: { type: Number }
});

const deviceSchema = new mongoose.Schema({
  deviceId: { type: String, required: true, unique: true, index: true },
  customerName: { type: String, required: true },
  customerPhone: { type: String, required: true },
  storeContact: { type: String, required: true },
  storePhone: { type: String, required: true },
  isLocked: { type: Boolean, default: false },
  isFullyPaid: { type: Boolean, default: false },
  releaseCode: { type: String, unique: true, sparse: true },
  appVersion: { type: String },
  lastSeen: { type: Date, default: Date.now },
  locations: [locationSchema],
  paymentHistory: [{
    date: { type: Date, default: Date.now },
    amount: { type: Number, required: true },
    status: { type: String, enum: ['pending', 'completed', 'failed'], default: 'pending' },
    transactionId: { type: String },
    paymentMethod: { type: String }
  }],
  paymentSchedule: [{
    dueDate: { type: Date, required: true },
    amount: { type: Number, required: true },
    status: { type: String, enum: ['paid', 'pending', 'overdue'], default: 'pending' }
  }],
  totalAmount: { type: Number, required: true },
  paidAmount: { type: Number, default: 0 },
  remainingBalance: { type: Number, required: true },
  policy: {
    lockOnOverdue: { type: Boolean, default: true },
    lockDelayHours: { type: Number, default: 24 },
    allowEmergencyCalls: { type: Boolean, default: true }
  },
  customMessage: { type: String },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

deviceSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

deviceSchema.methods.updatePaymentStatus = function() {
  const now = new Date();
  let totalPaid = 0;
  let hasOverdue = false;

  this.paymentSchedule.forEach(item => {
    if (item.status === 'paid') {
      totalPaid += item.amount;
    } else if (item.status === 'pending' && item.dueDate < now) {
      item.status = 'overdue';
      hasOverdue = true;
    }
  });

  this.paidAmount = totalPaid;
  this.remainingBalance = this.totalAmount - totalPaid;
  this.isFullyPaid = this.remainingBalance <= 0;
  this.isLocked = hasOverdue && this.policy.lockOnOverdue;

  return {
    isPaymentOverdue: hasOverdue,
    isFullyPaid: this.isFullyPaid,
    remainingBalance: this.remainingBalance
  };
};

module.exports = mongoose.model('Device', deviceSchema);

