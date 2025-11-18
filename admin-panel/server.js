const express = require('express');
const path = require('path');
const session = require('express-session');
const cookieParser = require('cookie-parser');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const http = require('http');
const { Server } = require('socket.io');
require('dotenv').config();
const Device = require('./models/Device');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    credentials: true
  }
});

// Socket.IO for real-time updates
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  socket.on('subscribe', (data) => {
    if (data.type === 'device') {
      socket.join(`device:${data.deviceId}`);
    } else if (data.type === 'dashboard') {
      socket.join('dashboard');
    }
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Export io for use in routes
app.set('io', io);
const socketUtils = require('./utils/socket');
socketUtils.setIO(io);

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https:"],
      scriptSrc: ["'self'", "'unsafe-inline'"], // Allow inline scripts for admin panel
      scriptSrcAttr: ["'unsafe-inline'", "'unsafe-hashes'"], // Allow inline event handlers (onclick, etc.)
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'", "https:", "data:"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
}));
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(session({
  secret: process.env.SESSION_SECRET || 'your-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: process.env.NODE_ENV === 'production', maxAge: 24 * 60 * 60 * 1000 } // 24 hours
}));

// Database connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/zarfinance')
.then(() => console.log('MongoDB connected'))
.catch(err => {
  console.error('MongoDB connection error:', err.message);
  console.log('Note: Make sure MongoDB is running. You can start it with: mongod');
});

// Serve static files (admin panel)
app.use(express.static(path.join(__dirname, 'public')));

// API Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/payment', require('./routes/payment'));
app.use('/api/device', require('./routes/device'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/customer', require('./routes/customer'));
app.use('/api/analytics', require('./routes/analytics'));
app.use('/api/financing-plan', require('./routes/financing-plan'));
app.use('/api/support', require('./routes/support'));

// Admin Panel Routes
app.get('/', (req, res) => {
  if (req.session.token) {
    res.redirect('/dashboard');
  } else {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
  }
});

app.get('/dashboard', (req, res) => {
  if (!req.session.token) {
    return res.redirect('/');
  }
  // Use enhanced dashboard if available, fallback to regular
  res.sendFile(path.join(__dirname, 'public', 'dashboard-enhanced.html'), (err) => {
    if (err) {
      res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
    }
  });
});

app.get('/settings', (req, res) => {
  if (!req.session.token) {
    return res.redirect('/');
  }
  res.sendFile(path.join(__dirname, 'public', 'settings.html'));
});

app.get('/devices', (req, res) => {
  if (!req.session.token) {
    return res.redirect('/');
  }
  res.sendFile(path.join(__dirname, 'public', 'devices.html'));
});

app.get('/customers', (req, res) => {
  if (!req.session.token) {
    return res.redirect('/');
  }
  res.sendFile(path.join(__dirname, 'public', 'customers.html'));
});

app.get('/payments', (req, res) => {
  if (!req.session.token) {
    return res.redirect('/');
  }
  res.sendFile(path.join(__dirname, 'public', 'payments.html'));
});

app.get('/analytics', (req, res) => {
  if (!req.session.token) {
    return res.redirect('/');
  }
  res.sendFile(path.join(__dirname, 'public', 'analytics.html'));
});

app.get('/plans', (req, res) => {
  if (!req.session.token) {
    return res.redirect('/');
  }
  res.sendFile(path.join(__dirname, 'public', 'plans.html'));
});

app.get('/support', (req, res) => {
  if (!req.session.token) {
    return res.redirect('/');
  }
  res.sendFile(path.join(__dirname, 'public', 'support.html'));
});

app.get('/users', (req, res) => {
  if (!req.session.token) {
    return res.redirect('/');
  }
  res.sendFile(path.join(__dirname, 'public', 'users.html'));
});

// Admin panel API proxy routes (for convenience - these match the dashboard endpoints)
app.get('/api/devices', require('./middleware/auth').authenticate, async (req, res) => {
  try {
    const devices = await Device.find()
      .select('-locations -paymentHistory')
      .sort({ createdAt: -1 });
    res.json(devices);
  } catch (error) {
    console.error('Error getting devices:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/devices/:deviceId', require('./middleware/auth').authenticate, async (req, res) => {
  try {
    const device = await Device.findOne({ deviceId: req.params.deviceId });
    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }
    res.json(device);
  } catch (error) {
    console.error('Error getting device details:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/devices', require('./middleware/auth').authenticate, async (req, res) => {
  try {
    const { deviceId, customerName, customerPhone, storeContact, storePhone, totalAmount, paymentFrequency, paymentSchedule } = req.body;
    
    // Generate release code
    const crypto = require('crypto');
    const releaseCode = crypto.randomBytes(8).toString('hex').toUpperCase();

    const device = new Device({
      deviceId,
      customerName,
      customerPhone,
      storeContact,
      storePhone,
      totalAmount,
      remainingBalance: totalAmount,
      paymentFrequency: paymentFrequency || 'daily',
      paymentSchedule: paymentSchedule.map(s => ({
        dueDate: new Date(s.dueDate),
        amount: s.amount,
        status: 'pending'
      })),
      releaseCode
    });

    await device.save();

    res.status(201).json({
      success: true,
      device,
      releaseCode
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Device ID already exists' });
    }
    console.error('Error creating device:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/unlock', require('./middleware/auth').authenticate, async (req, res) => {
  try {
    const { deviceId } = req.body;
    const device = await Device.findOne({ deviceId });
    if (!device) {
      return res.status(404).json({ success: false, message: 'Device not found' });
    }
    device.isLocked = false;
    await device.save();
    
    // Emit real-time update
    const socketUtils = require('./utils/socket');
    socketUtils.emitDeviceUpdate(deviceId, {
      type: 'unlock',
      isLocked: false
    });
    
    res.json({ success: true, message: 'Device unlocked successfully' });
  } catch (error) {
    console.error('Error unlocking device:', error);
    res.status(500).json({ success: false, message: 'Failed to unlock device' });
  }
});

app.post('/api/message', require('./middleware/auth').authenticate, async (req, res) => {
  try {
    const { deviceId, message } = req.body;
    const device = await Device.findOne({ deviceId });
    if (!device) {
      return res.status(404).json({ message: 'Device not found' });
    }
    device.customMessage = message;
    await device.save();
    res.json({ success: true, message: 'Message sent to device' });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/logout', (req, res) => {
  if (!req.session) {
    return res.json({ success: true });
  }
  req.session.destroy(err => {
    if (err) {
      return res.status(500).json({ message: 'Failed to logout' });
    }
    res.clearCookie('connect.sid');
    res.json({ success: true });
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Session check endpoint (for debugging)
app.get('/api/session-check', (req, res) => {
  res.json({
    hasSession: !!req.session,
    hasToken: !!req.session?.token,
    admin: req.session?.admin || null
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`ZarFinance Admin Panel running on port ${PORT}`);
  console.log(`WebSocket server ready for real-time updates`);
});

module.exports = app;
