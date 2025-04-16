import 'dart:async';
import 'dart:math';

class CoreIoTService {
  bool _isConnected = false;
  Timer? _simulationTimer;
  final Random _random = Random();

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Simulate device connection
    await Future.delayed(const Duration(seconds: 1));
    _isConnected = true;
  }

  Map<String, dynamic> getLatestData() {
    // Simulate real device data
    return {
      'heartbeat': _random.nextInt(40) + 60, // Random between 60-100
      'oxygen': _random.nextDouble() * (100 - 95) + 95, // Random between 95-100
    };
  }

  void dispose() {
    _simulationTimer?.cancel();
    _isConnected = false;
  }
}