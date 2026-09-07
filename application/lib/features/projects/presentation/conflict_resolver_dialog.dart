import 'package:flutter/material.dart';

class ConflictResolverDialog extends StatelessWidget {
  final VoidCallback onKeepLocal;
  final VoidCallback onKeepServer;

  const ConflictResolverDialog({
    Key? key,
    required this.onKeepLocal,
    required this.onKeepServer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Version Conflict Detected'),
      content: const Text(
          'Someone else has modified this project since you last synced. '
          'How would you like to resolve this?\n\n'
          '• Keep Local: Your changes will overwrite the server version as a new update.\n'
          '• Keep Server: Your unsynced changes will be discarded and replaced with the server version.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onKeepServer();
          },
          child: const Text('Keep Server Version (Discard Local)', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onKeepLocal();
          },
          child: const Text('Keep Local Version'),
        ),
      ],
    );
  }
}
