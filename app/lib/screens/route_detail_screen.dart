import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:my_app/data/color_utils.dart';
import 'package:my_app/data/route_planner.dart';
import 'package:my_app/data/route_service.dart';
import 'package:my_app/data/waste_repository.dart';
import 'package:my_app/models/models.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/common.dart';

class RouteDetailScreen extends StatefulWidget {
  const RouteDetailScreen({
    super.key,
    required this.repository,
    required this.route,
  });

  final WasteRepository repository;
  final RouteModel route;

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  static const double _priorityThreshold = 75;
  final RouteService _routeService = RouteService();
  String _routeKey = '';
  List<LatLng> _routeLine = [];

  void _ensureRouteLine(List<LatLng> points) {
    final key = _routeService.keyFor(points);
    if (key == _routeKey) {
      return;
    }
    _routeKey = key;
    _routeLine = points;
    _routeService.fetchRoute(points).then((line) {
      if (!mounted || key != _routeKey) {
        return;
      }
      setState(() => _routeLine = line);
    });
  }

  @override
  Widget build(BuildContext context) {
    final containers = widget.repository.containersForRoute(widget.route);
    final priorityStops = containers
        .where((container) => container.fillPercent >= _priorityThreshold)
        .toList();
    final startPoint = _startPoint(containers);
    final mapStops = priorityStops.isNotEmpty ? priorityStops : containers;
    final orderedStops = RoutePlanner.orderByNearest(mapStops, start: startPoint);
    final points = orderedStops
        .map((container) => LatLng(container.latitude, container.longitude))
        .toList();

    _ensureRouteLine(points);
    final linePoints = _routeLine.isNotEmpty ? _routeLine : points;

    final sortedStops = [
      ...priorityStops,
      ...containers.where((container) => !priorityStops.contains(container)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GradientHeader(
            title: widget.route.name,
            subtitle: '${widget.route.zone.name} - ${widget.route.distanceKm.toStringAsFixed(1)} km',
            trailing: StatusPill(
              label: widget.route.priority,
              color: widget.route.priority == 'high' ? AppColors.secondary : AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: points.isNotEmpty ? points.first : startPoint,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.my_app',
                    ),
                    if (linePoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: linePoints,
                            strokeWidth: 4,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: containers
                          .map(
                            (container) => Marker(
                              width: 34,
                              height: 34,
                              point: LatLng(container.latitude, container.longitude),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorFromHex(container.type.colorHex),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: container.fillPercent >= _priorityThreshold
                                        ? AppColors.danger
                                        : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            priorityStops.isNotEmpty
                ? 'Optimized for containers above 75%'
                : 'No priority stops above 75% today',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Stops',
            action: StatusPill(
              label: '${containers.length} total',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...sortedStops.map(
            (container) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorFromHex(container.type.colorHex).withAlpha(51),
                  child: Text(
                    container.type.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: colorFromHex(container.type.colorHex),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(container.code),
                subtitle: Text(container.address),
                trailing: StatusPill(
                  label: '${container.fillPercent.toStringAsFixed(0)}%',
                  color: container.fillPercent >= container.alertThreshold
                      ? AppColors.danger
                      : AppColors.success,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LatLng _startPoint(List<ContainerModel> containers) {
    if (containers.isNotEmpty) {
      return LatLng(containers.first.latitude, containers.first.longitude);
    }
    return const LatLng(33.59, -7.61);
  }
}
