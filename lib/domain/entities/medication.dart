enum MedicationTimingType { specificTime, contextBased }

enum MedicationType { pill, syrup }

enum MealContext {
  beforeBreakfast,
  afterBreakfast,
  beforeLunch,
  afterLunch,
  beforeDinner,
  afterDinner,
}

class MedicationDose {
  final DateTime? time; // For specific time
  final MealContext? context; // For context-based
  final bool taken;
  final DateTime? takenDate; // Date when the dose was taken

  const MedicationDose({
    this.time,
    this.context,
    this.taken = false,
    this.takenDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationDose &&
          runtimeType == other.runtimeType &&
          time == other.time &&
          context == other.context &&
          taken == other.taken &&
          takenDate == other.takenDate;

  @override
  int get hashCode =>
      time.hashCode ^ context.hashCode ^ taken.hashCode ^ takenDate.hashCode;
}

class Medication {
  final String id;
  final String name;
  final String usage;
  final String dosage;
  final MedicationType type;
  final MedicationTimingType timingType;
  final List<MedicationDose> doses;
  final int totalDays;
  final DateTime startDate;
  final bool repeatForever;

  const Medication({
    required this.id,
    required this.name,
    required this.usage,
    required this.dosage,
    required this.type,
    required this.timingType,
    required this.doses,
    required this.totalDays,
    required this.startDate,
    this.repeatForever = false,
  });

  /// Returns true if the medication should be visible and manageable
  /// (not yet fully completed or treatment period not ended)
  bool get isActive {
    return actualDaysLeft > 0 || !isDailyComplete;
  }

  /// Returns true if all daily doses for today have been taken
  bool get isDailyComplete {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDoses = doses.where((dose) {
      if (dose.time != null) {
        final doseDate = DateTime(
          dose.time!.year,
          dose.time!.month,
          dose.time!.day,
        );
        return doseDate.isAtSameMomentAs(today);
      }
      return false;
    }).toList();
    if (todayDoses.isEmpty) return false;
    return todayDoses.every(
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

  /// Returns true if the full treatment course is completed
  /// (all doses are taken AND course end date has passed)
  bool get isFullyComplete {
    return actualDaysLeft <= 0 &&
        doses.isNotEmpty &&
        doses.every((dose) => dose.taken);
  }

  /// Returns true if the medication can be deleted
  /// (users can delete any medication at any time)
  bool get canBeDeleted {
    return true; // Users can delete any medication at any time
  }

  /// Calculates the actual days left based on dose completion
  /// This considers both elapsed time and completed doses
  int get actualDaysLeft {
    final now = DateTime.now();
    final endDate = startDate.add(Duration(days: totalDays));

    // If the course period has ended, return 0
    if (now.isAfter(endDate)) {
      return 0;
    }

    // Calculate days elapsed since start
    final daysElapsed = now.difference(startDate).inDays;

    // If all doses are taken, consider this day as completed
    if (isDailyComplete) {
      // If all doses are taken, we've completed today's treatment
      // So the actual days left should be totalDays - (daysElapsed + 1)
      return totalDays - (daysElapsed + 1);
    }

    // If not all doses are taken, use the standard calculation
    return totalDays - daysElapsed;
  }

  /// Get today's doses (doses that should be taken today)
  List<MedicationDose> _getTodayDoses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // First, try to find doses for today
    final todayDoses = doses.where((dose) {
      if (dose.time != null) {
        final doseDate = DateTime(
          dose.time!.year,
          dose.time!.month,
          dose.time!.day,
        );
        return doseDate.isAtSameMomentAs(today);
      }
      return false;
    }).toList();

    // If there are doses for today, return them
    if (todayDoses.isNotEmpty) {
      return todayDoses;
    }

    // If no doses for today, return the scheduled dose times for display
    // We'll use the first day's doses to show the schedule
    final scheduledDoses = <MedicationDose>[];
    final seenTimes = <String>{};

    for (final dose in doses) {
      if (dose.time != null) {
        // Create a key for the time (hour:minute)
        final timeKey = '${dose.time!.hour}:${dose.time!.minute}';
        if (!seenTimes.contains(timeKey)) {
          seenTimes.add(timeKey);
          // Create a dose with today's date but the original time for display
          final displayTime = DateTime(
            now.year,
            now.month,
            now.day,
            dose.time!.hour,
            dose.time!.minute,
          );
          scheduledDoses.add(
            MedicationDose(
              time: displayTime,
              context: dose.context,
              taken: false,
            ),
          );
        }
      }
    }

    // Sort by time
    scheduledDoses.sort((a, b) => a.time!.compareTo(b.time!));
    return scheduledDoses;
  }

  /// Check if a dose was taken today
  bool isDoseTakenToday(int doseIndex) {
    if (doseIndex < 0 || doseIndex >= doses.length) return false;

    final dose = doses[doseIndex];
    if (!dose.taken || dose.takenDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final takenDate = DateTime(
      dose.takenDate!.year,
      dose.takenDate!.month,
      dose.takenDate!.day,
    );

    return takenDate.isAtSameMomentAs(today);
  }

  /// Reset all doses to not taken (for daily reset)
  Medication resetDailyDoses() {
    final updatedDoses = doses
        .map(
          (dose) => MedicationDose(
            time: dose.time,
            context: dose.context,
            taken: false,
            takenDate: null,
          ),
        )
        .toList();

    return Medication(
      id: id,
      name: name,
      usage: usage,
      dosage: dosage,
      type: type,
      timingType: timingType,
      doses: updatedDoses,
      totalDays: totalDays,
      startDate: startDate,
      repeatForever: repeatForever,
    );
  }

  /// Mark a specific dose as taken for today
  Medication markDoseTaken(int doseIndex) {
    if (doseIndex < 0 || doseIndex >= doses.length) return this;

    final updatedDoses = List<MedicationDose>.from(doses);
    updatedDoses[doseIndex] = MedicationDose(
      time: doses[doseIndex].time,
      context: doses[doseIndex].context,
      taken: true,
      takenDate: DateTime.now(),
    );

    return Medication(
      id: id,
      name: name,
      usage: usage,
      dosage: dosage,
      type: type,
      timingType: timingType,
      doses: updatedDoses,
      totalDays: totalDays,
      startDate: startDate,
      repeatForever: repeatForever,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Medication &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          usage == other.usage &&
          dosage == other.dosage &&
          type == other.type &&
          timingType == other.timingType &&
          doses == other.doses;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      usage.hashCode ^
      dosage.hashCode ^
      type.hashCode ^
      timingType.hashCode ^
      doses.hashCode;
}
