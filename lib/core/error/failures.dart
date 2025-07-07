import 'package:equatable/equatable.dart';

/// Abstract base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

/// Failure types for different error scenarios
class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.code]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, [super.code]);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code]);
}

/// Medication-specific failures
class MedicationNotFoundFailure extends Failure {
  const MedicationNotFoundFailure(String medicationId)
    : super('Medication not found: $medicationId', 'MEDICATION_NOT_FOUND');
}

class InvalidMedicationDataFailure extends Failure {
  const InvalidMedicationDataFailure(String message)
    : super(message, 'INVALID_MEDICATION_DATA');
}

class DoseIndexOutOfRangeFailure extends Failure {
  const DoseIndexOutOfRangeFailure(int index, int maxIndex)
    : super(
        'Dose index $index is out of range (0-$maxIndex)',
        'DOSE_INDEX_OUT_OF_RANGE',
      );
}

/// Notification-specific failures
class NotificationPermissionFailure extends Failure {
  const NotificationPermissionFailure()
    : super('Notification permission denied', 'NOTIFICATION_PERMISSION_DENIED');
}

class NotificationSchedulingFailure extends Failure {
  const NotificationSchedulingFailure(String message)
    : super(message, 'NOTIFICATION_SCHEDULING_FAILED');
}

/// Data persistence failures
class DataMigrationFailure extends Failure {
  const DataMigrationFailure(String message)
    : super(message, 'DATA_MIGRATION_FAILED');
}

class StorageFailure extends Failure {
  const StorageFailure(String message) : super(message, 'STORAGE_FAILED');
}
