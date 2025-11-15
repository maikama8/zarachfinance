# Backend API Requirements

## Overview

This document specifies the backend API requirements for the Device Admin App. The backend system (Finance System) must implement these endpoints to support device registration, payment processing, status monitoring, and remote device management.

## API Base Configuration

### Base URL
```
https://api.yourcompany.com/api/v1
```

### Authentication
- **Method:** JWT (JSON Web Tokens)
- **Header:** `Authorization: Bearer <token>`
- **Token Expiration:** 30 days
- **Token Rotation:** Automatic on expiration

### Request/Response Format
- **Content-Type:** `application/json`
- **Character Encoding:** UTF-8
- **Date Format:** ISO 8601 (e.g., `2024-01-15T10:30:00Z`)

### Rate Limiting
- **Default:** 100 requests per minute per device
- **Burst:** 20 requests per second
- **Response Header:** `X-RateLimit-Remaining`, `X-RateLimit-Reset`

### SSL/TLS Requirements
- **Minimum Version:** TLS 1.3
- **Certificate Pinning:** Required
- **Certificate Format:** X.509
- **Certificate Validity:** Minimum 90 days remaining

## Authentication Endpoints

### 1. Device Registration

**Endpoint:** `POST /device/register`

**Description:** Register a new device with the Finance System

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "deviceId": "string (UUID)",
  "imei": "string (15 digits)",
  "androidId": "string",
  "deviceModel": "string",
  "manufacturer": "string",
  "androidVersion": "string",
  "appVersion": "string",
  "customerId": "string",
  "storeId": "string",
  "registrationDate": "ISO 8601 datetime"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "deviceId": "string (UUID)",
  "token": "string (JWT)",
  "tokenExpiry": "ISO 8601 datetime",
  "paymentSchedule": {
    "scheduleId": "string",
    "totalAmount": "number",
    "paidAmount": "number",
    "remainingAmount": "number",
    "installments": [
      {
        "installmentId": "string",
        "dueDate": "ISO 8601 datetime",
        "amount": "number",
        "status": "PENDING|PAID|OVERDUE"
      }
    ]
  },
  "deviceConfig": {
    "lockGracePeriod": "number (hours)",
    "paymentCheckInterval": "number (hours)",
    "locationUpdateInterval": "number (hours)",
    "statusReportInterval": "number (hours)"
  }
}
```

**Error Responses:**
- `400 Bad Request`: Invalid device information
- `409 Conflict`: Device already registered
- `500 Internal Server Error`: Server error

### 2. Token Refresh

**Endpoint:** `POST /device/token/refresh`

**Description:** Refresh expired JWT token

**Request Headers:**
```
Authorization: Bearer <expired_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "deviceId": "string (UUID)"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "token": "string (JWT)",
  "tokenExpiry": "ISO 8601 datetime"
}
```

## Payment Endpoints

### 3. Get Payment Status

**Endpoint:** `GET /device/{deviceId}/payment-status`

**Description:** Check current payment status for a device

**Request Headers:**
```
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "deviceId": "string",
  "status": "ACTIVE|LOCKED|PAID_OFF|DEFAULTED",
  "totalAmount": "number",
  "paidAmount": "number",
  "remainingAmount": "number",
  "nextPaymentDue": "ISO 8601 datetime",
  "nextPaymentAmount": "number",
  "isOverdue": "boolean",
  "overdueAmount": "number",
  "overdueSince": "ISO 8601 datetime",
  "lastPaymentDate": "ISO 8601 datetime",
  "lastPaymentAmount": "number",
  "shouldLock": "boolean",
  "lockReason": "string"
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid or expired token
- `404 Not Found`: Device not found
- `500 Internal Server Error`: Server error

### 4. Submit Payment

**Endpoint:** `POST /device/{deviceId}/payment`

**Description:** Process a payment from the device

