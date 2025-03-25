import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class CoreIoTService {
  // MQTT configuration for Adafruit IO
  static const String mqttHost = 'io.adafruit.com';
  static const int mqttPort = 1883; // MQTT port (use 8883 for SSL)
  static const String username = 'nva212'; // Your Adafruit IO username
  static const String aioKey = 'aio_GfPZ952hW1HIrBSs59FTl9fSxI56'; // Your AIO key
  static const String oxygenFeed = 'nva212/feeds/oxygen'; // Oxygen feed
  static const String heartbeatFeed = 'nva212/feeds/heartbeat'; // Heartbeat feed

  MqttBrowserClient? _client;
  StreamController<Map<String, dynamic>>? _dataStreamController;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  Map<String, dynamic> _lastData = {
    'oxygen': 0.0,
    'heartbeat': 0,
    'timestamp': 0
  };

  // Initialize the service and create a stream for real-time data
  Future<void> initialize() async {
    _dataStreamController = StreamController<Map<String, dynamic>>.broadcast();
    await _connectMqtt();
  }

  // Connect to MQTT broker (Adafruit IO)
  Future<void> _connectMqtt() async {
    if (_client != null) {
      _client!.disconnect();
    }

    try {
      print('Connecting to MQTT broker for Adafruit IO...'); // Debug log

      // Create MQTT client for browser with WebSocket URL including access token
      _client = MqttBrowserClient.withPort(
        'wss://$mqttHost',
        'client_id_${DateTime.now().millisecondsSinceEpoch}',
        mqttPort
      );

      _client!.logging(on: true);
      _client!.keepAlivePeriod = 60;
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onSubscribeFail = _onSubscribeFail;
      _client!.pongCallback = _pongCallback;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier('client_id_${DateTime.now().millisecondsSinceEpoch}')
          .withWillQos(MqttQos.atLeastOnce)
          .authenticateAs(username, aioKey);

      _client!.connectionMessage = connMessage;

      try {
        await _client!.connect();
      } catch (e) {
        print('Exception during connect: $e');
        _client!.disconnect();
        _scheduleReconnect();
        return;
      }

      // Check connection status
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        print('MQTT client connected');
        _isConnected = true;
        _subscribeToFeeds();
      } else {
        print('ERROR: MQTT client connection failed - disconnecting, status is ${_client!.connectionStatus}');
        _client!.disconnect();
        _scheduleReconnect();
        return;
      }

      // Listen for messages
_client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
  final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
  final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
  final topic = c[0].topic;

  try {
    final data = json.decode(payload);

    if (topic == oxygenFeed) {
      _lastData['oxygen'] = _parseDoubleValue(data['value']);
    } else if (topic == heartbeatFeed) {
      _lastData['heartbeat'] = _parseDoubleValue(data['value']);
    }

    _lastData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    _dataStreamController?.add(_lastData);
  } catch (e) {
    print('Error parsing message: $e');
  }
});

    } catch (e) {
      print('Failed to connect to MQTT: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _onConnected() {
    print('Connected to MQTT broker for Adafruit IO');
    _isConnected = true;
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker for Adafruit IO');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _onSubscribeFail(String topic) {
    print('Failed to subscribe to topic: $topic');
  }

  void _pongCallback() {
    print('Ping response received');
  }

  double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Subscribe to Adafruit IO feed topics
  void _subscribeToFeeds() {
    print('Subscribing to Adafruit IO feeds...');
    _client!.subscribe(oxygenFeed, MqttQos.atLeastOnce);
    _client!.subscribe(heartbeatFeed, MqttQos.atLeastOnce);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        print('Attempting to reconnect...');
        _connectMqtt();
      }
    });
  }

  // Get latest data from Adafruit IO
  Map<String, dynamic> getLatestData() {
    return _lastData;
  }

  // Get real-time data stream
  Stream<Map<String, dynamic>>? get dataStream => _dataStreamController?.stream;

  bool get isConnected => _isConnected;

  // Dispose resources
  void dispose() {
    _reconnectTimer?.cancel();
    _client?.disconnect();
    _dataStreamController?.close();
    _isConnected = false;
  }
}
