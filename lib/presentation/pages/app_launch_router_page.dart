import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/auth/app_entry_session.dart';
import '../../domain/entities/auth/launch_route_decision.dart';
import '../../l10n/app_localizations.dart';
import '../cubit/auth/auth_entry_cubit.dart';
import '../cubit/auth/auth_entry_state.dart';
import '../cubit/sync/sync_status_cubit.dart';
import '../cubit/sync/sync_status_state.dart';
import 'auth_entry_gate_page.dart';
import 'home_page.dart';
import 'settings_page.dart';

class AppLaunchRouterPage extends StatelessWidget {
  final void Function(Locale) onLocaleChanged;
  final VoidCallback onRestartApp;

  const AppLaunchRouterPage({
    super.key,
    required this.onLocaleChanged,
    required this.onRestartApp,
  });

  Future<LaunchRouteDecision> _resolveLaunchDecision(
    AppEntrySession session,
  ) async {
    if (!session.isResolved) {
      return LaunchRouteDecision(
        destination: LaunchDestination.entryGate,
        session: session,
        mealTimesConfigured: false,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final mealTimesConfigured =
        prefs.containsKey('breakfastTime') &&
        prefs.containsKey('lunchTime') &&
        prefs.containsKey('dinnerTime');

    return LaunchRouteDecision(
      destination: mealTimesConfigured
          ? LaunchDestination.home
          : LaunchDestination.initialSettings,
      session: session,
      mealTimesConfigured: mealTimesConfigured,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncStatusCubit, SyncStatusState>(
      listenWhen: (previous, current) =>
          previous.userId != null && current.userId == null,
      listener: (context, state) {
        context.read<AuthEntryCubit>().restoreSession();
      },
      child: BlocBuilder<AuthEntryCubit, AuthEntryState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          if (state.session.status == AppEntrySessionStatus.restoring) {
            return Scaffold(
              body: Center(
                child: Semantics(
                  label: l10n.authEntryRestoring,
                  child: const CircularProgressIndicator(),
                ),
              ),
            );
          }

          return FutureBuilder<LaunchRouteDecision>(
            future: _resolveLaunchDecision(state.session),
            key: ValueKey<Object>(state.session),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Scaffold(
                  body: Center(
                    child: Semantics(
                      label: l10n.authEntryRestoring,
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                );
              }

              final decision = snapshot.data!;
              switch (decision.destination) {
                case LaunchDestination.entryGate:
                  return const AuthEntryGatePage();
                case LaunchDestination.initialSettings:
                  return SettingsPage(
                    key: const ValueKey('initialSettings'),
                    isInitialSetup: true,
                    onLocaleChanged: onLocaleChanged,
                    onRestartApp: onRestartApp,
                  );
                case LaunchDestination.home:
                  return HomePage(
                    key: const ValueKey('homePage'),
                    onLocaleChanged: onLocaleChanged,
                    onRestartApp: onRestartApp,
                  );
              }
            },
          );
        },
      ),
    );
  }
}
