import 'package:awesome_notifications/awesome_notifications.dart';

import '../../presentation/cubit/medication_cubit.dart';
import 'awesome_notification_service.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Handles notification action events for the app.
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  final payload = action.payload ?? {};
  final medicationId = payload['medicationId'];
  final doseIndex = int.tryParse(payload['doseIndex'] ?? '');
  final medicationName = payload['medicationName'];
  if (action.buttonKeyPressed == 'done') {
    if (medicationId == null || doseIndex == null) return;
    final notificationId = medicationId.hashCode + doseIndex;
    final context = navigatorKey.currentContext;
    if (context != null) {
      try {
        await context.read<MedicationCubit>().markDoseTaken(
          medicationId,
          doseIndex,
          true,
        );
        await AwesomeNotificationService.cancelMedicationReminder(notificationId);
      } catch (_) {
        // Leave notification visible so user knows the action did not complete
      }
    }
    // If context is null, notification stays visible (autoDismissible: false)
  } else if (action.buttonKeyPressed == 'remind_later') {
    if (medicationId != null && doseIndex != null && medicationName != null) {
      // Cancel any existing notification for this dose before rescheduling
      await AwesomeNotificationService.cancelMedicationReminder(
        medicationId.hashCode + doseIndex,
      );

      // Get localized strings only when context has localization scope
      final context = navigatorKey.currentContext;
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

      await AwesomeNotificationService.scheduleMedicationReminder(
        id: medicationId.hashCode + doseIndex,
        medicationName: medicationName,
        scheduledTime: DateTime.now().add(const Duration(minutes: 15)),
        medicationId: medicationId,
        doseIndex: doseIndex,
        title: title,
        body: body,
        doneLabel: doneLabel,
        remindLaterLabel: remindLaterLabel,
      );
    }
  }
}
