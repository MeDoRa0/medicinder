part of 'medication_form_cubit.dart';

class MedicationFormState {
  final String name;
  final String usage;
  final String dosage;
  final MedicationType type;
  final MedicationTimingType timingType;
  final List<TimeOfDay> doseTimes;
  final List<MealContext> mealContexts;
  final Map<MealContext, int> mealOffsets;
  final int totalDays;
  final bool submitted;

  MedicationFormState({
    required this.name,
    required this.usage,
    required this.dosage,
    required this.type,
    required this.timingType,
    required this.doseTimes,
    required this.mealContexts,
    required this.mealOffsets,
    required this.totalDays,
    required this.submitted,
  });

  factory MedicationFormState.initial(Medication? med) {
    return MedicationFormState(
      name: med?.name ?? '',
      usage: med?.usage ?? '',
      dosage: med?.dosage ?? '',
      type: med?.type ?? MedicationType.pill,
      timingType: med?.timingType ?? MedicationTimingType.specificTime,
      doseTimes:
          med != null && med.timingType == MedicationTimingType.specificTime
          ? med.doses
                .map(
                  (d) => TimeOfDay(hour: d.time!.hour, minute: d.time!.minute),
                )
                .toList()
          : [],
      mealContexts:
          med != null && med.timingType == MedicationTimingType.contextBased
          ? med.doses.map((d) => d.context!).toList()
          : [],
      mealOffsets: {},
      totalDays: med?.totalDays ?? 7,
      submitted: false,
    );
  }

  MedicationFormState copyWith({
    String? name,
    String? usage,
    String? dosage,
    MedicationType? type,
    MedicationTimingType? timingType,
    List<TimeOfDay>? doseTimes,
    List<MealContext>? mealContexts,
    Map<MealContext, int>? mealOffsets,
    int? totalDays,
    bool? submitted,
  }) {
    return MedicationFormState(
      name: name ?? this.name,
      usage: usage ?? this.usage,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      timingType: timingType ?? this.timingType,
      doseTimes: doseTimes ?? this.doseTimes,
      mealContexts: mealContexts ?? this.mealContexts,
      mealOffsets: mealOffsets ?? this.mealOffsets,
      totalDays: totalDays ?? this.totalDays,
      submitted: submitted ?? this.submitted,
    );
  }
}
