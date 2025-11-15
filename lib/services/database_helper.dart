import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment_schedule.dart';
import '../models/device_config.dart';
import '../models/payment_history.dart';
import '../models/sync_queue_item.dart';
import '../models/error_log.dart';
import 'secure_storage_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'device_admin.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      password: await _getDatabasePassword(),
    );
  }

  Future<String> _getDatabasePassword() async {
    final secureStorage = SecureStorageService();
    String? password = await secureStorage.getDatabasePassword();
    
    if (password == null || password.isEmpty) {
      password = await secureStorage.generateAndStoreDatabasePassword();
    }
    
    return password;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create payment_schedule table
    await db.execute('''
      CREATE TABLE payment_schedule (
        id TEXT PRIMARY KEY,
        dueDate INTEGER NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        paidDate INTEGER
      )
    ''');

    // Create device_config table
    await db.execute('''
      CREATE TABLE device_config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        lastUpdated INTEGER NOT NULL
      )
    ''');

    // Create payment_history table
    await db.execute('''
      CREATE TABLE payment_history (
        transactionId TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        status TEXT NOT NULL,
        method TEXT NOT NULL
      )
    ''');

    // Create sync_queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        retryCount INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create error_log table
    await db.execute('''
      CREATE TABLE error_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        errorType TEXT NOT NULL,
        message TEXT NOT NULL,
        stackTrace TEXT,
        context TEXT
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_payment_schedule_dueDate 
      ON payment_schedule(dueDate)
    ''');

    await db.execute('''
      CREATE INDEX idx_payment_schedule_status 
      ON payment_schedule(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_payment_history_timestamp 
      ON payment_history(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_error_log_timestamp 
      ON error_log(timestamp)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add error_log table for version 2
      await db.execute('''
        CREATE TABLE error_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp INTEGER NOT NULL,
          errorType TEXT NOT NULL,
          message TEXT NOT NULL,
          stackTrace TEXT,
          context TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_error_log_timestamp 
        ON error_log(timestamp)
      ''');
    }
  }

  // PaymentSchedule CRUD operations
  Future<int> insertPaymentSchedule(PaymentSchedule schedule) async {
    final db = await database;
    await db.insert(
      'payment_schedule',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return 1;
  }

  Future<int> updatePaymentSchedule(PaymentSchedule schedule) async {
    final db = await database;
    return await db.update(
      'payment_schedule',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deletePaymentSchedule(String id) async {
    final db = await database;
    return await db.delete(
      'payment_schedule',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<PaymentSchedule?> getPaymentSchedule(String id) async {
    final db = await database;
    final maps = await db.query(
      'payment_schedule',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return PaymentSchedule.fromMap(maps.first);
  }

  Future<List<PaymentSchedule>> getAllPaymentSchedules() async {
    final db = await database;
    final maps = await db.query(
      'payment_schedule',
      orderBy: 'dueDate ASC',
    );

    return maps.map((map) => PaymentSchedule.fromMap(map)).toList();
  }

  Future<List<PaymentSchedule>> getUpcomingPayments() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final maps = await db.query(
      'payment_schedule',
      where: 'dueDate >= ? AND status = ?',
      whereArgs: [now, PaymentStatus.pending.toString()],
      orderBy: 'dueDate ASC',
    );

    return maps.map((map) => PaymentSchedule.fromMap(map)).toList();
  }

  Future<List<PaymentSchedule>> getOverduePayments() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final maps = await db.query(
      'payment_schedule',
      where: 'dueDate < ? AND status = ?',
      whereArgs: [now, PaymentStatus.overdue.toString()],
      orderBy: 'dueDate ASC',
    );

    return maps.map((map) => PaymentSchedule.fromMap(map)).toList();
  }

  // DeviceConfig CRUD operations
  Future<int> insertDeviceConfig(DeviceConfig config) async {
    final db = await database;
    await db.insert(
      'device_config',
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return 1;
  }

  Future<int> updateDeviceConfig(DeviceConfig config) async {
    final db = await database;
    return await db.update(
      'device_config',
      config.toMap(),
      where: 'key = ?',
      whereArgs: [config.key],
    );
  }

  Future<int> deleteDeviceConfig(String key) async {
    final db = await database;
    return await db.delete(
      'device_config',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<DeviceConfig?> getDeviceConfig(String key) async {
    final db = await database;
    final maps = await db.query(
      'device_config',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isEmpty) return null;
    return DeviceConfig.fromMap(maps.first);
  }

  Future<List<DeviceConfig>> getAllDeviceConfigs() async {
    final db = await database;
    final maps = await db.query('device_config');
    return maps.map((map) => DeviceConfig.fromMap(map)).toList();
  }

  // PaymentHistory CRUD operations
  Future<int> insertPaymentHistory(PaymentHistory history) async {
    final db = await database;
    await db.insert(
      'payment_history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return 1;
  }

  Future<int> updatePaymentHistory(PaymentHistory history) async {
    final db = await database;
    return await db.update(
      'payment_history',
      history.toMap(),
      where: 'transactionId = ?',
      whereArgs: [history.transactionId],
    );
  }

  Future<int> deletePaymentHistory(String transactionId) async {
    final db = await database;
    return await db.delete(
      'payment_history',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
  }

  Future<PaymentHistory?> getPaymentHistoryById(String transactionId) async {
    final db = await database;
    final maps = await db.query(
      'payment_history',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );

    if (maps.isEmpty) return null;
    return PaymentHistory.fromMap(maps.first);
  }

  Future<List<PaymentHistory>> getPaymentHistory({int? limit}) async {
    final db = await database;
    final maps = await db.query(
      'payment_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => PaymentHistory.fromMap(map)).toList();
  }

  // SyncQueueItem CRUD operations
  Future<int> insertSyncQueueItem(SyncQueueItem item) async {
    final db = await database;
    return await db.insert(
      'sync_queue',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateSyncQueueItem(SyncQueueItem item) async {
    final db = await database;
    return await db.update(
      'sync_queue',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteSyncQueueItem(int id) async {
    final db = await database;
    return await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<SyncQueueItem?> getSyncQueueItem(int id) async {
    final db = await database;
    final maps = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return SyncQueueItem.fromMap(maps.first);
  }

  Future<List<SyncQueueItem>> getAllSyncQueueItems() async {
    final db = await database;
    final maps = await db.query(
      'sync_queue',
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  Future<List<SyncQueueItem>> getSyncQueueItemsByType(SyncType type) async {
    final db = await database;
    final maps = await db.query(
      'sync_queue',
      where: 'type = ?',
      whereArgs: [type.toString()],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  // Utility methods
  Future<void> setLockState(bool isLocked) async {
    final config = DeviceConfig(
      key: 'is_locked',
      value: isLocked.toString(),
      lastUpdated: DateTime.now(),
    );
    await insertDeviceConfig(config);
  }

  Future<bool> getLockState() async {
    final config = await getDeviceConfig('is_locked');
    if (config == null) return false;
    return config.value.toLowerCase() == 'true';
  }

  // ErrorLog CRUD operations
  Future<int> insertErrorLog(ErrorLog errorLog) async {
    final db = await database;
    return await db.insert(
      'error_log',
      errorLog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteErrorLog(int id) async {
    final db = await database;
    return await db.delete(
      'error_log',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ErrorLog>> getAllErrorLogs() async {
    final db = await database;
    final maps = await db.query(
      'error_log',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => ErrorLog.fromMap(map)).toList();
  }

  Future<List<ErrorLog>> getRecentErrorLogs({int limit = 50}) async {
    final db = await database;
    final maps = await db.query(
      'error_log',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => ErrorLog.fromMap(map)).toList();
  }

  Future<void> clearErrorLogs() async {
    final db = await database;
    await db.delete('error_log');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('payment_schedule');
    await db.delete('device_config');
    await db.delete('payment_history');
    await db.delete('sync_queue');
  }

  /// Batch update payment data using transaction for better performance
  Future<void> batchUpdatePaymentData({
    List<PaymentHistory>? paymentHistory,
    List<PaymentSchedule>? paymentSchedules,
  }) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Batch insert payment history
      if (paymentHistory != null && paymentHistory.isNotEmpty) {
        final batch = txn.batch();
        for (final payment in paymentHistory) {
          batch.insert(
            'payment_history',
            payment.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }

      // Batch insert payment schedules
      if (paymentSchedules != null && paymentSchedules.isNotEmpty) {
        final batch = txn.batch();
        for (final schedule in paymentSchedules) {
          batch.insert(
            'payment_schedule',
            schedule.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      }
    });
  }

  /// Batch delete sync queue items for better performance
  Future<void> batchDeleteSyncQueueItems(List<int> ids) async {
    if (ids.isEmpty) return;
    
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final id in ids) {
        batch.delete(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
