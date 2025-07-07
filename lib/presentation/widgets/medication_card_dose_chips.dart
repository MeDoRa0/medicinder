import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';

/// Dose chips for MedicationCard showing each scheduled dose.
class MedicationCardDoseChips extends StatefulWidget {
  final List<MedicationDose> uniqueScheduledTimes;
  final bool Function(DateTime) isTimeTaken;
  final String Function(MedicationDose, BuildContext) doseLabel;
  final BuildContext context;
  final void Function(MedicationDose dose, bool selected) onDoseToggle;
  const MedicationCardDoseChips({
    required this.uniqueScheduledTimes,
    required this.isTimeTaken,
    required this.doseLabel,
    required this.context,
    required this.onDoseToggle,
    super.key,
  });

  @override
  State<MedicationCardDoseChips> createState() =>
      _MedicationCardDoseChipsState();
}

class _MedicationCardDoseChipsState extends State<MedicationCardDoseChips> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: widget.uniqueScheduledTimes.asMap().entries.map((entry) {
        final dose = entry.value;
        final taken = widget.isTimeTaken(dose.time!);
        return FilterChip(
          label: Text(widget.doseLabel(dose, context)),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          selected: taken,
          onSelected: (selected) {
            widget.onDoseToggle(dose, selected);
          },
          selectedColor: Colors.green,
          checkmarkColor: Colors.white,
          backgroundColor: const Color(0xFF71C0B2),
        );
      }).toList(),
    );
  }
}
