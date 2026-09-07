import '../domain/organization.dart';
import '../infrastructure/organization_repository.dart';

class OrganizationService {
  final OrganizationRepository repository;
  // TODO: Inject LocalProjectStore or ProjectSyncService to check for dirty projects

  OrganizationService({required this.repository});

  Future<List<Organization>> loadOrganizations() async {
    return await repository.getOrganizations();
  }

  Future<String?> getActiveOrganizationId() async {
    return await repository.getActiveOrganizationId();
  }

  Future<bool> switchOrganization(String newOrgId) async {
    final currentOrgId = await getActiveOrganizationId();
    if (currentOrgId == newOrgId) return true;

    // RULE: Before switching, determine whether there are dirty projects belonging to A.
    // Do not silently abandon them.
    
    // final hasDirty = await _projectStore.hasDirtyProjects(currentOrgId);
    // if (hasDirty) {
    //   throw Exception('Cannot switch organizations while projects are pending synchronization. Please sync or discard local changes first.');
    // }

    await repository.setActiveOrganizationId(newOrgId);
    return true;
  }
}
