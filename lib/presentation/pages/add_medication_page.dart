import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/medication_name_field.dart';
import '../widgets/medication_usage_field.dart';
import '../widgets/medication_type_selector.dart';
import '../widgets/medication_dosage_field.dart';
import '../widgets/repeat_forever_checkbox.dart';
import '../widgets/medication_days_field.dart';
import '../widgets/save_button.dart';
import '../widgets/medication_timing_selector.dart';
import '../widgets/meal_label.dart';

/// Page for adding or editing a medication.
class AddMedicationPage extends StatefulWidget {
  /// The medication to edit, or null to add a new one.
  const AddMedicationPage({super.key, this.medication});
  final Medication? medication;

  @override
  State<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usageController = TextEditingController();
  final _dosageController = TextEditingController();
  final _daysController = TextEditingController();
  MedicationType _medicationType = MedicationType.pill;
  MedicationTimingType _timingType = MedicationTimingType.specificTime;
  final List<TimeOfDay> _doseTimes = [];
  final List<MealContext> _mealContexts = [];
  final Map<MealContext, int> _mealOffsets = {}; // in minutes
  final List<int> _offsetOptions = [15, 30, 60];
  bool _repeatForever = false;

  @override
  void initState() {
    super.initState();
    _loadMealTimes();
    if (widget.medication != null) {
      final med = widget.medication!;
      _nameController.text = med.name;
      _usageController.text = med.usage;
      _dosageController.text = med.dosage;
      _daysController.text = med.totalDays.toString();
      _medicationType = med.type;
      _timingType = med.timingType;
      _repeatForever = med.totalDays >= 10000;
      if (_timingType == MedicationTimingType.specificTime) {
        _doseTimes.clear();
        // Get unique scheduled times instead of all doses
        final uniqueTimes = <String, TimeOfDay>{};
        for (final dose in med.doses) {
          if (dose.time != null) {
            final timeKey = '${dose.time!.hour}:${dose.time!.minute}';
            if (!uniqueTimes.containsKey(timeKey)) {
              uniqueTimes[timeKey] = TimeOfDay(
                hour: dose.time!.hour,
                minute: dose.time!.minute,
              );
            }
          }
        }
        _doseTimes.addAll(uniqueTimes.values.toList());
        // Sort by time
        _doseTimes.sort(
          (a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute),
        );
      } else {
        _mealContexts.clear();
        // Get unique meal contexts instead of all doses
        final uniqueContexts = <MealContext>{};
        for (final dose in med.doses) {
          if (dose.context != null) {
            uniqueContexts.add(dose.context!);
          }
        }
        _mealContexts.addAll(uniqueContexts.toList());
        // Optionally, set _mealOffsets if you want to prefill offsets
      }
    }
  }

  Map<MealContext, TimeOfDay> _mealTimes = {};

  /// Loads meal times from shared preferences.
  Future<void> _loadMealTimes() async {
    final prefs = await SharedPreferences.getInstance();

    // Load meal times with debugging
    final breakfastTime =
        _getTimeOfDayFromPrefs(prefs, 'breakfastTime') ??
        const TimeOfDay(hour: 8, minute: 0);
    final lunchTime =
        _getTimeOfDayFromPrefs(prefs, 'lunchTime') ??
        const TimeOfDay(hour: 13, minute: 0);
    final dinnerTime =
        _getTimeOfDayFromPrefs(prefs, 'dinnerTime') ??
        const TimeOfDay(hour: 19, minute: 0);

    setState(() {
      _mealTimes = {
        MealContext.beforeBreakfast: breakfastTime,
        MealContext.afterBreakfast: breakfastTime,
        MealContext.beforeLunch: lunchTime,
        MealContext.afterLunch: lunchTime,
        MealContext.beforeDinner: dinnerTime,
        MealContext.afterDinner: dinnerTime,
      };
      // When editing a meal-based medication, infer offsets from first dose per context
      final med = widget.medication;
      if (med != null &&
          med.timingType == MedicationTimingType.contextBased &&
          _mealContexts.isNotEmpty) {
        for (final c in _mealContexts) {
          for (final dose in med.doses) {
            if (dose.context == c && dose.time != null) {
              final mealTime =
                  _mealTimes[c] ?? const TimeOfDay(hour: 8, minute: 0);
              final mealMins = mealTime.hour * 60 + mealTime.minute;
              final doseMins =
                  dose.time!.hour * 60 + dose.time!.minute;
              final offset = c.name.startsWith('before')
                  ? mealMins - doseMins
                  : doseMins - mealMins;
              _mealOffsets[c] = offset > 0 ? offset : 15;
              break;
            }
          }
        }
      }
    });
  }

  /// Gets a TimeOfDay from shared preferences.
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

