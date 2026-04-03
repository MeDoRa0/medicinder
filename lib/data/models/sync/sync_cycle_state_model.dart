import 'package:hive/hive.dart';
import '../../../domain/entities/sync/sync_cycle_state.dart';
import '../../../domain/entities/sync/sync_types.dart';

part 'sync_cycle_state_model.g.dart';

@HiveType(typeId: 6)
class SyncCycleStateModel extends HiveObject {
  @HiveField(0)
  String cycleId;

  @HiveField(1)
  String userId;

  @HiveField(2)
  int triggerIndex;

  @HiveField(3)
  DateTime startedAt;

  @HiveField(4)
  DateTime? completedAt;

  @HiveField(5)
  int statusIndex;

  @HiveField(6)
  int pushedCount;

  @HiveField(7)
  int pulledCount;

  @HiveField(8)
  int failedCount;

  @HiveField(9)
  String? failureClass;

  SyncCycleStateModel({
    required this.cycleId,
    required this.userId,
    required this.triggerIndex,
    required this.startedAt,
    this.completedAt,
    this.statusIndex = 0,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.failedCount = 0,
    this.failureClass,
  });

  factory SyncCycleStateModel.fromEntity(SyncCycleState state) {
    return SyncCycleStateModel(
      cycleId: state.cycleId,
      userId: state.userId,
      triggerIndex: state.trigger.index,
      startedAt: state.startedAt,
      completedAt: state.completedAt,
      statusIndex: state.status.index,
      pushedCount: state.pushedCount,
      pulledCount: state.pulledCount,
      failedCount: state.failedCount,
      failureClass: state.failureClass,
    );
  }

  SyncCycleState toEntity() {
    return SyncCycleState(
      cycleId: cycleId,
      userId: userId,
      trigger: SyncTrigger.values[triggerIndex],
      startedAt: startedAt,
      completedAt: completedAt,
      status: SyncCycleStatus.values[statusIndex],
      pushedCount: pushedCount,
      pulledCount: pulledCount,
      failedCount: failedCount,
      failureClass: failureClass,
    );
  }
}
