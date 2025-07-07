import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import '../../l10n/app_localizations.dart';

/// Info rows for MedicationCard (usage, dosage, doses per day).
class MedicationCardInfoRows extends StatelessWidget {
  final Medication medication;
  const MedicationCardInfoRows({required this.medication, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: Colors.orange),
            const SizedBox(width: 6),
            Text(
              '${AppLocalizations.of(context)!.usageLabel} ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: Text(
                medication.usage,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.local_hospital, size: 18, color: Colors.purple),
            const SizedBox(width: 6),
            Text(
              '${AppLocalizations.of(context)!.dosageLabel} ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: Text(
                medication.dosage,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.schedule, size: 18, color: Colors.indigo),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(
                context,
              )!.dosesPerDay(medication.doses.length),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
