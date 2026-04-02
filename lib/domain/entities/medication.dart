import 'sync_metadata.dart';

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
  final int? offsetMinutes; // Minutes before/after meal (only when context != null)
  final bool taken;
  final DateTime? takenDate; // Date when the dose was taken

  const MedicationDose({
    this.time,
    this.context,
    this.offsetMinutes,
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
          offsetMinutes == other.offsetMinutes &&
          taken == other.taken &&
          takenDate == other.takenDate;

  @override
  int get hashCode =>
      time.hashCode ^
      context.hashCode ^
      offsetMinutes.hashCode ^
      taken.hashCode ^
      takenDate.hashCode;
}

class Medication {
  final String id;
  final String? userId;
  final String name;
  final String usage;
  final String dosage;
  final MedicationType type;
  final MedicationTimingType timingType;
  final List<MedicationDose> doses;
  final int totalDays;
  final DateTime startDate;
  final bool repeatForever;
  final bool isDeleted;
  final DateTime? deletedAt;
  final SyncMetadata syncMetadata;

  const Medication({
    required this.id,
    this.userId,
    required this.name,
    required this.usage,
    required this.dosage,
    required this.type,
    required this.timingType,
    required this.doses,
    required this.totalDays,
    required this.startDate,
    this.repeatForever = false,
    this.isDeleted = false,
    this.deletedAt,
    required this.syncMetadata,
  });

  factory Medication.create({
    required String id,
    required String name,
    required String usage,
    required String dosage,
    required MedicationType type,
    required MedicationTimingType timingType,
    required List<MedicationDose> doses,
    required int totalDays,
    required DateTime startDate,
    bool repeatForever = false,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return Medication(
      id: id,
      userId: null,
      name: name,
      usage: usage,
      dosage: dosage,
      type: type,
      timingType: timingType,
      doses: doses,
      totalDays: totalDays,
      startDate: startDate,
      repeatForever: repeatForever,
      syncMetadata: SyncMetadata.initial(timestamp),
    );
  }

  /// Returns true if the medication should be visible and manageable
  /// (not yet fully completed or treatment period not ended)
  bool get isActive {
    if (isDeleted) return false;
    if (repeatForever) return true;
    final now = DateTime.now();
    final endDate = startDate.add(Duration(days: totalDays));
    if (now.isAfter(endDate)) {
      return false;
    }
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
    return !isDeleted &&
        actualDaysLeft <= 0 &&
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
    if (isDeleted) {
      return 0;
    }
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
            offsetMinutes: dose.offsetMinutes,
            taken: false,
            takenDate: null,
          ),
        )
        .toList();

    return copyWith(doses: updatedDoses);
  }

  /// Mark a specific dose as taken for today
  Medication markDoseTaken(int doseIndex) {
    if (doseIndex < 0 || doseIndex >= doses.length) return this;

    final updatedDoses = List<MedicationDose>.from(doses);
    updatedDoses[doseIndex] = MedicationDose(
      time: doses[doseIndex].time,
      context: doses[doseIndex].context,
      offsetMinutes: doses[doseIndex].offsetMinutes,
      taken: true,
      takenDate: DateTime.now(),
    );

    return copyWith(doses: updatedDoses);
  }

  Medication markUpdated({
    required DateTime updatedAt,
    required SyncStatus status,
  }) {
    return copyWith(
      syncMetadata: syncMetadata.copyWith(
        updatedAt: updatedAt,
        status: status,
        syncVersion: syncMetadata.syncVersion + 1,
      ),
    );
  }

  Medication markDeleted(DateTime deletedAt) {
    return copyWith(
      isDeleted: true,
      deletedAt: deletedAt,
      syncMetadata: syncMetadata.copyWith(
        updatedAt: deletedAt,
        deletedAt: deletedAt,
        status: SyncStatus.pendingDelete,
        syncVersion: syncMetadata.syncVersion + 1,
      ),
    );
  }

  Medication markSynced(DateTime syncedAt) {
    return copyWith(
      syncMetadata: syncMetadata.copyWith(
        updatedAt: syncedAt,
        lastSyncedAt: syncedAt,
        clearDeletedAt: true,
        status: SyncStatus.synced,
      ),
    );
  }

  Medication copyWith({
    String? id,
    String? userId,
    bool clearUserId = false,
    String? name,
    String? usage,
    String? dosage,
    MedicationType? type,
    MedicationTimingType? timingType,
    List<MedicationDose>? doses,
    int? totalDays,
    DateTime? startDate,
    bool? repeatForever,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    SyncMetadata? syncMetadata,
  }) {
    return Medication(
      id: id ?? this.id,
      userId: clearUserId ? null : (userId ?? this.userId),
      name: name ?? this.name,
      usage: usage ?? this.usage,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      timingType: timingType ?? this.timingType,
      doses: doses ?? this.doses,
      totalDays: totalDays ?? this.totalDays,
      startDate: startDate ?? this.startDate,
      repeatForever: repeatForever ?? this.repeatForever,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      syncMetadata: syncMetadata ?? this.syncMetadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Medication &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          usage == other.usage &&
          dosage == other.dosage &&
          type == other.type &&
          timingType == other.timingType &&
          doses == other.doses &&
          totalDays == other.totalDays &&
          startDate == other.startDate &&
          repeatForever == other.repeatForever &&
          isDeleted == other.isDeleted &&
          deletedAt == other.deletedAt &&
          syncMetadata == other.syncMetadata;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      usage.hashCode ^
      dosage.hashCode ^
      type.hashCode ^
      timingType.hashCode ^
      doses.hashCode ^
      totalDays.hashCode ^
      startDate.hashCode ^
      repeatForever.hashCode ^
      isDeleted.hashCode ^
      deletedAt.hashCode ^
      syncMetadata.hashCode;
}
