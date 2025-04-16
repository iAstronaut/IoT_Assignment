import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:heart_pulse_app/theme/app_theme.dart';
import 'package:heart_pulse_app/screens/login_screen.dart';
import 'package:heart_pulse_app/services/auth_service.dart';
import 'package:heart_pulse_app/services/api_service.dart';
import 'package:heart_pulse_app/services/measurement_service.dart';
import 'package:heart_pulse_app/services/database_service.dart';
import 'package:heart_pulse_app/models/measurement_record.dart';
import 'package:heart_pulse_app/services/coreiot_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _unreadNotifications = 3;
  Map<String, dynamic> _latestData = {};
  final ApiService _apiService = ApiService();
  final MeasurementService _measurementService = MeasurementService();
  StreamSubscription? _measurementSubscription;
  int _currentHeartRate = 0;
  double _currentOxygen = 0.0;
  final CoreIoTService _coreIoTService = CoreIoTService();

  // Activity data for the past week
  List<Map<String, dynamic>> _weeklyActivityData = [
    {'day': 'Mon', 'heartRate': 78, 'oxygen': 96},
    {'day': 'Tue', 'heartRate': 82, 'oxygen': 95},
    {'day': 'Wed', 'heartRate': 80, 'oxygen': 97},
    {'day': 'Thu', 'heartRate': 75, 'oxygen': 94},
    {'day': 'Fri', 'heartRate': 85, 'oxygen': 98},
    {'day': 'Sat', 'heartRate': 90, 'oxygen': 92},
    {'day': 'Sun', 'heartRate': 77, 'oxygen': 93},
  ];

  // Upcoming appointments
  final List<Map<String, dynamic>> _appointments = [
    {
      'doctor': 'Dr. Tai Anh Tran',
      'specialty': 'Cardiologist',
      'date': DateTime.now().add(const Duration(days: 3)),
      'location': 'Heart Health Clinic',
      'avatarColor': Colors.redAccent,
    },
    {
      'doctor': 'Dr. Dat Tien Tran',
      'specialty': 'General Practitioner',
      'date': DateTime.now().add(const Duration(days: 10)),
      'location': 'Community Medical Center',
      'avatarColor': Colors.blueAccent,
    }
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _fetchInitialData();
    _subscribeMeasurements();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  void _subscribeMeasurements() {
    _measurementSubscription = _measurementService.measurementStream.listen((data) {
      if (mounted) {
        setState(() {
          _currentHeartRate = data.heartRate;
          _currentOxygen = data.oxygen;
        });
      }
    });
  }

  Future<void> _fetchInitialData() async {
    try {
      // Fetch latest health metrics
      final metrics = await _apiService.getLatestHealthMetrics();
      // Fetch weekly activity data
      final weeklyData = await _apiService.getWeeklyActivityData();
      // Fetch appointments
      final appointments = await _apiService.getUpcomingAppointments();

      if (mounted) {
        setState(() {
          _latestData = metrics;
          if (weeklyData.isNotEmpty) {
            _weeklyActivityData = weeklyData;
          }
          // Update appointments if needed
        });
      }
    } catch (e) {
      print('Error fetching initial data: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _measurementSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM d, yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Health Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        // Navigate to notifications
                      },
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _unreadNotifications.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await AuthService.logout();
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            ),

            // Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Connection Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Health Metrics Cards
                    FadeTransition(
                      opacity: _animation,
                      child: _buildHealthMetricsCards(),
                    ),
                    const SizedBox(height: 24),

                    // Weekly Activity Chart
                    const Text(
                      'Weekly Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildWeeklyChart(),
                    ),
                    const SizedBox(height: 24),

                    // Upcoming Appointments
                    const Text(
                      'Upcoming Appointments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._appointments.map((appointment) => _buildAppointmentCard(appointment)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to measure screen
          Navigator.pushNamed(context, '/measure');
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.favorite),
        label: const Text('Measure Now'),
      ),
    );
  }

  Widget _buildHealthMetricsCards() {
    return SizedBox(
      height: 180,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMetricCard('Heart Rate', _currentHeartRate.toString(), 'bpm', Icons.favorite, AppTheme.primaryColor),
            const SizedBox(width: 16),
            _buildMetricCard('Oxygen', _currentOxygen.toStringAsFixed(1), '%', Icons.air, AppTheme.accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String unit, IconData icon, Color color) {
    final double numericValue = double.tryParse(value.split('/')[0]) ?? 0;
    final String status = _getHealthStatus(title, numericValue);
    final Color statusColor = _getStatusColor(status);

    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Center(
            child: Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.7),
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthStatus(String metric, double value) {
    switch (metric) {
      case 'Heart Rate':
        if (value < 60) return 'Low';
        if (value > 100) return 'High';
        return 'Normal';
      case 'Oxygen':
        if (value < 95) return 'Low';
        if (value > 100) return 'High';
        return 'Normal';
      case 'Blood Pressure':
        if (value < 90) return 'Low';
        if (value > 140) return 'High';
        return 'Normal';
      case 'Temperature':
        if (value < 36) return 'Low';
        if (value > 37.5) return 'High';
        return 'Normal';
      default:
        return 'Normal';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Low':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(
                  Icons.hourglass_empty,
                  color: Colors.white,
                ),
                label: const Text(
                  'Start',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(
                  Icons.stop,
                  color: Colors.white,
                ),
                label: const Text(
                  'Stop',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: appointment['avatarColor'],
            child: Text(
              appointment['doctor'].toString().substring(4, 6),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['doctor'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment['specialty'],
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(appointment['date']),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchWeeklyData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        // Create spots for heart rate and oxygen
        final heartRateSpots = records.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value['AvgHeartRate'].toDouble());
        }).toList();

        final oxygenSpots = records.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value['AvgOxygen'].toDouble());
        }).toList();

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 10,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: const Color(0xffe7e8ec),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: const Color(0xffe7e8ec),
                  strokeWidth: 1,
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
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= records.length) return const Text('');
                    final date = DateTime.parse(records[value.toInt()]['ReadingDate'].toString());
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        _getDayName(date),
                        style: const TextStyle(
                          color: Color(0xff68737d),
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Color(0xff68737d),
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                  reservedSize: 42,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xffe7e8ec)),
            ),
            minX: 0,
            maxX: (records.length - 1).toDouble(),
            minY: 0,
            maxY: 100,
            lineBarsData: [
              // Heart Rate Line
              LineChartBarData(
                spots: heartRateSpots,
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.5),
                    AppTheme.primaryColor,
                  ],
                ),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.2),
                      AppTheme.primaryColor.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Oxygen Line
              LineChartBarData(
                spots: oxygenSpots,
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentColor.withOpacity(0.5),
                    AppTheme.accentColor,
                  ],
                ),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentColor.withOpacity(0.2),
                      AppTheme.accentColor.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchWeeklyData() async {
    try {
      // Initialize CoreIoTService if not already initialized
      if (!_coreIoTService.isConnected) {
        await _coreIoTService.initialize();
      }

      // Get latest data from CoreIoTService
      final latestData = _coreIoTService.getLatestData();

      // For now, return a simulated weekly data since CoreIoTService
      // only provides latest readings
      return [
        {
          'ReadingDate': DateTime.now(),
          'AvgHeartRate': latestData['heartbeat'] ?? 0,
          'AvgOxygen': latestData['oxygen'] ?? 0,
        }
      ];
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    final difference = dateToCheck.difference(today).inDays;

    switch (difference) {
      case 0:
        return 'Today';
      case -1:
        return 'Yesterday';
      default:
        return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    }
  }
}
