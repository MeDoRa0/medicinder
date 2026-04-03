import 'package:equatable/equatable.dart';
import 'sync_types.dart';

/// Represents one synchronization attempt for the active signed-in user.
class SyncCycleState extends Equatable {
  final String cycleId;
  final String userId;
  final SyncTrigger trigger;
  final DateTime startedAt;
  final DateTime? completedAt;
  final SyncCycleStatus status;
  final int pushedCount;
  final int pulledCount;
  final int failedCount;
  final String? failureClass;

  const SyncCycleState({
    required this.cycleId,
    required this.userId,
    required this.trigger,
    required this.startedAt,
    this.completedAt,
    this.status = SyncCycleStatus.idle,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.failedCount = 0,
    this.failureClass,
  });

  @override
  List<Object?> get props => [
        cycleId,
        userId,
        trigger,
        startedAt,
        completedAt,
        status,
        pushedCount,
        pulledCount,
        failedCount,
        failureClass,
      ];

  SyncCycleState copyWith({
    String? cycleId,
    String? userId,
    SyncTrigger? trigger,
    DateTime? startedAt,
    DateTime? completedAt,
    SyncCycleStatus? status,
    int? pushedCount,
    int? pulledCount,
    int? failedCount,
    String? failureClass,
  }) {
    return SyncCycleState(
      cycleId: cycleId ?? this.cycleId,
      userId: userId ?? this.userId,
      trigger: trigger ?? this.trigger,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      pushedCount: pushedCount ?? this.pushedCount,
      pulledCount: pulledCount ?? this.pulledCount,
      failedCount: failedCount ?? this.failedCount,
      failureClass: failureClass ?? this.failureClass,
    );
  }
}
