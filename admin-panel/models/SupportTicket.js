const mongoose = require('mongoose');

const supportTicketSchema = new mongoose.Schema({
  ticketId: { type: String, required: true, unique: true },
  customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Customer', required: true },
  deviceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Device' },
  subject: { type: String, required: true },
  description: { type: String, required: true },
  category: { 
    type: String, 
    enum: ['payment', 'device', 'technical', 'billing', 'general', 'complaint'],
    default: 'general'
  },
  priority: { 
    type: String, 
    enum: ['low', 'medium', 'high', 'urgent'],
    default: 'medium'
  },
  status: { 
    type: String, 
    enum: ['open', 'in-progress', 'resolved', 'closed', 'escalated'],
    default: 'open'
  },
  assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin' },
  messages: [{
    sender: { type: String, enum: ['customer', 'admin'], required: true },
    senderId: { type: mongoose.Schema.Types.ObjectId, refPath: 'messages.senderModel' },
    senderModel: { type: String, enum: ['Customer', 'Admin'] },
    message: { type: String, required: true },
    attachments: [String],
    sentAt: { type: Date, default: Date.now }
  }],
  resolution: String,
  resolvedAt: Date,
  resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin' },
  customerSatisfaction: {
    rating: { type: Number, min: 1, max: 5 },
    feedback: String,
    submittedAt: Date
  },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

supportTicketSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  if (this.status === 'resolved' && !this.resolvedAt) {
    this.resolvedAt = Date.now();
  }
  next();
});

module.exports = mongoose.model('SupportTicket', supportTicketSchema);

