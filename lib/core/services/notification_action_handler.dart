import 'package:awesome_notifications/awesome_notifications.dart';

import '../../presentation/cubit/medication_cubit.dart';
import 'awesome_notification_service.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';
import 'medication_reminder_actions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Handles notification action events for the app.
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  final payload = action.payload ?? {};
  final medicationId = payload['medicationId'];
  final doseIndex = int.tryParse(payload['doseIndex'] ?? '');
  final medicationName = payload['medicationName'];
  final key = action.buttonKeyPressed;

  if (key == 'taken' || key == 'done') {
    if (medicationId == null || doseIndex == null) return;
    try {
      await MedicationReminderActions.applyDoseTaken(medicationId, doseIndex);
    } catch (_) {
      // Notification remains until the user acts again.
      return;
    }
    final navContext = navigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      await navContext.read<MedicationCubit>().loadMedications();
    }
  } else if (key == 'snooze' || key == 'remind_later') {
    if (medicationId != null && doseIndex != null && medicationName != null) {
      final navContext = navigatorKey.currentContext;
      String? title;
      String? body;
      String? doneLabel;
      String? remindLaterLabel;
      if (navContext != null && navContext.mounted) {
        final l10n = AppLocalizations.of(navContext);
        if (l10n != null) {
          title = l10n.medicationReminder;
          body = l10n.timeToTakeMedication(medicationName);
          doneLabel = l10n.done;
          remindLaterLabel = l10n.remindMeLater;
        }
      }

      await AwesomeNotificationService.cancelMedicationReminder(
        medicationId.hashCode + doseIndex,
      );

      await AwesomeNotificationService.scheduleMedicationReminder(
        id: medicationId.hashCode + doseIndex,
        medicationName: medicationName,
        scheduledTime:
            DateTime.now().add(AwesomeNotificationService.snoozeDuration),
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
