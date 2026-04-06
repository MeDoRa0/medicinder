class NotificationRegenerationSummary {
  final int medicationsProcessed;
  final int notificationsScheduled;
  final int notificationsCancelled;
  final int failures;
  final bool permissionDenied;
  final int durationMs;

  const NotificationRegenerationSummary({
    required this.medicationsProcessed,
    required this.notificationsScheduled,
    required this.notificationsCancelled,
    required this.failures,
    required this.permissionDenied,
    required this.durationMs,
  });

  @override
  String toString() => 'NotificationRegenerationSummary('
      'processed=$medicationsProcessed, '
      'scheduled=$notificationsScheduled, '
      'cancelled=$notificationsCancelled, '
      'failures=$failures, '
      'permissionDenied=$permissionDenied, '
      'durationMs=$durationMs)';
}
