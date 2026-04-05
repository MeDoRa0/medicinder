import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class MedicationNameField extends StatelessWidget {
  final TextEditingController controller;
  const MedicationNameField({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.medicineName,
      ),
      validator: (v) => v == null || v.isEmpty
          ? AppLocalizations.of(context)!.required
          : null,
    );
  }
}
