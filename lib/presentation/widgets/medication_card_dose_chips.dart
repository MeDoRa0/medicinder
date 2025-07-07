import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';

/// Dose chips for MedicationCard showing each scheduled dose.
class MedicationCardDoseChips extends StatelessWidget {
  final List<MedicationDose> uniqueScheduledTimes;
  final bool Function(DateTime) isTimeTaken;
  final String Function(MedicationDose, BuildContext) doseLabel;
  final BuildContext context;
  const MedicationCardDoseChips({
    required this.uniqueScheduledTimes,
    required this.isTimeTaken,
    required this.doseLabel,
    required this.context,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: uniqueScheduledTimes.asMap().entries.map((entry) {
        final dose = entry.value;
        final taken = isTimeTaken(dose.time!);
        return FilterChip(
          label: Text(doseLabel(dose, context)),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          selected: taken,
          onSelected: (_) {}, // You can add your logic here
          selectedColor: Colors.green,
          checkmarkColor: Colors.white,
          backgroundColor: const Color(0xFF71C0B2),
        );
      }).toList(),
    );
  }
}
