import '../../domain/usecases/update_dose_status.dart';
import '../../core/di/injector.dart';
import 'awesome_notification_service.dart';
import 'dart:developer';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  late UpdateDoseStatus _updateDoseStatus;

  void initialize() {
    _updateDoseStatus = sl<UpdateDoseStatus>();
  }

  // Call this from your main or wherever you listen to notification actions
  void handleActionReceived(Map<String, dynamic> payload, String? actionKey) {
    switch (actionKey) {
      case 'taken':
      case 'done':
      case 'confirm':
        _handleDoseTaken(payload);
        break;
      case 'snooze':
      case 'remind_later':
        _handleRemindLater(payload);
        break;
    }
  }

  Future<void> _handleDoseTaken(Map<String, dynamic> data) async {
    try {
      final medicationId = data['medicationId'] as String;
      final doseIndex = data['doseIndex'] as int;
      await _updateDoseStatus.call(medicationId, doseIndex, true);
      await AwesomeNotificationService.cancelMedicationReminder(
        medicationId.hashCode + doseIndex,
      );
      log(
        'Dose marked as taken for medication: $medicationId, dose: $doseIndex',
      );
    } catch (e) {
      log('Error marking dose as taken: $e');
    }
  }

  Future<void> _handleRemindLater(Map<String, dynamic> data) async {
    try {
      final medicationId = data['medicationId'] as String;
      final doseIndex = data['doseIndex'] as int;
      final medicationName = data['medicationName'] as String;
      await AwesomeNotificationService.cancelMedicationReminder(
        medicationId.hashCode + doseIndex,
      );
      await AwesomeNotificationService.scheduleMedicationReminder(
        id: medicationId.hashCode + doseIndex,
        medicationName: medicationName,
        scheduledTime:
            DateTime.now().add(AwesomeNotificationService.snoozeDuration),
      );
      log(
        'Reminder rescheduled for medication: $medicationId, dose: $doseIndex',
      );
    } catch (e) {
      log('Error rescheduling reminder: $e');
    }
  }
}
