import 'package:flutter/material.dart';
import 'package:heart_pulse_app/theme/app_theme.dart';
import 'package:heart_pulse_app/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:heart_pulse_app/widgets/custom_app_bar.dart';
import 'package:heart_pulse_app/widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> _measurements = [];
  String _selectedPeriod = 'Week';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await ApiService().getMeasurements();
      setState(() {
        _measurements = response['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Measurement History',
                    style: AppTheme.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Details'),
                    ],
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.white,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildDetailsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: Row(
              children: [
                Text('Period:', style: AppTheme.titleMedium),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: ['Day', 'Week', 'Month']
                      .map((period) => DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedPeriod = value!);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Average BPM',
                  value: '75',
                  icon: Icons.favorite,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Max BPM',
                  value: '120',
                  icon: Icons.arrow_upward,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Min BPM',
                  value: '60',
                  icon: Icons.arrow_downward,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Measurements',
                  value: '24',
                  icon: Icons.analytics,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          Container(
            height: 300,
        padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklyData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value['value'].toDouble()))
                        .toList(),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
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

  Widget _buildDetailsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _measurements.length,
      itemBuilder: (context, index) {
        final measurement = _measurements[index];
        final date = DateTime.parse(measurement['timestamp']);
        final value = measurement['value'];
        final status = _getHeartRateStatus(value);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppTheme.cardDecoration,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(value).withOpacity(0.1),
              child: Icon(
                Icons.favorite,
                color: _getStatusColor(value),
              ),
            ),
            title: Text(
              '$value BPM',
              style: AppTheme.titleMedium,
            ),
            subtitle: Text(
              DateFormat('MMM d, y HH:mm').format(date),
              style: AppTheme.bodyMedium,
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(value).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: AppTheme.labelLarge.copyWith(
                  color: _getStatusColor(value),
                ),
              ),
            ),
            onTap: () => _showMeasurementDetails(measurement),
            ),
          );
        },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTheme.labelLarge.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showMeasurementDetails(Map<String, dynamic> measurement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Measurement Details',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Heart Rate', '${measurement['value']} BPM'),
            _buildDetailRow('Date', DateFormat('MMM d, y').format(DateTime.parse(measurement['timestamp']))),
            _buildDetailRow('Time', DateFormat('HH:mm:ss').format(DateTime.parse(measurement['timestamp']))),
            _buildDetailRow('Status', _getHeartRateStatus(measurement['value'])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium,
          ),
          Text(
            value,
            style: AppTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  String _getHeartRateStatus(int value) {
    if (value < 60) return 'Low';
    if (value > 100) return 'High';
    return 'Normal';
  }

  Color _getStatusColor(int value) {
    if (value < 60) return AppTheme.warningColor;
    if (value > 100) return AppTheme.errorColor;
    return AppTheme.successColor;
  }
}