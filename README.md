# ZarFinance - Device Admin Application

A comprehensive mobile phone financing system for retail stores in Nigeria, featuring device admin controls, payment enforcement, and an integrated admin panel with backend API.

## Project Structure

```
Financeapp/
├── android-app/          # Android Device Admin Application (ZarFinance)
├── admin-panel/          # Admin Panel with Integrated Backend API
│   ├── models/          # Database models
│   ├── routes/          # API routes
│   ├── middleware/      # Authentication & validation
│   ├── services/        # Business logic (payment gateways)
│   ├── public/          # Admin panel frontend
│   └── server.js        # Unified server (API + Admin Panel)
└── README.md
```

## Features

### Android App (ZarFinance)
- Payment-based device locking
- Device administrator privileges enforcement
- Factory reset protection
- Location tracking
- Payment reminders and notifications
- In-app payment processing (Paystack/Flutterwave)
- Remote configuration
- Tamper detection and security

### Admin Panel (Unified Backend + Frontend)
- **RESTful API** for mobile app communication
- **Admin Dashboard** for device management
- **Payment Gateway Integration** (Paystack & Flutterwave)
- **Payment tracking** and history
- **Policy configuration**
- **Location monitoring**
- **User and customer management**
- **Payment gateway settings**

## Getting Started

### Quick Start

1. **Setup Admin Panel (includes backend)**:
   ```bash
   cd admin-panel
   npm install
   cp .env.example .env  # Configure your environment
   npm start
   ```

2. **Setup Android App**:
   - Open `android-app` in Android Studio
   - Update API endpoint in `Config.kt`
   - Build and install on device

See `SETUP.md` for detailed instructions.

## Architecture

The system uses a **unified server architecture** where the admin panel and backend API are integrated into a single Express.js server. This simplifies deployment and maintenance:

- **Single Server**: One Node.js server handles both API requests and serves the admin panel
- **Single Database**: MongoDB database for all data
- **Single Port**: One port (default 3000) for all services
- **Unified Authentication**: Session-based auth for admin panel, API keys for mobile app

