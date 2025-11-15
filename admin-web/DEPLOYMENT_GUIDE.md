# Zaracfinance Admin Web - VPS Deployment Guide (Debian 12)

Complete step-by-step guide to deploy the Zaracfinance Admin Dashboard on a Debian 12 VPS.

## Prerequisites

- Debian 12 VPS with root access
- Domain name (optional but recommended)
- PostgreSQL database already set up
- Backend API running

## Step 1: Initial Server Setup

### 1.1 Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 1.2 Install Required Software

```bash
# Install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Nginx
sudo apt install -y nginx

# Install PM2 globally
sudo npm install -g pm2

# Install Git (if not already installed)
sudo apt install -y git

# Verify installations
node --version
npm --version
nginx -v
pm2 --version
```

## Step 2: Create Application User

```bash
# Create a dedicated user for the application
sudo adduser zaracadmin --disabled-password --gecos ""

# Add to sudo group (optional)
sudo usermod -aG sudo zaracadmin

# Switch to the new user
sudo su - zaracadmin
```

## Step 3: Upload Application Files

### Option A: Using SCP (from your local machine)

```bash
# From your local machine
scp -r admin-web zaracadmin@your-vps-ip:/home/zaracadmin/
```

### Option B: Using Git

```bash
# On the VPS as zaracadmin user
cd /home/zaracadmin
git clone https://github.com/yourusername/zaracfinance.git
cd zaracfinance/admin-web
```

### Option C: Manual Upload via SFTP

Use FileZilla or WinSCP to upload the `admin-web` folder to `/home/zaracadmin/`

## Step 4: Configure Application

### 4.1 Navigate to Application Directory

```bash
cd /home/zaracadmin/admin-web
```

### 4.2 Install Dependencies

```bash
npm install --production
```

### 4.3 Create Environment File

```bash
cp .env.example .env
nano .env
```

Update the `.env` file with your actual configuration:

```env
# Server Configuration
NODE_ENV=production
PORT=3001

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=zaracfinance
DB_USER=zaracadmin
DB_PASSWORD=your_actual_database_password

# Session Configuration (generate a random string)
SESSION_SECRET=your_very_long_random_session_secret_change_this_to_something_secure

# API Configuration (Backend API URL)
API_BASE_URL=http://localhost:3000/api/v1

# Admin Configuration
ADMIN_EMAIL=admin@yourdomain.com
COMPANY_NAME=Zaracfinance
```

**Generate a secure session secret:**
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 4.4 Create Required Directories

```bash
mkdir -p logs
```

### 4.5 Test Database Connection

```bash
# Test PostgreSQL connection
psql -h localhost -U zaracadmin -d zaracfinance -c "SELECT 1;"
```

## Step 5: Create Database Tables

### 5.1 Create Admin Users Table

```bash
psql -h localhost -U zaracadmin -d zaracfinance
```

```sql
-- Create admin_users table
CREATE TABLE IF NOT EXISTS admin_users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'ADMIN',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create audit_logs table
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id SERIAL PRIMARY KEY,
    event VARCHAR(100) NOT NULL,
    device_id INTEGER,
    user_id INTEGER REFERENCES admin_users(user_id),
    data JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_audit_logs_device ON audit_logs(device_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);

\q
```

### 5.2 Create First Admin User

```bash
node scripts/create-admin.js
```

Follow the prompts to create your first admin user.

## Step 6: Start Application with PM2

### 6.1 Start the Application

```bash
pm2 start ecosystem.config.js
```

### 6.2 Configure PM2 to Start on Boot

```bash
pm2 startup
# Copy and run the command that PM2 outputs

pm2 save
```

### 6.3 Verify Application is Running

```bash
pm2 status
pm2 logs zaracfinance-admin --lines 50
```

### 6.4 Test Application Locally

```bash
curl http://localhost:3001
```

## Step 7: Configure Nginx as Reverse Proxy

