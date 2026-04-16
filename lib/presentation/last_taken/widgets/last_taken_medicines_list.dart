import 'package:flutter/material.dart';
import 'package:medicinder/domain/entities/medication_history.dart';
import 'package:medicinder/presentation/last_taken/widgets/taken_medicine_card.dart';

class LastTakenMedicinesList extends StatelessWidget {
  final List<MedicationHistory> medications;

  const LastTakenMedicinesList({super.key, required this.medications});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: medications.length,
      itemBuilder: (context, index) {
        final history = medications[index];
        return TakenMedicineCard(history: history);
      },
    );
  }
}
