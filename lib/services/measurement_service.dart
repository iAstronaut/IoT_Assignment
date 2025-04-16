import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/auth_service.dart';

class MeasurementData {
  final int heartRate;
  final double oxygen;

  MeasurementData({
    required this.heartRate,
    required this.oxygen,
  });
}

class MeasurementService extends ChangeNotifier {
  static final MeasurementService _instance = MeasurementService._internal();
  factory MeasurementService() => _instance;
  MeasurementService._internal();

  final _measurementController = StreamController<MeasurementData>.broadcast();

  Stream<MeasurementData> get measurementStream => _measurementController.stream;

  double _currentHeartRate = 0;
  double _currentOxygen = 0;
  String _status = 'Not measuring';
  bool _isMeasuring = false;
  Timer? _timer;

  final String _baseUrl = 'https://app.coreiot.io/api';
  final String _deviceId = '2b314740-090d-11f0-a887-6d1a184f2bb5';

  // Getters
  double get currentHeartRate => _currentHeartRate;
  double get currentOxygen => _currentOxygen;
  String get status => _status;
  bool get isMeasuring => _isMeasuring;

  void updateMeasurements(int heartRate, double oxygen) {
    _measurementController.add(
      MeasurementData(
        heartRate: heartRate,
        oxygen: oxygen,
      ),
    );
  }

  Future<void> startMeasurement() async {
    if (_isMeasuring) return;

    try {
      // Get token from AuthService
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/plugins/telemetry/DEVICE/$_deviceId/values/timeseries'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _isMeasuring = true;
        _status = 'Measuring';
        await _startPolling();
        notifyListeners();
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to start measurement');
      }
    } catch (e) {
      print('Error starting measurement: $e');
      _status = 'Error: $e';
      notifyListeners();
      rethrow;
    }
  }

  void stopMeasurement() {
    _timer?.cancel();
    _isMeasuring = false;
    _status = 'Not measuring';
    notifyListeners();
  }

  Future<void> _startPolling() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final token = await AuthService.getToken();
        if (token == null) {
          print('No token available for polling');
          return;
        }

        final response = await http.get(
          Uri.parse('$_baseUrl/plugins/telemetry/DEVICE/$_deviceId/values/timeseries'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _currentHeartRate = _parseDoubleValue(data['heartbeat']?[0]?['value']);
          _currentOxygen = _parseDoubleValue(data['oxygen']?[0]?['value']);
          _updateStatus();

          // Update stream
          updateMeasurements(_currentHeartRate.round(), _currentOxygen);

          notifyListeners();
        } else {
          print('Error polling: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Error polling data: $e');
      }
    });
  }

  double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _updateStatus() {
    if (_currentHeartRate < 60) {
      _status = 'Low';
    } else if (_currentHeartRate > 100) {
      _status = 'High';
    } else {
      _status = 'Normal';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _measurementController.close();
    super.dispose();
  }
}