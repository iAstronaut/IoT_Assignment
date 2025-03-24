import 'dart:async';
import 'dart:math';
import 'package:heart_rate_monitor/models/heart_rate_data.dart';
import 'package:heart_rate_monitor/services/iot_service.dart';

class MockIoTService implements IoTService {
  Timer? _timer;
  final _random = Random();
  final _controller = StreamController<HeartRateData>.broadcast();
  bool _isConnected = false;

  @override
  Stream<HeartRateData>? get dataStream => _controller.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect(String deviceId) async {
    if (_isConnected) return;

    _isConnected = true;
    _startGeneratingData();
  }

  void _startGeneratingData() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final value = 60 + _random.nextInt(40); // Random value between 60-100
      final now = DateTime.now();

      String status;
      String message;

      if (value < 60) {
        status = 'low';
        message = 'Heart rate is below normal range';
      } else if (value > 100) {
        status = 'high';
        message = 'Heart rate is above normal range';
      } else if (value > 90) {
        status = 'elevated';
        message = 'Heart rate is slightly elevated';
      } else {
        status = 'normal';
        message = 'Heart rate is within normal range';
      }

      final data = HeartRateData(
        value: value,
        timestamp: now,
        status: status,
        statusMessage: message,
      );

      _controller.add(data);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
    _isConnected = false;
  }
}