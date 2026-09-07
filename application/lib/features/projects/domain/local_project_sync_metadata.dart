import 'sync_state.dart';

class LocalProjectSyncMetadata {
  final String projectId;
  final String? baseVersionId;
  final SyncState syncState;
  final bool dirty;
  final DateTime? lastSyncedAt;

  LocalProjectSyncMetadata({
    required this.projectId,
    this.baseVersionId,
    required this.syncState,
    required this.dirty,
    this.lastSyncedAt,
  });

  factory LocalProjectSyncMetadata.fromJson(Map<String, dynamic> json) {
    return LocalProjectSyncMetadata(
      projectId: json['projectId'],
      baseVersionId: json['baseVersionId'],
      syncState: SyncState.values.firstWhere(
        (e) => e.name == json['syncState'],
        orElse: () => SyncState.CLEAN,
      ),
      dirty: json['dirty'] ?? false,
      lastSyncedAt: json['lastSyncedAt'] != null 
          ? DateTime.tryParse(json['lastSyncedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'baseVersionId': baseVersionId,
      'syncState': syncState.name,
      'dirty': dirty,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  LocalProjectSyncMetadata copyWith({
    String? baseVersionId,
    SyncState? syncState,
    bool? dirty,
    DateTime? lastSyncedAt,
  }) {
    return LocalProjectSyncMetadata(
      projectId: projectId,
      baseVersionId: baseVersionId ?? this.baseVersionId,
      syncState: syncState ?? this.syncState,
      dirty: dirty ?? this.dirty,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
