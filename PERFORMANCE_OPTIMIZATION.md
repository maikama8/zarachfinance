# Performance Optimization Guide

## Overview
This document outlines all performance optimizations implemented in the Device Lock Finance App to ensure efficient resource usage, minimal battery drain, and smooth user experience.

## Database Optimizations

### Indexes
The following indexes have been created to optimize query performance:

```sql
-- Payment schedule queries (most frequent)
CREATE INDEX idx_payment_schedule_dueDate ON payment_schedule(dueDate);
CREATE INDEX idx_payment_schedule_status ON payment_schedule(status);

-- Payment history queries
CREATE INDEX idx_payment_history_timestamp ON payment_history(timestamp);

-- Error log queries
CREATE INDEX idx_error_log_timestamp ON error_log(timestamp);
```

### Query Optimization Best Practices

#### Use Transactions for Batch Operations
```dart
// Good: Use transaction for multiple inserts
await db.transaction((txn) async {
  for (var payment in payments) {
    await txn.insert('payment_schedule', payment.toMap());
  }
});

// Bad: Individual inserts
for (var payment in payments) {
  await db.insert('payment_schedule', payment.toMap());
}
```

#### Limit Query Results
```dart
// Good: Limit results when displaying recent items
final recentPayments = await db.query(
  'payment_history',
  orderBy: 'timestamp DESC',
  limit: 50,
);

// Bad: Fetch all records
final allPayments = await db.query('payment_history');
```

#### Use Prepared Statements
```dart
// Good: Use parameterized queries
await db.query(
  'payment_schedule',
  where: 'dueDate >= ? AND status = ?',
  whereArgs: [now, 'pending'],
);

// Bad: String concatenation (also security risk)
await db.rawQuery(
  "SELECT * FROM payment_schedule WHERE dueDate >= $now AND status = 'pending'"
);
```

### Database Maintenance

#### Periodic Cleanup
```dart
// Clean up old error logs (keep last 30 days)
Future<void> cleanupOldErrorLogs() async {
  final db = await database;
  final thirtyDaysAgo = DateTime.now()
      .subtract(Duration(days: 30))
      .millisecondsSinceEpoch;
  
  await db.delete(
    'error_log',
    where: 'timestamp < ?',
    whereArgs: [thirtyDaysAgo],
  );
}

// Clean up processed sync queue items
Future<void> cleanupSyncQueue() async {
  final db = await database;
  final sevenDaysAgo = DateTime.now()
      .subtract(Duration(days: 7))
      .millisecondsSinceEpoch;
  
  await db.delete(
    'sync_queue',
    where: 'timestamp < ? AND retryCount >= 3',
    whereArgs: [sevenDaysAgo],
  );
}
```

## Background Task Optimizations

### Task Frequency
Background tasks are configured with optimal frequencies to balance functionality and battery usage:

| Task | Frequency | Rationale |
|------|-----------|-----------|
| Payment Status Check | 6 hours | Frequent enough to detect overdue payments within 24 hours |
| Location Capture | 12 hours | Sufficient for tracking without excessive battery drain |
| Policy Sync | 24 hours | Policies don't change frequently |
| Device Status Report | 24 hours | Daily reporting is adequate for monitoring |

### WorkManager Constraints
All background tasks use appropriate constraints to minimize battery impact:

```dart
Constraints(
  networkType: NetworkType.connected,  // Only run when connected
  requiresBatteryNotLow: false,        // Allow on low battery (critical tasks)
  requiresCharging: false,             // Don't require charging
  requiresDeviceIdle: false,           // Don't wait for idle
  requiresStorageNotLow: false,        // Don't check storage
)
```

### Backoff Policy
Exponential backoff prevents excessive retries:

```dart
backoffPolicy: BackoffPolicy.exponential,
backoffPolicyDelay: const Duration(minutes: 15),
```

This means:
- First retry: 15 minutes
- Second retry: 30 minutes
- Third retry: 60 minutes

### Battery Optimization Exemption

For critical functionality, request battery optimization exemption:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestBatteryOptimizationExemption() async {
  final status = await Permission.ignoreBatteryOptimizations.status;
  
  if (!status.isGranted) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}
