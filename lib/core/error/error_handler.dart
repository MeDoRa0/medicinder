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

    switch (failure.runtimeType) {
      case MedicationNotFoundFailure:
        return l10n?.medicationNotFound ?? 'Medication not found';

      case InvalidMedicationDataFailure:
        return l10n?.invalidData ?? 'Invalid medication data';

      case DoseIndexOutOfRangeFailure:
        return l10n?.invalidDoseIndex ?? 'Invalid dose selection';

      case NotificationPermissionFailure:
        return l10n?.notificationPermissionDenied ??
            'Notification permission denied';

      case NotificationSchedulingFailure:
        return l10n?.notificationSchedulingFailed ??
            'Failed to schedule notification';

      case DataMigrationFailure:
        return l10n?.dataMigrationFailed ?? 'Data migration failed';

      case StorageFailure:
        return l10n?.storageError ?? 'Storage error occurred';

      case NetworkFailure:
        return l10n?.networkError ?? 'Network connection failed';

      case ValidationFailure:
        return l10n?.validationError ?? 'Invalid data provided';

      case PermissionFailure:
        return l10n?.permissionDenied ?? 'Permission denied';

      case NotFoundFailure:
        return l10n?.resourceNotFound ?? 'Resource not found';

      case UnknownFailure:
      default:
        return l10n?.unknownError ?? 'An unexpected error occurred';
    }
  }

  /// Get appropriate icon for the failure type
  IconData getErrorIcon(Failure failure) {
    switch (failure.runtimeType) {
      case MedicationNotFoundFailure:
        return Icons.medication_outlined;

      case NotificationPermissionFailure:
      case NotificationSchedulingFailure:
        return Icons.notifications_off;

      case NetworkFailure:
        return Icons.wifi_off;

      case StorageFailure:
      case DataMigrationFailure:
        return Icons.storage;

      case ValidationFailure:
        return Icons.error_outline;

      case PermissionFailure:
        return Icons.block;

      case NotFoundFailure:
        return Icons.search_off;

      case UnknownFailure:
      default:
        return Icons.error;
    }
  }

  /// Get appropriate color for the failure type
  Color getErrorColor(Failure failure) {
    switch (failure.runtimeType) {
      case MedicationNotFoundFailure:
      case NotFoundFailure:
        return Colors.orange;

      case NotificationPermissionFailure:
      case PermissionFailure:
        return Colors.red;

      case NetworkFailure:
        return Colors.blue;

      case StorageFailure:
      case DataMigrationFailure:
        return Colors.purple;

      case ValidationFailure:
        return Colors.amber;

      case UnknownFailure:
      default:
        return Colors.grey;
    }
  }

  /// Check if the failure is recoverable
  bool isRecoverable(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
      case StorageFailure:
      case NotificationSchedulingFailure:
        return true;

      case PermissionFailure:
      case NotificationPermissionFailure:
        return false;

      case ValidationFailure:
      case InvalidMedicationDataFailure:
        return true;

      case NotFoundFailure:
      case MedicationNotFoundFailure:
        return false;

      case UnknownFailure:
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
      switch (failure.runtimeType) {
        case NetworkFailure:
          return 'Check your connection and try again';
        
        case StorageFailure:
          return 'Try again or restart the app';
        
        case NotificationSchedulingFailure:
          return 'Try again or check notification settings';
        
        case ValidationFailure:
          return 'Please check your input and try again';
        
        default:
          return 'Please try again';
      }
    }

    final l10n = AppLocalizations.of(context);
    
    switch (failure.runtimeType) {
      case NetworkFailure:
        return l10n?.retryNetwork ?? 'Check your connection and try again';

      case StorageFailure:
        return l10n?.retryStorage ?? 'Try again or restart the app';

      case NotificationSchedulingFailure:
        return l10n?.retryNotification ??
            'Try again or check notification settings';

      case ValidationFailure:
        return l10n?.checkInput ?? 'Please check your input and try again';

      default:
        return l10n?.tryAgain ?? 'Please try again';
    }
  }
}
