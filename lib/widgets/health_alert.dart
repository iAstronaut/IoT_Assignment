import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_rate_monitor/theme/app_theme.dart';

class HealthAlert extends StatefulWidget {
  final String title;
  final String message;
  final AlertType type;
  final VoidCallback? onAction;

  const HealthAlert({
    Key? key,
    required this.title,
    required this.message,
    required this.type,
    this.onAction,
  }) : super(key: key);

  static void show(BuildContext context, {
    required String title,
    required String message,
    required AlertType type,
    VoidCallback? onAction,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HealthAlert(
        title: title,
        message: message,
        type: type,
        onAction: onAction,
      ),
    );
  }

  @override
  State<HealthAlert> createState() => _HealthAlertState();
}

class _HealthAlertState extends State<HealthAlert> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.type.color.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.type.color.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.type.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.type.icon,
                        color: widget.type.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.type.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Actions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.type.recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                            color: widget.type.color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rec,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Dismiss'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onAction?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.type.color,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Take Action'),
                          ),
                        ),
                      ],
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
}

enum AlertType {
  warning(
    color: Colors.orange,
    icon: Icons.warning_rounded,
    recommendations: [
      'Take a few deep breaths',
      'Sit down and rest for a few minutes',
      'Avoid sudden movements',
      'Consider consulting a healthcare provider',
    ],
  ),
  danger(
    color: Colors.red,
    icon: Icons.dangerous_rounded,
    recommendations: [
      'Stop any physical activity immediately',
      'Seek immediate medical attention',
      'Take prescribed medication if available',
      'Stay calm and seated until help arrives',
    ],
  ),
  info(
    color: Colors.blue,
    icon: Icons.info_rounded,
    recommendations: [
      'Monitor your heart rate regularly',
      'Maintain a healthy lifestyle',
      'Stay hydrated',
      'Get adequate rest',
    ],
  );

  final Color color;
  final IconData icon;
  final List<String> recommendations;

  const AlertType({
    required this.color,
    required this.icon,
    required this.recommendations,
  });
}