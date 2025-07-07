import 'package:awesome_notifications/awesome_notifications.dart';

import '../../presentation/cubit/medication_cubit.dart';
import 'awesome_notification_service.dart';
import '../../main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Handles notification action events for the app.
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  final payload = action.payload ?? {};
  final medicationId = payload['medicationId'];
  final doseIndex = int.tryParse(payload['doseIndex'] ?? '');
  final medicationName = payload['medicationName'];
  if (action.buttonKeyPressed == 'done') {
    if (medicationId == null || doseIndex == null) return;
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = navigatorKey.currentContext;
      if (context != null) {
        context.read<MedicationCubit>().markDoseTaken(
          medicationId,
          doseIndex,
          true,
        );
      }
    });
  } else if (action.buttonKeyPressed == 'remind_later') {
    if (medicationId != null && doseIndex != null && medicationName != null) {
      // Cancel any existing notification for this dose before rescheduling
      await AwesomeNotificationService.cancelMedicationReminder(
        medicationId.hashCode + doseIndex,
      );
      await AwesomeNotificationService.scheduleMedicationReminder(
        id: medicationId.hashCode + doseIndex,
        medicationName: medicationName,
        scheduledTime: DateTime.now().add(const Duration(minutes: 15)),
        medicationId: medicationId,
        doseIndex: doseIndex,
      );
    }
  }
}
