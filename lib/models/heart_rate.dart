class HeartRate {
  final int id;
  final int patientId;
  final int value;
  final DateTime timestamp;
  final String? notes;
  final bool isAbnormal;

  HeartRate({
    required this.id,
    required this.patientId,
    required this.value,
    required this.timestamp,
    this.notes,
    required this.isAbnormal,
  });

  factory HeartRate.fromJson(Map<String, dynamic> json) {
    return HeartRate(
      id: json['id'] as int,
      patientId: json['patientId'] as int,
      value: json['value'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
      isAbnormal: json['isAbnormal'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'isAbnormal': isAbnormal,
    };
  }

  HeartRate copyWith({
    int? id,
    int? patientId,
    int? value,
    DateTime? timestamp,
    String? notes,
    bool? isAbnormal,
  }) {
    return HeartRate(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      isAbnormal: isAbnormal ?? this.isAbnormal,
    );
  }
}

class HeartRateStatistics {
  final double average;
  final int min;
  final int max;
  final int totalReadings;

  HeartRateStatistics({
    required this.average,
    required this.min,
    required this.max,
    required this.totalReadings,
  });

  factory HeartRateStatistics.fromJson(Map<String, dynamic> json) {
    return HeartRateStatistics(
      average: (json['average'] as num).toDouble(),
      min: json['min'] as int,
      max: json['max'] as int,
      totalReadings: json['totalReadings'] as int,
    );
  }
}