```

**Note:** Only request this if absolutely necessary, as it impacts battery life.

## Network Optimizations

### Request Batching
Batch multiple operations into single requests:

```dart
// Good: Batch sync operations
Future<void> syncQueuedOperations() async {
  final items = await db.getAllSyncQueueItems();
  
  // Group by type
  final paymentItems = items.where((i) => i.type == SyncType.payment).toList();
  final locationItems = items.where((i) => i.type == SyncType.location).toList();
  
  // Send in batches
  if (paymentItems.isNotEmpty) {
    await api.batchSyncPayments(paymentItems);
  }
  
  if (locationItems.isNotEmpty) {
    await api.batchSyncLocations(locationItems);
  }
}

// Bad: Individual requests
for (var item in items) {
  await api.syncItem(item);
}
```

### Connection Pooling
Dio client is configured with connection pooling:

```dart
final dio = Dio(BaseOptions(
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 60),
  sendTimeout: Duration(seconds: 30),
  // Connection pooling is enabled by default
));
```

### Response Caching
Cache responses for frequently accessed data:

```dart
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

final cacheOptions = CacheOptions(
  store: MemCacheStore(),
  policy: CachePolicy.request,
  maxStale: const Duration(hours: 1),
);

dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
```

### Minimize Payload Size
- Use JSON compression
- Request only necessary fields
- Paginate large result sets

```dart
// Good: Request specific fields
final response = await dio.get('/api/payments', queryParameters: {
  'fields': 'id,amount,dueDate,status',
  'limit': 50,
});

// Bad: Request all data
final response = await dio.get('/api/payments');
```

## Memory Optimizations

### Image Optimization
Use cached network images with size constraints:

```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: imageUrl,
  memCacheWidth: 400,  // Limit memory cache size
  memCacheHeight: 400,
  maxWidthDiskCache: 800,  // Limit disk cache size
  maxHeightDiskCache: 800,
);
```

### List View Optimization
Use ListView.builder for large lists:

```dart
// Good: Lazy loading
ListView.builder(
  itemCount: payments.length,
  itemBuilder: (context, index) {
    return PaymentTile(payment: payments[index]);
  },
);

// Bad: Load all items at once
ListView(
  children: payments.map((p) => PaymentTile(payment: p)).toList(),
);
```

### Dispose Resources
Always dispose controllers and streams:

```dart
class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  StreamSubscription? _paymentSubscription;
  
  @override
  void dispose() {
    _amountController.dispose();
    _paymentSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Build UI
  }
}
```

## App Size Optimization

### ProGuard Configuration
Optimize release builds with ProGuard:

```proguard
# android/app/proguard-rules.pro

# Keep essential classes
-keep class com.finance.device_admin_app.** { *; }
-keep class io.flutter.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Optimize
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose
```

### Asset Optimization
- Compress images (use WebP format)
- Remove unused assets
- Use vector graphics (SVG) where possible

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/logo.webp  # Use WebP instead of PNG
    - assets/icons/  # Vector icons
```

### Build Configuration
```gradle
// android/app/build.gradle.kts
android {
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    // Split APKs by ABI to reduce size
    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
            isUniversalApk = false
        }
    }
}
```

## UI Performance Optimizations

### Reduce Widget Rebuilds
Use const constructors and keys:

```dart
// Good: Const constructor prevents rebuilds
const Text('Payment Due', style: TextStyle(fontSize: 16));

// Bad: Creates new widget on every build
Text('Payment Due', style: TextStyle(fontSize: 16));
```

### Use RepaintBoundary
Isolate expensive widgets:

```dart
RepaintBoundary(
  child: ComplexChart(data: chartData),
)
```

### Optimize Animations
Use AnimatedBuilder for efficient animations:

```dart
// Good: Only rebuilds animated widget
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Transform.scale(
      scale: _controller.value,
      child: child,
    );
  },
  child: ExpensiveWidget(),  // Built once
);

// Bad: Rebuilds entire tree
Transform.scale(
  scale: _controller.value,
  child: ExpensiveWidget(),  // Rebuilt every frame
);
```

## Profiling and Monitoring

### Flutter DevTools
Profile app performance:

