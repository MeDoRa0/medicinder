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
  String triggerName;

  @HiveField(3)
  DateTime startedAt;

  @HiveField(4)
  DateTime? completedAt;

  @HiveField(5)
  String statusName;

  @HiveField(6)
  int pushedCount;

  @HiveField(7)
  int pulledCount;

  @HiveField(8)
  int failedCount;

  @HiveField(9)
  String? failureClass;

  static const String defaultStatusName = 'idle';
  static const String defaultTriggerName = 'appStartup';

  SyncCycleStateModel({
    required this.cycleId,
    required this.userId,
    required this.triggerName,
    required this.startedAt,
    this.completedAt,
    this.statusName = defaultStatusName,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.failedCount = 0,
    this.failureClass,
  });

  factory SyncCycleStateModel.fromEntity(SyncCycleState state) {
    return SyncCycleStateModel(
      cycleId: state.cycleId,
      userId: state.userId,
      triggerName: state.trigger.name,
      startedAt: state.startedAt,
      completedAt: state.completedAt,
      statusName: state.status.name,
      pushedCount: state.pushedCount,
      pulledCount: state.pulledCount,
      failedCount: state.failedCount,
      failureClass: state.failureClass,
    );
  }

  SyncCycleState toEntity() {
    SyncTrigger trigger;
    try {
      trigger = SyncTrigger.values.byName(triggerName);
    } catch (_) {
      trigger = SyncTrigger.appStartup;
    }

    SyncCycleStatus status;
    try {
      status = SyncCycleStatus.values.byName(statusName);
    } catch (_) {
      status = SyncCycleStatus.idle;
    }

    return SyncCycleState(
      cycleId: cycleId,
      userId: userId,
      trigger: trigger,
      startedAt: startedAt,
      completedAt: completedAt,
      status: status,
      pushedCount: pushedCount,
      pulledCount: pulledCount,
      failedCount: failedCount,
      failureClass: failureClass,
    );
  }
}
