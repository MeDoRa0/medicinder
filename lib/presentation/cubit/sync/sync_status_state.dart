import '../../../domain/entities/sync/sync_status_view_state.dart';

class SyncStatusState {
  final SyncStatusViewState viewState;
  final String? userId;
  final String? message;
  final bool busy;
  final int permanentlyFailedCount;

  const SyncStatusState({
    required this.viewState,
    this.userId,
    this.message,
    this.busy = false,
    this.permanentlyFailedCount = 0,
  });

  const SyncStatusState.initial()
    : this(viewState: SyncStatusViewState.signedOut);

  bool get isAuthenticated =>
      viewState != SyncStatusViewState.signedOut && userId != null;

  SyncStatusState copyWith({
    SyncStatusViewState? viewState,
    String? userId,
    bool clearUserId = false,
    String? message,
    bool clearMessage = false,
    bool? busy,
    int? permanentlyFailedCount,
  }) {
    return SyncStatusState(
      viewState: viewState ?? this.viewState,
      userId: clearUserId ? null : (userId ?? this.userId),
      message: clearMessage ? null : (message ?? this.message),
      busy: busy ?? this.busy,
      permanentlyFailedCount:
          permanentlyFailedCount ?? this.permanentlyFailedCount,
    );
  }
}
