import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/core/error/error_handler.dart';
import 'package:medicinder/core/error/failures.dart';

void main() {
  late ErrorHandler errorHandler;

  setUp(() {
    errorHandler = ErrorHandler();
  });

  group('ErrorHandler', () {
    test(
      'should return the same failure when exception is already a Failure',
      () {
        // Arrange
        const failure = MedicationNotFoundFailure('test-id');

        // Act
        final result = errorHandler.handleException(failure);

        // Assert
        expect(result, equals(failure));
      },
    );

    test('should map permission exception to PermissionFailure', () {
      // Arrange
      final exception = Exception('Permission denied');

      // Act
      final result = errorHandler.handleException(exception);

      // Assert
      expect(result, isA<PermissionFailure>());
      expect(result.message, contains('Permission denied'));
    });

    test('should map not found exception to NotFoundFailure', () {
      // Arrange
      final exception = Exception('Resource not found');

      // Act
      final result = errorHandler.handleException(exception);

      // Assert
      expect(result, isA<NotFoundFailure>());
      expect(result.message, contains('Resource not found'));
    });

    test('should map network exception to NetworkFailure', () {
      // Arrange
      final exception = Exception('Network connection failed');

      // Act
      final result = errorHandler.handleException(exception);

      // Assert
      expect(result, isA<NetworkFailure>());
      expect(result.message, contains('Network connection failed'));
    });

    test('should map validation exception to ValidationFailure', () {
      // Arrange
      final exception = Exception('Invalid data provided');

      // Act
      final result = errorHandler.handleException(exception);

      // Assert
      expect(result, isA<ValidationFailure>());
      expect(result.message, contains('Invalid data'));
    });

    test('should map storage exception to StorageFailure', () {
      // Arrange
      final exception = Exception('Database error occurred');

      // Act
      final result = errorHandler.handleException(exception);

      // Assert
      expect(result, isA<StorageFailure>());
      expect(result.message, contains('Storage error'));
    });

    test('should map unknown exception to UnknownFailure', () {
      // Arrange
      final exception = Exception('Some random error');

      // Act
      final result = errorHandler.handleException(exception);

      // Assert
      expect(result, isA<UnknownFailure>());
      expect(result.message, contains('Some random error'));
    });

    test('should handle null exception', () {
      // Act
      final result = errorHandler.handleException(null);

      // Assert
      expect(result, isA<UnknownFailure>());
      expect(result.message, contains('unknown error'));
    });

    test('should return correct error icon for different failure types', () {
      // Arrange
      final medicationNotFound = const MedicationNotFoundFailure('test');
      final networkFailure = const NetworkFailure('test');
      final permissionFailure = const PermissionFailure('test');

      // Act & Assert
      expect(
        errorHandler.getErrorIcon(medicationNotFound),
        equals(Icons.medication_outlined),
      );
      expect(errorHandler.getErrorIcon(networkFailure), equals(Icons.wifi_off));
      expect(errorHandler.getErrorIcon(permissionFailure), equals(Icons.block));
    });

    test('should return correct error color for different failure types', () {
      // Arrange
      final medicationNotFound = const MedicationNotFoundFailure('test');
      final networkFailure = const NetworkFailure('test');
      final permissionFailure = const PermissionFailure('test');

      // Act & Assert
      expect(
        errorHandler.getErrorColor(medicationNotFound),
        equals(Colors.orange),
      );
      expect(errorHandler.getErrorColor(networkFailure), equals(Colors.blue));
      expect(errorHandler.getErrorColor(permissionFailure), equals(Colors.red));
    });

    test('should correctly identify recoverable failures', () {
      // Arrange
      final networkFailure = const NetworkFailure('test');
      final storageFailure = const StorageFailure('test');
      final permissionFailure = const PermissionFailure('test');

      // Act & Assert
      expect(errorHandler.isRecoverable(networkFailure), isTrue);
      expect(errorHandler.isRecoverable(storageFailure), isTrue);
      expect(errorHandler.isRecoverable(permissionFailure), isFalse);
    });

    test('should return appropriate suggested actions', () {
      // Arrange
      final networkFailure = const NetworkFailure('test');
      final storageFailure = const StorageFailure('test');
      final validationFailure = const ValidationFailure('test');

      // Act & Assert
      expect(
        errorHandler.getSuggestedAction(networkFailure, null),
        contains('connection'),
      );
      expect(
        errorHandler.getSuggestedAction(storageFailure, null),
        contains('restart'),
      );
      expect(
        errorHandler.getSuggestedAction(validationFailure, null),
        contains('check your input'),
      );
    });

    test(
      'should return null suggested action for non-recoverable failures',
      () {
        // Arrange
        final permissionFailure = const PermissionFailure('test');

        // Act
        final result = errorHandler.getSuggestedAction(permissionFailure, null);

        // Assert
        expect(result, isNull);
      },
    );
  });
}
