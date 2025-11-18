# Finance App Backend

Node.js backend API for the Finance App Device Admin System.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
```

3. Update `.env` with your configuration:
- `MONGODB_URI`: MongoDB connection string
- `JWT_SECRET`: Secret key for JWT tokens
- `PORT`: Server port (default: 3000)

4. Start MongoDB (if running locally):
```bash
mongod
```

5. Run the server:
```bash
npm start
# or for development
npm run dev
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - Admin login
- `POST /api/auth/register` - Register new admin
- `GET /api/auth/me` - Get current admin info

### Payment
- `GET /api/payment/status/:deviceId` - Get payment status
- `POST /api/payment/process` - Process payment
- `GET /api/payment/history/:deviceId` - Get payment history
- `GET /api/payment/schedule/:deviceId` - Get payment schedule

### Device
- `POST /api/device/location` - Report device location
- `GET /api/device/status/:deviceId` - Get device status
- `POST /api/device/report` - Report device status

### Admin
- `GET /api/admin/policy/:deviceId` - Get device policy
- `POST /api/admin/unlock` - Unlock device manually
- `POST /api/admin/message` - Send message to device
- `GET /api/admin/devices` - Get all devices
- `GET /api/admin/devices/:deviceId` - Get device details
- `POST /api/admin/devices` - Create new device
- `PUT /api/admin/devices/:deviceId/policy` - Update device policy

## Authentication

- Admin endpoints require JWT token in `Authorization: Bearer <token>` header
- Device endpoints require API key in `X-API-Key` header

