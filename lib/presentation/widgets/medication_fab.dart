import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class MedicationFAB extends StatelessWidget {
  final VoidCallback onAddMedication;
  const MedicationFAB({super.key, required this.onAddMedication});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'add_medication',
          onPressed: onAddMedication,
          tooltip: AppLocalizations.of(context)!.addMedication,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}