```bash
# Run in profile mode
flutter run --profile

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

Monitor:
- CPU usage
- Memory allocation
- Frame rendering (target: 60 FPS)
- Network requests

### Performance Metrics

#### Target Metrics
| Metric | Target | Critical Threshold |
|--------|--------|-------------------|
| Cold Start Time | < 3s | < 5s |
| Warm Start Time | < 1.5s | < 2s |
| Hot Start Time | < 500ms | < 1s |
| Memory Usage (Idle) | < 50MB | < 80MB |
| Memory Usage (Active) | < 100MB | < 150MB |
| Frame Rate | 60 FPS | > 30 FPS |
| Battery Usage (24h) | < 2% | < 5% |

#### Monitoring Commands
```bash
# App startup time
adb shell am start -W -n com.finance.device_admin_app/.MainActivity

# Memory usage
adb shell dumpsys meminfo com.finance.device_admin_app

# Battery usage
adb shell dumpsys batterystats com.finance.device_admin_app

# Frame rate
adb shell dumpsys gfxinfo com.finance.device_admin_app
```

## Optimization Checklist

### Before Release
- [ ] Enable ProGuard/R8 obfuscation
- [ ] Enable resource shrinking
- [ ] Compress all images
- [ ] Remove unused dependencies
- [ ] Test on low-end devices (2GB RAM)
- [ ] Profile memory usage
- [ ] Profile battery usage
- [ ] Check app size (target: < 20MB)
- [ ] Verify frame rate (60 FPS)
- [ ] Test background task frequency
- [ ] Verify database query performance
- [ ] Check network request efficiency
- [ ] Test offline functionality
- [ ] Verify no memory leaks

### Continuous Monitoring
- [ ] Monitor crash reports
- [ ] Track ANR (Application Not Responding) events
- [ ] Monitor battery usage complaints
- [ ] Track app size growth
- [ ] Monitor API response times
- [ ] Track background task success rate

## Common Performance Issues

### Issue: High Battery Drain
**Symptoms:** Users report excessive battery usage

**Diagnosis:**
```bash
adb shell dumpsys batterystats com.finance.device_admin_app | grep "Estimated power use"
adb shell dumpsys power | grep com.finance.device_admin_app
```

**Solutions:**
1. Reduce background task frequency
2. Check for wakelocks
3. Optimize location tracking accuracy
4. Batch network requests

### Issue: Slow App Startup
**Symptoms:** App takes > 5 seconds to launch

**Diagnosis:**
```bash
adb shell am start -W -n com.finance.device_admin_app/.MainActivity
```

**Solutions:**
1. Defer non-critical initialization
2. Use lazy loading for services
3. Optimize database initialization
4. Reduce splash screen complexity

### Issue: UI Lag/Jank
**Symptoms:** Scrolling is not smooth, animations stutter

**Diagnosis:**
```bash
adb shell dumpsys gfxinfo com.finance.device_admin_app
```

**Solutions:**
1. Use ListView.builder for lists
2. Add RepaintBoundary to complex widgets
3. Optimize image loading
4. Reduce widget rebuilds

### Issue: High Memory Usage
**Symptoms:** App uses > 150MB RAM, crashes on low-end devices

**Diagnosis:**
```bash
adb shell dumpsys meminfo com.finance.device_admin_app
```

**Solutions:**
1. Fix memory leaks (dispose controllers)
2. Limit image cache size
3. Paginate large lists
4. Clear old data periodically

## Best Practices Summary

1. **Database:** Use indexes, transactions, and limit queries
2. **Background Tasks:** Optimize frequency, use constraints, implement backoff
3. **Network:** Batch requests, cache responses, minimize payload
4. **Memory:** Dispose resources, optimize images, use lazy loading
5. **UI:** Use const constructors, RepaintBoundary, efficient animations
6. **Build:** Enable ProGuard, shrink resources, split APKs
7. **Monitoring:** Profile regularly, track metrics, fix issues proactively

## Resources

- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices)
- [Android Performance Patterns](https://developer.android.com/topic/performance)
- [WorkManager Best Practices](https://developer.android.com/topic/libraries/architecture/workmanager/advanced)
- [Dio Performance Tips](https://pub.dev/packages/dio#performance)
