import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicinder/domain/repositories/app_entry_repository.dart';
import 'package:medicinder/domain/usecases/auth/clear_app_entry_state.dart';
import 'package:medicinder/domain/usecases/auth/continue_as_guest.dart';
import 'package:medicinder/domain/usecases/auth/restore_app_entry_session.dart';
import 'package:medicinder/l10n/app_localizations.dart';
import 'package:medicinder/presentation/cubit/auth/auth_entry_cubit.dart';
import 'package:medicinder/presentation/pages/auth_entry_gate_page.dart';

void main() {
  testWidgets('shows Apple on iOS and hides it on non-iOS', (tester) async {
    final iosCubit = _buildCubit(_FakeAppEntryRepository());
    await tester.pumpWidget(
      _GateHarness(
        cubit: iosCubit,
        platform: TargetPlatform.iOS,
      ),
    );

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    final androidCubit = _buildCubit(_FakeAppEntryRepository());
    await tester.pumpWidget(
      _GateHarness(
        cubit: androidCubit,
        platform: TargetPlatform.android,
      ),
    );
    await tester.pump();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
  });

  testWidgets('tapping guest persists guest state', (tester) async {
    final repository = _FakeAppEntryRepository();
    final cubit = _buildCubit(repository);

    await tester.pumpWidget(
      _GateHarness(
        cubit: cubit,
        platform: TargetPlatform.android,
      ),
    );

    await tester.tap(find.text('Continue as Guest'));
    await tester.pump();

    expect(repository.storedMode, 'guest');
    expect(cubit.state.session.isResolved, isTrue);
  });

  testWidgets('Arabic copy is RTL and disabled provider taps show feedback', (
    tester,
  ) async {
    final cubit = _buildCubit(_FakeAppEntryRepository());

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
      find.text('تسجيل الدخول باستخدام Google غير متاح في هذه المرحلة بعد.'),
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

AuthEntryCubit _buildCubit(_FakeAppEntryRepository repository) {
  return AuthEntryCubit(
    restoreAppEntrySession: RestoreAppEntrySession(repository),
    continueAsGuest: ContinueAsGuest(repository),
    clearAppEntryState: ClearAppEntryState(repository),
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
