import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteService {
  RouteService({
    this.baseUrl = 'https://router.project-osrm.org',
    this.maxWaypoints = 25,
  });

  final String baseUrl;
  final int maxWaypoints;
  final Map<String, List<LatLng>> _cache = {};

  String keyFor(List<LatLng> points) {
    return points
        .map((point) => '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}')
        .join('|');
  }

  Future<List<LatLng>> fetchRoute(List<LatLng> points) async {
    if (points.length < 2) {
      return points;
    }
    if (points.length > maxWaypoints) {
      return points;
    }

    final key = keyFor(points);
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }

    final coords = points.map((point) => '${point.longitude},${point.latitude}').join(';');
    final uri = Uri.parse('$baseUrl/route/v1/driving/$coords').replace(
      queryParameters: const {
        'overview': 'full',
        'geometries': 'geojson',
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return points;
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        return points;
      }
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) {
        return points;
      }
      final geometry = routes.first['geometry'];
      if (geometry is! Map<String, dynamic>) {
        return points;
      }
      final coordsJson = geometry['coordinates'];
      if (coordsJson is! List) {
        return points;
      }
      final line = coordsJson
          .whereType<List>()
          .where((pair) => pair.length >= 2)
          .map((pair) => LatLng(
                (pair[1] as num).toDouble(),
                (pair[0] as num).toDouble(),
              ))
          .toList();
      if (line.length < 2) {
        return points;
      }
      _cache[key] = line;
      return line;
    } catch (_) {
      return points;
    }
  }
}
