import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import '../widgets/medication_card.dart';
import '../cubit/medication_cubit.dart';
import '../pages/add_medication_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MedicationList extends StatelessWidget {
  final List<Medication> medications;
  final DateTime now;
  const MedicationList({super.key, required this.medications, required this.now});

  @override
  Widget build(BuildContext context) {
    final allMeds = medications.toList();
    allMeds.sort((a, b) {
      final aTodayDone = a.doses
          .where(
            (d) =>
                d.time != null &&
                d.time!.year == now.year &&
                d.time!.month == now.month &&
                d.time!.day == now.day,
          )
          .every((d) => d.taken);
      final bTodayDone = b.doses
          .where(
            (d) =>
                d.time != null &&
                d.time!.year == now.year &&
                d.time!.month == now.month &&
                d.time!.day == now.day,
          )
          .every((d) => d.taken);
      if (aTodayDone == bTodayDone) return 0;
      if (aTodayDone) return 1;
      return -1;
    });
    return ListView.builder(
      itemCount: allMeds.length,
      itemBuilder: (context, index) {
        final med = allMeds[index];
        final isTodayComplete = med.doses
            .where(
              (d) =>
                  d.time != null &&
                  d.time!.year == now.year &&
                  d.time!.month == now.month &&
                  d.time!.day == now.day,
            )
            .every((d) => d.taken);
        return MedicationCard(
          medication: med,
          highlight: isTodayComplete,
          onDoseTaken: (doseIndex) {
            context.read<MedicationCubit>().markDoseTaken(
              med.id,
              doseIndex,
              true,
            );
          },
          onDelete: () {
            context.read<MedicationCubit>().deleteMedication(med.id);
          },
          onEdit: () async {
            final updatedMedication = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddMedicationPage(medication: med),
              ),
            );
            if (updatedMedication != null && context.mounted) {
              context.read<MedicationCubit>().addNewMedication(
                updatedMedication,
              );
            }
          },
        );
      },
    );
  }
}
