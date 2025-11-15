#!/bin/bash

# Zaracfinance Admin Web - Quick Setup Script for Debian 12
# Run this script as the application user (not root)

set -e

echo "========================================="
echo "Zaracfinance Admin Web - Quick Setup"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Error: Do not run this script as root!${NC}"
    echo "Please run as the application user (e.g., zaracadmin)"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed!${NC}"
    echo "Please install Node.js 20.x first:"
    echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
    echo "  sudo apt install -y nodejs"
    exit 1
fi

echo -e "${GREEN}✓ Node.js $(node --version) detected${NC}"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ npm $(npm --version) detected${NC}"

# Install dependencies
echo ""
echo "Installing dependencies..."
npm install --production

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Dependencies installed successfully${NC}"
else
    echo -e "${RED}✗ Failed to install dependencies${NC}"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo ""
    echo "Creating .env file..."
    cp .env.example .env
    
    # Generate random session secret
    SESSION_SECRET=$(node -e "console.log(require('crypto').randomBytes(64).toString('hex'))")
    
    # Update .env with generated secret
    sed -i "s/your_very_long_random_session_secret_here/$SESSION_SECRET/" .env
    
    echo -e "${YELLOW}⚠ .env file created from template${NC}"
    echo -e "${YELLOW}⚠ Please edit .env and update the following:${NC}"
    echo "  - DB_HOST"
    echo "  - DB_PORT"
    echo "  - DB_NAME"
    echo "  - DB_USER"
    echo "  - DB_PASSWORD"
    echo "  - API_BASE_URL"
    echo "  - ADMIN_EMAIL"
    echo ""
    read -p "Press Enter after you've updated the .env file..."
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

# Create logs directory
mkdir -p logs
echo -e "${GREEN}✓ Logs directory created${NC}"

# Test database connection
echo ""
echo "Testing database connection..."
DB_HOST=$(grep DB_HOST .env | cut -d '=' -f2)
DB_USER=$(grep DB_USER .env | cut -d '=' -f2)
DB_NAME=$(grep DB_NAME .env | cut -d '=' -f2)

if psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Database connection failed${NC}"
    echo "Please check your database credentials in .env"
    exit 1
fi

# Check if admin_users table exists
echo ""
echo "Checking database tables..."
TABLE_EXISTS=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'admin_users');")

if [ "$TABLE_EXISTS" = "f" ]; then
    echo -e "${YELLOW}⚠ admin_users table does not exist${NC}"
    read -p "Do you want to create it now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << EOF
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

CREATE TABLE IF NOT EXISTS audit_logs (
    log_id SERIAL PRIMARY KEY,
    event VARCHAR(100) NOT NULL,
    device_id INTEGER,
    user_id INTEGER REFERENCES admin_users(user_id),
    data JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_device ON audit_logs(device_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp);
EOF
        echo -e "${GREEN}✓ Database tables created${NC}"
    fi
else
    echo -e "${GREEN}✓ Database tables exist${NC}"
fi

# Check if admin user exists
echo ""
ADMIN_COUNT=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM admin_users;")

if [ "$ADMIN_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠ No admin users found${NC}"
    read -p "Do you want to create an admin user now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        node scripts/create-admin.js
    fi
else
    echo -e "${GREEN}✓ Admin users exist ($ADMIN_COUNT)${NC}"
fi

# Check if PM2 is installed
echo ""
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}⚠ PM2 is not installed${NC}"
    read -p "Do you want to install PM2 globally? (requires sudo) (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo npm install -g pm2
        echo -e "${GREEN}✓ PM2 installed${NC}"
    fi
else
    echo -e "${GREEN}✓ PM2 $(pm2 --version) detected${NC}"
fi

# Start application
echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "To start the application:"
echo "  pm2 start ecosystem.config.js"
echo ""
echo "To view logs:"
echo "  pm2 logs zaracfinance-admin"
echo ""
echo "To enable startup on boot:"
echo "  pm2 startup"
echo "  pm2 save"
echo ""
echo "For full deployment instructions, see DEPLOYMENT_GUIDE.md"
echo ""

read -p "Do you want to start the application now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    pm2 start ecosystem.config.js
    echo ""
    echo -e "${GREEN}✓ Application started!${NC}"
    echo ""
    pm2 status
    echo ""
    echo "Access the admin dashboard at: http://localhost:3001"
fi
