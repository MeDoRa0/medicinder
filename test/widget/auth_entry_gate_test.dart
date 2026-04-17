import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/data/datasources/auth/apple_auth_provider_data_source.dart';
import 'package:medicinder/domain/entities/auth/app_entry_session.dart';
import 'package:medicinder/domain/entities/sync/auth_session.dart';
import 'package:medicinder/domain/repositories/app_entry_repository.dart';
import 'package:medicinder/domain/repositories/auth_repository.dart';
import 'package:medicinder/domain/usecases/auth/clear_app_entry_state.dart';
import 'package:medicinder/domain/usecases/auth/continue_as_guest.dart';
import 'package:medicinder/domain/usecases/auth/restore_app_entry_session.dart';
import 'package:medicinder/domain/usecases/auth/sign_in_with_apple.dart';
import 'package:medicinder/domain/usecases/auth/sign_in_with_google.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/cubit/auth/auth_entry_cubit.dart';
import 'package:medicinder/presentation/pages/auth_entry_gate_page.dart';
import 'package:get_it/get_it.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_cubit.dart';
import 'package:medicinder/features/medication/presentation/cubit/last_taken_medicines_state.dart';
import 'package:mocktail/mocktail.dart';

class MockLastTakenMedicinesCubit extends Mock implements LastTakenMedicinesCubit {}

