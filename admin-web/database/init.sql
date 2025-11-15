-- Zaracfinance Admin Database Initialization
-- Run this script to create the necessary tables for the admin dashboard

-- Create admin_users table
CREATE TABLE IF NOT EXISTS admin_users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'ADMIN',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_by INTEGER REFERENCES admin_users(user_id),
    CONSTRAINT valid_role CHECK (role IN ('SUPER_ADMIN', 'ADMIN', 'VIEWER'))
);

-- Create audit_logs table for tracking admin actions
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id SERIAL PRIMARY KEY,
    event VARCHAR(100) NOT NULL,
    device_id INTEGER,
    customer_id INTEGER,
    user_id INTEGER REFERENCES admin_users(user_id),
    data JSONB,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_audit_logs_device ON audit_logs(device_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_customer ON audit_logs(customer_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_event ON audit_logs(event);

CREATE INDEX IF NOT EXISTS idx_admin_users_username ON admin_users(username);
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_active ON admin_users(is_active);

-- Create function to log admin actions
CREATE OR REPLACE FUNCTION log_admin_action(
    p_event VARCHAR,
    p_device_id INTEGER DEFAULT NULL,
    p_customer_id INTEGER DEFAULT NULL,
    p_user_id INTEGER DEFAULT NULL,
    p_data JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
) RETURNS INTEGER AS $$
DECLARE
    v_log_id INTEGER;
BEGIN
    INSERT INTO audit_logs (event, device_id, customer_id, user_id, data, ip_address, user_agent)
    VALUES (p_event, p_device_id, p_customer_id, p_user_id, p_data, p_ip_address, p_user_agent)
    RETURNING log_id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- Create view for active admin users
CREATE OR REPLACE VIEW active_admin_users AS
SELECT 
    user_id,
    username,
    email,
    role,
    created_at,
    last_login
FROM admin_users
WHERE is_active = TRUE;

-- Create view for recent audit logs
CREATE OR REPLACE VIEW recent_audit_logs AS
SELECT 
    al.log_id,
    al.event,
    al.device_id,
    al.customer_id,
    al.timestamp,
    au.username,
    au.email,
    al.data
FROM audit_logs al
LEFT JOIN admin_users au ON al.user_id = au.user_id
ORDER BY al.timestamp DESC
LIMIT 1000;

-- Grant permissions (adjust as needed)
-- GRANT SELECT, INSERT, UPDATE ON admin_users TO zaracadmin;
-- GRANT SELECT, INSERT ON audit_logs TO zaracadmin;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO zaracadmin;

-- Display success message
DO $$
BEGIN
    RAISE NOTICE '✓ Admin database tables created successfully';
    RAISE NOTICE '✓ Indexes created';
    RAISE NOTICE '✓ Functions and views created';
    RAISE NOTICE '';
    RAISE NOTICE 'Next step: Create your first admin user';
    RAISE NOTICE 'Run: node scripts/create-admin.js';
END $$;
