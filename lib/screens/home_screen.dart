import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Import your models and services
import 'package:heart_rate_monitor/models/heart_rate_data.dart';
import 'package:heart_rate_monitor/services/mock_iot_service.dart';
import 'package:heart_rate_monitor/screens/login_screen.dart';
import 'package:heart_rate_monitor/screens/measure_screen.dart';
import 'package:heart_rate_monitor/screens/history_screen.dart';
import 'package:heart_rate_monitor/screens/about_me_screen.dart';
import 'package:heart_rate_monitor/screens/help_screen.dart';
import 'package:heart_rate_monitor/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final MockIoTService _iotService = MockIoTService();
  final List<HeartRateData> _heartRateData = [];
  bool _isConnected = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Activity data for the past week
  final List<Map<String, dynamic>> _weeklyActivityData = [
    {'day': 'Mon', 'steps': 6500, 'calories': 320},
    {'day': 'Tue', 'steps': 8200, 'calories': 410},
    {'day': 'Wed', 'steps': 7800, 'calories': 380},
    {'day': 'Thu', 'steps': 5400, 'calories': 290},
    {'day': 'Fri', 'steps': 9100, 'calories': 450},
    {'day': 'Sat', 'steps': 11200, 'calories': 520},
    {'day': 'Sun', 'steps': 7400, 'calories': 370},
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
    _connectToDevice();

    // Initialize animation controller for smooth loading effects
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

  Future<void> _connectToDevice() async {
    try {
      await _iotService.connect('mock-device-001');
      if (mounted) {
        setState(() => _isConnected = true);
      }

      _iotService.dataStream?.listen((data) {
        if (mounted) {
          setState(() {
            _heartRateData.add(data);
            if (_heartRateData.length > 20) {
              _heartRateData.removeAt(0);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to connect: $e');
      if (mounted) {
        setState(() => _isConnected = false);
      }
    }
  }

  void _handleLogout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _iotService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM d, yyyy').format(now);
    final size = MediaQuery.of(context).size;

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
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -20,
                        child: CircleAvatar(
                          radius: 100,
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutMeScreen()),
                    );
                  },
                ),
              ],
            ),

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
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
                      _buildConnectionStatus(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Health Metrics Cards
                  FadeTransition(
                    opacity: _animation,
                    child: _buildHealthMetricsCards(size),
                  ),
                  const SizedBox(height: 24),

                  // Weekly Activity Section
                  const Text(
                    'Weekly Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _animation,
                    child: _buildActivityChart(),
                  ),
                  const SizedBox(height: 24),

                  // Appointments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming Appointments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._buildAppointmentsList(),
                ]),
              ),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MeasureScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        label: const Text('Measure Now'),
        icon: const Icon(Icons.favorite),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isConnected
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            size: 16,
            color: _isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            _isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: _isConnected ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricsCards(Size size) {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMetricCard('Blood Sugar', '80', 'mg/dL', Icons.bloodtype, Colors.orangeAccent, size),
          _buildMetricCard('Heart Rate', '98', 'bpm', Icons.favorite, Colors.redAccent, size),
          _buildMetricCard('Blood Pressure', '102/72', 'mmHg', Icons.water_drop, Colors.blueAccent, size),
          _buildMetricCard('Oxygen', '98', '%', Icons.air, Colors.tealAccent.shade700, size),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String unit, IconData icon, Color color, Size size) {
    final cardWidth = size.width * 0.23;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Normal',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Steps',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Calories',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12000,
                minY: 0,
                groupsSpace: 20,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.grey.shade800,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String value = rod.toY.round().toString();
                      String label = rodIndex == 0 ? 'Steps' : 'Calories';
                      return BarTooltipItem(
                        '$label: $value',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= _weeklyActivityData.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _weeklyActivityData[value.toInt()]['day'],
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % 3000 != 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_weeklyActivityData.length, (index) {
                  // Ensure index is valid
                  if (index < 0 || index >= _weeklyActivityData.length) {
                    return BarChartGroupData(x: index);
                  }

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _weeklyActivityData[index]['steps'].toDouble(),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF8F6BFD)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: _weeklyActivityData[index]['calories'].toDouble() * 20, // Scale for visibility
                        gradient: const LinearGradient(
                          colors: [AppTheme.secondaryColor, Color(0xFFFF9A9E)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              swapAnimationDuration: const Duration(milliseconds: 250),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAppointmentsList() {
    return _appointments.map((appointment) {
      final formattedDate = DateFormat('EEEE, MMMM d').format(appointment['date']);
      final formattedTime = DateFormat('h:mm a').format(appointment['date']);

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 120,
                  decoration: BoxDecoration(
                    color: appointment['avatarColor'],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: appointment['avatarColor'].withOpacity(0.15),
                  child: Text(
                    appointment['doctor'].split(' ').map((e) => e.isNotEmpty ? e[0] : '').join(''),
                    style: TextStyle(
                      color: appointment['avatarColor'],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            appointment['location'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: appointment['avatarColor'].withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: appointment['avatarColor'],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'In ${DateTime.now().difference(appointment['date']).inDays.abs()} days',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: appointment['avatarColor'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 36,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'An Nguyen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'an.nguyen0212@hcmut.edu.vn',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Premium Member',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              isSelected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.monitor_heart_outlined,
              title: 'Measure',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MeasureScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.history_outlined,
              title: 'History',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Help',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'About Me',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutMeScreen()),
                );
              },
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {},
            ),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: _handleLogout,
              textColor: Colors.redAccent,
              iconColor: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : (iconColor ?? Colors.grey[700]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : (textColor ?? Colors.grey[800]),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 5,
              height: 30,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}