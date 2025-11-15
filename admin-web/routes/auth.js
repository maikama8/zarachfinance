const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const { query } = require('../config/database');

// Login page
router.get('/login', (req, res) => {
  // Redirect if already logged in
  if (req.session.user) {
    return res.redirect('/dashboard');
  }
  
  res.render('login', {
    title: 'Login - Zaracfinance Admin',
    error: null
  });
});

// Login POST
router.post('/login', async (req, res) => {
  const { username, password } = req.body;

  try {
    const result = await query(
      'SELECT * FROM admin_users WHERE username = $1 AND is_active = TRUE',
      [username]
    );

    if (result.rows.length === 0) {
      return res.render('login', {
        title: 'Login - Zaracfinance Admin',
        error: 'Invalid username or password'
      });
    }

    const user = result.rows[0];
    const validPassword = await bcrypt.compare(password, user.password_hash);

    if (!validPassword) {
      return res.render('login', {
        title: 'Login - Zaracfinance Admin',
        error: 'Invalid username or password'
      });
    }

    // Update last login
    await query(
      'UPDATE admin_users SET last_login = NOW() WHERE user_id = $1',
      [user.user_id]
    );

    // Set session
    req.session.user = {
      id: user.user_id,
      username: user.username,
      email: user.email,
      role: user.role
    };

    res.redirect('/dashboard');
  } catch (error) {
    console.error('Login error:', error);
    res.render('login', {
      title: 'Login - Zaracfinance Admin',
      error: 'An error occurred. Please try again.'
    });
  }
});

// Logout
router.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/auth/login');
});

module.exports = router;