**Request Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": "number",
  "method": "BANK_TRANSFER|MOBILE_MONEY|USSD|CARD",
  "transactionReference": "string",
  "timestamp": "ISO 8601 datetime",
  "metadata": {
    "provider": "string (e.g., MTN, Airtel)",
    "phoneNumber": "string (optional)",
    "accountNumber": "string (optional)"
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "transactionId": "string (UUID)",
  "status": "SUCCESS|PENDING|FAILED",
  "amount": "number",
  "newBalance": "number",
  "remainingAmount": "number",
  "nextPaymentDue": "ISO 8601 datetime",
  "receiptUrl": "string (URL)",
  "message": "string"
}
```

**Response (202 Accepted):** For pending payments
```json
{
  "success": true,
  "transactionId": "string (UUID)",
  "status": "PENDING",
  "message": "Payment is being processed",
  "estimatedCompletionTime": "ISO 8601 datetime"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid payment data
- `402 Payment Required`: Payment gateway error
- `409 Conflict`: Duplicate transaction
- `500 Internal Server Error`: Server error

### 5. Get Payment Schedule

**Endpoint:** `GET /device/{deviceId}/schedule`

**Description:** Retrieve complete payment schedule

**Request Headers:**
```
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "scheduleId": "string",
  "deviceId": "string",
  "totalAmount": "number",
  "paidAmount": "number",
  "remainingAmount": "number",
  "startDate": "ISO 8601 datetime",
  "endDate": "ISO 8601 datetime",
  "frequency": "DAILY|WEEKLY|MONTHLY",
  "installments": [
    {
      "installmentId": "string",
      "sequenceNumber": "number",
      "dueDate": "ISO 8601 datetime",
      "amount": "number",
      "status": "PENDING|PAID|OVERDUE",
      "paidDate": "ISO 8601 datetime",
      "paidAmount": "number",
      "transactionId": "string"
    }
  ]
}
```

### 6. Get Payment History

**Endpoint:** `GET /device/{deviceId}/payment-history`

**Description:** Retrieve payment transaction history

**Request Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit`: number (default: 50, max: 100)
- `offset`: number (default: 0)
- `startDate`: ISO 8601 datetime (optional)
- `endDate`: ISO 8601 datetime (optional)

**Response (200 OK):**
```json
{
  "success": true,
  "total": "number",
  "limit": "number",
  "offset": "number",
  "transactions": [
    {
      "transactionId": "string",
      "amount": "number",
      "method": "string",
      "status": "SUCCESS|FAILED|PENDING",
      "timestamp": "ISO 8601 datetime",
      "reference": "string",
      "receiptUrl": "string"
    }
  ]
}
```

### 7. Verify Release Code

**Endpoint:** `POST /device/{deviceId}/verify-release-code`

**Description:** Validate release code for device unlock

**Request Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "releaseCode": "string (12 alphanumeric characters)"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "valid": true,
  "message": "Release code verified successfully",
  "deviceReleased": true,
  "releaseDate": "ISO 8601 datetime"
}
```

**Response (400 Bad Request):**
```json
{
  "success": false,
  "valid": false,
  "message": "Invalid or expired release code",
  "reason": "INVALID_CODE|EXPIRED|ALREADY_USED|PAYMENT_INCOMPLETE"
}
```

## Device Management Endpoints

### 8. Update Device Status

**Endpoint:** `POST /device/{deviceId}/status`

**Description:** Report device status to backend

**Request Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "status": "ACTIVE|LOCKED|UNLOCKED",
  "appVersion": "string",
  "androidVersion": "string",
  "batteryLevel": "number (0-100)",
  "isCharging": "boolean",
  "storageAvailable": "number (bytes)",
  "lastBootTime": "ISO 8601 datetime",
  "lockState": "boolean",
  "lockReason": "string (optional)",
  "timestamp": "ISO 8601 datetime"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Status updated successfully",
  "commands": [
    {
      "commandId": "string",
      "type": "LOCK|UNLOCK|UPDATE_CONFIG|DISPLAY_MESSAGE",
      "payload": "object",
      "priority": "HIGH|NORMAL|LOW"
    }
  ]
}
```

### 9. Send Location

**Endpoint:** `POST /device/{deviceId}/location`

**Description:** Report device location

**Request Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "latitude": "number",
  "longitude": "number",
  "accuracy": "number (meters)",
  "timestamp": "ISO 8601 datetime",
  "provider": "GPS|NETWORK|PASSIVE"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Location recorded successfully"
}
```

