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

  bool get isActive {
    // Check if all doses have been taken
    final allDosesTaken = doses.isNotEmpty && doses.every((dose) => dose.taken);
    if (allDosesTaken) {
      return false; // Medication is complete when all doses are taken
    }

    // Check if the medication period has ended
    final endDate = startDate.add(Duration(days: totalDays));
    return DateTime.now().isBefore(endDate);
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
