import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CoreIoTService {
  static const String baseUrl = 'https://app.coreiot.io/api';
  // static const String deviceId = '2b314740-090d-11f0-a887-6d1a184f2bb5';

  StreamController<Map<String, dynamic>>? _dataStreamController;
  Timer? _pollingTimer;
  bool _isConnected = false;
  String? _token;
  Map<String, dynamic> _lastData = {
    'oxygen': 0.0,
    'heartbeat': 0,
    'timestamp': 0
  };

  // Initialize the service and create a stream for real-time data
  Future<void> initialize() async {
    _dataStreamController = StreamController<Map<String, dynamic>>.broadcast();

    // Get token from AuthService
    _token = await AuthService.loginCoreIoT();

    if (_token != null) {
      print('Token: $_token');
      _isConnected = true;
      _startPolling();
    } else {
      _isConnected = false;
    }
  }

  // Start polling for telemetry data
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/plugins/telemetry/DEVICE/$deviceId/values/timeseries'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          try {
            // Parse the response data
            final oxygen = _parseDoubleValue(data['oxygen']?[0]?['value']);
            final heartbeat = _parseDoubleValue(data['heartbeat']?[0]?['value']);

            _lastData = {
              'oxygen': oxygen,
              'heartbeat': heartbeat,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };

            print('Oxygen: $oxygen, Heartbeat: $heartbeat');
            _dataStreamController?.add(_lastData);
          } catch (e) {
            print('Error parsing message: $e');
          }
        } else {
          _isConnected = false;
          _scheduleReconnect();
        }
      } catch (e) {
        _isConnected = false;
        _scheduleReconnect();
      }
    });
  }

  double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _scheduleReconnect() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        initialize();
      }
    });
  }

  // Get latest data
  Map<String, dynamic> getLatestData() {
    return _lastData;
  }

  // Get real-time data stream
  Stream<Map<String, dynamic>>? get dataStream => _dataStreamController?.stream;

  bool get isConnected => _isConnected;

  // Dispose resources
  void dispose() {
    _pollingTimer?.cancel();
    _dataStreamController?.close();
    _isConnected = false;
  }
}
