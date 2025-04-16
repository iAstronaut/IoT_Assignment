import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:heart_pulse_app/services/auth_service.dart';

class CoreIoTService {
  static const String baseUrl = 'https://app.coreiot.io/api';
  static const String deviceId = '2b314740-090d-11f0-a887-6d1a184f2bb5';
  static const String username = 'an.nguyencse03@gmail.com';
  static const String password = '02121209An';

  bool _isConnected = false;
  bool _isMeasuring = false;
  Timer? _pollingTimer;
  String? _token;
  Map<String, dynamic> _lastData = {
    'heartbeat': 0,
    'oxygen': 0.0,
  };

  bool get isConnected => _isConnected;
  bool get isMeasuring => _isMeasuring;

  Future<void> initialize() async {
    try {
      // Login to CoreIoT to get JWT token
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('Login response: ${loginResponse.statusCode}');
      print('Login body: ${loginResponse.body}');

      if (loginResponse.statusCode == 200) {
        final loginData = json.decode(loginResponse.body);
        _token = loginData['token'];
        print('Got JWT token: $_token');

        // Test the connection with the token
        final response = await http.get(
          Uri.parse('$baseUrl/plugins/telemetry/DEVICE/$deviceId/values/timeseries'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );

        print('Connection test response: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          _isConnected = true;
          print('Successfully connected to CoreIoT');
          // Lấy data đầu tiên
          await _fetchData();
        } else {
          print('Failed to connect to CoreIoT: ${response.statusCode}');
          _isConnected = false;
        }
      } else {
        print('Login failed: ${loginResponse.statusCode}');
        _isConnected = false;
      }
    } catch (e) {
      print('Error initializing CoreIoT service: $e');
      _isConnected = false;
    }
  }

  void startMeasuring() {
    print('Starting measurement...');
    if (!_isConnected) {
      print('Not connected, trying to initialize...');
      initialize().then((_) {
        if (_isConnected) {
          print('Connected, starting polling...');
          _isMeasuring = true;
          _startPolling();
        } else {
          print('Failed to connect');
        }
      });
      return;
    }
    _isMeasuring = true;
    _startPolling();
  }

  void stopMeasuring() {
    _isMeasuring = false;
    _pollingTimer?.cancel();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _fetchData();
    });
  }

  Future<void> _fetchData() async {
    if (_token == null) {
      print('No token available for fetching data');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plugins/telemetry/DEVICE/$deviceId/values/timeseries?keys=heartbeat,oxygen'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      print('Fetch response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Parse heartbeat data
        final List<dynamic>? heartbeatData = data['heartbeat'];
        final List<dynamic>? oxygenData = data['oxygen'];

        if (heartbeatData != null && heartbeatData.isNotEmpty &&
            oxygenData != null && oxygenData.isNotEmpty) {
          _lastData = {
            'heartbeat': double.tryParse(heartbeatData.first['value'].toString()) ?? 0,
            'oxygen': double.tryParse(oxygenData.first['value'].toString()) ?? 0,
          };
          print('Updated last data: $_lastData');
        }
      } else if (response.statusCode == 401) {
        // Token expired, try to login again
        print('Token expired, trying to reconnect...');
        await initialize();
      } else {
        print('Error fetching data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _fetchData: $e');
    }
  }

  Map<String, dynamic> getLatestData() {
    if (!_isConnected) {
      print('Not connected to CoreIoT');
      return _lastData;
    }

    // Gọi API để lấy data mới
    _fetchData();
    return _lastData;
  }

  void dispose() {
    _pollingTimer?.cancel();
    _isConnected = false;
  }
}
