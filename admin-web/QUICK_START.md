# Zaracfinance Admin - Quick Start Guide

## 🚀 Deploy to Debian 12 VPS in 5 Minutes

### Prerequisites
- Debian 12 VPS with root access
- PostgreSQL database running
- Backend API running

### Option 1: Automated Deployment (Recommended)

**Step 1:** Upload the admin-web folder to your VPS

```bash
# From your local machine
scp -r admin-web root@your-vps-ip:/root/
```

**Step 2:** Run the deployment script

```bash
# SSH into your VPS
ssh root@your-vps-ip

# Navigate to the folder
cd /root/admin-web

# Make script executable
chmod +x VPS_QUICK_DEPLOY.sh

# Run deployment
./VPS_QUICK_DEPLOY.sh
```

The script will:
- ✓ Install Node.js, Nginx, PM2
- ✓ Create application user
- ✓ Install dependencies
- ✓ Configure environment
- ✓ Start application with PM2
- ✓ Configure Nginx reverse proxy
- ✓ Setup firewall

**Step 3:** Create admin user

```bash
cd /home/zaracadmin/admin-web
node scripts/create-admin.js
```

**Step 4:** Access your dashboard

Open browser: `http://your-vps-ip`

---

### Option 2: Manual Deployment

Follow the detailed guide in [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

---

## 📋 Post-Deployment Checklist

- [ ] Admin user created
- [ ] Can login to dashboard
- [ ] Database connection working
- [ ] Backend API accessible
- [ ] SSL certificate installed (optional)
- [ ] Firewall configured
- [ ] PM2 auto-start enabled

---

## 🔧 Common Commands

```bash
# View application logs
pm2 logs zaracfinance-admin

# Restart application
pm2 restart zaracfinance-admin

# Check application status
pm2 status

# View Nginx logs
sudo tail -f /var/log/nginx/zaracfinance-admin-access.log

# Restart Nginx
sudo systemctl restart nginx
```

---

## 🔐 Setup SSL (Optional but Recommended)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d admin.yourdomain.com

# Test auto-renewal
sudo certbot renew --dry-run
```

---

## 📞 Support

- Documentation: See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
- Issues: Check application logs with `pm2 logs`
- Email: support@zarachtech.com

---

## 🎯 What's Included

- **Dashboard**: Overview of devices, payments, and customers
- **Device Management**: View and manage all financed devices
- **Customer Management**: Track customer information and payment history
- **Payment Tracking**: Monitor payments, overdue accounts, and revenue
- **Reports**: Generate device and payment reports
- **Audit Logs**: Track all administrative actions

---

**Ready to deploy? Run the script and you'll be up in minutes!**
