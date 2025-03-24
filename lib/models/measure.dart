import 'package:flutter/material.dart';
import 'dart:math';

class Measure {
  final int id;
  final int heartRate;
  final double oxygenLevel;
  final double systolic;
  final double diastolic;
  final DateTime timestamp;

  Measure({
    required this.id,
    required this.heartRate,
    required this.oxygenLevel,
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
  });

  // Mock data generator
  static List<Measure> getMockMeasures() {
    final random = Random();
    final now = DateTime.now();
    return List.generate(10, (index) {
      return Measure(
        id: index,
        heartRate: 60 + random.nextInt(40),
        oxygenLevel: (95 + random.nextInt(5)).toDouble(),
        systolic: (110 + random.nextInt(30)).toDouble(),
        diastolic: (70 + random.nextInt(20)).toDouble(),
        timestamp: now.subtract(Duration(minutes: index * 5)),
      );
    });
  }

  // Get a single mock measurement
  static Measure getMockMeasure() {
    final random = Random();
    return Measure(
      id: DateTime.now().millisecondsSinceEpoch,
      heartRate: 60 + random.nextInt(40),
      oxygenLevel: (95 + random.nextInt(5)).toDouble(),
      systolic: (110 + random.nextInt(30)).toDouble(),
      diastolic: (70 + random.nextInt(20)).toDouble(),
      timestamp: DateTime.now(),
    );
  }
}
