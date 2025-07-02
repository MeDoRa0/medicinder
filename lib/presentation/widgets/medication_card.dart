import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import '../../l10n/app_localizations.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final void Function(int doseIndex) onDoseTaken;
  final void Function()? onDelete;
  final void Function()? onEdit;
  final bool highlight;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onDoseTaken,
    this.onDelete,
    this.onEdit,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysLeft =
        medication.totalDays - now.difference(medication.startDate).inDays;
    final isActive = medication.isActive;
    final isDailyComplete = medication.isDailyComplete;
    final isFullyComplete = medication.isFullyComplete;
    final canBeDeleted = medication.canBeDeleted;
    final takenCount = medication.doses.where((d) => d.taken).length;
    final totalCount = medication.doses.length;

    // Determine card color based on completion status
    Color cardColor;
    if (isFullyComplete) {
      cardColor = Colors.grey[200]!; // Fully completed - grey
    } else if (isDailyComplete) {
      cardColor = const Color(0xFFE8F5E8); // Daily complete - light green
    } else {
      cardColor = const Color(0xFFE6F7F1); // Active - light blue-green
    }

    return Opacity(
      opacity: isActive ? 1.0 : 0.7,
      child: Card(
        color: cardColor,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        Text(
                          '${AppLocalizations.of(context)!.type} ${_getTypeLabel(medication.type, context)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDailyComplete)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${AppLocalizations.of(context)!.usageLabel} ${medication.usage}',
              ),
              Text(
                '${AppLocalizations.of(context)!.dosageLabel} ${medication.dosage}',
              ),
              Text(
                AppLocalizations.of(
                  context,
                )!.daysLeft(daysLeft > 0 ? daysLeft : 0),
              ),
              if (isFullyComplete)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.courseFinished,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isDailyComplete && !isFullyComplete)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.dailyDosesCompleted,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.dosesPerDay(totalCount)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: totalCount == 0 ? 0 : takenCount / totalCount,
                      backgroundColor: Colors.grey[300],
                      color: isDailyComplete ? Colors.green : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$takenCount/$totalCount'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(medication.doses.length, (i) {
                  final dose = medication.doses[i];
                  return FilterChip(
                    label: Text(_doseLabel(dose, context)),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    selected: dose.taken,
                    onSelected: dose.taken ? (_) {} : (_) => onDoseTaken(i),

                    selectedColor: Colors.green,
                    checkmarkColor: Colors.white,
                    backgroundColor: const Color(0xFF71C0B2),
                  );
                }),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueGrey),
                      tooltip: AppLocalizations.of(context)!.edit,
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      tooltip: AppLocalizations.of(context)!.delete,
                      onPressed: onDelete != null
                          ? () async {
                              print(
                                'MedicationCard: Delete button pressed for medication: ${medication.name}',
                              );
                              print(
                                'MedicationCard: onDelete callback exists: ${onDelete != null}',
                              );

                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.deleteMedication,
                                  ),
                                  content: Text(
                                    AppLocalizations.of(context)!.deleteConfirm,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(
                                        AppLocalizations.of(context)!.delete,
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                print(
                                  'MedicationCard: User confirmed deletion, calling onDelete callback',
                                );
                                onDelete!();
                              } else {
                                print(
                                  'MedicationCard: User cancelled deletion',
                                );
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(MedicationType type, BuildContext context) {
    switch (type) {
      case MedicationType.pill:
        return AppLocalizations.of(context)!.pill;
      case MedicationType.syrup:
        return AppLocalizations.of(context)!.syrup;
    }
  }

  String _doseLabel(MedicationDose dose, BuildContext context) {
    // For meal context doses, show both context and time
    if (dose.time != null && dose.context != null) {
      final t = dose.time!;
      final hour = t.hour;
      final minute = t.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final timeString =
          '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';

      // Show the calculated time for meal context doses
      return timeString;
    }

    // For specific time doses (no context), show just the time
    if (dose.time != null) {
      final t = dose.time!;
      final hour = t.hour;
      final minute = t.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }

    // Only show context label if no time is available
    if (dose.context != null) {
      switch (dose.context!) {
        case MealContext.beforeBreakfast:
          return AppLocalizations.of(context)!.beforeBreakfast;
        case MealContext.afterBreakfast:
          return AppLocalizations.of(context)!.afterBreakfast;
        case MealContext.beforeLunch:
          return AppLocalizations.of(context)!.beforeLunch;
        case MealContext.afterLunch:
          return AppLocalizations.of(context)!.afterLunch;
        case MealContext.beforeDinner:
          return AppLocalizations.of(context)!.beforeDinner;
        case MealContext.afterDinner:
          return AppLocalizations.of(context)!.afterDinner;
      }
    }
    return 'Dose';
  }
}
