import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/medication.dart';
import 'package:flutter/material.dart';

part 'medication_form_state.dart';

class MedicationFormCubit extends Cubit<MedicationFormState> {
  MedicationFormCubit({Medication? initial})
    : super(MedicationFormState.initial(initial));

  void updateName(String name) => emit(state.copyWith(name: name));
  void updateUsage(String usage) => emit(state.copyWith(usage: usage));
  void updateDosage(String dosage) => emit(state.copyWith(dosage: dosage));
  void updateType(MedicationType type) => emit(state.copyWith(type: type));
  void updateTimingType(MedicationTimingType timingType) =>
      emit(state.copyWith(timingType: timingType));
  void updateDoseTimes(List<TimeOfDay> times) =>
      emit(state.copyWith(doseTimes: times));
  void updateMealContexts(List<MealContext> contexts) =>
      emit(state.copyWith(mealContexts: contexts));
  void updateMealOffsets(Map<MealContext, int> offsets) =>
      emit(state.copyWith(mealOffsets: offsets));
  void updateTotalDays(int days) => emit(state.copyWith(totalDays: days));

  void save() {
    emit(state.copyWith(submitted: true));
  }
}
