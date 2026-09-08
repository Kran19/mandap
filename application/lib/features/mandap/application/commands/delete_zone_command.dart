import '../domain/entities/mandap_layout.dart';
import '../domain/entities/mandap_zone.dart';
import 'mandap_command.dart';

class DeleteZoneCommand implements MandapCommand {
  final String zoneId;
  final MandapZone snapshot;

  DeleteZoneCommand({required this.zoneId, required this.snapshot});

  @override
  MandapLayout execute(MandapLayout layout) {
    return layout.withoutZone(zoneId);
  }

  @override
  MandapLayout undo(MandapLayout layout) {
    final updatedZones = List<MandapZone>.from(layout.zones)..add(snapshot);
    return MandapLayout(
      nodes: layout.nodes,
      edges: layout.edges,
      zones: updatedZones,
    );
  }

  @override
  String get description => 'Delete ${snapshot.type.name} zone';
}
