import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/local_project_sync_metadata.dart';
import '../domain/sync_state.dart';
import '../infrastructure/local_project_store.dart';
import '../infrastructure/project_version_repository.dart';
import '../../mandap/domain/entities/mandap_layout.dart';
import '../../mandap/infrastructure/layout_serializer.dart';
import '../../../core/errors/api_exceptions.dart';


class ProjectSyncService {
  final String organizationId;
  final String projectId;
  final LocalProjectStore store;
  final ProjectVersionRepository versionRepo;

  final ValueNotifier<SyncState> _syncState = ValueNotifier(SyncState.CLEAN);
  ValueListenable<SyncState> get syncState => _syncState;

  Timer? _debounceTimer;
  bool _isSyncing = false;

  ProjectSyncService({
    required this.organizationId,
    required this.projectId,
    required this.store,
    required this.versionRepo,
  });

  Future<void> initialize() async {
    final meta = await store.getMetadata(projectId);
    if (meta != null) {
      _updateState(meta.syncState);
      if (meta.dirty && meta.syncState != SyncState.CONFLICT) {
        _scheduleSync();
      }
    }
  }

  void _updateState(SyncState state) {
    if (_syncState.value != state) {
      _syncState.value = state;
    }
  }

  /// Called by the editor whenever the layout changes.
  Future<void> onLayoutModified(MandapLayout currentLayout, String baseVersionId) async {
    // 1. Immediate local persistence
    await store.saveLayout(projectId, currentLayout);
    
    final meta = LocalProjectSyncMetadata(
      projectId: projectId,
      baseVersionId: baseVersionId,
      syncState: SyncState.DIRTY,
      dirty: true,
    );
    await store.saveMetadata(meta);
    _updateState(SyncState.DIRTY);

    // 2. Schedule debounced network synchronization (Auto-Save)
    _scheduleSync();
  }

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _performSync();
    });
  }

  /// Immediately saves the current layout to the server without debouncing.
  Future<void> saveNow() async {
    _debounceTimer?.cancel();
    await _performSync();
  }

  Future<void> _performSync() async {
    if (_isSyncing || _syncState.value == SyncState.CONFLICT) return;

    final meta = await store.getMetadata(projectId);
    if (meta == null || !meta.dirty || meta.baseVersionId == null) return;

    final layout = await store.getLayout(projectId);
    if (layout == null) return;

    _isSyncing = true;
    _updateState(SyncState.SYNCING);
    await _updateMetaState(meta, SyncState.SYNCING);

    try {
      final layoutData = LayoutSerializer.toJson(layout);
      
      // Perform the POST
      final newVersion = await versionRepo.createVersion(
        organizationId,
        projectId,
        layoutData: layoutData,
        expectedCurrentVersionId: meta.baseVersionId,
      );

      // Success
      final cleanMeta = LocalProjectSyncMetadata(
        projectId: projectId,
        baseVersionId: newVersion.id, // we adopt the new version ID
        syncState: SyncState.CLEAN,
        dirty: false,
        lastSyncedAt: DateTime.now(),
      );
      await store.saveMetadata(cleanMeta);
      _updateState(SyncState.CLEAN);

    } on ConflictException {
      // 409 Conflict
      await _updateMetaState(meta, SyncState.CONFLICT);
      _updateState(SyncState.CONFLICT);
    } on AuthenticationExpiredException {
      // Auth blocked
      await _updateMetaState(meta, SyncState.AUTH_BLOCKED);
      _updateState(SyncState.AUTH_BLOCKED);
    } on RateLimitedException {
      // 429 Too Many Requests - stay DIRTY, let user retry manually
      await _updateMetaState(meta, SyncState.DIRTY);
      _updateState(SyncState.DIRTY);
    } on NetworkUnavailableException {
      // Offline
      await _updateMetaState(meta, SyncState.OFFLINE);
      _updateState(SyncState.OFFLINE);
    } catch (e) {
      // Generic or unknown error
      await _updateMetaState(meta, SyncState.ERROR);
      _updateState(SyncState.ERROR);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _updateMetaState(LocalProjectSyncMetadata meta, SyncState newState) async {
    final newMeta = meta.copyWith(syncState: newState);
    await store.saveMetadata(newMeta);
  }

  /// Handle conflict resolution: User chooses to keep local.
  /// Must fetch latest server version and use that as the expected base.
  Future<void> resolveConflictKeepLocal(String latestServerCurrentVersionId) async {
    final meta = await store.getMetadata(projectId);
    if (meta == null) return;

    // We adopt the latest server version as our base, 
    // and mark as DIRTY to trigger a new sync.
    final newMeta = meta.copyWith(
      baseVersionId: latestServerCurrentVersionId,
      syncState: SyncState.DIRTY,
      dirty: true,
    );
    await store.saveMetadata(newMeta);
    _updateState(SyncState.DIRTY);
    
    _scheduleSync();
  }

  /// Handle conflict resolution: User chooses to discard local changes and keep server.
  Future<void> resolveConflictKeepServer(MandapLayout serverLayout, String serverCurrentVersionId) async {
    // Overwrite local layout and clear dirty flag
    await store.saveLayout(projectId, serverLayout);
    final newMeta = LocalProjectSyncMetadata(
      projectId: projectId,
      baseVersionId: serverCurrentVersionId,
      syncState: SyncState.CLEAN,
      dirty: false,
    );
    await store.saveMetadata(newMeta);
    _updateState(SyncState.CLEAN);
  }
}
