import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import '../../l10n/app_localizations.dart';

class AwesomeNotificationService {
  static const String channelKey = 'medication_channel';

  static Future<void> initialize() async {
    log('AwesomeNotificationService: Initializing notifications...');
    try {
      await AwesomeNotifications().initialize(
        'resource://drawable/notification_icon', // Use our custom notification icon
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

      // Check notification permissions
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      log('AwesomeNotificationService: Notifications allowed: $isAllowed');

      log('AwesomeNotificationService: Initialized successfully');
    } catch (e) {
      log('AwesomeNotificationService: Error during initialization: $e');
      rethrow;
    }
  }

  static Future<void> requestPermissionIfNeeded() async {
    log('AwesomeNotificationService: Checking notification permissions...');
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    log('AwesomeNotificationService: Notifications allowed: $isAllowed');

    if (!isAllowed) {
      log('AwesomeNotificationService: Requesting notification permissions...');
      await AwesomeNotifications().requestPermissionToSendNotifications();

      // Check again after requesting
      isAllowed = await AwesomeNotifications().isNotificationAllowed();
      log(
        'AwesomeNotificationService: Notifications allowed after request: $isAllowed',
      );
    }
  }

  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationPermissionDeniedTitle),
        content: Text(l10n.enableNotificationsMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AwesomeNotifications().showNotificationConfigPage();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    String? body,
    String? medicationId,
    int? doseIndex,
    String? title,
    String? doneLabel,
    String? remindLaterLabel,
  }) async {
    log(
      'AwesomeNotificationService: Scheduling notification for $medicationName at $scheduledTime',
    );
    log('AwesomeNotificationService: Notification ID: $id');
    log('AwesomeNotificationService: Current time: ${DateTime.now()}');
    log(
      'AwesomeNotificationService: Time until notification: ${scheduledTime.difference(DateTime.now()).inMinutes} minutes',
    );

    try {
      // Cancel any existing notification with the same id to prevent duplicates
      await AwesomeNotifications().cancel(id);

      // Schedule notification using AwesomeNotifications
      // Using allowWhileIdle: true ensures notifications work even when device is idle
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title ?? 'Medication Reminder',
          body: body ?? 'Time to take $medicationName',
          notificationLayout: NotificationLayout.Default,

          payload: {
            if (medicationId != null) 'medicationId': medicationId,
            if (doseIndex != null) 'doseIndex': doseIndex.toString(),
            'medicationName': medicationName,
          },
          locked: true,
          fullScreenIntent: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'done',
            label: doneLabel ?? 'Done',
            autoDismissible: false,
            actionType: ActionType.Default,
          ),
          NotificationActionButton(
            key: 'remind_later',
            label: remindLaterLabel ?? 'Remind Me Later',
            autoDismissible: false,
            actionType: ActionType.Default,
          ),
        ],
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          preciseAlarm:
              false, // Set to false to comply with Google Play Store policy
          allowWhileIdle:
              true, // Still allow notifications while device is idle
        ),
      );
      log('AwesomeNotificationService: Notification scheduled successfully');

      // List all scheduled notifications for debugging
      List<NotificationModel> scheduledNotifications =
          await AwesomeNotifications().listScheduledNotifications();
      log(
        'AwesomeNotificationService: Total scheduled notifications: ${scheduledNotifications.length}',
      );
      for (var notification in scheduledNotifications) {
        log(
          'AwesomeNotificationService: Scheduled notification - ID: ${notification.content?.id}, Title: ${notification.content?.title}, Schedule: ${notification.schedule}',
        );
      }
    } catch (e) {
      log('AwesomeNotificationService: Error scheduling notification: $e');
      rethrow;
    }
  }

  static Future<void> cancelMedicationReminder(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  static Future<void> cancelAllReminders() async {
    await AwesomeNotifications().cancelAll();
  }
}
