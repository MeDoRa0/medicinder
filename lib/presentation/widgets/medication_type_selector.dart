import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/medication.dart';

class MedicationTypeSelector extends StatelessWidget {
  final MedicationType medicationType;
  final ValueChanged<MedicationType> onChanged;
  const MedicationTypeSelector({
    super.key,
    required this.medicationType,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.medicineType,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        RadioGroup<MedicationType>(
          groupValue: medicationType,
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
          child: Row(
            children: [
              Radio<MedicationType>(value: MedicationType.pill),
              Text(AppLocalizations.of(context)!.pill),
              Radio<MedicationType>(value: MedicationType.syrup),
              Text(AppLocalizations.of(context)!.syrup),
            ],
          ),
        ),
      ],
    );
  }
}
