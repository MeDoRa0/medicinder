import '../../../domain/entities/sync/sync_status_view_state.dart';

class SyncStatusState {
  final SyncStatusViewState viewState;
  final String? userId;
  final String? message;
  final bool busy;

  const SyncStatusState({
    required this.viewState,
    this.userId,
    this.message,
    this.busy = false,
  });

  const SyncStatusState.initial()
    : this(viewState: SyncStatusViewState.notSignedIn);

  SyncStatusState copyWith({
    SyncStatusViewState? viewState,
    String? userId,
    bool clearUserId = false,
    String? message,
    bool clearMessage = false,
    bool? busy,
  }) {
    return SyncStatusState(
      viewState: viewState ?? this.viewState,
      userId: clearUserId ? null : (userId ?? this.userId),
      message: clearMessage ? null : (message ?? this.message),
      busy: busy ?? this.busy,
    );
  }
}
