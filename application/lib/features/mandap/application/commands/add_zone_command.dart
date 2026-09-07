import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_zone.dart';
import 'mandap_command.dart';

int _zoneCounter = 0;

class AddZoneCommand implements MandapCommand {
  final MandapZone zone;

  AddZoneCommand({
    required this.zone,
  });

  factory AddZoneCommand.create({
    required ZoneType type,
    required double x1,
    required double y1,
    required double x2,
    required double y2,
  }) {
    _zoneCounter++;
    final idStr = 'z${DateTime.now().microsecondsSinceEpoch}_$_zoneCounter';
    return AddZoneCommand(
      zone: MandapZone(
        id: idStr,
        type: type,
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
      ),
    );
  }

  @override
  String get description => 'Add ${zone.type.name} zone';

  @override
  MandapLayout execute(MandapLayout current) {
    final newZones = List<MandapZone>.from(current.zones)..add(zone);
    return MandapLayout(
      nodes: current.nodes,
      edges: current.edges,
      zones: newZones,
    );
  }

  @override
  MandapLayout undo(MandapLayout current) {
    final newZones = current.zones.where((z) => z.id != zone.id).toList();
    return MandapLayout(
      nodes: current.nodes,
      edges: current.edges,
      zones: newZones,
    );
  }
}
