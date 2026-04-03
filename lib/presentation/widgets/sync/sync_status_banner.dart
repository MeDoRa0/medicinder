import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/sync/sync_status_view_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../cubit/sync/sync_status_cubit.dart';
import '../../cubit/sync/sync_status_state.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncStatusCubit, SyncStatusState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final bannerColor = switch (state.viewState) {
          SyncStatusViewState.signedOut => Colors.orange.shade100,
          SyncStatusViewState.signingIn => Colors.blue.shade100,
          SyncStatusViewState.workspaceInitializing => Colors.blue.shade50,
          SyncStatusViewState.ready => Colors.green.shade100,
          SyncStatusViewState.accessDenied => Colors.red.shade50,
          SyncStatusViewState.syncing => Colors.blue.shade100,
          SyncStatusViewState.syncFailed => Colors.red.shade100,
        };
        final label = switch (state.viewState) {
          SyncStatusViewState.signedOut => l10n.syncSignedOut,
          SyncStatusViewState.signingIn => l10n.syncSigningIn,
          SyncStatusViewState.workspaceInitializing =>
            l10n.syncWorkspaceInitializing,
          SyncStatusViewState.ready => l10n.syncReady,
          SyncStatusViewState.accessDenied => l10n.syncAccessDenied,
          SyncStatusViewState.syncing => l10n.syncRunning,
          SyncStatusViewState.syncFailed => l10n.syncFailed,
        };

        return Semantics(
          label: '${l10n.syncStatusTitle}: $label',
          container: true,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bannerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (state.busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    switch (state.viewState) {
                      SyncStatusViewState.signedOut =>
                        Icons.cloud_off_outlined,
                      SyncStatusViewState.signingIn => Icons.login,
                      SyncStatusViewState.workspaceInitializing =>
                        Icons.cloud_upload_outlined,
                      SyncStatusViewState.ready => Icons.cloud_done_outlined,
                      SyncStatusViewState.accessDenied =>
                        Icons.no_accounts_outlined,
                      SyncStatusViewState.syncing => Icons.sync,
                      SyncStatusViewState.syncFailed => Icons.cloud_off,
                    },
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (state.viewState == SyncStatusViewState.accessDenied ||
                    state.viewState == SyncStatusViewState.syncFailed)
                  TextButton(
                    onPressed: state.busy
                        ? null
                        : context.read<SyncStatusCubit>().retry,
                    child: Text(l10n.retry),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
