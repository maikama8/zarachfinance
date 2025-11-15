# Backend & Admin Web Deployment Guide - Debian 12 VPS

## Overview

This guide will help you set up the complete backend system for Zaracfinance on a Debian 12 VPS, including:
- REST API backend (Node.js/Express or Python/Django)
- Admin web dashboard
- PostgreSQL database
- Nginx reverse proxy
- SSL certificates
- Monitoring and logging

## Prerequisites

- Debian 12 VPS with root access
- Domain name pointed to your VPS IP
- Minimum 2GB RAM, 2 CPU cores, 20GB storage
- SSH access to your server

## Architecture Overview

```
Internet → Nginx (SSL) → Backend API (Port 3000)
                      → Admin Dashboard (Port 3001)
                      → PostgreSQL Database (Port 5432)
```

---

## Part 1: Initial Server Setup

### 1.1 Connect to Your VPS

```bash
ssh root@your-vps-ip
```

### 1.2 Update System

```bash
apt update && apt upgrade -y
```

### 1.3 Create Non-Root User

```bash
adduser zaracadmin
usermod -aG sudo zaracadmin
su - zaracadmin
```

### 1.4 Configure Firewall

```bash
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status
```

---

## Part 2: Install Required Software

### 2.1 Install Node.js (for Backend API)

```bash
# Install Node.js 20.x LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### 2.2 Install PostgreSQL

```bash
# Install PostgreSQL 15
sudo apt install postgresql postgresql-contrib -y

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify installation
sudo systemctl status postgresql
```

### 2.3 Install Nginx

```bash
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 2.4 Install PM2 (Process Manager)

```bash
sudo npm install -g pm2
```

### 2.5 Install Git

```bash
sudo apt install git -y
```

---

## Part 3: Database Setup

### 3.1 Create Database and User

```bash
# Switch to postgres user
sudo -u postgres psql

# In PostgreSQL prompt, run:
CREATE DATABASE zaracfinance;
CREATE USER zaracadmin WITH ENCRYPTED PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE zaracfinance TO zaracadmin;
\q
```

### 3.2 Configure PostgreSQL for Remote Access (Optional)

```bash
# Edit postgresql.conf
sudo nano /etc/postgresql/15/main/postgresql.conf

# Find and modify:
listen_addresses = 'localhost'  # Keep as localhost for security

# Edit pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Add this line:
local   all             zaracadmin                              md5

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### 3.3 Create Database Schema

```sql
-- Connect to database
psql -U zaracadmin -d zaracfinance

-- Create tables
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE devices (
    device_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id VARCHAR(50) REFERENCES customers(customer_id),
    imei VARCHAR(20) UNIQUE NOT NULL,
    android_id VARCHAR(50) NOT NULL,
    device_model VARCHAR(100),
    manufacturer VARCHAR(100),
    android_version VARCHAR(20),
    app_version VARCHAR(20),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    release_date TIMESTAMP,
    release_eligible BOOLEAN DEFAULT FALSE,
    release_code_generated_date TIMESTAMP,
    last_seen TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payment_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES devices(device_id),
    total_amount DECIMAL(10, 2) NOT NULL,
    paid_amount DECIMAL(10, 2) DEFAULT 0,
    remaining_amount DECIMAL(10, 2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    frequency VARCHAR(20) DEFAULT 'DAILY',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE installments (
    installment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    schedule_id UUID REFERENCES payment_schedules(schedule_id),
    sequence_number INT NOT NULL,
    due_date DATE NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    paid_date TIMESTAMP,
    paid_amount DECIMAL(10, 2),
    transaction_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES devices(device_id),
    amount DECIMAL(10, 2) NOT NULL,
    method VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    reference VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    receipt_url TEXT,
    metadata JSONB
);

CREATE TABLE release_codes (
    code VARCHAR(20) PRIMARY KEY,
    device_id UUID REFERENCES devices(device_id),
    customer_id VARCHAR(50) REFERENCES customers(customer_id),
    generated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    used_date TIMESTAMP,
    generated_by VARCHAR(100),
    revoked_date TIMESTAMP,
    revoked_by VARCHAR(100),
    revocation_reason TEXT
);

CREATE TABLE device_locations (
    location_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES devices(device_id),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(10, 2),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    provider VARCHAR(20)
);

CREATE TABLE tamper_alerts (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES devices(device_id),
    tamper_type VARCHAR(50) NOT NULL,
    description TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details JSONB,
    action_taken VARCHAR(50)
);

CREATE TABLE admin_users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'ADMIN',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE TABLE audit_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event VARCHAR(100) NOT NULL,
    device_id UUID,
    user_id UUID,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data JSONB
);

-- Create indexes for performance
CREATE INDEX idx_devices_customer ON devices(customer_id);
CREATE INDEX idx_devices_status ON devices(status);
CREATE INDEX idx_installments_schedule ON installments(schedule_id);
CREATE INDEX idx_installments_status ON installments(status);
CREATE INDEX idx_transactions_device ON transactions(device_id);
CREATE INDEX idx_locations_device ON device_locations(device_id);
CREATE INDEX idx_locations_timestamp ON device_locations(timestamp);
CREATE INDEX idx_audit_device ON audit_logs(device_id);
CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp);
```

---

## Part 4: Backend API Setup

### 4.1 Create Project Directory

```bash
cd /home/zaracadmin
mkdir zaracfinance-backend
cd zaracfinance-backend
```

### 4.2 Initialize Node.js Project

```bash
npm init -y
```

### 4.3 Install Dependencies

```bash
npm install express pg bcrypt jsonwebtoken cors dotenv helmet express-rate-limit
npm install --save-dev nodemon
```

### 4.4 Create Backend Structure

```bash
mkdir -p src/{routes,controllers,models,middleware,utils,config}
touch src/server.js
touch .env
```

### 4.5 Create Environment Configuration

```bash
nano .env
```

Add:
```env
# Server Configuration
NODE_ENV=production
PORT=3000
API_VERSION=v1

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=zaracfinance
DB_USER=zaracadmin
DB_PASSWORD=your_secure_password_here

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_here_make_it_very_long_and_random
JWT_EXPIRY=30d

