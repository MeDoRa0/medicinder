import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/medication.dart';

class MedicationTypeSelector extends StatelessWidget {
  final MedicationType medicationType;
  final ValueChanged<MedicationType> onChanged;
  const MedicationTypeSelector({super.key, 
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
        Row(
          children: [
            Radio<MedicationType>(
              value: MedicationType.pill,
              groupValue: medicationType,
              onChanged: (val) => onChanged(val!),
            ),
            Text(AppLocalizations.of(context)!.pill),
            Radio<MedicationType>(
              value: MedicationType.syrup,
              groupValue: medicationType,
              onChanged: (val) => onChanged(val!),
            ),
            Text(AppLocalizations.of(context)!.syrup),
          ],
        ),
      ],
    );
  }
}
