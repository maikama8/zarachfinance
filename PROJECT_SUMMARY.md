# Finance App - Project Summary

## Overview

A comprehensive mobile phone financing system for retail stores in Nigeria that enforces payment compliance through Android Device Admin controls. The system prevents unauthorized device usage, factory resets, and app removal until financing agreements are fully satisfied.

## System Components

### 1. Android Device Admin App (`android-app/`)

**Key Features:**
- ✅ Payment-based device locking (Requirement 1)
- ✅ Device administrator privileges enforcement (Requirement 2)
- ✅ Factory reset protection (Requirement 3)
- ✅ Location tracking every 12 hours (Requirement 4)
- ✅ Payment reminders (24h, 6h, overdue) (Requirement 5)
- ✅ In-app payment processing (Requirement 6)
- ✅ Remote policy configuration (Requirement 7)
- ✅ Tamper detection and security (Requirement 8)

**Core Components:**
- `DeviceAdminReceiver` - Manages device admin privileges
- `PaymentVerificationService` - Checks payment status every 6 hours
- `LocationTrackingService` - Tracks and reports device location
- `TamperDetectionService` - Monitors app integrity
- `PaymentReminderService` - Sends payment notifications
- `FactoryResetProtection` - Blocks factory reset attempts
- `LockScreenActivity` - Displays lock screen with payment info
- `PaymentActivity` - Handles in-app payments

### 2. Admin Panel with Integrated Backend (`admin-panel/`)

**Unified Server Architecture:**
- Single Express.js server handles both API and admin panel
- Node.js with Express
- MongoDB for data storage
- JWT for API authentication
- Session-based auth for admin panel
- Helmet.js for security headers
- Rate limiting for API protection

**Backend API Endpoints (`/api/*`):**
- `/api/auth/*` - Authentication (login, register)
- `/api/payment/*` - Payment processing with Paystack/Flutterwave
- `/api/device/*` - Device location and status reporting
- `/api/admin/*` - Admin device management and gateway configuration

**Admin Panel Pages:**
- `/` - Login page
- `/dashboard` - Main dashboard for device management
- `/settings` - Payment gateway configuration

**Key Features:**
- RESTful API design
- Device and payment management
- Location history tracking
- Payment schedule management
- Policy configuration
- Remote device unlocking
- Payment gateway integration (Paystack & Flutterwave)
- Web-based admin interface
- Real-time device status
- Custom message sending
- Device creation and configuration

**Technology:**
- Express server with unified API and frontend
- HTML/CSS/JavaScript frontend
- Direct database access (no API proxy needed)
- Payment gateway service integration

## Requirements Compliance

### ✅ Requirement 1: Payment-Based Device Locking
- Device locks within 24 hours of missed payment
- Payment reminder screen with store contact
- Unlocks within 5 minutes of payment confirmation
- Checks payment status every 6 hours
- Emergency calls remain functional

### ✅ Requirement 2: Device Administrator Privileges
- Requests admin privileges on installation
- Prevents deactivation during financing
- Blocks uninstallation until fully paid
- Allows removal after release code entry

### ✅ Requirement 3: Factory Reset Protection
- Intercepts factory reset attempts
- Blocks resets through settings
- Blocks resets through recovery mode
- Maintains protection after reboots
- Enables reset after release code

### ✅ Requirement 4: Location Tracking
- Records location every 12 hours
- Stores 30 days of payment status locally
- Displays balance and schedule in app
- Syncs with backend when online
- Queues updates when offline

### ✅ Requirement 5: Payment Reminders
- Notification 24 hours before due date
- Notification 6 hours before due date
- Notification when overdue
- Confirmation notification after payment
- Payment schedule view in app

### ✅ Requirement 6: In-App Payments
- Payment interface with mobile money support
- Transmits payment within 10 seconds
- Confirmation within 2 minutes
- Error handling with retry options
- Transaction history maintained

### ✅ Requirement 7: Remote Configuration
- Receives policy updates within 1 hour
- Remote payment schedule modification
- Manual unlock within 5 minutes
- Custom message display on locked devices
- Daily device status reporting

### ✅ Requirement 8: Security & Tamper Resistance
- Detects app modification attempts
- Locks device on tampering detection
- TLS 1.3 encryption for API communication
- Code integrity validation on launch
- Android Keystore for sensitive data

## Security Features

1. **Encryption:**
   - Android Keystore for device-side encryption
   - TLS 1.3 for network communication
   - Encrypted SharedPreferences for sensitive data

2. **Authentication:**
   - JWT tokens for admin access
   - API keys for device communication
   - Session management for admin panel

3. **Tamper Detection:**
   - App signature verification
   - Root detection
   - Device admin status monitoring
   - Code integrity checks

4. **Network Security:**
   - Rate limiting
   - Helmet.js security headers
   - Input validation
   - Error handling

## File Structure

```
Financeapp/
├── android-app/              # Android application
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── java/com/financeapp/deviceadmin/
│   │   │   │   ├── admin/          # Device admin components
│   │   │   │   ├── api/            # API client and models
│   │   │   │   ├── receiver/       # Broadcast receivers
│   │   │   │   ├── service/        # Background services
│   │   │   │   ├── ui/             # Activities
│   │   │   │   └── util/           # Utilities
│   │   │   └── res/                # Resources
│   │   └── build.gradle
│   └── build.gradle
├── backend/                  # Node.js API
│   ├── models/              # MongoDB models
│   ├── routes/              # API routes
│   ├── middleware/          # Auth and validation
│   ├── server.js            # Main server file
│   └── package.json
├── admin-panel/             # Web dashboard
│   ├── public/              # Frontend files
│   ├── server.js            # Express server
│   └── package.json
├── README.md
├── SETUP.md                 # Setup instructions
└── PROJECT_SUMMARY.md       # This file
```

## Next Steps for Deployment

1. **Backend:**
   - Set up MongoDB database
   - Configure environment variables
   - Set up SSL certificates
   - Deploy to production server

2. **Android App:**
   - Update API endpoint in Config.kt
   - Build release APK with signing
   - Test on physical devices
   - Publish to internal distribution

3. **Admin Panel:**
   - Configure API endpoint
   - Set up HTTPS
   - Deploy to web server

4. **Security Hardening:**
   - Change all default passwords
   - Rotate API keys
   - Enable MongoDB authentication
   - Set up monitoring and logging

## Testing Checklist

- [ ] Device locks on overdue payment
- [ ] Device unlocks after payment
- [ ] Factory reset is blocked
- [ ] Device admin cannot be disabled
- [ ] Location tracking works
- [ ] Payment reminders are sent
- [ ] In-app payments process correctly
- [ ] Admin panel can manage devices
- [ ] Remote unlock works
- [ ] Tamper detection triggers lock

## Support & Maintenance

- Monitor backend logs for errors
- Check device status in admin panel
- Review payment history regularly
- Update app version as needed
- Rotate API keys periodically

## License

This project is proprietary software for retail store use.

