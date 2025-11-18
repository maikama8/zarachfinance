#!/bin/bash

# Start ZarFinance Admin Panel Server

cd "$(dirname "$0")/admin-panel"

echo "Starting ZarFinance Admin Panel..."
echo ""

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Check for .env file
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cat > .env << EOF
MONGODB_URI=mongodb+srv://superadmin:kY9NTSFGzxyEwRxh@finance.mvsvdna.mongodb.net/?appName=Finance
PORT=3000
SESSION_SECRET=your-secret-key-change-this-in-production
NODE_ENV=development
ALLOWED_ORIGINS=*
EOF
    echo "✅ .env file created. Please update with your settings."
fi

# Start server
echo "🚀 Starting server on port 3000..."
echo "📱 Admin Panel: http://localhost:3000"
echo "🔌 API: http://localhost:3000/api/"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

node server.js

