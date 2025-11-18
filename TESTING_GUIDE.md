# Testing Guide

## Web Portal Testing

### 1. Start the Server
```bash
cd admin-panel
npm install  # If not already installed
node server.js
```

Server should start on `http://localhost:3000`

### 2. Test Login
1. Open browser: `http://localhost:3000`
2. Login with admin credentials
3. Should redirect to dashboard

### 3. Test Dashboard
- Check real-time stats load
- Verify charts display
- Check Socket.IO connection (open browser console)
- Test auto-refresh on updates

### 4. Test Device Management
- Navigate to `/devices`
- Test device list loading
- Test search and filtering
- Test bulk operations
- Test lock/unlock functionality

### 5. Test Customer Management
- Navigate to `/customers`
- Test customer list
- Test adding new customer
- Test KYC status

### 6. Test Payment Management
- Navigate to `/payments`
- Check payment history
- Verify payment charts
- Test date filtering

### 7. Test Real-time Updates
1. Open admin panel in browser
2. Make a payment from mobile app (or simulate)
3. Dashboard should auto-refresh
4. Check browser console for Socket.IO messages

## Mobile App Testing

### 1. Build APK
```bash
cd flutter-app
flutter clean
flutter pub get
flutter build apk --release
```

APK will be in: `build/app/outputs/flutter-apk/app-release.apk`

### 2. Install on Device
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 3. Test Flashing Protection
1. Enable USB debugging
2. Connect to computer
3. App should detect and lock device
4. Check logs: `adb logcat | grep FlashingProtection`

### 4. Test Device Admin
1. Launch app
2. Grant device admin privileges
3. Test device lock functionality

### 5. Test Payment Flow
1. Make a payment
2. Verify payment history updates
3. Check real-time sync with admin panel

### 6. Test Real-time Updates
1. Lock device from admin panel
2. Mobile app should receive update
3. Device should lock automatically

## Common Issues

### Server Won't Start
- Check MongoDB connection
- Verify PORT is not in use
- Check .env file exists

### Socket.IO Not Working
- Check browser console for errors
- Verify Socket.IO script loads
- Check CORS settings

### Mobile App Can't Connect
- Verify API URL in config.dart
- Check device and server on same network
- Test with curl from device

### Flashing Protection Not Working
- Check Device Admin is enabled
- Verify service is running
- Check logs for errors

