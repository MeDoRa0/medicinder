import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import '../../l10n/app_localizations.dart';

class AwesomeNotificationService {
  /// Small icon (white-on-transparent drawable). Also pass on each [NotificationContent]
  /// so scheduled notifications resolve the icon in release builds.
  static const String androidSmallIconResource =
      'resource://drawable/notification_icon';

  /// Expanded notification artwork on Android (full-color app icon).
  static const String androidLargeIconResource =
      'resource://mipmap/launcher_icon';

  /// New channel id so devices pick up alarm-style sound, vibration, and importance.
  static const String channelKey = 'medication_alarm_channel';

  /// Snooze duration when the user taps "Snooze" on a reminder.
  static const Duration snoozeDuration = Duration(minutes: 15);

  static Future<void> initialize() async {
    log('AwesomeNotificationService: Initializing notifications...');
    try {
      await AwesomeNotifications().initialize(
        androidSmallIconResource,
        [
          NotificationChannel(
            channelKey: channelKey,
            channelName: 'Medication alarms',
            channelDescription:
                'High-priority reminders with sound and vibration until you respond',
            defaultColor: Colors.blue,
            importance: NotificationImportance.Max,
            channelShowBadge: true,
            playSound: true,
            enableVibration: true,
            vibrationPattern: highVibrationPattern,
            defaultRingtoneType: DefaultRingtoneType.Alarm,
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

      final payload = <String, String?>{
        'medicationName': medicationName,
      };
      if (medicationId != null) payload['medicationId'] = medicationId;
      if (doseIndex != null) {
        payload['doseIndex'] = doseIndex.toString();
      }

      // Schedule notification using AwesomeNotifications
      // Using allowWhileIdle: true ensures notifications work even when device is idle
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title ?? 'Medication Reminder',
          body: body ?? 'Time to take $medicationName',
          icon: androidSmallIconResource,
          largeIcon: defaultTargetPlatform == TargetPlatform.android
              ? androidLargeIconResource
              : null,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Alarm,
          payload: payload,
          locked: true,
          fullScreenIntent: true,
          wakeUpScreen: true,
          autoDismissible: false,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'taken',
            label: doneLabel ?? 'Taken',
            autoDismissible: false,
            actionType: ActionType.Default,
          ),
          NotificationActionButton(
            key: 'snooze',
            label: remindLaterLabel ?? 'Snooze',
            autoDismissible: false,
            actionType: ActionType.Default,
          ),
        ],
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          preciseAlarm: true,
          allowWhileIdle: true,
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
