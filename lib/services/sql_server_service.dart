import 'package:mssql_connection/mssql_connection.dart';

class SqlServerService {
  static final SqlServerService _instance = SqlServerService._internal();
  factory SqlServerService() => _instance;
  SqlServerService._internal();

  static MSSQLConnection? _connection;

  Future<MSSQLConnection> get connection async {
    if (_connection != null) return _connection!;
    _connection = await _initConnection();
    return _connection!;
  }

  Future<MSSQLConnection> _initConnection() async {
    final connection = MSSQLConnection(
      host: 'DESKTOP-CSPIOE3',
      port: 1433,
      db: 'heart_pulse_db',
      user: 'admin',
      password: 'your_password', // Thay thế bằng mật khẩu thực
      trustServerCertificate: true,
    );
    await connection.connect();
    return connection;
  }

  Future<void> insertMeasurement(int heartRate, double oxygen) async {
    final conn = await connection;
    await conn.execute(
      '''
      INSERT INTO dbo.HeartRateReadings (
        PatientId,
        HeartRate,
        OxygenLevel,
        ReadingTime
      ) VALUES (
        @patientId,
        @heartRate,
        @oxygen,
        @timestamp
      )
      ''',
      params: {
        'patientId': 1, // Thay thế bằng ID của patient hiện tại
        'heartRate': heartRate,
        'oxygen': oxygen,
        'timestamp': DateTime.now(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getWeeklyReadings() async {
    final conn = await connection;
    final result = await conn.execute(
      '''
      SELECT
        HeartRate,
        OxygenLevel,
        ReadingTime
      FROM dbo.HeartRateReadings
      WHERE ReadingTime >= DATEADD(day, -7, GETDATE())
      ORDER BY ReadingTime ASC
      '''
    );
    return result.rows;
  }

  Future<List<Map<String, dynamic>>> getDailyAverages() async {
    final conn = await connection;
    final result = await conn.execute(
      '''
      SELECT
        CAST(ReadingTime AS DATE) as ReadingDate,
        AVG(CAST(HeartRate AS FLOAT)) as AvgHeartRate,
        AVG(CAST(OxygenLevel AS FLOAT)) as AvgOxygen
      FROM dbo.HeartRateReadings
      WHERE ReadingTime >= DATEADD(day, -7, GETDATE())
      GROUP BY CAST(ReadingTime AS DATE)
      ORDER BY ReadingDate ASC
      '''
    );
    return result.rows;
  }
}