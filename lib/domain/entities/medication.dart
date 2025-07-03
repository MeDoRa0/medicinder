import 'dart:developer';

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

  const MedicationDose({this.time, this.context, this.taken = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationDose &&
          runtimeType == other.runtimeType &&
          time == other.time &&
          context == other.context &&
          taken == other.taken;

  @override
  int get hashCode => time.hashCode ^ context.hashCode ^ taken.hashCode;
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
  });

  /// Returns true if the medication should be visible and manageable
  /// (not yet fully completed or treatment period not ended)
  bool get isActive {
    return actualDaysLeft > 0 || !isDailyComplete;
  }

  /// Returns true if all daily doses have been taken
  bool get isDailyComplete {
    return doses.isNotEmpty && doses.every((dose) => dose.taken);
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
