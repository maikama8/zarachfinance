// Authentication middleware
const requireAuth = (req, res, next) => {
  if (!req.session.user) {
    return res.redirect('/auth/login');
  }
  next();
};

// Check if user is admin
const requireAdmin = (req, res, next) => {
  if (!req.session.user) {
    return res.redirect('/auth/login');
  }
  
  if (req.session.user.role !== 'ADMIN' && req.session.user.role !== 'SUPER_ADMIN') {
    return res.status(403).render('error', {
      title: 'Access Denied',
      message: 'You do not have permission to access this resource',
      error: {}
    });
  }
  
  next();
};

// Redirect if already authenticated
const redirectIfAuthenticated = (req, res, next) => {
  if (req.session.user) {
    return res.redirect('/dashboard');
  }
  next();
};

module.exports = {
  requireAuth,
  requireAdmin,
  redirectIfAuthenticated
};
