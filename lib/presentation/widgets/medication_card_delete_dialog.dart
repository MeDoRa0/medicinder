import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

Future<bool?> showMedicationCardDeleteDialog(BuildContext context) {
  final localizations = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(localizations.deleteMedication),
      content: Text(localizations.deleteConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(localizations.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            localizations.delete,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}
