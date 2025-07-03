import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'dart:developer';

class AddMedicationPage extends StatefulWidget {
  final Medication? medication;
  const AddMedicationPage({super.key, this.medication});

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
      if (_timingType == MedicationTimingType.specificTime) {
        _doseTimes.clear();
        _doseTimes.addAll(
          med.doses.map(
            (d) => TimeOfDay(hour: d.time!.hour, minute: d.time!.minute),
          ),
        );
      } else {
        _mealContexts.clear();
        _mealContexts.addAll(med.doses.map((d) => d.context!).toList());
        // Optionally, set _mealOffsets if you want to prefill offsets
      }
    }
  }

  Map<MealContext, TimeOfDay> _mealTimes = {};

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

    print('AddMedicationPage: Loading meal times from SharedPreferences');
    print(
      'AddMedicationPage: Breakfast time: ${breakfastTime.hour}:${breakfastTime.minute}',
    );
    print(
      'AddMedicationPage: Lunch time: ${lunchTime.hour}:${lunchTime.minute}',
    );
    print(
      'AddMedicationPage: Dinner time: ${dinnerTime.hour}:${dinnerTime.minute}',
    );

    setState(() {
      _mealTimes = {
        MealContext.beforeBreakfast: breakfastTime,
        MealContext.afterBreakfast: breakfastTime,
        MealContext.beforeLunch: lunchTime,
        MealContext.afterLunch: lunchTime,
        MealContext.beforeDinner: dinnerTime,
        MealContext.afterDinner: dinnerTime,
      };
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

  void _toggleMealContext(MealContext contextType) {
    setState(() {
      if (_mealContexts.contains(contextType)) {
        _mealContexts.remove(contextType);
      } else {
        _mealContexts.add(contextType);
      }
    });
  }

  String _getDosageHint() {
    return _medicationType == MedicationType.pill
        ? 'e.g., 1 pill, 2 pills'
        : 'e.g., 5ml, 10ml';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final uuid = const Uuid();
    List<MedicationDose> doses = [];
    if (_timingType == MedicationTimingType.specificTime) {
      doses = _doseTimes.map((t) {
        final now = DateTime.now();
        final time = DateTime(now.year, now.month, now.day, t.hour, t.minute);
        return MedicationDose(time: time, taken: false);
      }).toList();
    } else {
      doses = _mealContexts.map((c) {
        final offset =
            _mealOffsets[c] ?? 15; // Default to 15 minutes if not set
        final mealTime = _mealTimes[c] ?? const TimeOfDay(hour: 8, minute: 0);
        final now = DateTime.now();
        final baseTime = DateTime(
          now.year,
          now.month,
          now.day,
          mealTime.hour,
          mealTime.minute,
        );

        print('AddMedicationPage: Calculating dose time for ${c.name}');
        print(
          'AddMedicationPage: Meal time: ${mealTime.hour}:${mealTime.minute}',
        );
        print('AddMedicationPage: Offset: $offset minutes');

        DateTime doseTime;
        if (c.name.startsWith('before')) {
          doseTime = baseTime.subtract(Duration(minutes: offset));
          print('AddMedicationPage: Before meal - subtracting $offset minutes');
        } else {
          doseTime = baseTime.add(Duration(minutes: offset));
          print('AddMedicationPage: After meal - adding $offset minutes');
        }

        print(
          'AddMedicationPage: Final dose time: ${doseTime.hour}:${doseTime.minute}',
        );

        return MedicationDose(time: doseTime, context: c, taken: false);
      }).toList();
    }

    final startDate = widget.medication?.startDate ?? DateTime.now();
    print('AddMedicationPage: Creating medication with start date: $startDate');
    print('AddMedicationPage: Current time: ${DateTime.now()}');
    print(
      'AddMedicationPage: Medication duration: ${int.tryParse(_daysController.text) ?? 7} days',
    );

    final medication = Medication(
      id: widget.medication?.id ?? uuid.v4(),
      name: _nameController.text.trim(),
      usage: _usageController.text.trim(),
      dosage: _dosageController.text.trim(),
      type: _medicationType,
      timingType: _timingType,
      doses: doses,
      totalDays: int.tryParse(_daysController.text) ?? 7,
      startDate: startDate,
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.medicineName,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usageController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.usage,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.medicineType,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  Radio<MedicationType>(
                    value: MedicationType.pill,
                    groupValue: _medicationType,
                    onChanged: (val) => setState(() => _medicationType = val!),
                  ),
                  Text(AppLocalizations.of(context)!.pill),
                  Radio<MedicationType>(
                    value: MedicationType.syrup,
                    groupValue: _medicationType,
                    onChanged: (val) => setState(() => _medicationType = val!),
                  ),
                  Text(AppLocalizations.of(context)!.syrup),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.dosage,
                  hintText: _getDosageHint(),
                  suffixText: _medicationType == MedicationType.pill
                      ? 'pill'
                      : 'ml',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _daysController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.days,
                  hintText: 'e.g., 7',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Enter a valid number of days';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.timing,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  Radio<MedicationTimingType>(
                    value: MedicationTimingType.specificTime,
                    groupValue: _timingType,
                    onChanged: (val) => setState(() => _timingType = val!),
                  ),
                  Text(AppLocalizations.of(context)!.specificTimes),
                  Radio<MedicationTimingType>(
                    value: MedicationTimingType.contextBased,
                    groupValue: _timingType,
                    onChanged: (val) => setState(() => _timingType = val!),
                  ),
                  Text(AppLocalizations.of(context)!.beforeAfterMeals),
                ],
              ),
              if (_timingType == MedicationTimingType.specificTime) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _doseTimes
                      .asMap()
                      .entries
                      .map(
                        (entry) => Chip(
                          label: Text('${entry.value.format(context)}'),
                          onDeleted: () =>
                              setState(() => _doseTimes.removeAt(entry.key)),
                        ),
                      )
                      .toList(),
                ),
                TextButton.icon(
                  onPressed: _addDoseTime,
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)!.addTime),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: MealContext.values.map((c) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilterChip(
                          label: Text(_mealLabel(c, context)),
                          selected: _mealContexts.contains(c),
                          onSelected: (_) => _toggleMealContext(c),
                        ),
                        if (_mealContexts.contains(c))
                          DropdownButton<int>(
                            value: _mealOffsets[c] ?? 15,
                            items: _offsetOptions.map((min) {
                              return DropdownMenuItem<int>(
                                value: min,
                                child: Text(
                                  '${min ~/ 60 > 0 ? '${min ~/ 60} hour${min == 60 ? '' : 's'}' : '$min minutes'}',
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _mealOffsets[c] = val;
                                });
                              }
                            },
                          ),
                        if (_mealContexts.contains(c))
                          Text(
                            c.name.startsWith('before')
                                ? AppLocalizations.of(context)!.before
                                : AppLocalizations.of(context)!.after,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mealLabel(MealContext c, BuildContext context) {
    switch (c) {
      case MealContext.beforeBreakfast:
        return AppLocalizations.of(context)!.beforeBreakfast;
      case MealContext.afterBreakfast:
        return AppLocalizations.of(context)!.afterBreakfast;
      case MealContext.beforeLunch:
        return AppLocalizations.of(context)!.beforeLunch;
      case MealContext.afterLunch:
        return AppLocalizations.of(context)!.afterLunch;
      case MealContext.beforeDinner:
        return AppLocalizations.of(context)!.beforeDinner;
      case MealContext.afterDinner:
        return AppLocalizations.of(context)!.afterDinner;
    }
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
