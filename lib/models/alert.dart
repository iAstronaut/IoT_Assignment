class Alert {
  final int id;
  final int patientId;
  final String type;
  final String value;
  final DateTime timestamp;
  final String status;

  Alert({
    required this.id,
    required this.patientId,
    required this.type,
    required this.value,
    required this.timestamp,
    required this.status,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as int,
      patientId: json['patientId'] as int,
      type: json['type'] as String,
      value: json['value'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'type': type,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }
}