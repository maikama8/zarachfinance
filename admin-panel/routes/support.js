const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const SupportTicket = require('../models/SupportTicket');
const Customer = require('../models/Customer');
const { authenticate } = require('../middleware/auth');
const AuditLog = require('../models/AuditLog');

// Get all tickets
router.get('/', authenticate, async (req, res) => {
  try {
    const { status, priority, category, page = 1, limit = 50 } = req.query;
    const query = {};
    
    if (status) query.status = status;
    if (priority) query.priority = priority;
    if (category) query.category = category;

    const tickets = await SupportTicket.find(query)
      .populate('customerId', 'firstName lastName email phone')
      .populate('deviceId', 'deviceId model')
      .populate('assignedTo', 'name email')
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .sort({ createdAt: -1 });

    const total = await SupportTicket.countDocuments(query);

    res.json({
      tickets,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      total
    });
  } catch (error) {
    console.error('Error getting tickets:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get ticket by ID
router.get('/:id', authenticate, async (req, res) => {
  try {
    const ticket = await SupportTicket.findById(req.params.id)
      .populate('customerId')
      .populate('deviceId')
      .populate('assignedTo')
      .populate('resolvedBy');

    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    res.json(ticket);
  } catch (error) {
    console.error('Error getting ticket:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create new ticket
router.post('/',
  authenticate,
  [
    body('customerId').notEmpty(),
    body('subject').notEmpty(),
    body('description').notEmpty()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { customerId, deviceId, subject, description, category, priority } = req.body;

      // Generate ticket ID
      const ticketId = `TKT${Date.now()}${Math.random().toString(36).substr(2, 5).toUpperCase()}`;

      const ticket = new SupportTicket({
        ticketId,
        customerId,
        deviceId,
        subject,
        description,
        category: category || 'general',
        priority: priority || 'medium'
      });

      await ticket.save();

      // Add to customer's ticket list
      await Customer.findByIdAndUpdate(customerId, {
        $push: { supportTickets: ticket._id }
      });

      res.status(201).json(ticket);
    } catch (error) {
      console.error('Error creating ticket:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// Add message to ticket
router.post('/:id/messages', authenticate, async (req, res) => {
  try {
    const { message, attachments } = req.body;
    const ticket = await SupportTicket.findById(req.params.id);

    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    ticket.messages.push({
      sender: 'admin',
      senderId: req.user.id,
      senderModel: 'Admin',
      message,
      attachments: attachments || []
    });

    if (ticket.status === 'open') {
      ticket.status = 'in-progress';
    }

    await ticket.save();
    res.json(ticket);
  } catch (error) {
    console.error('Error adding message:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Update ticket status
router.patch('/:id/status', authenticate, async (req, res) => {
  try {
    const { status, resolution } = req.body;
    const ticket = await SupportTicket.findById(req.params.id);

    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    ticket.status = status;
    if (status === 'resolved' && resolution) {
      ticket.resolution = resolution;
      ticket.resolvedBy = req.user.id;
      ticket.resolvedAt = new Date();
    }

    await ticket.save();
    res.json(ticket);
  } catch (error) {
    console.error('Error updating ticket status:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Assign ticket
router.patch('/:id/assign', authenticate, async (req, res) => {
  try {
    const { assignedTo } = req.body;
    const ticket = await SupportTicket.findById(req.params.id);

    if (!ticket) {
      return res.status(404).json({ message: 'Ticket not found' });
    }

    ticket.assignedTo = assignedTo;
    if (ticket.status === 'open') {
      ticket.status = 'in-progress';
    }

    await ticket.save();
    res.json(ticket);
  } catch (error) {
    console.error('Error assigning ticket:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;

