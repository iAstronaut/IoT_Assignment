import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:heart_rate_monitor/models/heart_rate_data.dart';

abstract class IoTService {
  Stream<HeartRateData>? get dataStream;
  bool get isConnected;
  Future<void> connect(String deviceId);
  void dispose();
}

class IoTServiceImpl implements IoTService {
  WebSocketChannel? _channel;
  StreamController<HeartRateData>? _streamController;
  bool _isConnected = false;

  @override
  Stream<HeartRateData>? get dataStream => _streamController?.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect(String deviceId) async {
    try {
      // Replace with your actual WebSocket server URL
      final wsUrl = Uri.parse('ws://your-server-url/ws/$deviceId');
      _channel = WebSocketChannel.connect(wsUrl);
      _streamController = StreamController<HeartRateData>.broadcast();

      _channel!.stream.listen(
        (data) {
          if (data != null) {
            final heartRateData = HeartRateData.fromJson(data);
            _streamController?.add(heartRateData);
          }
        },
        onError: (error) {
          _isConnected = false;
          _streamController?.addError(error);
        },
        onDone: () {
          _isConnected = false;
          dispose();
        },
      );

      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _streamController?.close();
    _isConnected = false;
  }
}