### 10. Report Tamper Attempt

**Endpoint:** `POST /device/{deviceId}/tamper-alert`

**Description:** Report security violation or tampering attempt

**Request Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "tamperType": "ROOT_DETECTED|APP_TAMPERED|DEBUGGER_ATTACHED|XPOSED_DETECTED",
  "details": "string",
  "timestamp": "ISO 8601 datetime",
  "deviceInfo": {
    "isRooted": "boolean",
    "bootloaderUnlocked": "boolean",
    "securityPatchLevel": "string"
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Tamper alert recorded",
  "action": "LOCK|MONITOR|ALERT_STORE",
  "lockDevice": "boolean"
}
```

## Policy Management Endpoints

### 11. Get Policy Updates

**Endpoint:** `GET /device/{deviceId}/policy`

**Description:** Retrieve current device policies

**Request Headers:**
```
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "policyVersion": "string",
  "lastUpdated": "ISO 8601 datetime",
  "policies": {
    "lockGracePeriod": "number (hours)",
    "paymentCheckInterval": "number (hours)",
    "locationUpdateInterval": "number (hours)",
    "statusReportInterval": "number (hours)",
    "networkGracePeriod": "number (hours)",
    "allowEmergencyCalls": "boolean",
    "customLockMessage": "string (optional)",
    "forceUpdate": "boolean",
    "minimumAppVersion": "string"
  }
}
```

### 12. Check for Remote Commands

**Endpoint:** `GET /device/{deviceId}/commands`

**Description:** Poll for pending remote commands

**Request Headers:**
```
Authorization: Bearer <token>
```

**Response (200 OK):**
```json
{
  "success": true,
  "commands": [
    {
      "commandId": "string (UUID)",
      "type": "LOCK|UNLOCK|UPDATE_CONFIG|DISPLAY_MESSAGE|FORCE_SYNC",
      "priority": "HIGH|NORMAL|LOW",
      "createdAt": "ISO 8601 datetime",
      "expiresAt": "ISO 8601 datetime",
      "payload": {
        "message": "string (for DISPLAY_MESSAGE)",
        "config": "object (for UPDATE_CONFIG)"
      }
    }
  ]
}
```

### 13. Acknowledge Command

**Endpoint:** `POST /device/{deviceId}/commands/{commandId}/acknowledge`

**Description:** Confirm command execution

**Request Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "status": "SUCCESS|FAILED",
  "message": "string",
  "executedAt": "ISO 8601 datetime",
  "error": "string (optional)"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Command acknowledged"
}
```

## Sync and Queue Endpoints

### 14. Batch Sync

**Endpoint:** `POST /device/{deviceId}/sync`

**Description:** Synchronize queued operations in batch

