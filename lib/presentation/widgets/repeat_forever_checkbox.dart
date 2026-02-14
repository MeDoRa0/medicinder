import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class RepeatForeverCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const RepeatForeverCheckbox({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (val) => onChanged(val ?? false)),
        const SizedBox(width: 8),
        Text(AppLocalizations.of(context)!.repeatForever),
      ],
    );
  }
}
