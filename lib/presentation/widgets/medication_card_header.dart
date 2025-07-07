import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import '../../l10n/app_localizations.dart';

/// Header section for MedicationCard showing name, type, and days left.
class MedicationCardHeader extends StatelessWidget {
  final Medication medication;
  final String daysLeft;
  final String typeLabel;
  const MedicationCardHeader({
    required this.medication,
    required this.daysLeft,
    required this.typeLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medication.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  const Icon(Icons.medication, size: 18, color: Colors.teal),
                  const SizedBox(width: 6),
                  Text(
                    typeLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  daysLeft != 'Forever'
                      ? (int.tryParse(daysLeft) ?? 0) > 0
                            ? AppLocalizations.of(
                                context,
                              )!.daysLeft(int.tryParse(daysLeft) ?? 0)
                            : AppLocalizations.of(context)!.courseFinished
                      : 'Forever',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: daysLeft != 'Forever'
                        ? ((int.tryParse(daysLeft) ?? 0) > 0
                              ? Colors.blueGrey
                              : Colors.red)
                        : Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
