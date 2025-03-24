import 'package:flutter/material.dart';
import 'package:heart_rate_monitor/models/heart_rate_data.dart';
import 'package:heart_rate_monitor/widgets/glass_card.dart';
import 'package:heart_rate_monitor/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<HeartRateData> _mockHistoryData = [
    HeartRateData(value: 72, timestamp: DateTime.now().subtract(const Duration(hours: 1))),
    HeartRateData(value: 75, timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    HeartRateData(value: 68, timestamp: DateTime.now().subtract(const Duration(hours: 3))),
    HeartRateData(value: 82, timestamp: DateTime.now().subtract(const Duration(hours: 4))),
    HeartRateData(value: 88, timestamp: DateTime.now().subtract(const Duration(hours: 5))),
  ];

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getHeartRateColor(int bpm) {
    if (bpm < 60) return Colors.blue;
    if (bpm < 100) return Colors.green;
    if (bpm < 140) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement History'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockHistoryData.length,
        itemBuilder: (context, index) {
          final data = _mockHistoryData[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GlassCard(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getHeartRateColor(data.value).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${data.value}',
                      style: TextStyle(
                        color: _getHeartRateColor(data.value),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Heart Rate: ${data.value} BPM',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Measured ${_getTimeAgo(data.timestamp)}',
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
                trailing: Text(
                  DateFormat('HH:mm').format(data.timestamp),
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}