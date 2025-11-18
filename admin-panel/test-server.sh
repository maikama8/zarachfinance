#!/bin/bash

echo "=== ZarFinance Admin Panel Test Script ==="
echo ""

# Check if server is running
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Server is running on port 3000"
else
    echo "❌ Server is not running. Starting server..."
    cd "$(dirname "$0")"
    node server.js &
    sleep 3
fi

echo ""
echo "=== Testing Endpoints ==="
echo ""

# Test health endpoint
echo "1. Health Check:"
curl -s http://localhost:3000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:3000/health
echo ""
echo ""

# Test login page
echo "2. Login Page (should return HTML):"
curl -s http://localhost:3000/ | head -5
echo ""
echo ""

# Test API endpoints (will fail without MongoDB)
echo "3. API Endpoints (require MongoDB):"
echo "   - Register: POST /api/auth/register"
echo "   - Login: POST /api/auth/login"
echo "   - Devices: GET /api/admin/devices"
echo ""

# Check MongoDB connection
if curl -s http://localhost:3000/api/auth/register -X POST -H "Content-Type: application/json" -d '{"test":"test"}' 2>&1 | grep -q "MongoDB\|connection"; then
    echo "⚠️  MongoDB connection issue detected"
    echo "   Start MongoDB with: mongod"
    echo "   Or: brew services start mongodb-community"
else
    echo "✅ API endpoints responding"
fi

echo ""
echo "=== Access Points ==="
echo "  Admin Panel: http://localhost:3000"
echo "  Dashboard:   http://localhost:3000/dashboard"
echo "  Settings:    http://localhost:3000/settings"
echo "  Health:      http://localhost:3000/health"
echo ""

