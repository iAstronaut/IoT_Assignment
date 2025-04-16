import 'package:flutter/material.dart';
import 'package:heart_pulse_app/theme/app_theme.dart';
import 'package:heart_pulse_app/services/auth_service.dart';
import 'package:heart_pulse_app/models/user.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isLoading = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement get user profile
      setState(() {
        _user = User(
          id: 1,
          username: 'johndoe',
          role: 'patient',
          email: 'john@example.com',
          fullName: 'John Doe',
          createdAt: DateTime.now(),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _user?.fullName ?? _user?.username ?? '',
                            style: AppTheme.headlineMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _user?.email ?? '',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Profile Details
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile Information',
                            style: AppTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            icon: Icons.person,
                            title: 'Username',
                            value: _user?.username ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            icon: Icons.badge,
                            title: 'Role',
                            value: _user?.role.toUpperCase() ?? '',
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            icon: Icons.calendar_today,
                            title: 'Member Since',
                            value: _user?.createdAt != null
                                ? '${_user!.createdAt.year}-${_user!.createdAt.month.toString().padLeft(2, '0')}-${_user!.createdAt.day.toString().padLeft(2, '0')}'
                                : '',
                          ),
                          const SizedBox(height: 32),

                          // Settings Section
                          Text(
                            'Settings',
                            style: AppTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildSettingTile(
                            icon: Icons.notifications,
                            title: 'Notifications',
                            subtitle: 'Manage notification settings',
                            onTap: () {
                              // TODO: Navigate to notification settings
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.security,
                            title: 'Privacy',
                            subtitle: 'Manage privacy settings',
                            onTap: () {
                              // TODO: Navigate to privacy settings
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.help,
                            title: 'Help & Support',
                            subtitle: 'Get help or contact support',
                            onTap: () {
                              // TODO: Navigate to help screen
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.info,
                            title: 'About App',
                            subtitle: 'Version 1.0.0',
                            onTap: () {
                              // TODO: Show about dialog
                            },
                          ),
                          const SizedBox(height: 32),

                          // Logout Button
                          ElevatedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          title,
          style: AppTheme.titleMedium,
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.bodyMedium,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}