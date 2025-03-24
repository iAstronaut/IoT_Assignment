import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:heart_rate_monitor/models/heart_rate_data.dart';
import 'package:heart_rate_monitor/theme/app_theme.dart';
import 'package:heart_rate_monitor/widgets/glass_card.dart';
import 'package:heart_rate_monitor/widgets/pulse_loading.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HeartRateMonitor extends StatefulWidget {
  final Stream<HeartRateData> dataStream;
  final HeartRateData? lastReading;
  final String timeRange;

  const HeartRateMonitor({
    Key? key,
    required this.dataStream,
    required this.lastReading,
    required this.timeRange,
  }) : super(key: key);

  @override
  State<HeartRateMonitor> createState() => _HeartRateMonitorState();
}

class _HeartRateMonitorState extends State<HeartRateMonitor> with SingleTickerProviderStateMixin {
  final List<FlSpot> _dataPoints = [];
  final List<FlSpot> _ecgPoints = [];
  final int _maxDataPoints = 30;
  final int _maxEcgPoints = 100;
  double _minX = 0;
  double _maxX = 30;
  double _minY = 40;
  double _maxY = 120;
  double _maxBpm = 0;
  double _minBpm = double.infinity;
  double _avgBpm = 0;
  late AnimationController _pulseController;
  Timer? _blinkTimer;
  Timer? _ecgTimer;
  bool _showBlink = true;
  bool _hasArrhythmia = false;
  double _qtInterval = 0.0;
  List<double> _hrvIntervals = [];
  StreamSubscription<HeartRateData>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupDataStream();
    _setupEcgSimulation();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Simulate ECG monitor blinking
    _blinkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _showBlink = !_showBlink;
        });
      }
    });
  }

  void _setupEcgSimulation() {
    _ecgTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (mounted && _dataPoints.isNotEmpty) {
        setState(() {
          final lastBpm = _dataPoints.last.y;
          final now = DateTime.now().millisecondsSinceEpoch.toDouble();

          // Simulate ECG waveform based on current heart rate
          final cycleLength = 60000 / lastBpm; // ms per beat
          final position = (now % cycleLength) / cycleLength;

          double ecgValue = _simulateEcgWave(position);
          _ecgPoints.add(FlSpot(now, ecgValue));

          if (_ecgPoints.length > _maxEcgPoints) {
            _ecgPoints.removeAt(0);
          }
        });
      }
    });
  }

  double _simulateEcgWave(double position) {
    // Simplified ECG wave simulation
    if (position < 0.1) {
      return 60 + math.sin(position * 31.4) * 5; // P wave
    } else if (position < 0.2) {
      return 60 + math.sin(position * 31.4) * 40; // QRS complex
    } else if (position < 0.4) {
      return 60 + math.sin(position * 31.4) * 10; // T wave
    } else {
      return 60; // Baseline
    }
  }

  void _updateArrhythmiaStatus() {
    if (_dataPoints.length < 3) return;

    // Calculate RR intervals
    List<double> rrIntervals = [];
    for (int i = 1; i < _dataPoints.length; i++) {
      double interval = _dataPoints[i].x - _dataPoints[i - 1].x;
      rrIntervals.add(interval);
    }

    // Check for irregular intervals
    double avgInterval = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    int irregularCount = rrIntervals.where((interval) {
      return (interval - avgInterval).abs() > avgInterval * 0.2;
    }).length;

    _hasArrhythmia = irregularCount > rrIntervals.length * 0.2;

    // Update HRV intervals for time-domain analysis
    _hrvIntervals = rrIntervals;

    // Estimate QT interval (simplified)
    _qtInterval = avgInterval * 0.4;
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _pulseController.dispose();
    _blinkTimer?.cancel();
    _ecgTimer?.cancel();
    super.dispose();
  }

  void _setupDataStream() {
    // Cancel existing subscription if any
    _dataSubscription?.cancel();

    _dataSubscription = widget.dataStream.listen((data) {
      if (!mounted) return;

      setState(() {
        final now = DateTime.now().millisecondsSinceEpoch.toDouble();

        // Add new data point
        _dataPoints.add(FlSpot(now, data.bpm.toDouble()));

        // Keep only last _maxDataPoints
        if (_dataPoints.length > _maxDataPoints) {
          _dataPoints.removeAt(0);
        }

        // Update statistics
        _maxBpm = math.max(_maxBpm, data.bpm.toDouble());
        _minBpm = math.min(_minBpm, data.bpm.toDouble());
        _avgBpm = _dataPoints.map((p) => p.y).reduce((a, b) => a + b) / _dataPoints.length;

        // Update axis ranges for smooth scrolling effect
        if (_dataPoints.isNotEmpty) {
          _minX = _dataPoints.first.x;
          _maxX = _dataPoints.last.x;
          // Adjust Y range dynamically based on current values
          double minValue = _dataPoints.map((p) => p.y).reduce((a, b) => math.min(a.toDouble(), b.toDouble()));
          double maxValue = _dataPoints.map((p) => p.y).reduce((a, b) => math.max(a.toDouble(), b.toDouble()));
          _minY = (minValue - 10).clamp(40, 200);
          _maxY = (maxValue + 10).clamp(40, 200);
        }
      });
    });
  }

  String _formatTimestamp(double timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    return DateFormat('HH:mm:ss').format(date);
  }

  String _getDetailedStatus(double bpm, bool hasArrhythmia) {
    if (hasArrhythmia) return 'Irregular Rhythm';
    if (bpm < 60) return 'Bradycardia';
    if (bpm > 100) return 'Tachycardia';
    return 'Normal Sinus Rhythm';
  }

  Color _getStatusColor(double bpm) {
    if (bpm < 60) return Colors.blue;
    if (bpm > 100) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        children: [
          _buildChartHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildChart(),
          ),
          const SizedBox(height: 16),
          _buildChartFooter(),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_dataPoints.isEmpty) {
      return const Center(
        child: PulseLoading(
          message: 'Waiting for heart rate data...',
          size: 80,
          color: Colors.greenAccent,
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: _minX,
        maxX: _maxX,
        minY: _minY,
        maxY: _maxY,
        clipData: FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _formatTimestamp(value),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                );
              },
              interval: (_maxX - _minX) / 5,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                );
              },
              interval: 20,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _dataPoints,
            isCurved: true,
            curveSmoothness: 0.35,
            color: Colors.greenAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Colors.greenAccent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.greenAccent.withOpacity(0.2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.greenAccent.withOpacity(0.2),
                  Colors.greenAccent.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueAccent.withOpacity(0.8),
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(0)} BPM\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: _formatTimestamp(touchedSpot.x),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChartHeader() {
    final latestBpm = _dataPoints.isNotEmpty ? _dataPoints.last.y : 0.0;
    final heartRateStatus = _getDetailedStatus(latestBpm, _hasArrhythmia);
    final statusColor = _hasArrhythmia ? Colors.red : _getStatusColor(latestBpm);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heart Rate',
              style: AppTheme.headingStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  heartRateStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_dataPoints.isNotEmpty)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: latestBpm),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Text(
                '${value.toInt()} BPM',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildChartFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard('Min', _minBpm == double.infinity ? '--' : _minBpm.toStringAsFixed(0)),
        _buildStatCard('Avg', _dataPoints.isEmpty ? '--' : _avgBpm.toStringAsFixed(0)),
        _buildStatCard('Max', _maxBpm == 0 ? '--' : _maxBpm.toStringAsFixed(0)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value${value != '--' ? ' BPM' : ''}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}