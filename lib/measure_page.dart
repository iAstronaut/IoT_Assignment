import 'package:flutter/material.dart';
import 'package:heart_rate_monitor/models/heart_rate_data.dart';
import 'package:heart_rate_monitor/services/iot_service.dart';
import 'package:heart_rate_monitor/theme/app_theme.dart';
import 'package:heart_rate_monitor/widgets/heart_rate_monitor.dart';
import 'package:heart_rate_monitor/widgets/glass_card.dart';
import 'package:heart_rate_monitor/widgets/gradient_button.dart';
import 'package:heart_rate_monitor/widgets/animated_background.dart';
import 'package:heart_rate_monitor/widgets/health_alert.dart';
import 'package:heart_rate_monitor/widgets/health_metrics_card.dart';
import 'package:share_plus/share_plus.dart';

//About Page
class MeasurePage extends StatefulWidget {
  @override
  _MeasurePageState createState() => _MeasurePageState();
}

class _MeasurePageState extends State<MeasurePage> with SingleTickerProviderStateMixin {
  final IoTService _iotService = IoTService();
  HeartRateData? _lastReading;
  bool _isConnecting = false;
  String? _errorMessage;
  bool _isMetricsExpanded = false;
  late TabController _tabController;
  final List<String> _timeRanges = ['Real-time', '1 Hour', '24 Hours', '7 Days'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _timeRanges.length, vsync: this);
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await _iotService.connect('your-device-id');
      _iotService.dataStream?.listen((data) {
      setState(() {
          _lastReading = data;
        });
        _checkHealthStatus(data);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to device: $e';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _checkHealthStatus(HeartRateData data) {
    // Check heart rate
    if (data.bpm > 100) {
      HealthAlert.show(
        context,
        title: 'Elevated Heart Rate',
        message: 'Your heart rate is above normal range at ${data.bpm} BPM.',
        type: AlertType.warning,
        onAction: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('High Heart Rate Information'),
              content: const Text(
                'A heart rate above 100 BPM at rest may indicate:\n'
                '• Stress or anxiety\n'
                '• Dehydration\n'
                '• Fever or infection\n'
                '• Medication side effects\n\n'
                'If this persists, please consult a healthcare provider.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      );
    } else if (data.bpm < 60) {
      HealthAlert.show(
        context,
        title: 'Low Heart Rate',
        message: 'Your heart rate is below normal range at ${data.bpm} BPM.',
        type: AlertType.warning,
        onAction: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Low Heart Rate Information'),
              content: const Text(
                'A heart rate below 60 BPM at rest may indicate:\n'
                '• High level of fitness\n'
                '• Medication effects\n'
                '• Heart conduction problems\n\n'
                'If you experience dizziness or fatigue, consult a healthcare provider.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      );
    }

    // Check blood pressure
    if (data.systolic != null && data.diastolic != null) {
      if (data.systolic! >= 180 || data.diastolic! >= 120) {
        HealthAlert.show(
          context,
          title: 'Hypertensive Crisis',
          message: 'Your blood pressure is dangerously high at ${data.systolic!.toStringAsFixed(0)}/${data.diastolic!.toStringAsFixed(0)} mmHg.',
          type: AlertType.danger,
          onAction: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('EMERGENCY - Hypertensive Crisis'),
                content: const Text(
                  'This is a medical emergency!\n\n'
                  'Immediate actions needed:\n'
                  '• Call emergency services (911)\n'
                  '• Sit or lie down\n'
                  '• Stay calm and take slow breaths\n'
                  '• If prescribed, take emergency medication\n\n'
                  'Symptoms to watch for:\n'
                  '• Severe headache\n'
                  '• Chest pain\n'
                  '• Vision problems\n'
                  '• Difficulty breathing',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      } else if (data.systolic! >= 140 || data.diastolic! >= 90) {
        HealthAlert.show(
          context,
          title: 'High Blood Pressure',
          message: 'Your blood pressure is elevated at ${data.systolic!.toStringAsFixed(0)}/${data.diastolic!.toStringAsFixed(0)} mmHg.',
          type: AlertType.warning,
          onAction: () {
            // Navigate to blood pressure info
          },
        );
      }
    }

    // Check oxygen levels
    if (data.oxygenLevel != null && data.oxygenLevel! < 95) {
      HealthAlert.show(
        context,
        title: 'Low Oxygen Saturation',
        message: 'Your SpO₂ level is below normal at ${data.oxygenLevel!.toStringAsFixed(1)}%.',
        type: data.oxygenLevel! < 90 ? AlertType.danger : AlertType.warning,
        onAction: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Low Oxygen Level Information'),
              content: Text(
                data.oxygenLevel! < 90
                  ? 'EMERGENCY: SpO₂ below 90% requires immediate medical attention!\n\n'
                    'Take these immediate actions:\n'
                    '• Call emergency services (911)\n'
                    '• Sit upright and take slow deep breaths\n'
                    '• Open windows for fresh air\n'
                    '• If prescribed, use supplemental oxygen'
                  : 'SpO₂ levels below 95% may indicate:\n'
                    '• Respiratory issues\n'
                    '• Sleep apnea\n'
                    '• High altitude\n\n'
                    'Monitor your breathing and consult a healthcare provider if this persists.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _iotService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Health Monitor',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          )
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text('Health Monitor Info',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  content: const SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Normal Ranges:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          )
                        ),
                        SizedBox(height: 12),
                        InfoRow(icon: Icons.favorite, text: 'Heart Rate: 60-100 BPM'),
                        SizedBox(height: 8),
                        InfoRow(icon: Icons.speed, text: 'Blood Pressure: <120/80 mmHg'),
                        SizedBox(height: 8),
                        InfoRow(icon: Icons.air, text: 'Oxygen Level: >95%'),
                        SizedBox(height: 20),
                        Text(
                          'If values are outside these ranges, please consult a healthcare professional.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isConnecting ? null : () {
              _connectToDevice();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reconnecting to device...'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              tabs: _timeRanges.map((range) => Tab(text: range)).toList(),
            ),
          ),
        ),
      ),
        body: Stack(
        children: [
          Container(
                decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
          ),
          AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                if (_lastReading != null)
                  HealthMetricsCard(
                    data: _lastReading!,
                    isExpanded: _isMetricsExpanded,
                    onToggle: () => setState(() => _isMetricsExpanded = !_isMetricsExpanded),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.defaultPadding),
                    child: _errorMessage != null
                        ? _buildErrorCard()
                        : TabBarView(
                            controller: _tabController,
                            children: _timeRanges.map((range) => HeartRateMonitor(
                              dataStream: _iotService.dataStream!,
                              lastReading: _lastReading,
                              timeRange: range,
                            )).toList(),
                          ),
                  ),
                ),
                _buildDeviceStatus(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: _lastReading != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton.extended(
          onPressed: () async {
            if (_lastReading != null) {
              final report = '''
Health Report (${DateTime.now().toString()})
----------------------------------------
Heart Rate: ${_lastReading!.bpm} BPM
Blood Pressure: ${_lastReading!.systolic}/${_lastReading!.diastolic} mmHg
Oxygen Level: ${_lastReading!.oxygenLevel}%
Status: ${_lastReading!.status}
''';
              try {
                await Share.share(report);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to share report: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'DISMISS',
                      onPressed: () {},
                      textColor: Colors.white,
                    ),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.share),
          label: const Text('Share Report'),
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
              size: 48,
            ),
          ),
          const SizedBox(height: AppTheme.defaultPadding),
          Text(
            'Connection Error',
            style: AppTheme.headingStyle.copyWith(
              color: Colors.red.shade400,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: AppTheme.subheadingStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.defaultPadding),
          GradientButton(
            text: 'Retry Connection',
            onPressed: () {
              _connectToDevice();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attempting to reconnect...'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: Icons.refresh,
            isLoading: _isConnecting,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatus() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _iotService.isConnected ? Colors.green : Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: (_iotService.isConnected ? Colors.green : Colors.red).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _iotService.isConnected ? 'Connected' : 'Disconnected',
                style: AppTheme.buttonTextStyle.copyWith(
                  color: _iotService.isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isConnecting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              if (!_isConnecting && _iotService.isConnected)
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(seconds: 1),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: child,
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.battery_full,
                            color: Colors.green[700],
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '95%',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_iotService.isConnected) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.95,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}