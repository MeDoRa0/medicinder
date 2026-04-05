enum SyncStatus {
  localOnly,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  synced,
  failed,
}

class SyncMetadata {
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  final DateTime? deletedAt;
  final SyncStatus status;
  final int syncVersion;

  const SyncMetadata({
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
    this.deletedAt,
    this.status = SyncStatus.pendingCreate,
    this.syncVersion = 1,
  });

  factory SyncMetadata.initial(DateTime now) => SyncMetadata(
    createdAt: now,
    updatedAt: now,
    status: SyncStatus.localOnly,
  );

  SyncMetadata copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    SyncStatus? status,
    int? syncVersion,
  }) {
    return SyncMetadata(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : (lastSyncedAt ?? this.lastSyncedAt),
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      status: status ?? this.status,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
    'status': status.name,
    'syncVersion': syncVersion,
  };

  factory SyncMetadata.fromJson(Map<String, dynamic> json) => SyncMetadata(
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    lastSyncedAt: json['lastSyncedAt'] != null
        ? DateTime.parse(json['lastSyncedAt'] as String)
        : null,
    deletedAt: json['deletedAt'] != null
        ? DateTime.parse(json['deletedAt'] as String)
        : null,
    status: SyncStatus.values.byName(json['status'] as String),
    syncVersion: json['syncVersion'] as int? ?? 1,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMetadata &&
          runtimeType == other.runtimeType &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          lastSyncedAt == other.lastSyncedAt &&
          deletedAt == other.deletedAt &&
          status == other.status &&
          syncVersion == other.syncVersion;

  @override
  int get hashCode =>
      createdAt.hashCode ^
      updatedAt.hashCode ^
      lastSyncedAt.hashCode ^
      deletedAt.hashCode ^
      status.hashCode ^
      syncVersion.hashCode;
}
