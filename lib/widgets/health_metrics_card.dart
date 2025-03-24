import 'package:flutter/material.dart';
import 'package:heart_rate_monitor/theme/app_theme.dart';
import 'package:heart_rate_monitor/models/heart_rate_data.dart';

class HealthMetricsCard extends StatelessWidget {
  final HeartRateData data;
  final bool isExpanded;
  final VoidCallback onToggle;

  const HealthMetricsCard({
    Key? key,
    required this.data,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildMetricBox(
                    'Heart Rate',
                    '${data.bpm}',
                    'BPM',
                    _getHeartRateColor(data.bpm),
                    Icons.favorite,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricBox(
                    'SpO₂',
                    '${data.oxygenLevel?.toStringAsFixed(1) ?? '--'}',
                    '%',
                    _getOxygenColor(data.oxygenLevel),
                    Icons.air,
                  ),
                  const SizedBox(width: 8),
                  _buildMetricBox(
                    'Blood Pressure',
                    '${data.systolic?.toStringAsFixed(0) ?? '--'}/${data.diastolic?.toStringAsFixed(0) ?? '--'}',
                    'mmHg',
                    _getBPColor(data.systolic, data.diastolic),
                    Icons.speed,
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Pulse Interval', '${_calculatePulseInterval(data.bpm)} ms'),
                    const Divider(height: 16),
                    _buildDetailRow('Heart Rate Variability', '${_calculateHRV()} ms'),
                    const Divider(height: 16),
                    _buildDetailRow('Perfusion Index', '${_calculatePI()} %'),
                    const Divider(height: 16),
                    _buildDetailRow('Mean Arterial Pressure', '${_calculateMAP(data.systolic, data.diastolic)} mmHg'),
                    const SizedBox(height: 16),
                    _buildTrendIndicator(),
                  ],
                ),
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String title, String value, String unit, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.trending_up,
          color: Colors.green[700],
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Trending within normal range',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getHeartRateColor(int bpm) {
    if (bpm < 60) return Colors.blue;
    if (bpm > 100) return Colors.orange;
    return Colors.green;
  }

  Color _getOxygenColor(double? spo2) {
    if (spo2 == null) return Colors.grey;
    if (spo2 < 90) return Colors.red;
    if (spo2 < 95) return Colors.orange;
    return Colors.green;
  }

  Color _getBPColor(double? systolic, double? diastolic) {
    if (systolic == null || diastolic == null) return Colors.grey;
    if (systolic >= 180 || diastolic >= 120) return Colors.red;
    if (systolic >= 140 || diastolic >= 90) return Colors.orange;
    return Colors.green;
  }

  int _calculatePulseInterval(int bpm) {
    return (60000 / bpm).round(); // Convert BPM to milliseconds between beats
  }

  double _calculateHRV() {
    // Mock HRV calculation
    return 45.5;
  }

  double _calculatePI() {
    // Mock Perfusion Index
    return 2.8;
  }

  double _calculateMAP(double? systolic, double? diastolic) {
    if (systolic == null || diastolic == null) return 0;
    return ((2 * diastolic) + systolic) / 3;
  }
}