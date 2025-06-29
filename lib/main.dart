import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/di/injector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'l10n/app_localizations.dart';

import 'presentation/pages/home_page.dart';
import 'presentation/cubit/medication_cubit.dart';
import 'presentation/pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initDependencies();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Locale? _locale;

  Future<bool> _areMealTimesSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('breakfastTime') &&
        prefs.containsKey('lunchTime') &&
        prefs.containsKey('dinnerTime');
  }

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
  }

  @override
  Widget build(BuildContext context) {
    final customColor = const Color(0xFF71C0B2);
    return BlocProvider(
      create: (_) => sl<MedicationCubit>()..loadMedications(),
      child: FutureBuilder<bool>(
        future: _areMealTimesSet(),
        builder: (context, snapshot) {
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
          if (!snapshot.hasData) {
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
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (snapshot.data == false) {
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
              home: SettingsPage(
                key: const ValueKey('initialSettings'),
                isInitialSetup: true,
                onLocaleChanged: setLocale,
              ),
            );
          }
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
            home: HomePage(onLocaleChanged: setLocale),
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
          );
        },
      ),
    );
  }
}
