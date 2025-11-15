#!/bin/bash

# Zaracfinance Admin Web - Complete VPS Deployment Script
# For Debian 12
# Run this script on your VPS as root or with sudo privileges

set -e

echo "========================================="
echo "Zaracfinance Admin - VPS Deployment"
echo "Debian 12 - Complete Setup"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
    echo "Usage: sudo bash VPS_QUICK_DEPLOY.sh"
    exit 1
fi

# Get configuration from user
echo -e "${BLUE}Please provide the following information:${NC}"
echo ""

read -p "Application user name [zaracadmin]: " APP_USER
APP_USER=${APP_USER:-zaracadmin}

read -p "Domain name (or press Enter to use IP): " DOMAIN_NAME

read -p "Database name [zaracfinance]: " DB_NAME
DB_NAME=${DB_NAME:-zaracfinance}

read -p "Database user [zaracadmin]: " DB_USER
DB_USER=${DB_USER:-zaracadmin}

read -sp "Database password: " DB_PASSWORD
echo ""

read -p "Backend API URL [http://localhost:3000/api/v1]: " API_URL
API_URL=${API_URL:-http://localhost:3000/api/v1}

read -p "Admin email: " ADMIN_EMAIL

echo ""
echo -e "${YELLOW}Configuration Summary:${NC}"
echo "  User: $APP_USER"
echo "  Domain: ${DOMAIN_NAME:-IP Address}"
echo "  Database: $DB_NAME"
echo "  DB User: $DB_USER"
echo "  API URL: $API_URL"
echo "  Admin Email: $ADMIN_EMAIL"
echo ""
read -p "Continue with installation? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

# Step 1: Update system
echo ""
echo -e "${BLUE}[1/10] Updating system...${NC}"
apt update && apt upgrade -y

# Step 2: Install Node.js
echo ""
echo -e "${BLUE}[2/10] Installing Node.js 20.x...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    echo -e "${GREEN}✓ Node.js installed: $(node --version)${NC}"
else
    echo -e "${GREEN}✓ Node.js already installed: $(node --version)${NC}"
fi

# Step 3: Install Nginx
echo ""
echo -e "${BLUE}[3/10] Installing Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    apt install -y nginx
    echo -e "${GREEN}✓ Nginx installed${NC}"
else
    echo -e "${GREEN}✓ Nginx already installed${NC}"
fi

# Step 4: Install PM2
echo ""
echo -e "${BLUE}[4/10] Installing PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
    echo -e "${GREEN}✓ PM2 installed${NC}"
else
    echo -e "${GREEN}✓ PM2 already installed${NC}"
fi

# Step 5: Create application user
echo ""
echo -e "${BLUE}[5/10] Creating application user...${NC}"
if id "$APP_USER" &>/dev/null; then
    echo -e "${GREEN}✓ User $APP_USER already exists${NC}"
else
    adduser $APP_USER --disabled-password --gecos ""
    echo -e "${GREEN}✓ User $APP_USER created${NC}"
fi

# Step 6: Setup application directory
echo ""
echo -e "${BLUE}[6/10] Setting up application directory...${NC}"
APP_DIR="/home/$APP_USER/admin-web"

if [ ! -d "$APP_DIR" ]; then
    echo -e "${YELLOW}⚠ Application directory not found at $APP_DIR${NC}"
    echo "Please upload your admin-web folder to /home/$APP_USER/"
    echo ""
    echo "You can use one of these methods:"
    echo "  1. SCP: scp -r admin-web $APP_USER@your-vps-ip:/home/$APP_USER/"
    echo "  2. Git: git clone your-repo /home/$APP_USER/admin-web"
    echo "  3. SFTP: Use FileZilla or WinSCP"
    echo ""
    read -p "Press Enter after uploading the files..."
    
    if [ ! -d "$APP_DIR" ]; then
        echo -e "${RED}✗ Application directory still not found. Exiting.${NC}"
        exit 1
    fi
fi

cd $APP_DIR
chown -R $APP_USER:$APP_USER $APP_DIR

# Step 7: Install dependencies
echo ""
echo -e "${BLUE}[7/10] Installing application dependencies...${NC}"
sudo -u $APP_USER npm install --production
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Step 8: Configure environment
echo ""
echo -e "${BLUE}[8/10] Configuring environment...${NC}"

# Generate session secret
SESSION_SECRET=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'))")

# Create .env file
cat > $APP_DIR/.env << EOF
# Server Configuration
NODE_ENV=production
PORT=3001

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# Session Configuration
SESSION_SECRET=$SESSION_SECRET

# API Configuration
API_BASE_URL=$API_URL

# Admin Configuration
ADMIN_EMAIL=$ADMIN_EMAIL
COMPANY_NAME=Zaracfinance
EOF

chown $APP_USER:$APP_USER $APP_DIR/.env
chmod 600 $APP_DIR/.env
echo -e "${GREEN}✓ Environment configured${NC}"

# Create logs directory
mkdir -p $APP_DIR/logs
chown -R $APP_USER:$APP_USER $APP_DIR/logs

# Step 9: Start application with PM2
echo ""
echo -e "${BLUE}[9/10] Starting application...${NC}"
cd $APP_DIR
sudo -u $APP_USER pm2 start ecosystem.config.js
sudo -u $APP_USER pm2 save

# Setup PM2 startup
env PATH=$PATH:/usr/bin pm2 startup systemd -u $APP_USER --hp /home/$APP_USER
echo -e "${GREEN}✓ Application started with PM2${NC}"

# Step 10: Configure Nginx
echo ""
echo -e "${BLUE}[10/10] Configuring Nginx...${NC}"

if [ -z "$DOMAIN_NAME" ]; then
    SERVER_NAME="_"
else
    SERVER_NAME="$DOMAIN_NAME"
fi

cat > /etc/nginx/sites-available/zaracfinance-admin << EOF
server {
    listen 80;
    server_name $SERVER_NAME;

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
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
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
EOF

# Enable site
ln -sf /etc/nginx/sites-available/zaracfinance-admin /etc/nginx/sites-enabled/

# Test and reload Nginx
nginx -t
systemctl reload nginx
echo -e "${GREEN}✓ Nginx configured${NC}"

# Configure firewall
echo ""
echo -e "${BLUE}Configuring firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 'Nginx Full'
    echo -e "${GREEN}✓ Firewall configured${NC}"
fi

# Final summary
echo ""
echo "========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "========================================="
echo ""
echo "Application Status:"
sudo -u $APP_USER pm2 status
echo ""
echo "Access your admin dashboard:"
if [ -z "$DOMAIN_NAME" ]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "  http://$SERVER_IP"
else
    echo "  http://$DOMAIN_NAME"
fi
echo ""
echo "Next Steps:"
echo "  1. Create admin user: cd $APP_DIR && node scripts/create-admin.js"
echo "  2. Setup SSL (if using domain): sudo certbot --nginx -d $DOMAIN_NAME"
echo "  3. View logs: pm2 logs zaracfinance-admin"
echo ""
echo "Documentation:"
echo "  - Full guide: $APP_DIR/DEPLOYMENT_GUIDE.md"
echo "  - README: $APP_DIR/README.md"
echo ""
echo -e "${YELLOW}Important: Create your first admin user now!${NC}"
read -p "Do you want to create an admin user now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd $APP_DIR
    sudo -u $APP_USER node scripts/create-admin.js
fi

echo ""
echo -e "${GREEN}All done! Your admin dashboard is ready.${NC}"
