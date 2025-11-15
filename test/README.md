# Unit Tests

This directory contains unit tests for the Device Admin App core functionality.

## Test Structure

### Models Tests (`test/models/`)
- `payment_schedule_test.dart` - Tests for PaymentSchedule model serialization and data integrity
- `payment_history_test.dart` - Tests for PaymentHistory model serialization and data integrity

### Services Tests (`test/services/`)
- `payment_service_test.dart` - Tests for payment logic, status mapping, and calculations
- `database_helper_test.dart` - Tests for database query logic and data operations
- `api_client_test.dart` - Tests for API client retry logic, error handling, and configuration

## Running Tests

Run all unit tests:
```bash
flutter test
```

Run specific test file:
```bash
flutter test test/models/payment_schedule_test.dart
```

Run tests with coverage:
```bash
flutter test --coverage
```

## Test Coverage

The unit tests focus on:
- Model serialization (toMap/fromMap)
- Data integrity through serialization round-trips
- Payment status and transaction status mapping
- Date/time calculations for payment schedules
- Payment amount calculations
- Database query filtering and sorting logic
- API retry logic with exponential backoff
- Error message extraction and status code mapping
- Grace period calculations
- Transaction ID generation and duplicate prevention

## Test Results

All 83 tests pass successfully, covering:
- 16 tests for PaymentSchedule model
- 8 tests for PaymentHistory model
- 23 tests for PaymentService logic
- 20 tests for DatabaseHelper operations
- 16 tests for ApiClient functionality