# Security
BCRYPT_ROUNDS=12

# Rate Limiting
RATE_LIMIT_WINDOW=15
RATE_LIMIT_MAX=100

# CORS
ALLOWED_ORIGINS=https://admin.yourdomain.com,https://yourdomain.com
```

### 4.6 Create Database Connection

```bash
nano src/config/database.js
```

```javascript
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

module.exports = pool;
```

### 4.7 Create Main Server File

```bash
nano src/server.js
```

```javascript
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS.split(','),
  credentials: true,
};
app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW) * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX),
});
app.use('/api/', limiter);

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.API_VERSION,
  });
});

// API routes
app.use('/api/v1/auth', require('./routes/auth'));
app.use('/api/v1/devices', require('./routes/devices'));
app.use('/api/v1/payments', require('./routes/payments'));
app.use('/api/v1/admin', require('./routes/admin'));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: {
      message: 'Internal server error',
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    },
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
});
```

### 4.8 Create Sample Routes

```bash
nano src/routes/devices.js
```

```javascript
const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Register device
router.post('/register', async (req, res) => {
  try {
    const { imei, androidId, deviceModel, manufacturer, osVersion, appVersion, customerId } = req.body;
    
    const result = await pool.query(
      `INSERT INTO devices (imei, android_id, device_model, manufacturer, android_version, app_version, customer_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING device_id`,
      [imei, androidId, deviceModel, manufacturer, osVersion, appVersion, customerId]
    );
    
    res.json({
      success: true,
      deviceId: result.rows[0].device_id,
    });
  } catch (error) {
    console.error('Device registration error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get device status
router.get('/:deviceId/status', async (req, res) => {
  try {
    const { deviceId } = req.params;
    
    const result = await pool.query(
      'SELECT * FROM devices WHERE device_id = $1',
      [deviceId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Device not found' });
    }
    
    res.json({
      success: true,
      device: result.rows[0],
    });
  } catch (error) {
    console.error('Get device status error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
```

### 4.9 Start Backend with PM2

```bash
# Create PM2 ecosystem file
nano ecosystem.config.js
```

```javascript
module.exports = {
  apps: [{
    name: 'zaracfinance-api',
    script: 'src/server.js',
    instances: 2,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
  }],
};
```

```bash
# Create logs directory
mkdir logs

# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
# Run the command it outputs
```

---

## Part 5: Admin Dashboard Setup

### 5.1 Create Admin Dashboard Directory

```bash
cd /home/zaracadmin
mkdir zaracfinance-admin
cd zaracfinance-admin
```

### 5.2 Create React Admin Dashboard

```bash
# Install Create React App
npx create-react-app admin-dashboard
cd admin-dashboard

# Install dependencies
npm install axios react-router-dom @mui/material @mui/icons-material recharts
```

### 5.3 Build for Production

```bash
npm run build
```

### 5.4 Serve with PM2

```bash
npm install -g serve

# Create PM2 config for admin
cd /home/zaracadmin/zaracfinance-admin
nano ecosystem.admin.config.js
```

```javascript
module.exports = {
  apps: [{
    name: 'zaracfinance-admin',
    script: 'serve',
    args: '-s build -l 3001',
    cwd: './admin-dashboard',
    env: {
      NODE_ENV: 'production',
    },
  }],
};
```

```bash
pm2 start ecosystem.admin.config.js
pm2 save
```

---

## Part 6: Nginx Configuration

### 6.1 Create Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/zaracfinance
```

```nginx
# API Backend
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# Admin Dashboard
server {
    listen 80;
    server_name admin.yourdomain.com;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 6.2 Enable Site

```bash
sudo ln -s /etc/nginx/sites-available/zaracfinance /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## Part 7: SSL Certificate Setup

### 7.1 Install Certbot

```bash
sudo apt install certbot python3-certbot-nginx -y
```

### 7.2 Obtain SSL Certificates

```bash
sudo certbot --nginx -d api.yourdomain.com -d admin.yourdomain.com
```

### 7.3 Auto-Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Certbot automatically sets up a cron job for renewal
```

---

## Part 8: Monitoring and Maintenance

### 8.1 Setup Logging

```bash
# View PM2 logs
pm2 logs

# View specific app logs
pm2 logs zaracfinance-api
pm2 logs zaracfinance-admin

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 8.2 Setup Monitoring

```bash
# Install PM2 monitoring
pm2 install pm2-logrotate

# Configure log rotation
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
```

### 8.3 Database Backups

```bash
# Create backup script
nano /home/zaracadmin/backup-db.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/home/zaracadmin/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

pg_dump -U zaracadmin zaracfinance > $BACKUP_DIR/zaracfinance_$DATE.sql

# Keep only last 7 days of backups
find $BACKUP_DIR -name "zaracfinance_*.sql" -mtime +7 -delete
```

```bash
chmod +x /home/zaracadmin/backup-db.sh

# Add to crontab
crontab -e
# Add: 0 2 * * * /home/zaracadmin/backup-db.sh
```

---

## Part 9: Security Hardening

### 9.1 Configure Firewall

```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

### 9.2 Fail2Ban Setup

```bash
sudo apt install fail2ban -y
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```

### 9.3 Secure PostgreSQL

```bash
sudo nano /etc/postgresql/15/main/pg_hba.conf
# Ensure only local connections are allowed
```

---

## Part 10: Testing

### 10.1 Test API

```bash
curl https://api.yourdomain.com/health
```

### 10.2 Test Admin Dashboard

Open browser: `https://admin.yourdomain.com`

### 10.3 Test Database Connection

```bash
psql -U zaracadmin -d zaracfinance -c "SELECT COUNT(*) FROM devices;"
```

---

## Maintenance Commands

```bash
# Restart services
pm2 restart all
sudo systemctl restart nginx
sudo systemctl restart postgresql

# View status
pm2 status
sudo systemctl status nginx
sudo systemctl status postgresql

# Update application
cd /home/zaracadmin/zaracfinance-backend
git pull
npm install
pm2 restart zaracfinance-api

# View logs
pm2 logs
sudo tail -f /var/log/nginx/error.log
```

---

## Troubleshooting

### API Not Responding
```bash
pm2 logs zaracfinance-api
sudo netstat -tulpn | grep 3000
```

### Database Connection Issues
```bash
sudo systemctl status postgresql
psql -U zaracadmin -d zaracfinance
```

### SSL Certificate Issues
```bash
sudo certbot certificates
sudo certbot renew --force-renewal
```

---

## Next Steps

1. Implement authentication endpoints
2. Create admin dashboard UI
3. Set up monitoring (Grafana/Prometheus)
4. Configure automated backups
5. Set up CI/CD pipeline
6. Implement rate limiting per device
7. Add API documentation (Swagger)

---

**Document Version:** 1.0  
**Last Updated:** [Date]  
**For Support:** [Your Email]
