# Finance App - Setup Guide

Complete setup instructions for the Finance App Device Admin System.

## Architecture Overview

The system consists of two main components:
1. **Android App (ZarFinance)** - Device admin application installed on financed devices
2. **Admin Panel (Unified Server)** - Single Node.js/Express server that includes:
   - Backend API for Android app communication
   - Admin Dashboard web interface
   - Payment gateway integration
   - All business logic and database models

**Note**: The `backend/` directory in the project is legacy/unused. All functionality is now integrated into `admin-panel/`.

## Prerequisites

- Node.js 16+ and npm
- MongoDB 4.4+
- Android Studio (for Android app development)
- Android device with API level 24+ (Android 7.0+)

## Admin Panel Setup (Unified Backend + Frontend)

The admin panel includes both the backend API and the admin dashboard in a single server.

1. Navigate to admin-panel directory:
```bash
cd admin-panel
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```bash
# Create .env file with the following:
PORT=3000
NODE_ENV=production
MONGODB_URI=mongodb://localhost:27017/zarfinance
JWT_SECRET=your-very-secure-secret-key-change-this
JWT_EXPIRES_IN=7d
SESSION_SECRET=your-session-secret-for-admin-panel
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com
```

4. Start MongoDB:
```bash
mongod
```

5. Start the unified server:
```bash
npm start
```

The server will be available at `http://localhost:3000`:
- **Admin Panel**: `http://localhost:3000` (login page)
- **Dashboard**: `http://localhost:3000/dashboard`
- **Settings**: `http://localhost:3000/settings`
- **API Endpoints**: `http://localhost:3000/api/*`

6. Register the first admin account:
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@store.com",
    "password": "securepassword",
    "name": "Store Owner",
    "storeName": "My Store"
  }'
```

7. Login to the admin panel at `http://localhost:3000` with your credentials.

## Android App Setup

1. Open Android Studio

2. Open the `android-app` directory as a project

3. Update `Config.kt` with your API endpoint:
```kotlin
const val API_BASE_URL = "https://your-api-domain.com/api/"
```

4. Build and install the app on a test device:
   - Connect Android device or start emulator
   - Run the app from Android Studio
   - Grant all required permissions when prompted

5. On first launch:
   - The app will request Device Administrator privileges
   - Grant the privileges to enable device locking features
   - The app will register with the backend using the device ID

## Initial Configuration

### Configure Payment Gateways

1. Login to the admin panel at `http://localhost:3000`
2. Navigate to Settings page
3. Configure Paystack or Flutterwave:
   - Enter Public Key
   - Enter Secret Key
   - Enter Webhook Secret (optional)
   - Set as Active Gateway
4. Save configuration

### Create a Device Financing Agreement

1. Login to the admin panel at `http://localhost:3000`

2. Click "Add New Device"

3. Fill in the device information:
   - Device ID (use the Android ID from the device)
   - Customer details
   - Total amount
   - Payment schedule (JSON format)

4. Save the Release Code - this will be needed when the device is fully paid.

## Security Considerations

### Production Deployment

1. **Backend Security**:
   - Use HTTPS with valid SSL certificates
   - Change all default passwords and secrets
   - Enable MongoDB authentication
   - Use environment variables for sensitive data
   - Implement rate limiting (already included)
   - Use Helmet.js security headers (already included)

2. **Android App Security**:
   - Enable ProGuard/R8 code obfuscation
   - Use certificate pinning for API calls
   - Store sensitive data in Android Keystore (already implemented)
   - Validate app signatures on launch (already implemented)

3. **Network Security**:
   - All API communication should use TLS 1.3
   - Implement API key rotation
   - Use JWT tokens with short expiration times

## API Authentication

### Device Requests
Devices use API keys in the `X-API-Key` header:
```
X-API-Key: your-api-key-here
```

### Admin Requests
Admin endpoints require JWT tokens (automatically handled via session for web interface):
```
Authorization: Bearer your-jwt-token-here
```

Note: The admin panel web interface uses session-based authentication, so you don't need to manually add tokens when using the dashboard.

## Testing

### Test Payment Flow

1. Create a test device in the admin panel
2. Set up a payment schedule with a due date in the past
3. The device should lock automatically after the payment deadline
4. Process a payment through the app
5. Device should unlock within 5 minutes

### Test Factory Reset Protection

1. Attempt to factory reset through device settings
2. The reset should be blocked
3. Enter the release code (after full payment)
4. Factory reset should now be allowed

## Troubleshooting

### Device Not Locking
- Check if Device Admin privileges are active
- Verify payment status in admin panel
- Check device logs for errors

### API Connection Issues
- Verify API_BASE_URL in Config.kt
- Check network connectivity
- Verify API key is correct

### Admin Panel Not Loading
- Check backend is running
- Verify API_BASE_URL in admin-panel .env
- Check browser console for errors

## Support

For issues or questions, check the logs:
- Backend: Console output
- Android: `adb logcat | grep FinanceApp`
- Admin Panel: Browser console

