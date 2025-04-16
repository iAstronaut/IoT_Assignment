import 'package:flutter/material.dart';

class Appointment {
  final int id;
  final int userId;
  final int doctorId;
  final String doctorName;
  final String specialty;
  final DateTime date;
  final String location;
  final String? notes;
  final String status;
  final Color avatarColor;

  Appointment({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.location,
    this.notes,
    required this.status,
    required this.avatarColor,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as int,
      userId: json['userId'] as int,
      doctorId: json['doctorId'] as int,
      doctorName: json['doctorName'] as String,
      specialty: json['specialty'] as String,
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      avatarColor: _getAvatarColor(json['specialty'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'specialty': specialty,
      'date': date.toIso8601String(),
      'location': location,
      'notes': notes,
      'status': status,
    };
  }

  static Color _getAvatarColor(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'cardiologist':
        return Colors.redAccent;
      case 'pulmonologist':
        return Colors.blueAccent;
      case 'general practitioner':
        return Colors.greenAccent;
      case 'neurologist':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  String get formattedDate => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get formattedTime => '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String get statusText {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get timeUntil {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      return 'Past';
    } else if (difference.inDays > 0) {
      return 'In ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minutes';
    } else {
      return 'Now';
    }
  }

  bool get isPast => date.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  Appointment copyWith({
    int? id,
    int? userId,
    int? doctorId,
    String? doctorName,
    String? specialty,
    DateTime? date,
    String? location,
    String? notes,
    String? status,
    Color? avatarColor,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      date: date ?? this.date,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }

  @override
  String toString() {
    return 'Appointment(id: $id, doctorName: $doctorName, specialty: $specialty, date: $formattedDate $formattedTime, status: $status)';
  }
}