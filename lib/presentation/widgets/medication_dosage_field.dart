import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/entities/medication.dart';

class MedicationDosageField extends StatelessWidget {
  final TextEditingController controller;
  final MedicationType medicationType;
  final String Function() getDosageHint;
  const MedicationDosageField({
    super.key,
    required this.controller,
    required this.medicationType,
    required this.getDosageHint,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.dosage,
        hintText: getDosageHint(),
        suffixText: medicationType == MedicationType.pill 
            ? AppLocalizations.of(context)!.pillUnit 
            : AppLocalizations.of(context)!.mlUnit,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context)!.required : null,
    );
  }
}
