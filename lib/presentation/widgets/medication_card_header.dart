import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import '../../l10n/app_localizations.dart';

/// Header section for MedicationCard showing name, type, and days left.
class MedicationCardHeader extends StatelessWidget {
  final Medication medication;

  /// When true, show "Forever"; otherwise use [daysLeft] (null or 0 = course finished).
  final bool isForever;
  final int? daysLeft;
  final String typeLabel;
  const MedicationCardHeader({
    required this.medication,
    required this.isForever,
    this.daysLeft,
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
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    final days = daysLeft ?? 0;
                    final hasDaysLeft = days > 0;
                    return Text(
                      isForever
                          ? l10n.forever
                          : (hasDaysLeft
                                ? l10n.daysLeft(days)
                                : l10n.courseFinished),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isForever
                            ? Colors.teal
                            : (hasDaysLeft ? Colors.blueGrey : Colors.red),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
