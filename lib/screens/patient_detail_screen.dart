import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/patient.dart';
import '../models/heart_rate.dart';
import '../models/alert.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _apiService = ApiService();
  late WebSocketService _webSocketService;
  List<HeartRate> _heartRates = [];
  List<Alert> _alerts = [];
  bool _isLoading = false;
  int _currentHeartRate = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupWebSocket();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final [heartRates, alerts] = await Future.wait([
        _apiService.getHeartRateHistory(widget.patient.id),
        _apiService.getActiveAlerts(widget.patient.id),
      ]);
      setState(() {
        _heartRates = (heartRates as List).cast<HeartRate>();
        _alerts = (alerts as List).cast<Alert>();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupWebSocket() {
    _webSocketService = WebSocketService(
      onHeartRateUpdate: (heartRate) {
        setState(() {
          _currentHeartRate = heartRate.heartRate;
          _heartRates.insert(0, heartRate);
          if (_heartRates.length > 100) {
            _heartRates.removeLast();
          }
        });
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
    _webSocketService.connect(_apiService.token!);
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientInfo(),
                  const SizedBox(height: 20),
                  _buildHeartRateChart(),
                  const SizedBox(height: 20),
                  _buildAlerts(),
                ],
              ),
            ),
    );
  }

  Widget _buildPatientInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin bệnh nhân',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _buildInfoRow('Tên', widget.patient.name),
            _buildInfoRow('Tuổi', widget.patient.age.toString()),
            _buildInfoRow('Giới tính', widget.patient.gender),
            if (widget.patient.phone != null)
              _buildInfoRow('Số điện thoại', widget.patient.phone!),
            if (widget.patient.address != null)
              _buildInfoRow('Địa chỉ', widget.patient.address!),
            if (widget.patient.medicalHistory != null)
              _buildInfoRow(
                'Tiền sử bệnh',
                widget.patient.medicalHistory!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhịp tim',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Hiện tại: $_currentHeartRate BPM',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _heartRates.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.heartRate.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts() {
    if (_alerts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('Không có cảnh báo nào'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cảnh báo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ..._alerts.map((alert) => ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text('Nhịp tim: ${alert.value} BPM'),
                  subtitle: Text(
                    'Thời gian: ${alert.timestamp.toString()}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _apiService.updateAlertStatus(
                          alert.id,
                          'resolved',
                        );
                        await _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    child: const Text('Đã xử lý'),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}