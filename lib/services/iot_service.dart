import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/heart_rate_data.dart';

class IoTService {
  static const String baseUrl = 'https://your-iot-server.com/api';
  static const String wsUrl = 'wss://your-iot-server.com/ws';

  StreamController<HeartRateData>? _streamController;
  Timer? _mockDataTimer;
  bool _isConnected = false;
  final _random = math.Random();

  // Singleton pattern
  static final IoTService _instance = IoTService._internal();
  factory IoTService() => _instance;
  IoTService._internal();

  Stream<HeartRateData>? get dataStream => _streamController?.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String deviceId) async {
    try {
      _streamController?.close();
      _streamController = StreamController<HeartRateData>.broadcast();
      _isConnected = true;

      // For demo purposes, generate mock data
      _mockDataTimer?.cancel();
      _mockDataTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isConnected) {
          final mockData = HeartRateData(
            bpm: 60 + _random.nextInt(40),
            timestamp: DateTime.now(),
            status: _getRandomStatus(),
            deviceId: deviceId,
            oxygenLevel: (95 + _random.nextInt(5)).toDouble(),
            systolic: (110 + _random.nextInt(30)).toDouble(),
            diastolic: (70 + _random.nextInt(20)).toDouble(),
          );
          _streamController?.add(mockData);
        }
      });
    } catch (e) {
      print('Connection error: $e');
      _handleConnectionError();
    }
  }

  String _getRandomStatus() {
    final statuses = ['normal', 'elevated', 'high', 'low'];
    return statuses[_random.nextInt(statuses.length)];
  }

  void _handleConnectionError() {
    _isConnected = false;
    _mockDataTimer?.cancel();
  }

  Future<List<HeartRateData>> getHistoricalData(
    String deviceId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // For demo purposes, generate mock historical data
    final now = DateTime.now();
    final List<HeartRateData> mockData = [];

    for (int i = 0; i < 50; i++) {
      mockData.add(HeartRateData(
        bpm: 60 + _random.nextInt(40),
        timestamp: now.subtract(Duration(minutes: i * 5)),
        status: _getRandomStatus(),
        deviceId: deviceId,
        oxygenLevel: (95 + _random.nextInt(5)).toDouble(),
        systolic: (110 + _random.nextInt(30)).toDouble(),
        diastolic: (70 + _random.nextInt(20)).toDouble(),
      ));
    }

    return mockData;
  }

  Future<Map<String, dynamic>> getDeviceStatus(String deviceId) async {
    // For demo purposes, return mock device status
    return {
      'status': 'connected',
      'battery': '${70 + _random.nextInt(30)}%',
      'signal_strength': '${-50 - _random.nextInt(30)} dBm',
      'last_sync': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    _mockDataTimer?.cancel();
    _streamController?.close();
    _isConnected = false;
  }
}