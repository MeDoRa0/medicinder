import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medicinder/domain/repositories/medication_repository.dart';
import 'package:medicinder/domain/entities/medication_history.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_state.dart';
import 'dart:developer';

class LastTakenMedicinesCubit extends Cubit<LastTakenMedicinesState> {
  final MedicationRepository _repository;
  StreamSubscription<List<MedicationHistory>>? _subscription;

  LastTakenMedicinesCubit({required MedicationRepository repository})
    : _repository = repository,
      super(const LastTakenMedicinesInitial());

  void watchRecentMedicines() {
    // Prevent multiple subscriptions
    _subscription?.cancel();

    emit(const LastTakenMedicinesLoading());

    _subscription = _repository.getLastTakenMedicinesStream().listen(
      (medications) {
        emit(LastTakenMedicinesLoaded(medications: medications));
      },
      onError: (error, stackTrace) {
        // Log explicitly as required by Constitution Principle VI
        log(
          '[Diagnostic] LastTakenMedicinesCubit stream error: $error\n$stackTrace',
        );
        emit(
          LastTakenMedicinesError(
            message: 'Failed to fetch recently taken medications',
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
