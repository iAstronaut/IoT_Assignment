import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/heart_rate.dart';

class WebSocketService {
  static const String baseUrl = 'ws://localhost:3000';
  WebSocketChannel? _channel;
  final Function(HeartRate) onHeartRateUpdate;
  final Function(String) onError;

  WebSocketService({
    required this.onHeartRateUpdate,
    required this.onError,
  });

  void connect(String token) {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$baseUrl?token=$token'),
      );

      _channel?.stream.listen(
        (data) {
          try {
            final heartRate = HeartRate.fromJson(data);
            onHeartRateUpdate(heartRate);
          } catch (e) {
            onError('Failed to parse heart rate data: $e');
          }
        },
        onError: (error) {
          onError('WebSocket error: $error');
        },
        onDone: () {
          onError('WebSocket connection closed');
        },
      );
    } catch (e) {
      onError('Failed to connect to WebSocket: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void sendHeartRateUpdate(HeartRate heartRate) {
    if (_channel != null) {
      _channel!.sink.add(heartRate.toJson());
    } else {
      onError('WebSocket not connected');
    }
  }
}