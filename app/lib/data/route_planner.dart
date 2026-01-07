import 'package:latlong2/latlong.dart';

import 'package:my_app/models/models.dart';

class RoutePlanner {
  static List<ContainerModel> orderByNearest(
    List<ContainerModel> containers, {
    LatLng? start,
  }) {
    if (containers.isEmpty) return [];
    final remaining = List<ContainerModel>.from(containers);
    final ordered = <ContainerModel>[];
    final distance = const Distance();

    ContainerModel current;
    if (start != null) {
      current = remaining.reduce((a, b) {
        final distA = distance.as(LengthUnit.Meter, start, LatLng(a.latitude, a.longitude));
        final distB = distance.as(LengthUnit.Meter, start, LatLng(b.latitude, b.longitude));
        return distA <= distB ? a : b;
      });
      remaining.remove(current);
    } else {
      current = remaining.removeAt(0);
    }

    ordered.add(current);
    while (remaining.isNotEmpty) {
      final currentPoint = LatLng(current.latitude, current.longitude);
      current = remaining.reduce((a, b) {
        final distA = distance.as(LengthUnit.Meter, currentPoint, LatLng(a.latitude, a.longitude));
        final distB = distance.as(LengthUnit.Meter, currentPoint, LatLng(b.latitude, b.longitude));
        return distA <= distB ? a : b;
      });
      remaining.remove(current);
      ordered.add(current);
    }

    return ordered;
  }

  static List<List<ContainerModel>> splitForVehicles(
    List<ContainerModel> orderedStops,
    int vehicleCount,
  ) {
    if (vehicleCount <= 1) {
      return [orderedStops];
    }
    final buckets = List.generate(vehicleCount, (_) => <ContainerModel>[]);
    for (var i = 0; i < orderedStops.length; i++) {
      buckets[i % vehicleCount].add(orderedStops[i]);
    }
    return buckets;
  }
}
