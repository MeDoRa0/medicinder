import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth/app_entry_session.dart';
import '../../l10n/app_localizations.dart';
import '../cubit/auth/auth_entry_cubit.dart';
import '../cubit/auth/auth_entry_state.dart';
import '../widgets/auth/auth_entry_option_button.dart';

class AuthEntryGatePage extends StatelessWidget {
  final TargetPlatform? platformOverride;

  const AuthEntryGatePage({super.key, this.platformOverride});

  bool get _showAppleOption {
    final platform = platformOverride ?? defaultTargetPlatform;
    return !kIsWeb && platform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthEntryCubit, AuthEntryState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final cubit = context.read<AuthEntryCubit>();
        final platform = platformOverride ?? defaultTargetPlatform;
        final googleSupported = !kIsWeb &&
            (platform == TargetPlatform.android ||
                platform == TargetPlatform.iOS);
        final feedbackMessage = switch (state.feedbackCode) {
          'google_unavailable' => l10n.authEntryGoogleUnavailableFeedback,
          'apple_coming_soon' => l10n.authEntryAppleUnavailableFeedback,
          'GOOGLE_SIGN_IN_CANCELLED' => l10n.authEntryGoogleCancelledFeedback,
          'GOOGLE_SIGN_IN_UNSUPPORTED' =>
            l10n.authEntryGoogleUnsupportedRunnerFeedback,
          'GOOGLE_SIGN_IN_FAILED' => l10n.authEntryGoogleFailedFeedback,
          'GOOGLE_ID_TOKEN_MISSING' => l10n.authEntryGoogleFailedFeedback,
          'network-request-failed' => l10n.authEntryGoogleFailedFeedback,
          'invalid-credential' => l10n.authEntryGoogleFailedFeedback,
          'user-disabled' => l10n.authEntryGoogleFailedFeedback,
          _ => state.session.failureCode == 'UNSUPPORTED_ENTRY_MODE'
              ? l10n.authEntryUnsupportedRestoreFeedback
              : null,
        };

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.authEntryTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.authEntrySubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      AuthEntryOptionButton(
                        title: l10n.authEntryGoogleTitle,
                        description: state.inProgressMode == AppEntryMode.google
                            ? l10n.authEntryGoogleLoading
                            : googleSupported
                            ? l10n.authEntryGoogleDescription
                            : l10n.authEntryComingSoon,
                        enabled: googleSupported && !state.busy,
                        onPressed: state.busy
                            ? null
                            : googleSupported
                            ? cubit.signInWithGoogle
                            : () =>
                                  cubit.onDisabledProviderTap(
                                    AppEntryMode.google,
                                  ),
                        icon: Icons.g_mobiledata_rounded,
                        semanticsLabel:
                            '${l10n.authEntryGoogleTitle}. ${googleSupported ? l10n.authEntryGoogleDescription : l10n.authEntryComingSoon}',
                        semanticsHint: googleSupported
                            ? l10n.authEntryGoogleEnabledSemanticsHint
                            : l10n.authEntryDisabledSemanticsHint,
                      ),
                      if (_showAppleOption) ...[
                        const SizedBox(height: 16),
                        AuthEntryOptionButton(
                          title: l10n.authEntryAppleTitle,
                          description: l10n.authEntryComingSoon,
                          enabled: false,
                          onPressed: state.busy
                              ? null
                              : () =>
                                    cubit.onDisabledProviderTap(
                                      AppEntryMode.apple,
                                    ),
                          icon: Icons.apple,
                          semanticsLabel:
                              '${l10n.authEntryAppleTitle}. ${l10n.authEntryComingSoon}',
                          semanticsHint: l10n.authEntryDisabledSemanticsHint,
                        ),
                      ],
                      const SizedBox(height: 16),
                      AuthEntryOptionButton(
                        title: l10n.authEntryGuestTitle,
                        description: l10n.authEntryGuestDescription,
                        enabled: true,
                        onPressed: state.busy ? null : cubit.continueAsGuest,
                        icon: Icons.person_outline,
                        semanticsLabel: l10n.authEntryGuestSemanticsLabel,
                      ),
                      if (state.busy) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: Semantics(
                            liveRegion: true,
                            label: state.inProgressMode == AppEntryMode.google
                                ? l10n.authEntryGoogleLoading
                                : l10n.authEntryRestoring,
                            child: const CircularProgressIndicator(),
                          ),
                        ),
                      ],
                      if (feedbackMessage != null) ...[
                        const SizedBox(height: 20),
                        Semantics(
                          liveRegion: true,
                          label: feedbackMessage,
                          child: Text(
                            feedbackMessage,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
