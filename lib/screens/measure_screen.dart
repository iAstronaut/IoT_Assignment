import 'package:flutter/material.dart';
import 'package:heart_rate_monitor/models/heart_rate_data.dart';
import 'package:heart_rate_monitor/services/mock_iot_service.dart';
import 'package:heart_rate_monitor/widgets/heart_rate_chart.dart';
import 'package:heart_rate_monitor/widgets/glass_card.dart';
import 'package:heart_rate_monitor/theme/app_theme.dart';

class MeasureScreen extends StatefulWidget {
  const MeasureScreen({Key? key}) : super(key: key);

  @override
  _MeasureScreenState createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen> {
  final MockIoTService _iotService = MockIoTService();
  final List<HeartRateData> _heartRateData = [];
  bool _isConnected = false;
  String _selectedTimeRange = 'Real-time';

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    await _iotService.connect('mock-device-001');
    setState(() => _isConnected = true);

    _iotService.dataStream?.listen((data) {
      setState(() {
        _heartRateData.add(data);
        if (_heartRateData.length > 20) {
          _heartRateData.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _iotService.dispose();
    super.dispose();
  }

  List<HeartRateData> _getFilteredData() {
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case '1 Hour':
        return _heartRateData.where((data) => data.timestamp.isAfter(now.subtract(const Duration(hours: 1)))).toList();
      case '6 Hours':
        return _heartRateData.where((data) => data.timestamp.isAfter(now.subtract(const Duration(hours: 6)))).toList();
      case '12 Hours':
        return _heartRateData.where((data) => data.timestamp.isAfter(now.subtract(const Duration(hours: 12)))).toList();
      case '24 Hours':
        return _heartRateData.where((data) => data.timestamp.isAfter(now.subtract(const Duration(hours: 24)))).toList();
      default:
        return _heartRateData;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measure Heart Rate'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimeRangeSelector(),
          Expanded(
            child: GlassCard(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Heart Rate',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _heartRateData.isEmpty
                                  ? '--'
                                  : '${_heartRateData.last.value} BPM',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isConnected ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isConnected ? 'Connected' : 'Disconnected',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getHeartRateStatus(_heartRateData.isEmpty
                                  ? 0
                                  : _heartRateData.last.value),
                              style: TextStyle(
                                color: _getStatusColor(_heartRateData.isEmpty
                                    ? 0
                                    : _heartRateData.last.value),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.black26),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _heartRateData.isEmpty
                          ? const Center(
                              child: Text(
                                'Waiting for data...',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : HeartRateChart(
                              data: _getFilteredData(),
                              timeRange: _selectedTimeRange,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeRangeButton('Real-time'),
          _buildTimeRangeButton('1 Hour'),
          _buildTimeRangeButton('6 Hours'),
          _buildTimeRangeButton('12 Hours'),
          _buildTimeRangeButton('24 Hours'),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String timeRange) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTimeRange = timeRange;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedTimeRange == timeRange
            ? AppTheme.secondaryColor
            : Colors.grey,
      ),
      child: Text(
        timeRange,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  String _getHeartRateStatus(int bpm) {
    if (bpm == 0) return 'No Reading';
    if (bpm < 60) return 'Low';
    if (bpm < 100) return 'Normal';
    if (bpm < 140) return 'Elevated';
    return 'High';
  }

  Color _getStatusColor(int bpm) {
    if (bpm == 0) return Colors.black54;
    if (bpm < 60) return Colors.blue;
    if (bpm < 100) return Colors.green;
    if (bpm < 140) return Colors.orange;
    return Colors.red;
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('App Version'),
              onTap: () {
                // Display app version
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                // Handle logout
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}