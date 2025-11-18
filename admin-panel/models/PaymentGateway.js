const mongoose = require('mongoose');

const paymentGatewaySchema = new mongoose.Schema({
  gateway: { 
    type: String, 
    enum: ['paystack', 'flutterwave'], 
    required: true,
    unique: true
  },
  isActive: { type: Boolean, default: true },
  publicKey: { type: String, required: true },
  secretKey: { type: String, required: true },
  webhookSecret: { type: String },
  currency: { type: String, default: 'NGN' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

paymentGatewaySchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('PaymentGateway', paymentGatewaySchema);

