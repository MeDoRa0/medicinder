# Testing Guide for Medicinder

This document provides a comprehensive guide to the testing infrastructure for the Medicinder medication management app.

## Table of Contents

1. [Overview](#overview)
2. [Test Structure](#test-structure)
3. [Running Tests](#running-tests)
4. [Test Categories](#test-categories)
5. [Writing Tests](#writing-tests)
6. [Best Practices](#best-practices)
7. [CI/CD Integration](#cicd-integration)
8. [Troubleshooting](#troubleshooting)

## Overview

Medicinder uses a comprehensive testing strategy that includes:

- **Unit Tests**: Testing individual functions and classes
- **Widget Tests**: Testing UI components in isolation
- **Integration Tests**: Testing complete user flows
- **Performance Tests**: Ensuring app performance under various conditions
- **Error Handling Tests**: Validating error scenarios
- **Accessibility Tests**: Ensuring app accessibility
- **Localization Tests**: Testing multi-language support

## Test Structure

```
test/
├── run_tests.dart                 # Main test runner
├── test_config.dart              # Test configuration and utilities
├── unit/                         # Unit tests
│   ├── core/
│   │   └── error/
│   │       └── error_handler_test.dart
│   ├── domain/
│   │   └── usecases/
│   │       ├── add_medication_test.dart
│   │       └── get_medications_test.dart
│   ├── data/
│   │   └── repositories/
│   │       └── medication_repository_impl_test.dart
│   └── presentation/
│       └── cubit/
│           └── medication_cubit_test.dart
├── widget/                       # Widget tests
│   └── medication_card_test.dart
├── integration/                  # Integration tests
│   └── medication_flow_test.dart
├── performance/                  # Performance tests
│   └── performance_test.dart
├── accessibility/                # Accessibility tests
└── localization/                 # Localization tests
```

## Running Tests

### Prerequisites

1. Install Flutter SDK (version 3.19.0 or higher)
2. Install dependencies: `flutter pub get`
3. Generate mocks: `flutter packages pub run build_runner build`

### Basic Commands

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test categories
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
flutter test test/performance/

# Run specific test file
flutter test test/unit/domain/usecases/add_medication_test.dart

# Run tests with verbose output
flutter test --verbose

# Run tests and generate HTML coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Categories

#### Unit Tests
```bash
# Run all unit tests
flutter test test/unit/

# Run specific unit test groups
flutter test test/unit/domain/
flutter test test/unit/data/
flutter test test/unit/presentation/
```

#### Widget Tests
```bash
# Run all widget tests
flutter test test/widget/

# Run specific widget tests
flutter test test/widget/medication_card_test.dart
```

#### Integration Tests
```bash
# Run all integration tests
flutter test test/integration/

# Run integration tests with device
flutter drive --target=test/integration/medication_flow_test.dart
```

#### Performance Tests
```bash
# Run performance tests
flutter test test/performance/

# Run performance tests with timing
flutter test test/performance/ --reporter expanded
```

## Test Categories

### 1. Unit Tests

Unit tests verify individual functions, classes, and methods work correctly in isolation.

**Location**: `test/unit/`

**Examples**:
- Use case tests
- Repository tests
- Service tests
- Utility function tests

**Best Practices**:
- Test one thing at a time
- Use descriptive test names
- Mock external dependencies
- Test both success and failure scenarios

### 2. Widget Tests

Widget tests verify UI components render correctly and respond to user interactions.

**Location**: `test/widget/`

**Examples**:
- Component rendering tests
- User interaction tests
- State management tests

**Best Practices**:
- Test widget in isolation
- Use `TestConfig.createTestWidget()` for proper setup
- Test user interactions (tap, scroll, etc.)
- Verify UI state changes

### 3. Integration Tests

Integration tests verify complete user flows and system integration.

**Location**: `test/integration/`

**Examples**:
- Complete medication flow
- Navigation tests
- Data persistence tests

**Best Practices**:
- Test real user scenarios
- Use realistic test data
- Test error handling
- Verify end-to-end functionality

### 4. Performance Tests

Performance tests ensure the app performs well under various conditions.

**Location**: `test/performance/`

**Examples**:
- Large dataset handling
- Memory usage tests
- Response time tests
- Scroll performance tests

**Best Practices**:
- Set performance thresholds
- Test with realistic data sizes
- Monitor memory usage
- Test on different devices

### 5. Error Handling Tests

Error handling tests verify the app handles errors gracefully.

**Location**: `test/unit/core/error/`

**Examples**:
- Network error handling
- Database error handling
- Validation error handling

**Best Practices**:
- Test all error scenarios
- Verify user-friendly error messages
- Test error recovery
- Ensure app doesn't crash

## Writing Tests

### Test Configuration

Use the `TestConfig` class for consistent test setup:

```dart
import '../test_config.dart';

void main() {
  group('MyTest', () {
    testWidgets('should work correctly', (WidgetTester tester) async {
      // Use TestConfig utilities
      final testMedication = TestConfig.createTestMedication();
      
      await tester.pumpWidget(TestConfig.createTestWidget(
        MyWidget(medication: testMedication),
      ));
      
      await TestUtils.pumpAndWait(tester);
      
      // Assertions
      expect(find.text('Expected Text'), findsOneWidget);
    });
  });
}
```

### Test Utilities

Use `TestUtils` for common test operations:

```dart
// Wait for async operations
await TestUtils.pumpAndWait(tester);

// Tap and wait
await TestUtils.tapAndWait(tester, find.byIcon(Icons.add));

// Enter text and wait
await TestUtils.enterTextAndWait(tester, find.byType(TextField), 'Test Text');

// Scroll to widget
await TestUtils.scrollToAndWait(tester, find.text('Hidden Widget'));
```

### Mocking

Use Mockito for mocking dependencies:

```dart
@GenerateMocks([MyRepository])
void main() {
  late MockMyRepository mockRepository;
  
  setUp(() {
    mockRepository = MockMyRepository();
  });
  
  test('should work with mock', () async {
    when(mockRepository.getData()).thenAnswer((_) async => testData);
    
    final result = await myUseCase.call();
    
    expect(result, equals(expectedResult));
    verify(mockRepository.getData()).called(1);
  });
}
```

## Best Practices

### 1. Test Organization

- Group related tests using `group()`
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- Keep tests independent

### 2. Test Data

- Use `TestConfig` for consistent test data
- Create realistic test scenarios
- Avoid hardcoded values
- Use factories for complex objects

### 3. Assertions

- Use specific assertions
- Test one thing per test
- Verify both positive and negative cases
- Use meaningful error messages

### 4. Performance

- Keep tests fast
- Use appropriate timeouts
- Avoid unnecessary async operations
- Clean up resources

### 5. Maintainability

- Keep tests simple
- Use helper functions for common operations
- Document complex test scenarios
- Update tests when code changes

## CI/CD Integration

The project includes GitHub Actions workflows for automated testing:

### Workflow Features

- **Multi-platform testing**: Windows, macOS, Linux
- **Cross-platform testing**: Android, iOS, Web
- **Performance testing**: Automated performance validation
- **Security scanning**: Dependency vulnerability checks
- **Coverage reporting**: Code coverage tracking
- **Build verification**: Automated build testing

### Running CI Locally

```bash
# Install act (GitHub Actions local runner)
brew install act

# Run CI workflow locally
act -j test
```

## Troubleshooting

### Common Issues

#### 1. Test Failures

**Problem**: Tests fail with null safety errors
**Solution**: Ensure all required parameters are provided in test setup

```dart
// Use TestConfig for proper setup
final testMedication = TestConfig.createTestMedication();
```

#### 2. Mock Generation

**Problem**: Mock classes not found
**Solution**: Regenerate mocks

```bash
flutter packages pub run build_runner build
```

#### 3. Localization Issues

**Problem**: Tests fail due to missing localization
**Solution**: Use `TestConfig.createTestWidget()` with proper localization setup

#### 4. Performance Test Failures

**Problem**: Performance tests timeout
**Solution**: Adjust performance thresholds in `TestSettings`

#### 5. Integration Test Issues

**Problem**: Integration tests fail on CI
**Solution**: Ensure proper device setup and dependencies

### Debugging Tests

```bash
# Run tests with debug output
flutter test --verbose

# Run specific test with debug
flutter test test/unit/my_test.dart --verbose

# Run tests with coverage and debug
flutter test --coverage --verbose
```

### Test Logs

Check test logs for detailed error information:

```bash
# Generate detailed test report
flutter test --reporter expanded

# Generate JSON test report
flutter test --reporter json
```

## Contributing

When adding new tests:

1. Follow the existing test structure
2. Use `TestConfig` and `TestUtils` utilities
3. Add appropriate test categories
4. Update this documentation if needed
5. Ensure tests pass on all platforms

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing Guide](https://docs.flutter.dev/cookbook/testing/integration/introduction)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Bloc Testing Guide](https://bloclibrary.dev/#/testing) 