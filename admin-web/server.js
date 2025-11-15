const express = require('express');
const session = require('express-session');
const cookieParser = require('cookie-parser');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

// Test database connection on startup
const { pool } = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disable for development, configure properly in production
}));
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// Session configuration
app.use(session({
  secret: process.env.SESSION_SECRET || 'your-secret-key-change-this',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
}));

// View engine setup
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Make user available to all views
app.use((req, res, next) => {
  res.locals.user = req.session.user || null;
  res.locals.currentPath = req.path;
  next();
});

// Routes
app.use('/', require('./routes/index'));
app.use('/auth', require('./routes/auth'));
app.use('/dashboard', require('./routes/dashboard'));
app.use('/devices', require('./routes/devices'));
app.use('/customers', require('./routes/customers'));
app.use('/payments', require('./routes/payments'));
app.use('/reports', require('./routes/reports'));

// 404 handler
app.use((req, res) => {
  res.status(404).render('404', { title: 'Page Not Found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).render('error', {
    title: 'Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
    error: process.env.NODE_ENV === 'development' ? err : {}
  });
});

// Test database connection before starting server
pool.query('SELECT NOW()')
  .then(() => {
    console.log('✓ Database connection verified');
    
    // Start server
    app.listen(PORT, () => {
      console.log('========================================');
      console.log('Zaracfinance Admin Dashboard');
      console.log('========================================');
      console.log(`✓ Server running on port ${PORT}`);
      console.log(`✓ Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`✓ Visit: http://localhost:${PORT}`);
      console.log('========================================');
    });
  })
  .catch(err => {
    console.error('✗ Database connection failed:', err.message);
    console.error('Please check your database configuration in .env file');
    process.exit(1);
  });
