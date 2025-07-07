import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/meal_time_selector.dart';
import '../widgets/language_selector.dart';
import '../widgets/settings_save_button.dart';
import '../../l10n/app_localizations.dart';
import 'home_page.dart';

class SettingsPage extends StatefulWidget {
  final bool isInitialSetup;
  final void Function(Locale)? onLocaleChanged;
  const SettingsPage({
    super.key,
    this.isInitialSetup = false,
    this.onLocaleChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay? _breakfastTime;
  TimeOfDay? _lunchTime;
  TimeOfDay? _dinnerTime;
  String? _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    _loadMealTimes();
    _loadLanguage();
  }

  Future<void> _loadMealTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _breakfastTime =
          _getTimeOfDayFromPrefs(prefs, 'breakfastTime') ??
          const TimeOfDay(hour: 8, minute: 0);
      _lunchTime =
          _getTimeOfDayFromPrefs(prefs, 'lunchTime') ??
          const TimeOfDay(hour: 13, minute: 0);
      _dinnerTime =
          _getTimeOfDayFromPrefs(prefs, 'dinnerTime') ??
          const TimeOfDay(hour: 19, minute: 0);
    });
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguageCode = prefs.getString('appLanguage') ?? 'en';
    });
  }

  TimeOfDay? _getTimeOfDayFromPrefs(SharedPreferences prefs, String key) {
    final timeString = prefs.getString(key);
    if (timeString == null) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _saveMealTimes() async {
    final prefs = await SharedPreferences.getInstance();
    if (_breakfastTime != null) {
      prefs.setString(
        'breakfastTime',
        '${_breakfastTime!.hour}:${_breakfastTime!.minute}',
      );
    }
    if (_lunchTime != null) {
      prefs.setString('lunchTime', '${_lunchTime!.hour}:${_lunchTime!.minute}');
    }
    if (_dinnerTime != null) {
      prefs.setString(
        'dinnerTime',
        '${_dinnerTime!.hour}:${_dinnerTime!.minute}',
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.mealTimesSaved)),
    );
    if (widget.isInitialSetup ||
        (ModalRoute.of(context)?.settings.arguments == 'initialSetup')) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              HomePage(onLocaleChanged: widget.onLocaleChanged ?? (locale) {}),
        ),
        (route) => false,
      );
    }
  }

  void _changeLanguage(String? code) {
    if (code == null) return;
    setState(() {
      _selectedLanguageCode = code;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('appLanguage', code);
    });
    if (widget.onLocaleChanged != null) {
      widget.onLocaleChanged!(Locale(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInitial =
        widget.isInitialSetup ||
        (ModalRoute.of(context)?.settings.arguments == 'initialSetup');
    return PopScope(
      canPop: !isInitial,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settings),
          automaticallyImplyLeading: !isInitial,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isInitial) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.welcome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              LanguageSelector(
                selectedLanguageCode: _selectedLanguageCode,
                onChanged: _changeLanguage,
              ),
              const SizedBox(height: 24),
              MealTimeSelector(
                breakfastTime: _breakfastTime,
                lunchTime: _lunchTime,
                dinnerTime: _dinnerTime,
                onBreakfastTimeChanged: (t) =>
                    setState(() => _breakfastTime = t),
                onLunchTimeChanged: (t) => setState(() => _lunchTime = t),
                onDinnerTimeChanged: (t) => setState(() => _dinnerTime = t),
              ),
              const SizedBox(height: 24),
              SettingsSaveButton(
                onPressed: _saveMealTimes,
                text: AppLocalizations.of(context)!.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
