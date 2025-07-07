import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  final String? selectedLanguageCode;
  final ValueChanged<String?> onChanged;
  const LanguageSelector({
    super.key,
    required this.selectedLanguageCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context)!.language,
          style: const TextStyle(fontSize: 16),
        ),
        DropdownButton<String>(
          value: selectedLanguageCode,
          items: [
            DropdownMenuItem(
              value: 'en',
              child: Text(AppLocalizations.of(context)!.english),
            ),
            DropdownMenuItem(
              value: 'ar',
              child: Text(AppLocalizations.of(context)!.arabic),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
