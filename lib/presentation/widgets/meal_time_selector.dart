import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

class MealTimeSelector extends StatefulWidget {
  final TimeOfDay? breakfastTime;
  final TimeOfDay? lunchTime;
  final TimeOfDay? dinnerTime;
  final ValueChanged<TimeOfDay>? onBreakfastTimeChanged;
  final ValueChanged<TimeOfDay>? onLunchTimeChanged;
  final ValueChanged<TimeOfDay>? onDinnerTimeChanged;

  const MealTimeSelector({
    super.key,
    this.breakfastTime,
    this.lunchTime,
    this.dinnerTime,
    this.onBreakfastTimeChanged,
    this.onLunchTimeChanged,
    this.onDinnerTimeChanged,
  });

  @override
  State<MealTimeSelector> createState() => _MealTimeSelectorState();
}

class _MealTimeSelectorState extends State<MealTimeSelector> {
  TimeOfDay? _breakfastTime;
  TimeOfDay? _lunchTime;
  TimeOfDay? _dinnerTime;

  @override
  void initState() {
    super.initState();
    _loadMealTimes();
  }

  Future<void> _loadMealTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _breakfastTime =
          widget.breakfastTime ??
          _getTimeOfDayFromPrefs(prefs, 'breakfastTime') ??
          const TimeOfDay(hour: 8, minute: 0);
      _lunchTime =
          widget.lunchTime ??
          _getTimeOfDayFromPrefs(prefs, 'lunchTime') ??
          const TimeOfDay(hour: 13, minute: 0);
      _dinnerTime =
          widget.dinnerTime ??
          _getTimeOfDayFromPrefs(prefs, 'dinnerTime') ??
          const TimeOfDay(hour: 19, minute: 0);
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

  Future<void> _pickTime(
    String meal,
    TimeOfDay? initialTime,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.setMealTimes,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildTimeRow(AppLocalizations.of(context)!.breakfast, _breakfastTime, (
          t,
        ) {
          setState(() => _breakfastTime = t);
          widget.onBreakfastTimeChanged?.call(t);
        }),
        const SizedBox(height: 16),
        _buildTimeRow(AppLocalizations.of(context)!.lunch, _lunchTime, (t) {
          setState(() => _lunchTime = t);
          widget.onLunchTimeChanged?.call(t);
        }),
        const SizedBox(height: 16),
        _buildTimeRow(AppLocalizations.of(context)!.dinner, _dinnerTime, (t) {
          setState(() => _dinnerTime = t);
          widget.onDinnerTimeChanged?.call(t);
        }),
      ],
    );
  }

  Widget _buildTimeRow(
    String label,
    TimeOfDay? time,
    ValueChanged<TimeOfDay> onPicked,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        TextButton(
          onPressed: () => _pickTime(label, time, onPicked),
          child: Text(time != null ? time.format(context) : '--:--'),
        ),
      ],
    );
  }
}
