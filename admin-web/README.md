# Zaracfinance Admin Dashboard

Professional Node.js/Express web application for managing the Zaracfinance device financing system.

## 🎯 Features

- **Dashboard**: Real-time statistics and charts
- **Device Management**: View, lock, unlock, and track devices
- **Customer Management**: Complete customer information and history
- **Payment Tracking**: Monitor payments, overdue accounts, and revenue
- **Release Code Generation**: Generate secure device release codes
- **Reports & Analytics**: Comprehensive reporting system
- **Audit Logs**: Track all administrative actions
- **Secure Authentication**: Role-based access control

## 🚀 Quick Deployment to VPS

### Automated Deployment (Recommended)

```bash
# 1. Upload to your Debian 12 VPS
scp -r admin-web root@your-vps-ip:/root/

# 2. Run the deployment script
ssh root@your-vps-ip
cd /root/admin-web
chmod +x VPS_QUICK_DEPLOY.sh
./VPS_QUICK_DEPLOY.sh

# 3. Create admin user
cd /home/zaracadmin/admin-web
node scripts/create-admin.js
```

**Done!** Access at `http://your-vps-ip`

See [QUICK_START.md](./QUICK_START.md) for details.

## 📋 Manual Installation

### 1. Install Dependencies

```bash
cd admin-web
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

Update with your settings:
```env
NODE_ENV=production
PORT=3001
DB_HOST=localhost
DB_NAME=zaracfinance
DB_USER=zaracadmin
DB_PASSWORD=your_password
SESSION_SECRET=generate_random_string
API_BASE_URL=http://localhost:3000/api/v1
```

Update the values in `.env` with your actual configuration.

### 3. Create Required Directories

```bash
mkdir -p config routes controllers models middleware public/css public/js views/partials
```

### 4. Run the Application

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

## Project Structure

```
admin-web/
├── server.js              # Main application file
├── package.json           # Dependencies
├── .env                   # Environment variables
├── config/
│   └── database.js        # Database configuration
├── routes/
│   ├── index.js           # Home routes
│   ├── auth.js            # Authentication routes
│   ├── dashboard.js       # Dashboard routes
│   ├── devices.js         # Device management routes
│   ├── customers.js       # Customer management routes
│   ├── payments.js        # Payment routes
│   └── reports.js         # Reports routes
├── controllers/
│   ├── authController.js
│   ├── dashboardController.js
│   ├── deviceController.js
│   ├── customerController.js
│   ├── paymentController.js
│   └── reportController.js
├── models/
│   ├── User.js
│   ├── Device.js
│   ├── Customer.js
│   └── Payment.js
├── middleware/
│   └── auth.js            # Authentication middleware
├── views/
│   ├── layout.ejs         # Main layout template
│   ├── login.ejs          # Login page
│   ├── dashboard.ejs      # Dashboard
│   ├── devices/
│   │   ├── list.ejs
│   │   └── detail.ejs
│   ├── customers/
│   │   ├── list.ejs
│   │   └── detail.ejs
│   ├── payments/
│   │   ├── list.ejs
│   │   └── detail.ejs
│   └── partials/
│       ├── header.ejs
│       ├── sidebar.ejs
│       └── footer.ejs
└── public/
    ├── css/
    │   └── style.css
    └── js/
        └── main.js
```

## Deployment on Debian 12 VPS

### 1. Upload Files

```bash
# On your local machine
scp -r admin-web user@your-vps-ip:/home/zaracadmin/
```

### 2. Install Dependencies on VPS

```bash
ssh user@your-vps-ip
cd /home/zaracadmin/admin-web
npm install --production
```

### 3. Configure PM2

```bash
# Create PM2 ecosystem file
nano ecosystem.config.js
```

Add:
```javascript
module.exports = {
  apps: [{
    name: 'zaracfinance-admin',
    script: 'server.js',
    instances: 1,
    env: {
      NODE_ENV: 'production',
      PORT: 3001
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
```

### 4. Start with PM2

```bash
mkdir logs
pm2 start ecosystem.config.js
pm2 save
```

### 5. Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/zaracfinance-admin
```

Add:
```nginx
server {
    listen 80;
    server_name admin.yourdomain.com;

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
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/zaracfinance-admin /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 6. Setup SSL

```bash
sudo certbot --nginx -d admin.yourdomain.com
```

## Default Login

After first setup, create an admin user in the database:

```sql
INSERT INTO admin_users (username, email, password_hash, role)
VALUES ('admin', 'admin@yourdomain.com', '$2b$12$...', 'SUPER_ADMIN');
```

Or use the provided script:
```bash
node scripts/create-admin.js
```

## API Endpoints Used

The admin dashboard connects to these backend API endpoints:

- `GET /api/v1/devices` - List all devices
- `GET /api/v1/devices/:id` - Get device details
- `POST /api/v1/devices/:id/lock` - Lock device
- `POST /api/v1/devices/:id/unlock` - Unlock device
- `GET /api/v1/customers` - List customers
- `GET /api/v1/payments` - List payments
- `POST /api/v1/release-codes/generate` - Generate release code
- `GET /api/v1/reports/dashboard` - Dashboard statistics

## Security

- All routes except login require authentication
- Passwords are hashed with bcrypt
- Session-based authentication
- CSRF protection enabled
- Helmet.js for security headers
- Input validation on all forms

## Maintenance

```bash
# View logs
pm2 logs zaracfinance-admin

# Restart application
pm2 restart zaracfinance-admin

# Stop application
pm2 stop zaracfinance-admin

# Update application
git pull
npm install
pm2 restart zaracfinance-admin
```

## Troubleshooting

### Port Already in Use
```bash
lsof -i :3001
kill -9 <PID>
```

### Database Connection Issues
```bash
# Test database connection
psql -U zaracadmin -d zaracfinance -c "SELECT 1;"
```

### View Application Logs
```bash
pm2 logs zaracfinance-admin --lines 100
```

## Support

For issues or questions, contact: support@zarachtech.com

## License

Proprietary - Zarachtech © 2024
