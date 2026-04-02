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
            state.viewState != SyncStatusViewState.notSignedIn &&
            state.userId != null;

        return Semantics(
          label: l10n.syncStatusTitle,
          button: true,
          child: Card(
            child: ListTile(
              leading: Icon(
                isSignedIn ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              ),
              title: Text(l10n.syncStatusTitle),
              subtitle: Text(
                isSignedIn
                    ? l10n.syncSignedInAs(state.userId!)
                    : l10n.syncUnavailableLocalOnly,
              ),
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
