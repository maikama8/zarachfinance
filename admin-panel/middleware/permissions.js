const Admin = require('../models/Admin');

// Check if user has specific permission
exports.checkPermission = (permission) => {
  return async (req, res, next) => {
    try {
      const admin = await Admin.findById(req.user.id);
      
      if (!admin) {
        return res.status(401).json({ message: 'User not found' });
      }

      // Admins have all permissions
      if (admin.role === 'admin') {
        return next();
      }

      // Check specific permission
      const permissionPath = permission.split('.');
      let hasPermission = admin.permissions;

      for (const part of permissionPath) {
        hasPermission = hasPermission?.[part];
      }

      if (!hasPermission) {
        return res.status(403).json({ 
          message: 'You do not have permission to perform this action' 
        });
      }

      next();
    } catch (error) {
      console.error('Permission check error:', error);
      res.status(500).json({ message: 'Server error' });
    }
  };
};

// Check if user has any of the specified roles
exports.checkRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Authentication required' });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Access denied' });
    }

    next();
  };
};