### 7.1 Create Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/zaracfinance-admin
```

Add the following configuration:

```nginx
server {
    listen 80;
    server_name admin.yourdomain.com;  # Change to your domain or IP

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/zaracfinance-admin-access.log;
    error_log /var/log/nginx/zaracfinance-admin-error.log;

    # Proxy settings
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        proxy_pass http://localhost:3001;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 7.2 Enable the Site

```bash
# Test Nginx configuration
sudo nginx -t

# Create symbolic link
sudo ln -s /etc/nginx/sites-available/zaracfinance-admin /etc/nginx/sites-enabled/

# Reload Nginx
sudo systemctl reload nginx
```

### 7.3 Configure Firewall

```bash
# Allow HTTP and HTTPS
sudo ufw allow 'Nginx Full'

# Check firewall status
sudo ufw status
```

## Step 8: Setup SSL Certificate (Recommended)

### 8.1 Install Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 8.2 Obtain SSL Certificate

```bash
sudo certbot --nginx -d admin.yourdomain.com
```

Follow the prompts. Certbot will automatically configure Nginx for HTTPS.

### 8.3 Test Auto-Renewal

```bash
sudo certbot renew --dry-run
```

## Step 9: Verify Deployment

### 9.1 Check Application Status

```bash
pm2 status
pm2 logs zaracfinance-admin --lines 20
```

### 9.2 Check Nginx Status

```bash
sudo systemctl status nginx
sudo tail -f /var/log/nginx/zaracfinance-admin-access.log
```

### 9.3 Access the Application

Open your browser and navigate to:
- HTTP: `http://admin.yourdomain.com` or `http://your-vps-ip`
- HTTPS: `https://admin.yourdomain.com` (if SSL configured)

Login with the admin credentials you created earlier.

## Step 10: Monitoring and Maintenance

### 10.1 View Application Logs

```bash
# Real-time logs
pm2 logs zaracfinance-admin

# Last 100 lines
pm2 logs zaracfinance-admin --lines 100

# Error logs only
pm2 logs zaracfinance-admin --err
```

### 10.2 Restart Application

```bash
pm2 restart zaracfinance-admin
```

### 10.3 Stop Application

```bash
pm2 stop zaracfinance-admin
```

### 10.4 Monitor Resources

```bash
pm2 monit
```

### 10.5 Update Application

```bash
cd /home/zaracadmin/admin-web

# Pull latest changes (if using Git)
git pull

# Install new dependencies
npm install --production

# Restart application
pm2 restart zaracfinance-admin
```

## Troubleshooting

### Application Won't Start

```bash
# Check logs
pm2 logs zaracfinance-admin --lines 50

# Check if port is already in use
sudo lsof -i :3001

# Verify environment variables
cat .env

# Test database connection
psql -h localhost -U zaracadmin -d zaracfinance -c "SELECT 1;"
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check database exists
sudo -u postgres psql -l | grep zaracfinance

# Test connection
psql -h localhost -U zaracadmin -d zaracfinance
```

### Nginx Issues

```bash
# Check Nginx configuration
sudo nginx -t

# Check Nginx status
sudo systemctl status nginx

# View error logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

### Permission Issues

```bash
# Fix ownership
sudo chown -R zaracadmin:zaracadmin /home/zaracadmin/admin-web

# Fix permissions
chmod -R 755 /home/zaracadmin/admin-web
```

### Can't Access from Browser

```bash
# Check firewall
sudo ufw status

# Allow port 80 and 443
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Check if application is listening
sudo netstat -tulpn | grep :3001
```

## Security Best Practices

### 1. Keep System Updated

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Configure Firewall

```bash
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
```

### 3. Disable Root Login

```bash
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
sudo systemctl restart sshd
```

### 4. Use Strong Passwords

- Use strong, unique passwords for database and admin accounts
- Change default passwords immediately
- Use password managers

### 5. Regular Backups

```bash
# Backup database
pg_dump -U zaracadmin zaracfinance > backup_$(date +%Y%m%d).sql

# Backup application
tar -czf admin-web-backup-$(date +%Y%m%d).tar.gz /home/zaracadmin/admin-web
```

### 6. Monitor Logs

```bash
# Setup log rotation
sudo nano /etc/logrotate.d/zaracfinance-admin
```

Add:
```
/home/zaracadmin/admin-web/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 zaracadmin zaracadmin
    sharedscripts
}
```

## Performance Optimization

### 1. Enable Gzip Compression in Nginx

```bash
sudo nano /etc/nginx/nginx.conf
```

Add in `http` block:
```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;
```

### 2. Configure PM2 for Production

```bash
pm2 set pm2:autodump true
pm2 set pm2:watch false
```

### 3. Database Connection Pooling

Already configured in `config/database.js` with optimal settings.

## Support

For issues or questions:
- Email: support@zarachtech.com
- Check logs: `pm2 logs zaracfinance-admin`
- Review documentation: `/home/zaracadmin/admin-web/README.md`

## Quick Reference Commands

```bash
# Application Management
pm2 start ecosystem.config.js
pm2 restart zaracfinance-admin
pm2 stop zaracfinance-admin
pm2 logs zaracfinance-admin
pm2 monit

# Nginx Management
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx
sudo nginx -t

# Database Management
psql -U zaracadmin -d zaracfinance
pg_dump -U zaracadmin zaracfinance > backup.sql

# View Logs
pm2 logs zaracfinance-admin --lines 100
sudo tail -f /var/log/nginx/zaracfinance-admin-access.log
sudo tail -f /var/log/nginx/zaracfinance-admin-error.log
```

---

**Deployment Complete!** Your Zaracfinance Admin Dashboard should now be running on your VPS.
