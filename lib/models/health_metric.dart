class HealthMetric {
  final int id;
  final int userId;
  final double heartRate;
  final double? bloodOxygen;
  final String? bloodPressure;
  final double? temperature;
  final DateTime timestamp;
  final String? status;
  final String? notes;

  HealthMetric({
    required this.id,
    required this.userId,
    required this.heartRate,
    this.bloodOxygen,
    this.bloodPressure,
    this.temperature,
    required this.timestamp,
    this.status,
    this.notes,
  });

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['id'] as int,
      userId: json['userId'] as int,
      heartRate: (json['heartRate'] as num).toDouble(),
      bloodOxygen: json['bloodOxygen'] != null
          ? (json['bloodOxygen'] as num).toDouble()
          : null,
      bloodPressure: json['bloodPressure'] as String?,
      temperature: json['temperature'] != null
          ? (json['temperature'] as num).toDouble()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'heartRate': heartRate,
      'bloodOxygen': bloodOxygen,
      'bloodPressure': bloodPressure,
      'temperature': temperature,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  HealthMetric copyWith({
    int? id,
    int? userId,
    double? heartRate,
    double? bloodOxygen,
    String? bloodPressure,
    double? temperature,
    DateTime? timestamp,
    String? status,
    String? notes,
  }) {
    return HealthMetric(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      heartRate: heartRate ?? this.heartRate,
      bloodOxygen: bloodOxygen ?? this.bloodOxygen,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      temperature: temperature ?? this.temperature,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'HealthMetric(id: $id, userId: $userId, heartRate: $heartRate, bloodOxygen: $bloodOxygen, bloodPressure: $bloodPressure, temperature: $temperature, timestamp: $timestamp, status: $status)';
  }

  String getStatusDescription() {
    if (status == null) return 'Unknown';

    switch (status!.toLowerCase()) {
      case 'normal':
        return 'Your vital signs are within normal range';
      case 'elevated':
        return 'Your vital signs are slightly elevated';
      case 'high':
        return 'Your vital signs are high - please consult a doctor';
      case 'low':
        return 'Your vital signs are low - please consult a doctor';
      default:
        return 'Status: $status';
    }
  }

  bool isNormal() {
    final bool isHeartRateNormal = heartRate >= 60 && heartRate <= 100;
    final bool isOxygenNormal = bloodOxygen == null || (bloodOxygen! >= 95 && bloodOxygen! <= 100);
    final bool isTemperatureNormal = temperature == null || (temperature! >= 36.1 && temperature! <= 37.2);

    return isHeartRateNormal && isOxygenNormal && isTemperatureNormal;
  }
}