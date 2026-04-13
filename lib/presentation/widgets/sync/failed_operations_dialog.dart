import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injector.dart';
import '../../../../data/datasources/sync_queue_local_data_source.dart';
import '../../../../domain/entities/sync/pending_change.dart';
import '../../../../l10n/app_localizations.dart';
import '../../cubit/sync/sync_status_cubit.dart';

class FailedOperationsDialog extends StatefulWidget {
  const FailedOperationsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const FailedOperationsDialog(),
    );
  }

  @override
  State<FailedOperationsDialog> createState() => _FailedOperationsDialogState();
}

class _FailedOperationsDialogState extends State<FailedOperationsDialog> {
  List<PendingChange>? _failedChanges;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChanges();
  }

  Future<void> _loadChanges() async {
    final userId = context.read<SyncStatusCubit>().state.userId;
    try {
      final queue = sl<SyncQueueLocalDataSource>();
      final changes = await queue.getPermanentlyFailedChanges(userId: userId);
      if (mounted) {
        setState(() {
          _failedChanges = changes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _failedChanges = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMd().add_Hm();

    return AlertDialog(
      title: Text(l10n.syncFailed),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _failedChanges == null || _failedChanges!.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(l10n.syncReady),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: _failedChanges!.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final change = _failedChanges![index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${change.operation.name.toUpperCase()} ${change.entityType.name}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Failed at: ${change.lastAttemptAt != null ? dateFormat.format(change.lastAttemptAt!) : 'N/A'}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (change.errorMessage != null &&
                            change.errorMessage!.isNotEmpty)
                          Text(
                            change.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
