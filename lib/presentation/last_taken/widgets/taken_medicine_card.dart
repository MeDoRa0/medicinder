import 'package:flutter/material.dart';
import 'package:medicinder/domain/entities/medication_history.dart';
import 'package:medicinder/core/utils/time_extension.dart';

class TakenMedicineCard extends StatelessWidget {
  final MedicationHistory history;

  const TakenMedicineCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    history.medicineName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  history.takenAt.toRelativeTime(context),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(history.dose, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
