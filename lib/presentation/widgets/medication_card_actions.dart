import 'package:flutter/material.dart';
import 'dart:developer';
import '../../domain/entities/medication.dart';
import '../../l10n/app_localizations.dart';
import 'medication_card_delete_dialog.dart';

class MedicationCardActions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Medication medication;
  const MedicationCardActions({
    super.key,
    this.onEdit,
    this.onDelete,
    required this.medication,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueGrey),
            tooltip: AppLocalizations.of(context)!.edit,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.grey),
            tooltip: AppLocalizations.of(context)!.delete,
            onPressed: onDelete != null
                ? () async {
                    log(
                      'MedicationCard: Delete button pressed for medication: \\${medication.name}',
                    );
                    log(
                      'MedicationCard: onDelete callback exists: \\${onDelete != null}',
                    );
                    final confirmed = await showMedicationCardDeleteDialog(
                      context,
                    );
                    if (confirmed == true) {
                      log(
                        'MedicationCard: User confirmed deletion, calling onDelete callback',
                      );
                      onDelete!();
                    } else {
                      log('MedicationCard: User cancelled deletion');
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