**Request Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "operations": [
    {
      "type": "PAYMENT|LOCATION|STATUS",
      "timestamp": "ISO 8601 datetime",
      "data": "object (type-specific data)"
    }
  ]
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "processed": "number",
  "failed": "number",
  "results": [
    {
      "index": "number",
      "success": "boolean",
      "message": "string",
      "transactionId": "string (optional)"
    }
  ]
}
```

## Error Response Format

All error responses follow this format:

```json
{
  "success": false,
  "error": {
    "code": "string (ERROR_CODE)",
    "message": "string (human-readable)",
    "details": "string (optional)",
    "timestamp": "ISO 8601 datetime"
  }
}
```

### Common Error Codes

- `INVALID_TOKEN`: JWT token is invalid or expired
- `DEVICE_NOT_FOUND`: Device ID not found in system
- `PAYMENT_FAILED`: Payment processing failed
- `DUPLICATE_TRANSACTION`: Transaction already processed
- `INVALID_REQUEST`: Request data validation failed
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `SERVER_ERROR`: Internal server error
- `SERVICE_UNAVAILABLE`: Service temporarily unavailable

## Webhook Notifications (Optional)

If the backend supports webhooks, the app can register for push notifications:

### 15. Register Webhook

**Endpoint:** `POST /device/{deviceId}/webhook`

**Request Body:**
```json
{
  "url": "string (HTTPS URL)",
  "events": ["PAYMENT_CONFIRMED", "LOCK_COMMAND", "UNLOCK_COMMAND", "POLICY_UPDATE"]
}
```

### Webhook Payload Format

```json
{
  "event": "string",
  "deviceId": "string",
  "timestamp": "ISO 8601 datetime",
  "data": "object (event-specific)"
}
```

## Performance Requirements

### Response Times
- **Authentication:** < 2 seconds
- **Payment Status:** < 1 second
- **Payment Submission:** < 5 seconds
- **Location Update:** < 1 second
- **Policy Retrieval:** < 1 second

### Availability
- **Uptime:** 99.9% (excluding planned maintenance)
- **Planned Maintenance:** Announced 24 hours in advance
- **Maintenance Window:** Off-peak hours

### Scalability
- Support for 10,000+ concurrent devices
- Handle 100+ requests per second
- Database query optimization for large datasets

## Security Requirements

### Data Encryption
- All data in transit encrypted with TLS 1.3
- Sensitive data at rest encrypted (AES-256)
- Database encryption enabled

### Authentication Security
- JWT tokens signed with RS256 algorithm
- Token rotation every 30 days
- Revocation list for compromised tokens

### API Security
- Rate limiting per device
- IP whitelisting for admin endpoints
- SQL injection prevention
- XSS protection
- CSRF protection

### Audit Logging
- Log all API requests
- Log authentication attempts
- Log payment transactions
- Log remote commands
- Retain logs for 90 days minimum

## Testing Requirements

### Test Environment
- Separate test API endpoint
- Test device registration without affecting production
- Mock payment gateway for testing
- Test data cleanup procedures

### Test Credentials
- Test JWT tokens with extended expiry
- Test device IDs for various scenarios
- Test payment methods that don't process real money

## Monitoring and Alerting

### Health Check Endpoint

**Endpoint:** `GET /health`

**Response (200 OK):**
```json
{
  "status": "healthy",
  "version": "string",
  "timestamp": "ISO 8601 datetime",
  "services": {
    "database": "healthy|degraded|down",
    "paymentGateway": "healthy|degraded|down",
    "cache": "healthy|degraded|down"
  }
}
```

### Metrics to Monitor
- API response times
- Error rates by endpoint
- Active device count
- Payment success rate
- Token refresh rate
- Database query performance

### Alerts
- API downtime
- High error rate (> 5%)
- Payment gateway failures
- Database connection issues
- Unusual device activity

## Compliance and Legal

### Data Retention
- Payment records: 7 years
- Device logs: 90 days
- Location data: 30 days after device release
- User data: Until device release + 30 days

### GDPR Compliance (if applicable)
- Right to access data
- Right to deletion (after payment completion)
- Data portability
- Consent management

### Nigerian Data Protection Regulation
- Comply with NDPR requirements
- Data localization if required
- User consent for data collection
- Data breach notification procedures

## Support and Documentation

### API Documentation
- Interactive API documentation (Swagger/OpenAPI)
- Code examples in multiple languages
- Postman collection for testing
- Changelog for API versions

### Support Contacts
- **Technical Support:** [Email]
- **API Issues:** [Email]
- **Emergency Contact:** [Phone]
- **Response Time:** < 4 hours for critical issues

## Versioning

### API Version Strategy
- Current Version: v1
- Version in URL path: `/api/v1/`
- Backward compatibility for 12 months
- Deprecation notices 6 months in advance

### Breaking Changes
- New major version for breaking changes
- Migration guide provided
- Parallel support for old and new versions
- Forced upgrade only for security issues

---

**Document Version:** 1.0  
**Last Updated:** [Date]  
**Contact:** [Technical Contact Email]
