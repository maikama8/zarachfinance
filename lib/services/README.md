# API Services Documentation

This directory contains the API client and service classes for communicating with the backend Finance System.

## Overview

The API layer consists of:
- **ApiClient**: Core HTTP client with interceptors for authentication, logging, and retry logic
- **PaymentApiService**: Handles payment-related endpoints
- **DeviceApiService**: Handles device registration, status updates, and location tracking
- **Custom Exceptions**: Typed exceptions for better error handling

## Setup

### 1. Initialize the API Client

Before making any API calls, initialize the API client in your app's main function:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API client
  ApiClient().initialize(enableCertificatePinning: true);
  
  runApp(MyApp());
}
```

### 2. Configure Base URL

Update the base URL in `lib/services/api_client.dart`:

```dart
static const String _baseUrl = 'https://your-backend-api.com';
```

### 3. Add SSL Certificate (for Certificate Pinning)

1. Obtain your backend's SSL certificate in PEM format
2. Replace the placeholder in `assets/certificates/backend_cert.pem`
3. For testing, you can disable certificate pinning:

```dart
ApiClient().initialize(enableCertificatePinning: false);
```

## Usage Examples

### Payment API Service

```dart
final paymentService = PaymentApiService();

// Get payment status
try {
  final status = await paymentService.getPaymentStatus(deviceId);
  print('Remaining balance: ${status.remainingBalance}');
} on NetworkException catch (e) {
  print('Network error: ${e.message}');
} on PaymentException catch (e) {
  print('Payment error: ${e.message}');
}

// Submit a payment
try {
  final result = await paymentService.submitPayment(
    deviceId: deviceId,
    amount: 5000.0,
    method: 'mobile_money',
    metadata: {'provider': 'MTN'},
  );
  print('Payment successful: ${result.transactionId}');
} catch (e) {
  print('Payment failed: $e');
}

// Get payment schedule
final schedule = await paymentService.getPaymentSchedule(deviceId);
print('Total installments: ${schedule.totalInstallments}');

// Verify release code
final verification = await paymentService.verifyReleaseCode(
  deviceId: deviceId,
  code: 'ABC123XYZ456',
);
if (verification.isValid) {
  print('Release code valid - device can be released');
}
```

### Device API Service

```dart
final deviceService = DeviceApiService();

// Register device
final registrationRequest = DeviceRegistrationRequest(
  imei: '123456789012345',
  androidId: 'android_id_here',
  model: 'Samsung Galaxy A10',
  manufacturer: 'Samsung',
  osVersion: 'Android 11',
  appVersion: '1.0.0',
  deviceFingerprint: 'unique_fingerprint',
  customerId: 'customer_123',
);

final registration = await deviceService.registerDevice(registrationRequest);
// Store JWT token
await SecureStorageService().storeJwtToken(registration.jwtToken);

// Update device status
await deviceService.updateDeviceStatus(
  deviceId: deviceId,
  statusUpdate: DeviceStatusUpdate(
    status: 'LOCKED',
    lockReason: 'Payment overdue',
    timestamp: DateTime.now(),
  ),
);

// Send location
await deviceService.sendLocation(
  deviceId: deviceId,
  location: LocationData(
    latitude: 6.5244,
    longitude: 3.3792,
    accuracy: 10.0,
    timestamp: DateTime.now(),
  ),
);

// Report tampering
await deviceService.reportTamper(
  deviceId: deviceId,
  alert: TamperAlert(
    tamperType: 'ROOT_DETECTED',
    description: 'Device root access detected',
    timestamp: DateTime.now(),
  ),
);

// Check for remote commands
final commands = await deviceService.checkRemoteCommands(deviceId);
for (final command in commands) {
  if (command['type'] == 'UNLOCK') {
    // Execute unlock
    await deviceService.acknowledgeCommand(
      deviceId: deviceId,
      commandId: command['id'],
      success: true,
    );
  }
}
```

## Error Handling

The API services throw typed exceptions for better error handling:

```dart
try {
  await paymentService.submitPayment(...);
} on NetworkException catch (e) {
  // Handle network errors (no connection, timeout)
  showSnackbar('No internet connection');
} on AuthException catch (e) {
  // Handle authentication errors (401, 403)
  navigateToLogin();
} on PaymentException catch (e) {
  // Handle payment-specific errors
  showDialog('Payment failed: ${e.failureReason}');
} on ServerException catch (e) {
  // Handle server errors (5xx)
  showSnackbar('Server error, please try again later');
} on ApiException catch (e) {
  // Handle generic API errors
  showSnackbar('Error: ${e.message}');
}
```

## Features

### Authentication Interceptor
- Automatically adds JWT token to all requests
- Adds device ID to request headers
- Handles 401 authentication errors

### Logging Interceptor
- Logs all requests and responses for debugging
- Includes headers, query parameters, and request/response data
- Can be disabled in production by removing from interceptor chain

### Retry Interceptor
- Automatically retries failed requests up to 3 times
- Uses exponential backoff (1s, 2s, 4s)
- Only retries on network errors and 5xx server errors
- Does not retry on client errors (4xx)

### Certificate Pinning
- Validates server SSL certificate against pinned certificate
- Prevents man-in-the-middle attacks
- Can be disabled for testing/development

## Configuration

### Timeouts
- Connect timeout: 30 seconds
- Receive timeout: 60 seconds

### Retry Configuration
- Max retries: 3
- Initial delay: 1 second
- Backoff strategy: Exponential (1s, 2s, 4s)

### Headers
All requests include:
- `Content-Type: application/json`
- `Accept: application/json`
- `Authorization: Bearer <token>` (if available)
- `X-Device-ID: <device_id>` (if available)

## Testing

For testing purposes, you can:

1. Disable certificate pinning:
```dart
ApiClient().initialize(enableCertificatePinning: false);
```

2. Update base URL for staging environment:
```dart
ApiClient().updateBaseUrl('https://staging-api.example.com');
```

3. Add custom headers:
```dart
ApiClient().addHeader('X-Test-Mode', 'true');
```

## Security Notes

1. **Always use HTTPS** in production
2. **Enable certificate pinning** in production builds
3. **Store JWT tokens securely** using SecureStorageService
4. **Never log sensitive data** in production (remove logging interceptor)
5. **Validate all user inputs** before sending to API
6. **Handle errors gracefully** without exposing sensitive information

## Backend API Requirements

The backend must implement the following endpoints:

### Payment Endpoints
- `GET /api/v1/device/{deviceId}/payment-status`
- `POST /api/v1/device/{deviceId}/payment`
- `GET /api/v1/device/{deviceId}/schedule`
- `POST /api/v1/device/{deviceId}/verify-release-code`
- `GET /api/v1/device/{deviceId}/payment-history`

### Device Endpoints
- `POST /api/v1/device/register`
- `PUT /api/v1/device/{deviceId}/status`
- `POST /api/v1/device/{deviceId}/location`
- `POST /api/v1/device/{deviceId}/report`
- `POST /api/v1/device/{deviceId}/tamper-alert`
- `GET /api/v1/device/{deviceId}/config`
- `GET /api/v1/device/{deviceId}/commands`
- `POST /api/v1/device/{deviceId}/commands/{commandId}/acknowledge`
- `DELETE /api/v1/device/{deviceId}`

All endpoints should:
- Accept JSON request bodies
- Return JSON responses
- Use JWT authentication (except registration)
- Return appropriate HTTP status codes
- Include error messages in response body
