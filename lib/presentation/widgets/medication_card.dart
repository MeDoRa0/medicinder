import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import '../../l10n/app_localizations.dart';
import 'dart:developer';

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
    final daysLeft = medication.repeatForever
        ? 'Forever'
        : medication.actualDaysLeft.toString();
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
                        Row(
                          children: [
                            Icon(
                              Icons.medication,
                              size: 18,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getTypeLabel(medication.type, context),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Days left on the right
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
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
                                      : AppLocalizations.of(
                                          context,
                                        )!.courseFinished
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
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.usageLabel + ' ',
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
                  Icon(Icons.local_hospital, size: 18, color: Colors.purple),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.dosageLabel + ' ',
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
              // Improved Doses Per Day UI (without icons)
              Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: Colors.indigo),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.dosesPerDay(_getUniqueScheduledTimes().length),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _getTodayDosesProgress(),
                      backgroundColor: Colors.grey[300],
                      color: isDailyComplete ? Colors.green : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_getTodayTakenCount()}/${_getUniqueScheduledTimes().length}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _getUniqueScheduledTimes().asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final dose = entry.value;
                  final isTimeTaken = _isTimeTaken(dose.time!);

                  return FilterChip(
                    label: Text(_doseLabel(dose, context)),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    selected: isTimeTaken,
                    onSelected: (_) {
                      // Find and mark all doses for this time as taken
                      _markAllDosesForTimeTaken(dose.time!);
                    },
                    selectedColor: Colors.green,
                    checkmarkColor: Colors.white,
                    backgroundColor: const Color(0xFF71C0B2),
                  );
                }).toList(),
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
              // Show 'Course Completed' indicator if the medication is fully complete
              if (isFullyComplete)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Course Completed',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
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
                              log(
                                'MedicationCard: Delete button pressed for medication: ${medication.name}',
                              );
                              log(
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
                                log(
                                  'MedicationCard: User confirmed deletion, calling onDelete callback',
                                );
                                onDelete!();
                              } else {
                                log('MedicationCard: User cancelled deletion');
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

  List<MedicationDose> _getUniqueScheduledTimes() {
    final uniqueTimes = <String, MedicationDose>{};

    for (final dose in medication.doses) {
      if (dose.time != null) {
        // Create a key based on hour:minute to identify unique times
        final timeKey = '${dose.time!.hour}:${dose.time!.minute}';

        if (!uniqueTimes.containsKey(timeKey)) {
          // Create a display dose with today's date but the original time
          final now = DateTime.now();
          final displayTime = DateTime(
            now.year,
            now.month,
            now.day,
            dose.time!.hour,
            dose.time!.minute,
          );

          uniqueTimes[timeKey] = MedicationDose(
            time: displayTime,
            context: dose.context,
            taken: false,
          );
        }
      }
    }

    // Sort by time and return the values
    final sortedTimes = uniqueTimes.values.toList();
    sortedTimes.sort((a, b) => a.time!.compareTo(b.time!));
    return sortedTimes;
  }

  bool _isTimeTaken(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchingDoses = medication.doses.where((dose) {
      if (dose.time == null) return false;
      final doseTime = dose.time!;
      return doseTime.hour == time.hour && doseTime.minute == time.minute;
    }).toList();
    // Return true if any matching dose was taken today
    return matchingDoses.any(
      (dose) =>
          dose.taken &&
          dose.takenDate != null &&
          DateTime(
            dose.takenDate!.year,
            dose.takenDate!.month,
            dose.takenDate!.day,
          ).isAtSameMomentAs(today),
    );
  }

  void _markAllDosesForTimeTaken(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < medication.doses.length; i++) {
      final dose = medication.doses[i];
      if (dose.time != null &&
          dose.time!.hour == time.hour &&
          dose.time!.minute == time.minute &&
          dose.time!.year == today.year &&
          dose.time!.month == today.month &&
          dose.time!.day == today.day) {
        // Mark only today's dose as taken
        onDoseTaken(i);
        break; // Only one dose per day per time
      }
    }
  }

  double _getTodayDosesProgress() {
    final todayTakenCount = _getTodayTakenCount();
    final totalTodayDoses = _getUniqueScheduledTimes().length;
    return totalTodayDoses == 0 ? 0 : todayTakenCount / totalTodayDoses;
  }

  int _getTodayTakenCount() {
    // Count the number of unique scheduled times where _isTimeTaken(time) is true
    return _getUniqueScheduledTimes()
        .where((dose) => _isTimeTaken(dose.time!))
        .length;
  }
}
