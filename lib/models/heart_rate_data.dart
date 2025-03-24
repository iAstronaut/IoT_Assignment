import 'package:flutter/material.dart';

class HeartRateData {
  final int bpm;
  final DateTime timestamp;
  final String status;
  final double? systolic;
  final double? diastolic;
  final double? oxygenLevel;
  final String deviceId;

  HeartRateData({
    required this.bpm,
    required this.timestamp,
    required this.status,
    required this.deviceId,
    this.systolic,
    this.diastolic,
    this.oxygenLevel,
  });

  factory HeartRateData.fromJson(Map<String, dynamic> json) {
    return HeartRateData(
      bpm: json['bpm'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      deviceId: json['device_id'] as String,
      systolic: json['systolic']?.toDouble(),
      diastolic: json['diastolic']?.toDouble(),
      oxygenLevel: json['oxygen_level']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bpm': bpm,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'device_id': deviceId,
      'systolic': systolic,
      'diastolic': diastolic,
      'oxygen_level': oxygenLevel,
    };
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'normal':
        return '#4CAF50';
      case 'elevated':
        return '#FFC107';
      case 'high':
        return '#F44336';
      case 'low':
        return '#2196F3';
      default:
        return '#9E9E9E';
    }
  }

  String get statusMessage {
    switch (status.toLowerCase()) {
      case 'normal':
        return 'Your heart rate is within normal range';
      case 'elevated':
        return 'Your heart rate is slightly elevated';
      case 'high':
        return 'Your heart rate is high, please take precautions';
      case 'low':
        return 'Your heart rate is low, please take precautions';
      default:
        return 'Status unknown';
    }
  }
}