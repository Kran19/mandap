enum SyncState {
  /// local state matches persisted local state and no upload is pending
  CLEAN,
  /// local changes exist that are not yet acknowledged by server
  DIRTY,
  /// upload currently in progress
  SYNCING,
  /// server changed since local base version
  CONFLICT,
  /// non-transient synchronization failure
  ERROR,
  /// synchronization requires authentication
  AUTH_BLOCKED,
  /// synchronization currently cannot reach the backend
  OFFLINE,
}
