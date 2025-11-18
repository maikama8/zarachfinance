# ZarFinance Admin Panel

Unified admin panel and backend API server for ZarFinance device admin system.

## Overview

This is a **unified server** that combines:
- **Backend API** - RESTful API for Android app communication
- **Admin Dashboard** - Web interface for managing devices and payments
- **Payment Gateway Integration** - Paystack and Flutterwave support

All functionality runs on a single Express.js server.

## Quick Start

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Configure environment** (create `.env` file):
   ```
   PORT=3000
   NODE_ENV=production
   MONGODB_URI=mongodb://localhost:27017/zarfinance
   JWT_SECRET=your-very-secure-secret-key
   JWT_EXPIRES_IN=7d
   SESSION_SECRET=your-session-secret
   ALLOWED_ORIGINS=http://localhost:3000
   ```

3. **Start MongoDB**:
   ```bash
   mongod
   ```

4. **Start the server**:
   ```bash
   npm start
   # or for development
   npm run dev
   ```

5. **Access the admin panel**:
   - Open `http://localhost:3000` in your browser
   - Register first admin account via API or login if already created

## Project Structure

```
admin-panel/
├── models/              # MongoDB models (Device, Admin, Payment, PaymentGateway)
├── routes/              # API route handlers
│   ├── auth.js         # Authentication routes
│   ├── payment.js       # Payment processing routes
│   ├── device.js       # Device management routes
│   └── admin.js        # Admin panel routes
├── middleware/          # Auth and validation middleware
├── services/            # Business logic services
│   └── paymentGateway.js  # Paystack & Flutterwave integration
├── public/              # Admin panel frontend
│   ├── login.html      # Login page
│   ├── dashboard.html   # Main dashboard
│   └── settings.html    # Payment gateway settings
└── server.js            # Main server file (API + Admin Panel)
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - Admin login
- `POST /api/auth/register` - Register new admin
- `GET /api/auth/me` - Get current admin info

### Payment
- `GET /api/payment/status/:deviceId` - Get payment status
- `POST /api/payment/initialize` - Initialize payment with gateway
- `POST /api/payment/verify` - Verify payment after gateway processing
- `POST /api/payment/process` - Direct payment processing (legacy)
- `GET /api/payment/history/:deviceId` - Get payment history
- `GET /api/payment/schedule/:deviceId` - Get payment schedule
- `POST /api/payment/webhook/:gateway` - Payment gateway webhooks

### Device
- `POST /api/device/location` - Report device location
- `GET /api/device/status/:deviceId` - Get device status
- `POST /api/device/report` - Report device status

### Admin
- `GET /api/admin/devices` - Get all devices
- `GET /api/admin/devices/:deviceId` - Get device details
- `POST /api/admin/devices` - Create new device
- `PUT /api/admin/devices/:deviceId/policy` - Update device policy
- `POST /api/admin/unlock` - Unlock device manually
- `POST /api/admin/message` - Send message to device
- `GET /api/admin/payment-gateway` - Get payment gateway config
- `PUT /api/admin/payment-gateway/:gateway` - Update gateway config
- `POST /api/admin/payment-gateway/:gateway/activate` - Activate gateway

## Authentication

- **Admin Panel**: Uses session-based authentication (cookies)
- **API Requests**: Uses API keys in `X-API-Key` header for device requests, JWT tokens for admin API requests

## Payment Gateways

The system supports Paystack and Flutterwave payment gateways:

1. Configure gateways in Settings page (`/settings`)
2. Set one gateway as active
3. Payments are automatically processed through the active gateway

## Database

Uses MongoDB with the following collections:
- `devices` - Device and customer information
- `admins` - Admin user accounts
- `payments` - Payment transaction records
- `paymentgateways` - Payment gateway configurations

## Security Features

- Helmet.js for security headers
- Rate limiting on API endpoints
- CORS configuration
- JWT token authentication
- Session-based admin authentication
- Input validation with express-validator

## Development

```bash
# Install dependencies
npm install

# Run in development mode (with auto-reload)
npm run dev

# Run in production mode
npm start
```

## Production Deployment

1. Set `NODE_ENV=production` in `.env`
2. Use a process manager like PM2:
   ```bash
   pm2 start server.js --name zarfinance
   ```
3. Configure reverse proxy (nginx) if needed
4. Set up SSL/TLS certificates
5. Configure MongoDB authentication
6. Update `ALLOWED_ORIGINS` with your domain

## Notes

- All prices are in Naira (₦)
- Payment amounts are automatically converted to kobo/pesewas for gateways
- Only one payment gateway can be active at a time
- Webhook support included for automatic payment verification
