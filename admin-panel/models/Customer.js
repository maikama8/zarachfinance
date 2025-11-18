const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema({
  customerId: { type: String, required: true, unique: true },
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  email: { type: String, required: true },
  phone: { type: String, required: true },
  alternatePhone: String,
  address: {
    street: String,
    city: String,
    state: String,
    country: { type: String, default: 'Nigeria' },
    postalCode: String
  },
  kycData: {
    idType: { type: String, enum: ['NIN', 'Driver License', 'International Passport', 'Voter Card'] },
    idNumber: String,
    idDocument: String, // URL to uploaded document
    photo: String, // URL to customer photo
    verified: { type: Boolean, default: false },
    verifiedAt: Date,
    verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin' }
  },
  assignedDevices: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Device' }],
  paymentHistory: [{
    date: { type: Date, default: Date.now },
    amount: Number,
    method: String,
    status: { type: String, enum: ['completed', 'pending', 'failed'], default: 'completed' },
    transactionId: String,
    deviceId: String
  }],
  communicationHistory: [{
    type: { type: String, enum: ['sms', 'email', 'push', 'call', 'in-app'] },
    message: String,
    sentAt: { type: Date, default: Date.now },
    status: { type: String, enum: ['sent', 'delivered', 'failed'], default: 'sent' }
  }],
  supportTickets: [{ type: mongoose.Schema.Types.ObjectId, ref: 'SupportTicket' }],
  riskScore: { type: Number, default: 0, min: 0, max: 100 },
  notes: String,
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

customerSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('Customer', customerSchema);

