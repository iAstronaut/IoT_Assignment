class MeasurementRecord {
  final int id;
  final DateTime timestamp;
  final int heartRate;
  final double oxygen;

  MeasurementRecord({
    required this.id,
    required this.timestamp,
    required this.heartRate,
    required this.oxygen,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'heart_rate': heartRate,
      'oxygen': oxygen,
    };
  }

  factory MeasurementRecord.fromMap(Map<String, dynamic> map) {
    return MeasurementRecord(
      id: map['id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      heartRate: map['heart_rate'],
      oxygen: map['oxygen'],
    );
  }
}