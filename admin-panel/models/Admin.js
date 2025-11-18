const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const adminSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true },
  name: { type: String, required: true },
  role: { type: String, enum: ['admin', 'manager', 'agent', 'store_owner'], default: 'agent' },
  storeName: { type: String },
  apiKey: { type: String, unique: true, sparse: true },
  permissions: {
    deviceManagement: { type: Boolean, default: true },
    customerManagement: { type: Boolean, default: true },
    paymentManagement: { type: Boolean, default: true },
    systemConfiguration: { type: Boolean, default: false },
    analytics: { type: Boolean, default: true },
    userManagement: { type: Boolean, default: false },
    reports: { type: Boolean, default: true }
  },
  isActive: { type: Boolean, default: true },
  lastLogin: { type: Date },
  loginAttempts: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now }
});

adminSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

adminSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

adminSchema.methods.generateApiKey = function() {
  const crypto = require('crypto');
  this.apiKey = crypto.randomBytes(32).toString('hex');
  return this.apiKey;
};

module.exports = mongoose.model('Admin', adminSchema);

