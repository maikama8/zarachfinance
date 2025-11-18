# ZarFinance Architecture

## Unified Server Architecture

ZarFinance uses a **unified server architecture** where all backend functionality is integrated into the admin panel server. This simplifies deployment, maintenance, and reduces complexity.

## System Components

### 1. Android App (`android-app/`)
- Package: `com.zarfinance.admin`
- App Name: ZarFinance
- Communicates with unified server via REST API
- Uses API key authentication

### 2. Admin Panel Server (`admin-panel/`)
**Single Express.js server that handles everything:**

#### Backend API (`/api/*`)
- Authentication endpoints
- Payment processing (with Paystack/Flutterwave)
- Device management
- Location tracking
- Admin operations

#### Admin Dashboard (`/`, `/dashboard`, `/settings`)
- Web-based interface
- Session-based authentication
- Device management UI
- Payment gateway configuration
- Real-time monitoring

#### Services
- Payment gateway integration (Paystack & Flutterwave)
- Database models (MongoDB)
- Business logic

## Server Structure

```
admin-panel/
├── server.js           # Main server (handles API + Admin Panel)
├── models/             # Database models
│   ├── Device.js
│   ├── Admin.js
│   ├── Payment.js
│   └── PaymentGateway.js
├── routes/             # API route handlers
│   ├── auth.js
│   ├── payment.js
│   ├── device.js
│   └── admin.js
├── middleware/         # Auth & validation
│   └── auth.js
├── services/           # Business logic
│   └── paymentGateway.js
└── public/             # Admin panel frontend
    ├── login.html
    ├── dashboard.html
    └── settings.html
```

## Request Flow

### Android App Requests
```
Android App → API Endpoint (/api/*) → Route Handler → Service → Database
```

### Admin Panel Requests
```
Browser → Admin Page (/dashboard) → API Endpoint (/api/*) → Route Handler → Database
```

## Authentication

### Android App
- Uses API key in `X-API-Key` header
- API key stored in Admin model
- No session required

### Admin Panel
- Session-based authentication (cookies)
- JWT tokens for API calls (handled automatically)
- Login via `/api/auth/login`

## Database

Single MongoDB database (`zarfinance`) with collections:
- `devices` - Device and customer data
- `admins` - Admin user accounts
- `payments` - Payment transactions
- `paymentgateways` - Gateway configurations

## Deployment

### Single Server Deployment
1. Deploy `admin-panel/` directory
2. Configure environment variables
3. Start single server process
4. All functionality available on one port

### Benefits
- ✅ Simplified deployment
- ✅ Single codebase to maintain
- ✅ Shared authentication
- ✅ Easier debugging
- ✅ Reduced infrastructure costs

## Port Configuration

Default port: **3000**

- Admin Panel: `http://localhost:3000`
- API Endpoints: `http://localhost:3000/api/*`
- Dashboard: `http://localhost:3000/dashboard`
- Settings: `http://localhost:3000/settings`

## Legacy Backend Directory

The `backend/` directory exists but is **not used**. All functionality has been migrated to `admin-panel/`. You can safely ignore or remove this directory.

