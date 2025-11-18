const AuditLog = require('../models/AuditLog');

// Middleware to log all admin actions
exports.logAction = (action, resourceType) => {
  return async (req, res, next) => {
    // Store original json method
    const originalJson = res.json.bind(res);

    // Override json method to log after response
    res.json = function(data) {
      // Log the action
      AuditLog.create({
        action: action || req.method + ' ' + req.path,
        userId: req.user?.id,
        userEmail: req.user?.email,
        userRole: req.user?.role,
        resourceType: resourceType || req.path.split('/')[2],
        resourceId: req.params.id || req.body.id,
        changes: req.method === 'PUT' || req.method === 'PATCH' ? req.body : undefined,
        ipAddress: req.ip || req.connection.remoteAddress,
        userAgent: req.get('user-agent'),
        status: res.statusCode < 400 ? 'success' : 'failed',
        errorMessage: res.statusCode >= 400 ? data.message : undefined
      }).catch(err => {
        console.error('Error creating audit log:', err);
      });

      // Call original json method
      return originalJson(data);
    };

    next();
  };
};

