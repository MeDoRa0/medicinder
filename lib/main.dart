import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/di/injector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/services/awesome_notification_service.dart';
import 'core/services/medication_reminder_actions.dart';
import 'core/services/notification_action_handler.dart';
import 'core/services/sync/sync_diagnostics.dart';
import 'presentation/pages/app_launch_router_page.dart';
import 'presentation/cubit/auth/auth_entry_cubit.dart';
import 'presentation/cubit/medication_cubit.dart';
import 'presentation/cubit/sync/sync_status_cubit.dart';

/// Global navigator key for accessing context outside the widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// The app's entry point. Initializes dependencies and runs the app.
Future<void> main() async {
  log('Starting Medicinder app...');
  WidgetsFlutterBinding.ensureInitialized();

  log('Initializing timezone...');
  tz.initializeTimeZones();

  var firebaseConfigured = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseConfigured = true;
    log('Firebase initialized for cloud sync foundation.');
  } catch (error) {
    log(
      'Firebase configuration missing or invalid; continuing in local-only mode: $error',
    );
  }
  const SyncDiagnostics().logStartupMode(
    firebaseConfigured: firebaseConfigured,
    localOnly: !firebaseConfigured,
  );

  log('Initializing dependencies...');
  await initDependencies(firebaseConfigured: firebaseConfigured);

  log('Initializing awesome notifications...');
  await AwesomeNotificationService.initialize();

  // Defer non-critical initialization until after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    log('Requesting notification permissions...');
    await AwesomeNotificationService.requestPermissionIfNeeded();

    // Set up notification action listener
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  });

  log('Starting app...');
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Locale? _locale;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('appLanguage') ?? 'en';
    setState(() {
      _locale = Locale(langCode);
      Intl.defaultLocale = langCode;
    });
  }

  void setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', locale.languageCode);
    setState(() {
      _locale = locale;
      Intl.defaultLocale = locale.languageCode;
    });
  }

  void restartApp() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadLocale();

    // Handle notification action if app was launched by it
    AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true)
        .then((receivedAction) {
          if (receivedAction != null) {
            final payload = receivedAction.payload ?? {};
            final medicationId = payload['medicationId'];
            final doseIndex = int.tryParse(payload['doseIndex'] ?? '');
            if ((receivedAction.buttonKeyPressed == 'taken' ||
                    receivedAction.buttonKeyPressed == 'done') &&
                medicationId != null &&
                doseIndex != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await MedicationReminderActions.applyDoseTaken(
                  medicationId,
                  doseIndex,
                );
                final context = navigatorKey.currentContext;
                if (context != null && context.mounted) {
                  await context.read<MedicationCubit>().loadMedications();
                }
              });
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final customColor = const Color(0xFF71C0B2);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<MedicationCubit>()..loadMedications()),
        BlocProvider(create: (_) => sl<AuthEntryCubit>()..restoreSession()),
        BlocProvider(create: (_) => sl<SyncStatusCubit>()..initialize()),
      ],
      child: Builder(
        builder: (context) {
          final theme = ThemeData(
            primaryColor: customColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: customColor,
              primary: customColor,
              secondary: customColor,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: customColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: customColor,
              foregroundColor: Colors.white,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: customColor.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            scaffoldBackgroundColor: Colors.white,
          );
          return MaterialApp(
            theme: theme,
            locale: _locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            home: AppLaunchRouterPage(
              onLocaleChanged: setLocale,
              onRestartApp: restartApp,
            ),
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