  /// Adds a new dose time to the list.
  void _addDoseTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _doseTimes.add(picked);
      });
    }
  }

  /// Toggles a meal context selection.
  void _toggleMealContext(MealContext contextType) {
    setState(() {
      if (_mealContexts.contains(contextType)) {
        _mealContexts.remove(contextType);
      } else {
        _mealContexts.add(contextType);
      }
    });
  }

  /// Returns a hint for the dosage field based on medication type.
  String _getDosageHint() {
    final l10n = AppLocalizations.of(context)!;
    return _medicationType == MedicationType.pill
        ? l10n.dosageHintPill
        : l10n.dosageHintSyrup;
  }

  /// Saves the medication form.
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final uuid = const Uuid();
    final startDate = widget.medication?.startDate ?? DateTime.now();
    final totalDays = _repeatForever
        ? 30
        : int.tryParse(_daysController.text) ?? 7;

    List<MedicationDose> doses = [];
    if (_timingType == MedicationTimingType.specificTime) {
      // Create doses for each day of the treatment period
      for (int day = 0; day < totalDays; day++) {
        final currentDate = startDate.add(Duration(days: day));
        for (final time in _doseTimes) {
          final doseTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            time.hour,
            time.minute,
          );
          doses.add(MedicationDose(time: doseTime, taken: false));
        }
      }
    } else {
      // Create doses for each day of the treatment period
      for (int day = 0; day < totalDays; day++) {
        final currentDate = startDate.add(Duration(days: day));
        for (final c in _mealContexts) {
          final offset =
              _mealOffsets[c] ?? 15; // Default to 15 minutes if not set
          final mealTime = _mealTimes[c] ?? const TimeOfDay(hour: 8, minute: 0);
          final baseTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            mealTime.hour,
            mealTime.minute,
          );

          DateTime doseTime;
          if (c.name.startsWith('before')) {
            doseTime = baseTime.subtract(Duration(minutes: offset));
          } else {
            doseTime = baseTime.add(Duration(minutes: offset));
          }

          doses.add(MedicationDose(
            time: doseTime,
            context: c,
            offsetMinutes: _mealOffsets[c] ?? 15,
            taken: false,
          ));
        }
      }
    }

    final medication = widget.medication?.copyWith(
          name: _nameController.text.trim(),
          usage: _usageController.text.trim(),
          dosage: _dosageController.text.trim(),
          type: _medicationType,
          timingType: _timingType,
          doses: doses,
          totalDays: _repeatForever
              ? 10000
              : (int.tryParse(_daysController.text) ?? 7),
          startDate: startDate,
          repeatForever: _repeatForever,
        ) ??
        Medication.create(
      id: widget.medication?.id ?? uuid.v4(),
      name: _nameController.text.trim(),
      usage: _usageController.text.trim(),
      dosage: _dosageController.text.trim(),
      type: _medicationType,
      timingType: _timingType,
      doses: doses,
      totalDays: _repeatForever
          ? 10000
          : (int.tryParse(_daysController.text) ?? 7),
      startDate: startDate,
      repeatForever: _repeatForever,
    );
    Navigator.pop(context, medication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medication != null
              ? AppLocalizations.of(context)!.editMedication
              : AppLocalizations.of(context)!.addMedication,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              MedicationNameField(controller: _nameController),
              const SizedBox(height: 12),
              MedicationUsageField(controller: _usageController),
              const SizedBox(height: 20),
              MedicationTypeSelector(
                medicationType: _medicationType,
                onChanged: (val) => setState(() => _medicationType = val),
              ),
              const SizedBox(height: 12),
              MedicationDosageField(
                controller: _dosageController,
                medicationType: _medicationType,
                getDosageHint: _getDosageHint,
              ),
              const SizedBox(height: 12),
              RepeatForeverCheckbox(
                value: _repeatForever,
                onChanged: (val) {
                  setState(() {
                    _repeatForever = val;
                    if (_repeatForever) {
                      _daysController.text = '10000';
                    }
                  });
                },
              ),
              MedicationDaysField(
                controller: _daysController,
                enabled: !_repeatForever,
                repeatForever: _repeatForever,
              ),
              const SizedBox(height: 20),
              MedicationTimingSelector(
                timingType: _timingType,
                onChanged: (val) => setState(() => _timingType = val),
                doseTimes: _doseTimes,
                addDoseTime: _addDoseTime,
                removeDoseTime: (index) {
                  setState(() {
                    _doseTimes.removeAt(index);
                  });
                },
                mealContexts: _mealContexts,
                toggleMealContext: _toggleMealContext,
                mealOffsets: _mealOffsets,
                offsetOptions: _offsetOptions,
                setMealOffset: (c, val) {
                  setState(() {
                    _mealOffsets[c] = val;
                  });
                },
                mealLabel: mealLabel,
              ),
              const SizedBox(height: 24),
              SaveButton(onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usageController.dispose();
    _dosageController.dispose();
    _daysController.dispose();
    super.dispose();
  }
}
