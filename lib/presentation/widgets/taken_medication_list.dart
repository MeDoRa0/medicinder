import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import 'taken_medication_card.dart';
import '../../l10n/app_localizations.dart';

class TakenMedicationList extends StatelessWidget {
  final List<Medication> medications;
  final DateTime now;

  const TakenMedicationList({
    super.key,
    required this.medications,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    // Get all medications that have at least one dose taken today
    final today = DateTime(now.year, now.month, now.day);
    final takenMedications = <_TakenMedicationEntry>[];

    for (final medication in medications) {
      // Find all doses taken today for this medication
      final todayTakenDoses = medication.doses.where((dose) {
        if (!dose.taken || dose.takenDate == null) return false;
        final takenDate = DateTime(
          dose.takenDate!.year,
          dose.takenDate!.month,
          dose.takenDate!.day,
        );
        return takenDate.isAtSameMomentAs(today);
      }).toList();

      if (todayTakenDoses.isNotEmpty) {
        // Group by medication and collect all taken doses with their times
        for (final dose in todayTakenDoses) {
          takenMedications.add(
            _TakenMedicationEntry(
              medication: medication,
              dose: dose,
              takenTime: dose.takenDate!,
            ),
          );
        }
      }
    }

    // Sort by taken time (most recent first)
    takenMedications.sort((a, b) => b.takenTime.compareTo(a.takenTime));

    if (takenMedications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_liquid,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No medications taken today',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Medications you take will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: takenMedications.length,
      itemBuilder: (context, index) {
        final entry = takenMedications[index];
        return TakenMedicationCard(
          medication: entry.medication,
          dose: entry.dose,
          takenTime: entry.takenTime,
        );
      },
    );
  }
}

class _TakenMedicationEntry {
  final Medication medication;
  final MedicationDose dose;
  final DateTime takenTime;

  _TakenMedicationEntry({
    required this.medication,
    required this.dose,
    required this.takenTime,
  });
}

