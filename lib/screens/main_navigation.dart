import 'package:flutter/material.dart';
import 'package:heart_pulse_app/screens/home_screen.dart';
import 'package:heart_pulse_app/screens/measure_screen.dart';
import 'package:heart_pulse_app/screens/history_screen.dart';
import 'package:heart_pulse_app/screens/about_me_screen.dart';
import 'package:heart_pulse_app/theme/app_theme.dart';
import 'package:heart_pulse_app/services/auth_service.dart';
import 'package:heart_pulse_app/widgets/custom_app_bar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final TabController _tabController;
  final List<Widget> _screens = [
    const HomeScreen(),
    const MeasureScreen(),
    const HistoryScreen(),
    const AboutMeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _screens.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
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
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
              _tabController.animateTo(index);
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: _currentIndex == 0 ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
              ),
              selectedIcon: const Icon(
                Icons.home,
                color: AppTheme.primaryColor,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.favorite_outline,
                color: _currentIndex == 1 ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
              ),
              selectedIcon: const Icon(
                Icons.favorite,
                color: AppTheme.primaryColor,
              ),
              label: 'Measure',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.history_outlined,
                color: _currentIndex == 2 ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
              ),
              selectedIcon: const Icon(
                Icons.history,
                color: AppTheme.primaryColor,
              ),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                color: _currentIndex == 3 ? AppTheme.primaryColor : AppTheme.secondaryTextColor,
              ),
              selectedIcon: const Icon(
                Icons.person,
                color: AppTheme.primaryColor,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AuthService.currentUser?.username ?? 'Guest',
                    style: AppTheme.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    AuthService.currentUser?.role ?? '',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help'),
              onTap: () {
                Navigator.pushNamed(context, '/help');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text('Logout'),
              onTap: () async {
                await AuthService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}