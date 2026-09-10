import 'package:uuid/uuid.dart';

import '../../mandap/domain/entities/mandap_layout.dart';
import '../../mandap/domain/generators/truss_generator.dart';
import '../../mandap/domain/specifications/component_specifications.dart';
import '../domain/local_project_sync_metadata.dart';
import '../domain/sync_state.dart';
import '../infrastructure/local_project_store.dart';
import 'project_sync_service.dart';

class CreateTrussProjectRequest {
  final String projectName;
  final double plotWidth;
  final double plotDepth;
  final double trussWidth;
  final double trussDepth;
  final double towerHeight;
  final int points;

  const CreateTrussProjectRequest({
    required this.projectName,
    required this.plotWidth,
    required this.plotDepth,
    required this.trussWidth,
    required this.trussDepth,
    required this.towerHeight,
    required this.points,
  });
}

class CreateTrussProjectCommand {
  final LocalProjectStore store;
  final ProjectSyncService syncService;

  const CreateTrussProjectCommand({
    required this.store,
    required this.syncService,
  });

  Future<String> execute(CreateTrussProjectRequest request) async {
    // 1. Create Specification
    final spec = TrussSpecification(
      width: request.trussWidth,
      depth: request.trussDepth,
      height: request.towerHeight,
      roofElevation: request.towerHeight - 2.0, // Assuming a slight pitch
      points: request.points,
    );

    // 2. Invoke Generator
    final generator = TrussGenerator(spec);
    final layout = generator.generate();

    // 3. Create Project Metadata
    final projectId = const Uuid().v4();
    final meta = LocalProjectSyncMetadata(
      projectId: projectId,
      syncState: SyncState.DIRTY,
      dirty: true,
      // For a purely local un-synced project, we won't have a baseVersionId yet
    );

    // 4. Local Persistence
    await store.saveLayout(projectId, layout);
    await store.saveMetadata(meta);

    // 5. Initialize Sync Service (syncService.projectId needs to be set, 
    // or the app needs to navigate to the editor which instantiates a new sync service)
    // We just return the projectId to the UI to handle navigation.
    return projectId;
  }
}
