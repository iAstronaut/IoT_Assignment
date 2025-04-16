import 'package:flutter/material.dart';
import 'package:heart_pulse_app/theme/app_theme.dart';
import 'package:heart_pulse_app/widgets/custom_app_bar.dart';
import 'package:heart_pulse_app/services/coreiot_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:heart_pulse_app/services/measurement_service.dart';

class MeasureScreen extends StatefulWidget {
  const MeasureScreen({super.key});

  @override
  State<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final MeasurementService _measurementService = MeasurementService();
  late AnimationController _pulseController;
  final List<FlSpot> _heartRateData = [];
  final List<FlSpot> _oxygenData = [];
  static const int maxDataPoints = 30;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupPulseAnimation();
    _measurementService.addListener(_updateChartData);
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);
  }

  void _updateChartData() {
    if (!mounted) return;

    setState(() {
      double nextX = _heartRateData.isEmpty ? 0 : _heartRateData.last.x + 1;

      _heartRateData.add(FlSpot(
        nextX,
        _measurementService.currentHeartRate,
      ));
      _oxygenData.add(FlSpot(
        nextX,
        _measurementService.currentOxygen,
      ));

      // Keep only the last 30 points
      if (_heartRateData.length > maxDataPoints) {
        _heartRateData.removeAt(0);
        _oxygenData.removeAt(0);
      }
    });
  }

  void _startMeasurement() async {
    await _measurementService.startMeasurement();
  }

  void _stopMeasurement() {
    _measurementService.stopMeasurement();
    setState(() {
      _heartRateData.clear();
      _oxygenData.clear();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          minX: _heartRateData.isEmpty ? 0 : _heartRateData.first.x,
          maxX: _heartRateData.isEmpty ? maxDataPoints.toDouble() : _heartRateData.last.x + 5,
          minY: 0,
          maxY: 100,
          clipData: FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _heartRateData,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.primaryColor,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.primaryColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
            LineChartBarData(
              spots: _oxygenData,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppTheme.secondaryColor,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppTheme.secondaryColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.secondaryColor.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white,
              tooltipRoundedRadius: 8,
              tooltipBorder: BorderSide(
                color: Colors.grey.withOpacity(0.2),
              ),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final String prefix = touchedSpot.barIndex == 0 ? 'HR: ' : 'SpO2: ';
                  return LineTooltipItem(
                    '$prefix${touchedSpot.y.toStringAsFixed(1)}',
                    TextStyle(
                      color: touchedSpot.barIndex == 0
                          ? AppTheme.primaryColor
                          : AppTheme.secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator:
                (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((spotIndex) {
                final color = barData.color ?? Colors.grey;
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: color,
                    strokeWidth: 2,
                    dashArray: [3, 3],
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 150,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Measure',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_measurementService.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _getStatusIcon(),
                      const SizedBox(width: 12),
                      Text(
                        _measurementService.status,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(_measurementService.status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Measurements Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Heart Rate',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _measurementService.currentHeartRate.toString(),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              'BPM',
                              style: TextStyle(
                                color: AppTheme.primaryColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.air, color: AppTheme.accentColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Oxygen',
                                  style: TextStyle(
                                    color: AppTheme.accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _measurementService.currentOxygen.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            Text(
                              '%',
                              style: TextStyle(
                                color: AppTheme.accentColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Chart
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildChart(),
                  ),
                ),
                const SizedBox(height: 24),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      onPressed: _measurementService.isMeasuring ? null : _startMeasurement,
                      icon: _measurementService.isMeasuring ? Icons.hourglass_empty : Icons.play_arrow,
                      label: 'Start',
                      color: AppTheme.primaryColor,
                    ),
                    _buildControlButton(
                      onPressed: _measurementService.isMeasuring ? _stopMeasurement : null,
                      icon: Icons.stop,
                      label: 'Stop',
                      color: AppTheme.errorColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Error')) return AppTheme.errorColor;
    if (status.contains('Measuring')) return AppTheme.successColor;
    if (status.contains('Connecting')) return AppTheme.warningColor;
    return Colors.grey;
  }

  Icon _getStatusIcon() {
    if (_measurementService.isMeasuring) {
      return const Icon(Icons.favorite, color: AppTheme.successColor);
    } else {
      return const Icon(Icons.favorite_border, color: Colors.grey);
    }
  }
}
