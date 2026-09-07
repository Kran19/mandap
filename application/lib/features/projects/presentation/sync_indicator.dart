import 'package:flutter/material.dart';
import '../domain/sync_state.dart';

class SyncIndicator extends StatelessWidget {
  final SyncState state;

  const SyncIndicator({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String tooltip;

    switch (state) {
      case SyncState.CLEAN:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = 'All changes saved to cloud';
        break;
      case SyncState.DIRTY:
        icon = Icons.cloud_queue;
        color = Colors.grey;
        tooltip = 'Unsaved local changes';
        break;
      case SyncState.SYNCING:
        icon = Icons.sync;
        color = Colors.blue;
        tooltip = 'Syncing...';
        break;
      case SyncState.CONFLICT:
        icon = Icons.warning;
        color = Colors.orange;
        tooltip = 'Version conflict! Action required.';
        break;
      case SyncState.ERROR:
        icon = Icons.error;
        color = Colors.red;
        tooltip = 'Sync failed. Will retry later.';
        break;
      case SyncState.AUTH_BLOCKED:
        icon = Icons.lock;
        color = Colors.red;
        tooltip = 'Authentication expired. Please log in again.';
        break;
      case SyncState.OFFLINE:
        icon = Icons.cloud_off;
        color = Colors.grey;
        tooltip = 'Offline. Changes saved locally.';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == SyncState.SYNCING)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            state.name,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
