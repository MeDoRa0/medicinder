import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/sync/sync_status_view_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../cubit/sync/sync_status_cubit.dart';
import '../../cubit/sync/sync_status_state.dart';

class SyncAccountTile extends StatelessWidget {
  const SyncAccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncStatusCubit, SyncStatusState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final cubit = context.read<SyncStatusCubit>();
        final isSignedIn =
            state.viewState != SyncStatusViewState.signedOut &&
            state.userId != null;
        final subtitle = switch (state.viewState) {
          SyncStatusViewState.signedOut => l10n.syncUnavailableLocalOnly,
          SyncStatusViewState.signingIn => l10n.syncSigningIn,
          SyncStatusViewState.workspaceInitializing =>
            l10n.syncWorkspaceInitializing,
          SyncStatusViewState.ready => l10n.syncReadyAs(state.userId ?? ''),
          SyncStatusViewState.accessDenied => l10n.syncAccessDenied,
          SyncStatusViewState.syncing => l10n.syncRunning,
          SyncStatusViewState.syncFailed => state.message ?? l10n.syncFailed,
        };

        return Semantics(
          label: l10n.syncStatusTitle,
          button: true,
          child: Card(
            child: ListTile(
              leading: Icon(
                isSignedIn ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              ),
              title: Text(l10n.syncStatusTitle),
              subtitle: Text(subtitle),
              trailing: TextButton(
                onPressed: state.busy
                    ? null
                    : (isSignedIn ? cubit.signOut : cubit.signIn),
                child: Text(
                  isSignedIn
                      ? l10n.syncDisableCloudSync
                      : l10n.syncEnableCloudSync,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
