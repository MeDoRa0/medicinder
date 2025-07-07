import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import '../../l10n/app_localizations.dart';
import 'medication_card_header.dart';
import 'medication_card_info_rows.dart';
import 'medication_card_progress.dart';
import 'medication_card_dose_chips.dart';

import 'medication_card_utils.dart';
import 'medication_card_actions.dart';

/// A card widget that displays medication details, progress, and actions.
class MedicationCard extends StatelessWidget {
  /// The medication to display.
  final Medication medication;

  /// Callback when a dose is marked as taken.
  final void Function(int doseIndex) onDoseTaken;

  /// Callback when the medication is deleted.
  final void Function()? onDelete;

  /// Callback when the medication is edited.
  final void Function()? onEdit;

  /// Whether to highlight the card (e.g., if today's doses are complete).
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
    final daysLeft = medication.repeatForever
        ? 'Forever'
        : medication.actualDaysLeft.toString();
    final isActive = medication.isActive;
    final isDailyComplete = medication.isDailyComplete;
    final isFullyComplete = medication.isFullyComplete;

    return Opacity(
      opacity: isActive ? 1.0 : 0.7,
      child: Card(
        color: isFullyComplete
            ? Colors.grey[200]!
            : isDailyComplete
            ? const Color(0xFFE8F5E8)
            : const Color(0xFFE6F7F1),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MedicationCardHeader(
                medication: medication,
                daysLeft: daysLeft,
                typeLabel: getTypeLabel(medication.type, context),
              ),
              const SizedBox(height: 8),
              MedicationCardInfoRows(medication: medication),
              const SizedBox(height: 8),
              MedicationCardProgress(
                medication: medication,
                isDailyComplete: isDailyComplete,
                getTodayDosesProgress: _getTodayDosesProgress(),
                getTodayTakenCount: _getTodayTakenCount(),
                getUniqueScheduledTimes: _getUniqueScheduledTimes().length,
              ),
              const SizedBox(height: 12),
              MedicationCardDoseChips(
                uniqueScheduledTimes: _getUniqueScheduledTimes(),
                isTimeTaken: _isTimeTaken,
                doseLabel: doseLabel,
                context: context,
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
              MedicationCardActions(
                onEdit: onEdit,
                onDelete: onDelete,
                medication: medication,
              ),
            ],
          ),
        ),
      ),
    );
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
