# Changelog - ZarFinance Updates

## Payment Gateway Integration

### Added
- **Paystack Integration**: Full payment gateway integration with Paystack
- **Flutterwave Integration**: Full payment gateway integration with Flutterwave
- **Payment Gateway Configuration**: Admin panel settings page to configure payment gateways
- **Payment Frequency Support**: Daily, weekly, and monthly payment frequencies
- **Payment Initialization API**: New endpoint to initialize payments with gateways
- **Payment Verification API**: New endpoint to verify payments after gateway processing

### Changed
- **App Name**: Changed from "Finance App" to "ZarFinance"
- **Package Name**: Changed from `com.financeapp.deviceadmin` to `com.zarfinance.admin`
- **Backend Merged**: Backend API merged into admin-panel as single server
- **Payment Flow**: Updated to use payment gateway flow (initialize → redirect → verify)
- **Currency**: All prices now displayed in Naira (₦)

### Updated Components

#### Android App
- Updated package names throughout
- Updated PaymentActivity to use gateway payment flow
- Added email field for payment initialization
- Updated API models to include payment frequency

#### Backend/Admin Panel
- Merged backend into admin-panel
- Added PaymentGateway model
- Added payment gateway service (Paystack & Flutterwave)
- Updated payment routes with initialize and verify endpoints
- Added webhook support for payment gateways
- Added payment gateway configuration routes

#### Admin Dashboard
- Added Settings page for payment gateway configuration
- Added payment frequency selector when creating devices
- Updated device creation form to include payment frequency
- All amounts displayed in Naira (₦)

### Payment Gateway Flow

1. User enters amount and email in app
2. App calls `/api/payment/initialize` endpoint
3. Backend initializes payment with active gateway (Paystack/Flutterwave)
4. User redirected to gateway payment page
5. After payment, app calls `/api/payment/verify` endpoint
6. Backend verifies payment with gateway and updates device status

### Configuration

Payment gateways can be configured in the admin panel Settings page:
- Enter Paystack public key and secret key
- Enter Flutterwave public key and secret key
- Set one gateway as active
- Configure webhook secrets (optional)

### Notes

- Only one payment gateway can be active at a time
- Payment amounts are automatically converted to kobo/pesewas for gateways
- Webhook support included for automatic payment verification
- Legacy payment processing endpoint still available for direct payments

