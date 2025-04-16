import 'package:flutter/material.dart';
import 'package:heart_pulse_app/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
                    'Help & Support',
                    style: AppTheme.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find answers to common questions and get support',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Start Guide
                    Text(
                      'Quick Start Guide',
                      style: AppTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildGuideCard(
                      icon: Icons.play_circle,
                      title: 'Getting Started',
                      description: 'Learn how to set up your device and take your first measurement',
                      onTap: () {
                        // TODO: Navigate to getting started guide
                      },
                    ),
                    _buildGuideCard(
                      icon: Icons.favorite,
                      title: 'Taking Measurements',
                      description: 'How to take accurate heart rate measurements',
                      onTap: () {
                        // TODO: Navigate to measurement guide
                      },
                    ),
                    _buildGuideCard(
                      icon: Icons.analytics,
                      title: 'Understanding Results',
                      description: 'Learn how to interpret your measurements',
                      onTap: () {
                        // TODO: Navigate to results guide
                      },
                    ),

                    const SizedBox(height: 32),

                    // FAQs
                    Text(
                      'Frequently Asked Questions',
                      style: AppTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildFaqItem(
                      question: 'How accurate are the measurements?',
                      answer: 'Our device provides medical-grade accuracy with a margin of error of ±2 BPM when used correctly.',
                    ),
                    _buildFaqItem(
                      question: 'How often should I measure my heart rate?',
                      answer: 'For general health monitoring, measuring once or twice a day is sufficient. Consult your healthcare provider for personalized recommendations.',
                    ),
                    _buildFaqItem(
                      question: 'What do the different heart rate zones mean?',
                      answer: 'Normal resting heart rate is typically between 60-100 BPM. Below 60 BPM is considered low, and above 100 BPM is considered high.',
                    ),

                    const SizedBox(height: 32),

                    // Contact Support
                    Text(
                      'Need More Help?',
                      style: AppTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Support',
                            style: AppTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          _buildContactMethod(
                            icon: Icons.email,
                            title: 'Email Support',
                            value: 'support@heartpulse.com',
                            onTap: () {
                              // TODO: Launch email client
                            },
                          ),
                          const Divider(height: 32),
                          _buildContactMethod(
                            icon: Icons.phone,
                            title: 'Phone Support',
                            value: '+1 (555) 123-4567',
                            onTap: () {
                              // TODO: Launch phone dialer
                            },
                          ),
                          const Divider(height: 32),
                          _buildContactMethod(
                            icon: Icons.chat,
                            title: 'Live Chat',
                            value: 'Available 24/7',
                            onTap: () {
                              // TODO: Open live chat
                            },
                          ),
                        ],
                      ),
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

  Widget _buildGuideCard({
    required IconData icon,
    required String title,
    required String description,
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
          description,
          style: AppTheme.bodyMedium,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            question,
            style: AppTheme.titleMedium,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: AppTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
                  style: AppTheme.labelLarge,
                ),
                Text(
                  value,
                  style: AppTheme.titleMedium,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}