const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  deviceId: { type: String, required: true, index: true },
  amount: { type: Number, required: true },
  paymentMethod: { type: String, required: true },
  transactionReference: { type: String, required: true, unique: true },
  status: { type: String, enum: ['pending', 'completed', 'failed'], default: 'pending' },
  transactionId: { type: String, unique: true, sparse: true },
  processedAt: { type: Date },
  failureReason: { type: String },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Payment', paymentSchema);

