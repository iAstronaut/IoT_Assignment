import 'package:flutter/material.dart';
import 'package:heart_rate_monitor/widgets/health_info_card.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Information'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
                decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: const [
            HealthInfoCard(
              title: 'Heart Rate Zones',
              description: 'Understanding your heart rate zones is crucial for monitoring your cardiovascular health and optimizing your workouts.',
              icon: Icons.favorite,
              color: Colors.red,
              bulletPoints: [
                'Resting Heart Rate (60-100 BPM): Normal rate when you\'re at rest',
                'Fat Burning Zone (70-80% of max): Ideal for weight management',
                'Cardio Zone (80-90% of max): Improves cardiovascular fitness',
                'Peak Zone (90-100% of max): Increases performance ceiling',
                'Warning Signs: Irregular rhythm, extreme rates, or unexplained changes',
              ],
            ),
            HealthInfoCard(
              title: 'Blood Pressure Readings',
              description: 'Blood pressure is measured using two numbers: systolic (top) and diastolic (bottom) pressure.',
              icon: Icons.speed,
              color: Colors.orange,
              bulletPoints: [
                'Normal: Less than 120/80 mmHg',
                'Elevated: 120-129/<80 mmHg',
                'Stage 1 Hypertension: 130-139/80-89 mmHg',
                'Stage 2 Hypertension: 140+/90+ mmHg',
                'Hypertensive Crisis: 180+/120+ mmHg (Emergency)',
              ],
            ),
            HealthInfoCard(
              title: 'Oxygen Saturation (SpO₂)',
              description: 'SpO₂ measures the percentage of oxygen in your blood. Normal levels are crucial for overall health.',
              icon: Icons.air,
              color: Colors.blue,
              bulletPoints: [
                'Normal Range: 95-100%',
                'Mild Hypoxemia: 90-94%',
                'Moderate Hypoxemia: 85-89%',
                'Severe Hypoxemia: Below 85%',
                'Seek immediate medical attention if below 90%',
              ],
            ),
            HealthInfoCard(
              title: 'Common Heart Conditions',
              description: 'Understanding common heart conditions can help you identify potential health issues early.',
              icon: Icons.medical_services,
              color: Colors.purple,
              bulletPoints: [
                'Arrhythmia: Irregular heartbeat patterns',
                'Tachycardia: Abnormally fast heart rate',
                'Bradycardia: Abnormally slow heart rate',
                'Hypertension: High blood pressure',
                'Heart Failure: Reduced pumping efficiency',
              ],
            ),
            HealthInfoCard(
              title: 'Lifestyle Recommendations',
              description: 'Maintaining a healthy lifestyle is key to preventing heart-related issues.',
              icon: Icons.self_improvement,
              color: Colors.green,
              bulletPoints: [
                'Regular exercise (150 minutes/week moderate activity)',
                'Balanced diet rich in fruits, vegetables, and whole grains',
                'Adequate sleep (7-9 hours per night)',
                'Stress management through relaxation techniques',
                'Regular health check-ups and screenings',
              ],
            ),
            HealthInfoCard(
              title: 'Emergency Signs',
              description: 'Recognize these warning signs that require immediate medical attention.',
              icon: Icons.warning,
              color: Colors.red,
              bulletPoints: [
                'Chest pain or pressure lasting more than a few minutes',
                'Difficulty breathing or shortness of breath',
                'Unexplained dizziness or fainting',
                'Rapid or irregular heartbeat with other symptoms',
                'Severe sweating with chest discomfort',
              ],
            ),
                                      ],
                                    ),
                                  ),
    );
  }
}