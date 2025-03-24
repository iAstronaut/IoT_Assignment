import 'package:flutter/material.dart';
import 'package:heart_rate_monitor/models/alert_type.dart';

class HealthAlert {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required AlertType type,
  }) {
    final Color backgroundColor;
    final Color textColor = Colors.white;
    final IconData icon;

    switch (type) {
      case AlertType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info_outline;
        break;
      case AlertType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertType.danger:
        backgroundColor = Colors.red;
        icon = Icons.error_outline;
        break;
      case AlertType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(
              icon,
              color: textColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}