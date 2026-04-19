import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/medication.dart';

class MedicationTimingSelector extends StatelessWidget {
  final MedicationTimingType timingType;
  final ValueChanged<MedicationTimingType> onChanged;
  final List<TimeOfDay> doseTimes;
  final VoidCallback addDoseTime;
  final void Function(int) removeDoseTime;
  final List<MealContext> mealContexts;
  final ValueChanged<MealContext> toggleMealContext;
  final Map<MealContext, int> mealOffsets;
  final List<int> offsetOptions;
  final void Function(MealContext, int) setMealOffset;
  final String Function(MealContext, BuildContext) mealLabel;
  const MedicationTimingSelector({
    super.key,
    required this.timingType,
    required this.onChanged,
    required this.doseTimes,
    required this.addDoseTime,
    required this.removeDoseTime,
    required this.mealContexts,
    required this.toggleMealContext,
    required this.mealOffsets,
    required this.offsetOptions,
    required this.setMealOffset,
    required this.mealLabel,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.timing,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        RadioGroup<MedicationTimingType>(
          groupValue: timingType,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          child: Row(
            children: [
              Radio<MedicationTimingType>(value: MedicationTimingType.specificTime),
              Text(AppLocalizations.of(context)!.specificTimes),
              Radio<MedicationTimingType>(value: MedicationTimingType.contextBased),
              Text(AppLocalizations.of(context)!.beforeAfterMeals),
            ],
          ),
        ),
        if (timingType == MedicationTimingType.specificTime) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: doseTimes
                .asMap()
                .entries
                .map(
                  (entry) => Chip(
                    label: Text(entry.value.format(context)),
                    onDeleted: () => removeDoseTime(entry.key),
                  ),
                )
                .toList(),
          ),
          TextButton.icon(
            onPressed: addDoseTime,
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
                    label: Text(mealLabel(c, context)),
                    selected: mealContexts.contains(c),
                    onSelected: (_) => toggleMealContext(c),
                  ),
                  if (mealContexts.contains(c))
                    DropdownButton<int>(
                      value: mealOffsets[c] ?? 15,
                      items: offsetOptions.map((min) {
                        return DropdownMenuItem<int>(
                          value: min,
                          child: Text(
                            min ~/ 60 > 0
                                ? '${min ~/ 60} hour${min == 60 ? '' : 's'}'
                                : '$min minutes',
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setMealOffset(c, val);
                        }
                      },
                    ),
                  if (mealContexts.contains(c))
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
      ],
    );
  }
}
