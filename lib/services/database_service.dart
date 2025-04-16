import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/measurement_record.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'health_measurements.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE measurements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            heart_rate INTEGER NOT NULL,
            oxygen REAL NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertMeasurement(int heartRate, double oxygen) async {
    final db = await database;
    await db.insert(
      'measurements',
      {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'heart_rate': heartRate,
        'oxygen': oxygen,
      },
    );
  }

  Future<List<MeasurementRecord>> getWeeklyMeasurements() async {
    final db = await database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    final List<Map<String, dynamic>> maps = await db.query(
      'measurements',
      where: 'timestamp > ?',
      whereArgs: [weekAgo.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return MeasurementRecord.fromMap(maps[i]);
    });
  }

  Future<List<MeasurementRecord>> getDailyAverages() async {
    final db = await database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        date(datetime(timestamp/1000, 'unixepoch')) as day,
        AVG(heart_rate) as heart_rate,
        AVG(oxygen) as oxygen,
        MIN(id) as id,
        MIN(timestamp) as timestamp
      FROM measurements
      WHERE timestamp > ?
      GROUP BY day
      ORDER BY day ASC
    ''', [weekAgo.millisecondsSinceEpoch]);

    return List.generate(maps.length, (i) {
      return MeasurementRecord.fromMap({
        'id': maps[i]['id'] as int,
        'timestamp': maps[i]['timestamp'] as int,
        'heart_rate': (maps[i]['heart_rate'] as num).round(),
        'oxygen': (maps[i]['oxygen'] as num).toDouble(),
      });
    });
  }

  Future<List<MeasurementRecord>> getAllMeasurements() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'measurements',
      orderBy: 'timestamp DESC',
      limit: 100, // Limit to last 100 records for performance
    );

    return List.generate(maps.length, (i) {
      return MeasurementRecord.fromMap(maps[i]);
    });
  }

  // Debug function to print all measurements
  Future<void> printAllMeasurements() async {
    final measurements = await getAllMeasurements();
    print('Total records: ${measurements.length}');
    for (var measurement in measurements) {
      print('''
Record ID: ${measurement.id}
Timestamp: ${measurement.timestamp}
Heart Rate: ${measurement.heartRate}
Oxygen: ${measurement.oxygen}
-------------------''');
    }
  }
}