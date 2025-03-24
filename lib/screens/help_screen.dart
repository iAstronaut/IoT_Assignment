import 'package:flutter/material.dart';
import 'package:heart_rate_monitor/widgets/glass_card.dart';
import 'package:heart_rate_monitor/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Information'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Understanding Heart Rate',
            [
              _buildInfoCard(
                'What is Heart Rate?',
                'Heart rate is the number of times your heart beats per minute (BPM). A normal resting heart rate for adults ranges from 60 to 100 BPM.',
                Icons.favorite,
              ),
              _buildInfoCard(
                'Factors Affecting Heart Rate',
                'Age, physical activity, emotions, body position, medications, and air temperature can all affect your heart rate.',
                Icons.psychology,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Common Heart Conditions',
            [
              _buildInfoCard(
                'Tachycardia',
                'A heart rate that exceeds 100 BPM. Can be normal during exercise but concerning at rest.',
                Icons.trending_up,
              ),
              _buildInfoCard(
                'Bradycardia',
                'A heart rate below 60 BPM. Common in athletes but may indicate a problem in others.',
                Icons.trending_down,
              ),
              _buildInfoCard(
                'Arrhythmia',
                'Irregular heartbeat patterns. Can be harmless or indicate a serious condition.',
                Icons.timeline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Emergency Contacts',
            [
              _buildEmergencyContact(
                'Emergency Services',
                '115',
                Icons.emergency,
              ),
              _buildEmergencyContact(
                'HCMUT Medical Center',
                '(+84) 28-3864-7256',
                Icons.local_hospital,
              ),
              _buildEmergencyContact(
                'Health Hotline',
                '19009095',
                Icons.phone,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Healthy Lifestyle Tips',
            [
              _buildInfoCard(
                'Regular Exercise',
                'Engage in moderate aerobic activity for at least 150 minutes per week.',
                Icons.directions_run,
              ),
              _buildInfoCard(
                'Stress Management',
                'Practice relaxation techniques like deep breathing, meditation, or yoga.',
                Icons.spa,
              ),
              _buildInfoCard(
                'Balanced Diet',
                'Eat a diet rich in fruits, vegetables, whole grains, and lean proteins.',
                Icons.restaurant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.black,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContact(String name, String number, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: ListTile(
          leading: Icon(
            icon,
            color: Colors.black,
            size: 28,
          ),
          title: Text(
            name,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            number,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          trailing: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.phone,
                color: Colors.black,
              ),
              onPressed: () {
                // TODO: Implement phone call functionality
              },
            ),
          ),
        ),
      ),
    );
  }
}