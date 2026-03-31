import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:medicinder/domain/entities/medication.dart';
import 'dart:developer';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'awesome_notification_service.dart';

/// Optimized notification service that reduces redundant operations
class NotificationOptimizer {
  static final NotificationOptimizer _instance =
      NotificationOptimizer._internal();
  factory NotificationOptimizer() => _instance;
  NotificationOptimizer._internal();

  // Cache for scheduled notifications to avoid repeated API calls
  final Map<int, NotificationModel> _scheduledNotificationsCache = {};
  DateTime? _lastCacheUpdate;

  /// Get scheduled notifications with caching
  Future<List<NotificationModel>> getScheduledNotifications() async {
    final now = DateTime.now();

    // Update cache if it's older than 30 seconds
    if (_lastCacheUpdate == null ||
        now.difference(_lastCacheUpdate!).inSeconds > 30) {
      await _updateCache();
    }

    return _scheduledNotificationsCache.values.toList();
  }

  /// Update the notification cache
  Future<void> _updateCache() async {
    try {
      final notifications = await AwesomeNotifications()
          .listScheduledNotifications();
      _scheduledNotificationsCache.clear();

      for (final notification in notifications) {
        if (notification.content?.id != null) {
          _scheduledNotificationsCache[notification.content!.id!] =
              notification;
        }
      }

      _lastCacheUpdate = DateTime.now();
      log(
        'NotificationOptimizer: Cache updated with ${notifications.length} notifications',
      );
    } catch (e) {
      log('NotificationOptimizer: Error updating cache: $e');
    }
  }

  /// Efficiently cancel notifications for a specific medication
  Future<int> cancelMedicationNotifications(String medicationId) async {
    try {
      await _updateCache(); // Ensure cache is up to date

      int cancelledCount = 0;
      final notificationsToCancel = <int>[];

      // Find notifications to cancel
      for (final notification in _scheduledNotificationsCache.values) {
        if (notification.content?.payload?['medicationId'] == medicationId) {
          notificationsToCancel.add(notification.content!.id!);
        }
      }

      // Cancel notifications in batch
      for (final id in notificationsToCancel) {
        await AwesomeNotifications().cancel(id);
        _scheduledNotificationsCache.remove(id);
        cancelledCount++;
      }

      log(
        'NotificationOptimizer: Cancelled $cancelledCount notifications for medication $medicationId',
      );
      return cancelledCount;
    } catch (e) {
      log('NotificationOptimizer: Error cancelling notifications: $e');
      return 0;
    }
  }

  /// Schedule only the next upcoming dose notification
  Future<void> scheduleNextDoseNotification(
    Medication medication, {
    BuildContext? context,
  }) async {
    try {
      final now = DateTime.now();
      int? nextDoseIndex;
      DateTime? nextDoseTime;

      // Find the next upcoming dose
      for (int i = 0; i < medication.doses.length; i++) {
        final dose = medication.doses[i];
        if (dose.time != null && dose.time!.isAfter(now) && !dose.taken) {
          if (nextDoseTime == null || dose.time!.isBefore(nextDoseTime)) {
            nextDoseTime = dose.time;
            nextDoseIndex = i;
          }
        }
      }

      // Cancel existing notifications for this medication
      await cancelMedicationNotifications(medication.id);

      // Schedule only the next dose
      if (nextDoseIndex != null && nextDoseTime != null) {
        await _scheduleSingleNotification(
          id: medication.id.hashCode + nextDoseIndex,
          medicationName: medication.name,
          scheduledTime: nextDoseTime,
          medicationId: medication.id,
          doseIndex: nextDoseIndex,
          context: context,
        );

        log(
          'NotificationOptimizer: Scheduled next dose notification for ${medication.name} at $nextDoseTime',
        );
      }
    } catch (e) {
      log('NotificationOptimizer: Error scheduling next dose notification: $e');
    }
  }

  /// Schedule a single notification efficiently
  Future<void> _scheduleSingleNotification({
    required int id,
    required String medicationName,
    required DateTime scheduledTime,
    required String medicationId,
    required int doseIndex,
    BuildContext? context,
  }) async {
    try {
      // Cancel any existing notification with the same ID
      await AwesomeNotifications().cancel(id);

      String? title;
      String? body;
      String? doneLabel;
      String? remindLaterLabel;

      final l10n = context != null ? AppLocalizations.of(context) : null;
      if (l10n != null) {
        title = l10n.medicationReminder;
        body = l10n.timeToTakeMedication(medicationName);
        doneLabel = l10n.done;
        remindLaterLabel = l10n.remindMeLater;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: AwesomeNotificationService.channelKey,
          title: title ?? 'Medication Reminder',
          body: body ?? 'Time to take $medicationName',
          icon: AwesomeNotificationService.androidSmallIconResource,
          largeIcon: defaultTargetPlatform == TargetPlatform.android
              ? AwesomeNotificationService.androidLargeIconResource
              : null,
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Alarm,
          payload: {
            'medicationId': medicationId,
            'doseIndex': doseIndex.toString(),
            'medicationName': medicationName,
          },
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

      // Update cache
      final notification = NotificationModel(
        content: NotificationContent(
          id: id,
          channelKey: AwesomeNotificationService.channelKey,
          title: title ?? 'Medication Reminder',
          body: body ?? 'Time to take $medicationName',
          payload: {
            'medicationId': medicationId,
            'doseIndex': doseIndex.toString(),
            'medicationName': medicationName,
          },
        ),
        schedule: NotificationCalendar.fromDate(date: scheduledTime),
      );

      _scheduledNotificationsCache[id] = notification;
    } catch (e) {
      log('NotificationOptimizer: Error scheduling single notification: $e');
    }
  }

  /// Batch schedule notifications for multiple medications
  Future<void> batchScheduleNotifications(
    List<Medication> medications, {
    BuildContext? context,
  }) async {
    try {
      log(
        'NotificationOptimizer: Starting batch scheduling for ${medications.length} medications',
      );

      for (final medication in medications) {
        await scheduleNextDoseNotification(medication, context: context);
      }

      log('NotificationOptimizer: Batch scheduling completed');
    } catch (e) {
      log('NotificationOptimizer: Error in batch scheduling: $e');
    }
  }

  /// Clear all notifications and cache
  Future<void> clearAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
      _scheduledNotificationsCache.clear();
      _lastCacheUpdate = null;
      log('NotificationOptimizer: All notifications cleared');
    } catch (e) {
      log('NotificationOptimizer: Error clearing notifications: $e');
    }
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _scheduledNotificationsCache.length,
      'lastUpdate': _lastCacheUpdate?.toIso8601String(),
      'cacheAge': _lastCacheUpdate != null
          ? DateTime.now().difference(_lastCacheUpdate!).inSeconds
          : null,
    };
  }
}
