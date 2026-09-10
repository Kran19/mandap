import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../../projects/application/project_sync_service.dart';
import '../../../../projects/domain/sync_state.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = context.watch<ProjectSyncService>();
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<SyncState>(
      valueListenable: syncService.syncState,
      builder: (context, state, child) {
        IconData icon;
        Color color;
        String text;
        bool isSpinning = false;

        switch (state) {
          case SyncState.CLEAN:
            icon = Icons.check_circle;
            color = Colors.greenAccent;
            text = l10n.saved;
            break;
          case SyncState.DIRTY:
          case SyncState.SYNCING:
            icon = Icons.sync;
            color = Colors.blueAccent;
            text = l10n.saving;
            isSpinning = true;
            break;
          case SyncState.CONFLICT:
            icon = Icons.warning;
            color = Colors.orangeAccent;
            text = l10n.conflict;
            break;
          case SyncState.ERROR:
          case SyncState.OFFLINE:
            icon = Icons.cloud_off;
            color = Colors.redAccent;
            text = l10n.offline;
            break;
          case SyncState.AUTH_BLOCKED:
            icon = Icons.lock;
            color = Colors.red;
            text = 'Auth Blocked'; // Or from l10n if added
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSpinning)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
