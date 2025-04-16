import 'package:flutter/material.dart';

class HeartRateData {
  final int value;
  final DateTime timestamp;
  final String status;
  final String statusMessage;

  HeartRateData({
    required this.value,
    required this.timestamp,
    this.status = 'normal',
    this.statusMessage = '',
  });

  factory HeartRateData.fromJson(Map<String, dynamic> json) {
    return HeartRateData(
      value: json['value'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
      statusMessage: json['statusMessage'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'statusMessage': statusMessage,
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

  String getStatus() {
    if (value < 60) return 'low';
    if (value < 100) return 'normal';
    if (value < 140) return 'elevated';
    return 'high';
  }

  String getStatusMessage() {
    if (value < 60) return 'Heart rate is below normal range';
    if (value < 100) return 'Heart rate is within normal range';
    if (value < 140) return 'Heart rate is slightly elevated';
    return 'Heart rate is high, consider resting';
  }
}