void main() {
  setUp(() async {
    await GetIt.I.reset();
    final mockCubit = MockLastTakenMedicinesCubit();
    when(() => mockCubit.state).thenReturn(const LastTakenMedicinesLoaded(medications: []));
    when(() => mockCubit.stream).thenAnswer((_) => Stream.value(const LastTakenMedicinesLoaded(medications: [])));
    when(() => mockCubit.watchRecentMedicines()).thenReturn(null);
    when(() => mockCubit.close()).thenAnswer((_) async {});
    GetIt.I.registerSingleton<LastTakenMedicinesCubit>(mockCubit);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });
  testWidgets('shows Apple on iOS and hides it on non-iOS', (tester) async {
    final iosCubit = _buildCubit(
      _FakeAppEntryRepository(),
      _FakeAuthRepository(appleAvailability: AppleAuthAvailability.supported),
    );
    await tester.pumpWidget(
      _GateHarness(cubit: iosCubit, platform: TargetPlatform.iOS),
    );
    await tester.pump();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    final androidCubit = _buildCubit(
      _FakeAppEntryRepository(),
      _FakeAuthRepository(),
    );
    await tester.pumpWidget(
      _GateHarness(cubit: androidCubit, platform: TargetPlatform.android),
    );
    await tester.pump();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
  });

  testWidgets('tapping guest persists guest state', (tester) async {
    final repository = _FakeAppEntryRepository();
    final cubit = _buildCubit(repository, _FakeAuthRepository());

    await tester.pumpWidget(
      _GateHarness(cubit: cubit, platform: TargetPlatform.android),
    );

    await tester.tap(find.text('Continue as Guest'));
    await tester.pump();

    expect(repository.storedMode, 'guest');
    expect(cubit.state.session.isResolved, isTrue);
  });

  testWidgets(
    'successful Google sign-in routes the cubit to authenticated state',
    (tester) async {
      final cubit = _buildCubit(
        _FakeAppEntryRepository(),
        _FakeAuthRepository(
          signInSession: const AuthSession.ready(
            'user-123',
            providerId: 'google.com',
          ),
        ),
      );

      await tester.pumpWidget(
        _GateHarness(cubit: cubit, platform: TargetPlatform.android),
      );

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      expect(cubit.state.session.status, AppEntrySessionStatus.authenticated);
      expect(cubit.state.session.entryMode, AppEntryMode.google);
    },
  );

  testWidgets(
    'successful Apple sign-in routes the cubit to authenticated state',
    (tester) async {
      final cubit = _buildCubit(
        _FakeAppEntryRepository(),
        _FakeAuthRepository(
          appleAvailability: AppleAuthAvailability.supported,
          signInSession: const AuthSession.ready(
            'user-apple',
            providerId: 'apple.com',
          ),
        ),
      );

      await tester.pumpWidget(
        _GateHarness(cubit: cubit, platform: TargetPlatform.iOS),
      );
      await tester.pump();

      await tester.tap(find.text('Continue with Apple'));
      await tester.pump();

      expect(cubit.state.session.status, AppEntrySessionStatus.authenticated);
      expect(cubit.state.session.entryMode, AppEntryMode.apple);
    },
  );

  testWidgets('shows a loading indicator while Google sign-in is in progress', (
    tester,
  ) async {
    final completer = Completer<AuthSession>();
    final cubit = _buildCubit(
      _FakeAppEntryRepository(),
      _FakeAuthRepository(signInCompleter: completer),
    );

    await tester.pumpWidget(
      _GateHarness(cubit: cubit, platform: TargetPlatform.android),
    );

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const AuthSession.ready('user-123', providerId: 'google.com'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('unsupported runner keeps the gate local-only', (tester) async {
    final cubit = _buildCubit(_FakeAppEntryRepository(), _FakeAuthRepository());

    await tester.pumpWidget(
      _GateHarness(cubit: cubit, platform: TargetPlatform.windows),
    );

    final googleButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue with Google'),
    );
    expect(googleButton.onPressed, isNull);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets(
    'unavailable iOS device shows Apple as disabled with localized copy',
    (tester) async {
      final cubit = _buildCubit(
        _FakeAppEntryRepository(),
        _FakeAuthRepository(
          appleAvailability: AppleAuthAvailability.unavailableOnDevice,
        ),
      );

      await tester.pumpWidget(
        _GateHarness(cubit: cubit, platform: TargetPlatform.iOS),
      );
      await tester.pump();

      final appleButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continue with Apple'),
      );
      expect(appleButton.onPressed, isNull);
      expect(
        find.text('Apple sign-in is not available on this device right now.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Apple conflict feedback is localized after a failed attempt', (
    tester,
  ) async {
    final cubit = _buildCubit(
      _FakeAppEntryRepository(),
      _FakeAuthRepository(
        appleAvailability: AppleAuthAvailability.supported,
        signInSession: const AuthSession.failed(
          failureCode: 'APPLE_SIGN_IN_CONFLICT',
        ),
      ),
    );

    await tester.pumpWidget(
      _GateHarness(cubit: cubit, platform: TargetPlatform.iOS),
    );
    await tester.pump();

    await tester.tap(find.text('Continue with Apple'));
    await tester.pump();

    expect(
      find.text(
        'This account already exists with another sign-in method. Use the original sign-in option to continue.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Arabic copy is RTL and Google failure feedback is localized', (
    tester,
  ) async {
    final cubit = _buildCubit(
      _FakeAppEntryRepository(),
      _FakeAuthRepository(
        signInSession: const AuthSession.failed(
          failureCode: 'GOOGLE_SIGN_IN_FAILED',
        ),
      ),
    );

    await tester.pumpWidget(
      _GateHarness(
        cubit: cubit,
        platform: TargetPlatform.iOS,
        locale: const Locale('ar'),
      ),
    );

    await tester.tap(find.text('المتابعة باستخدام Google'));
    await tester.pump();

    expect(find.text('اختر طريقة الدخول'), findsOneWidget);
    expect(
      find.text('تعذر إكمال تسجيل الدخول باستخدام Google. حاول مرة أخرى.'),
      findsOneWidget,
    );
    expect(
      Directionality.of(tester.element(find.text('اختر طريقة الدخول'))),
      TextDirection.rtl,
    );
  });
}

class _GateHarness extends StatelessWidget {
  final AuthEntryCubit cubit;
  final TargetPlatform platform;
  final Locale locale;

  const _GateHarness({
    required this.cubit,
    required this.platform,
    this.locale = const Locale('en'),
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: BlocProvider.value(
        value: cubit,
        child: AuthEntryGatePage(platformOverride: platform),
      ),
    );
  }
}

AuthEntryCubit _buildCubit(
  _FakeAppEntryRepository repository,
  _FakeAuthRepository authRepository,
) {
  return AuthEntryCubit(
    restoreAppEntrySession: RestoreAppEntrySession(authRepository, repository),
    continueAsGuest: ContinueAsGuest(repository),
    clearAppEntryState: ClearAppEntryState(repository),
    signInWithApple: SignInWithApple(authRepository),
    signInWithGoogle: SignInWithGoogle(authRepository),
  );
}

class _FakeAppEntryRepository implements AppEntryRepository {
  String? storedMode;

  @override
  Future<void> clearResolvedEntryMode() async {
    storedMode = null;
  }

  @override
  Future<void> persistGuestMode() async {
    storedMode = 'guest';
  }

  @override
  Future<String?> readResolvedEntryMode() async => storedMode;
}

class _FakeAuthRepository implements AuthRepository {
  final AuthSession currentSession;
  final AuthSession signInSession;
  final Completer<AuthSession>? signInCompleter;
  final AppleAuthAvailability appleAvailability;

  _FakeAuthRepository({
    this.currentSession = const AuthSession.signedOut(),
    AuthSession? signInSession,
    this.signInCompleter,
    this.appleAvailability = AppleAuthAvailability.unsupportedRunner,
  }) : signInSession = signInSession ?? currentSession;

  @override
  Future<AuthSession> getCurrentSession() async => currentSession;

  @override
  Future<AppleAuthAvailability> getAppleAvailability() async =>
      appleAvailability;

  @override
  Future<AuthSession> signInForSync({String? providerId}) async {
    if (signInCompleter != null) {
      return signInCompleter!.future;
    }
    return signInSession;
  }

  @override
  Future<void> signOutFromSync() async {}

  @override
  Stream<AuthSession> watchSession() async* {
    yield currentSession;
  }
}
