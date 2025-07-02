import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class AwesomeNotificationService {
  static const String channelKey = 'medication_channel';

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // icon for notification
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Medication Reminders',
          channelDescription: 'Reminders for medication doses',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );
  }

  static Future<void> requestPermissionIfNeeded(BuildContext context) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    String? body,
    String? medicationId,
    int? doseIndex,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: 'Medication Reminder',
        body: body ?? 'Time to take $medicationName',
        notificationLayout: NotificationLayout.Default,
        payload: {
          if (medicationId != null) 'medicationId': medicationId,
          if (doseIndex != null) 'doseIndex': doseIndex.toString(),
          'medicationName': medicationName,
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'done',
          label: 'Done',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'remind_later',
          label: 'Remind Me Later',
          autoDismissible: true,
          actionType: ActionType.Default,
        ),
      ],
      schedule: NotificationCalendar.fromDate(
        date: scheduledTime,
        preciseAlarm: true,
      ),
    );
  }

  static Future<void> cancelMedicationReminder(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  static Future<void> cancelAllReminders() async {
    await AwesomeNotifications().cancelAll();
  }
}
