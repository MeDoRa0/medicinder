import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';

class MedicationDaysField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool repeatForever;
  const MedicationDaysField({super.key, 
    required this.controller,
    required this.enabled,
    required this.repeatForever,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.days,
        hintText: 'e.g., 7',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      validator: (v) {
        if (repeatForever) return null;
        if (v == null || v.isEmpty) return 'Required';
        final n = int.tryParse(v);
        if (n == null || n < 1) return 'Enter a valid number of days';
        return null;
      },
      enabled: enabled,
    );
  }
}
