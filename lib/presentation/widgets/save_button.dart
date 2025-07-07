import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class SaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  const SaveButton({super.key, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(AppLocalizations.of(context)!.save),
    );
  }
}
