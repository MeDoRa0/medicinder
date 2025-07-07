import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';

/// Progress bar for MedicationCard showing today's dose progress.
class MedicationCardProgress extends StatelessWidget {
  final Medication medication;
  final bool isDailyComplete;
  final double getTodayDosesProgress;
  final int getTodayTakenCount;
  final int getUniqueScheduledTimes;
  const MedicationCardProgress({
    required this.medication,
    required this.isDailyComplete,
    required this.getTodayDosesProgress,
    required this.getTodayTakenCount,
    required this.getUniqueScheduledTimes,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: getTodayDosesProgress,
            backgroundColor: Colors.grey[300],
            color: isDailyComplete ? Colors.green : Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Text('$getTodayTakenCount/$getUniqueScheduledTimes'),
      ],
    );
  }
}
