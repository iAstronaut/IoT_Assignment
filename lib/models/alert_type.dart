enum AlertType {
  info,
  warning,
  danger,
  success;
}

extension AlertTypeExtension on AlertType {
  String get color {
    switch (this) {
      case AlertType.info:
        return '#2196F3';
      case AlertType.warning:
        return '#FFC107';
      case AlertType.danger:
        return '#F44336';
      case AlertType.success:
        return '#4CAF50';
    }
  }

  String get icon {
    switch (this) {
      case AlertType.info:
        return 'info';
      case AlertType.warning:
        return 'warning';
      case AlertType.danger:
        return 'error';
      case AlertType.success:
        return 'check_circle';
    }
  }
}