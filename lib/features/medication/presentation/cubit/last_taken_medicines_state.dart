import 'package:equatable/equatable.dart';
import '../../../../domain/entities/medication_history.dart';

abstract class LastTakenMedicinesState extends Equatable {
  const LastTakenMedicinesState();

  @override
  List<Object?> get props => [];
}

class LastTakenMedicinesInitial extends LastTakenMedicinesState {
  const LastTakenMedicinesInitial();
}

class LastTakenMedicinesLoading extends LastTakenMedicinesState {
  const LastTakenMedicinesLoading();
}

class LastTakenMedicinesLoaded extends LastTakenMedicinesState {
  final List<MedicationHistory> medications;

  const LastTakenMedicinesLoaded({required this.medications});

  @override
  List<Object?> get props => [medications];
}

class LastTakenMedicinesError extends LastTakenMedicinesState {
  final String message;

  const LastTakenMedicinesError({required this.message});

  @override
  List<Object?> get props => [message];
}
