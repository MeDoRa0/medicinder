import 'package:flutter/material.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'failures.dart';
import 'dart:developer';

/// Centralized error handler for the application
class ErrorHandler {
  static const ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  const ErrorHandler._internal();

  /// Convert any exception to a Failure object
  Failure handleException(dynamic exception, [String? context]) {
    log('ErrorHandler: Handling exception: $exception in context: $context');

    if (exception is Failure) {
      return exception;
    }

    if (exception is Exception) {
      return _mapExceptionToFailure(exception, context);
    }

    return UnknownFailure(
      exception?.toString() ?? 'An unknown error occurred',
      'UNKNOWN_ERROR',
    );
  }

  /// Map specific exceptions to appropriate failure types
  Failure _mapExceptionToFailure(Exception exception, String? context) {
    final message = exception.toString();

    if (message.contains('permission') || message.contains('denied')) {
      return const PermissionFailure('Permission denied');
    }

    if (message.contains('not found') || message.contains('404')) {
      return const NotFoundFailure('Resource not found');
    }

    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure('Network connection failed');
    }

    if (message.contains('validation') || message.contains('invalid')) {
      return ValidationFailure('Invalid data: ${exception.toString()}');
    }

    if (message.contains('storage') || message.contains('database')) {
      return StorageFailure('Storage error: ${exception.toString()}');
    }

    return UnknownFailure(exception.toString(), 'MAPPED_EXCEPTION');
  }

  /// Get user-friendly error message for a failure
  String getUserFriendlyMessage(Failure failure, BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (failure) {
      case MedicationNotFoundFailure _:
        return l10n?.medicationNotFound ?? 'Medication not found';

      case InvalidMedicationDataFailure _:
        return l10n?.invalidData ?? 'Invalid medication data';

      case DoseIndexOutOfRangeFailure _:
        return l10n?.invalidDoseIndex ?? 'Invalid dose selection';

      case NotificationPermissionFailure _:
        return l10n?.notificationPermissionDenied ??
            'Notification permission denied';

      case NotificationSchedulingFailure _:
        return l10n?.notificationSchedulingFailed ??
            'Failed to schedule notification';

      case DataMigrationFailure _:
        return l10n?.dataMigrationFailed ?? 'Data migration failed';

      case StorageFailure _:
        return l10n?.storageError ?? 'Storage error occurred';

      case NetworkFailure _:
        return l10n?.networkError ?? 'Network connection failed';

      case ValidationFailure _:
        return l10n?.validationError ?? 'Invalid data provided';

      case PermissionFailure _:
        return l10n?.permissionDenied ?? 'Permission denied';

      case NotFoundFailure _:
        return l10n?.resourceNotFound ?? 'Resource not found';

      case UnknownFailure _:
      default:
        return l10n?.unknownError ?? 'An unexpected error occurred';
    }
  }

  /// Get appropriate icon for the failure type
  IconData getErrorIcon(Failure failure) {
    switch (failure) {
      case MedicationNotFoundFailure _:
        return Icons.medication_outlined;

      case NotificationPermissionFailure _:
      case NotificationSchedulingFailure _:
        return Icons.notifications_off;

      case NetworkFailure _:
        return Icons.wifi_off;

      case StorageFailure _:
      case DataMigrationFailure _:
        return Icons.storage;

      case ValidationFailure _:
        return Icons.error_outline;

      case PermissionFailure _:
        return Icons.block;

      case NotFoundFailure _:
        return Icons.search_off;

      case UnknownFailure _:
      default:
        return Icons.error;
    }
  }

  /// Get appropriate color for the failure type
  Color getErrorColor(Failure failure) {
    switch (failure) {
      case MedicationNotFoundFailure _:
      case NotFoundFailure _:
        return Colors.orange;

      case NotificationPermissionFailure _:
      case PermissionFailure _:
        return Colors.red;

      case NetworkFailure _:
        return Colors.blue;

      case StorageFailure _:
      case DataMigrationFailure _:
        return Colors.purple;

      case ValidationFailure _:
        return Colors.amber;

      case UnknownFailure _:
      default:
        return Colors.grey;
    }
  }

  /// Check if the failure is recoverable
  bool isRecoverable(Failure failure) {
    switch (failure) {
      case NetworkFailure _:
      case StorageFailure _:
      case NotificationSchedulingFailure _:
        return true;

      case PermissionFailure _:
      case NotificationPermissionFailure _:
        return false;

      case ValidationFailure _:
      case InvalidMedicationDataFailure _:
        return true;

      case NotFoundFailure _:
      case MedicationNotFoundFailure _:
        return false;

      case UnknownFailure _:
      default:
        return false;
    }
  }

  /// Get suggested action for the failure
  String? getSuggestedAction(Failure failure, BuildContext? context) {
    if (!isRecoverable(failure)) {
      return null;
    }

    // Handle null context by providing default messages
    if (context == null) {
      switch (failure) {
        case NetworkFailure _:
          return 'Check your connection and try again';

        case StorageFailure _:
          return 'Try again or restart the app';

        case NotificationSchedulingFailure _:
          return 'Try again or check notification settings';

        case ValidationFailure _:
          return 'Please check your input and try again';

        default:
          return 'Please try again';
      }
    }

    final l10n = AppLocalizations.of(context);

    switch (failure) {
      case NetworkFailure _:
        return l10n?.retryNetwork ?? 'Check your connection and try again';

      case StorageFailure _:
        return l10n?.retryStorage ?? 'Try again or restart the app';

      case NotificationSchedulingFailure _:
        return l10n?.retryNotification ??
            'Try again or check notification settings';

      case ValidationFailure _:
        return l10n?.checkInput ?? 'Please check your input and try again';

      default:
        return l10n?.tryAgain ?? 'Please try again';
    }
  }
}
