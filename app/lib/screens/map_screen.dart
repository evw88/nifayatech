import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:my_app/data/color_utils.dart';
import 'package:my_app/data/route_planner.dart';
import 'package:my_app/data/route_service.dart';
import 'package:my_app/data/waste_repository.dart';
import 'package:my_app/models/models.dart';
import 'package:my_app/theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.repository});

  final WasteRepository repository;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const double _priorityThreshold = 75;
  static const Duration _stepDuration = Duration(seconds: 3);
  final RouteService _routeService = RouteService();
  bool _priorityOnly = true;
  bool _simulationOn = false;
  Timer? _timer;
  List<_SimVehicle> _vehicles = [];
  final Map<int, double> _fillOverrides = {};
  final Set<int> _collected = {};
  String _routeKey = '';
  List<LatLng> _routeLine = [];
  List<List<LatLng>> _vehicleRouteLines = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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

  void _loadVehicleRouteLines() {
    if (_vehicles.isEmpty) {
      return;
    }
    final futures = _vehicles
        .map((vehicle) => _routeService.fetchRoute(vehicle.straightPoints))
        .toList();
    Future.wait(futures).then((lines) {
      if (!mounted || !_simulationOn) {
        return;
      }
      setState(() => _vehicleRouteLines = lines);
    });
  }

  void _toggleSimulation(List<ContainerModel> stops, LatLng startPoint) {
    if (_simulationOn) {
      _stopSimulation();
    } else {
      _startSimulation(stops, startPoint);
    }
  }

  void _startSimulation(List<ContainerModel> stops, LatLng startPoint) {
    if (stops.isEmpty) {
      _showSnack('No stops available for simulation.');
      return;
    }

    final ordered = RoutePlanner.orderByNearest(stops, start: startPoint);
    final vehicleCount = _vehicleCountFor(ordered.length);
    final buckets = RoutePlanner.splitForVehicles(ordered, vehicleCount);

    _fillOverrides.clear();
    _collected.clear();

    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent];
    _vehicles = buckets.asMap().entries.map((entry) {
      final index = entry.key;
      final bucket = entry.value;
      final orderedBucket = RoutePlanner.orderByNearest(bucket, start: startPoint);
      return _SimVehicle(
        label: 'Truck ${String.fromCharCode(65 + index)}',
        color: colors[index % colors.length],
        stops: orderedBucket,
        position: orderedBucket.isNotEmpty
            ? LatLng(orderedBucket.first.latitude, orderedBucket.first.longitude)
            : startPoint,
      );
    }).toList();

    _vehicleRouteLines = _vehicles.map((vehicle) => vehicle.straightPoints).toList();
    _simulationOn = true;
    _timer?.cancel();
    _timer = Timer.periodic(_stepDuration, (_) => _advanceSimulation());
    setState(() {});
    _loadVehicleRouteLines();
  }

  void _stopSimulation() {
    _timer?.cancel();
    _simulationOn = false;
    _vehicleRouteLines = [];
    setState(() {});
  }

  void _advanceSimulation() {
    var progressed = false;
    for (final vehicle in _vehicles) {
      final stop = vehicle.advance();
      if (stop != null) {
        _fillOverrides[stop.id] = 0;
        _collected.add(stop.id);
        progressed = true;
      }
    }

    if (!progressed) {
      _stopSimulation();
      _showSnack('Simulation complete.');
      return;
    }

    setState(() {});
  }

  int _vehicleCountFor(int stopCount) {
    if (stopCount <= 4) return 1;
    if (stopCount <= 8) return 2;
    return 3;
  }

  double _fillFor(ContainerModel container) {
    return _fillOverrides[container.id] ?? container.fillPercent;
  }

  LatLng _startPoint(List<ContainerModel> containers) {
    final vehicle = widget.repository.currentVehicle;
    if (vehicle.latitude != null && vehicle.longitude != null) {
      return LatLng(vehicle.latitude!, vehicle.longitude!);
    }
    if (containers.isNotEmpty) {
      return LatLng(containers.first.latitude, containers.first.longitude);
    }
    return const LatLng(33.59, -7.61);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildContainerMarker(ContainerModel container) {
    final fill = _fillFor(container);
    final isCollected = _collected.contains(container.id);
    final baseColor = colorFromHex(container.type.colorHex);
    final displayColor = isCollected ? AppColors.success : baseColor;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: displayColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        if (isCollected)
          const Icon(Icons.check, color: Colors.white, size: 16)
        else
          Text(
            '${fill.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildVehicleMarker(_SimVehicle vehicle) {
    return Container(
      decoration: BoxDecoration(
        color: vehicle.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_shipping, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            vehicle.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.repository.routes.first;
    final allContainers = widget.repository.containersForRoute(route);
    final priorityContainers = allContainers
        .where((container) => container.fillPercent >= _priorityThreshold)
        .toList();
    final displayContainers = _priorityOnly && priorityContainers.isNotEmpty
        ? priorityContainers
        : allContainers;
    final startPoint = _startPoint(allContainers);
    final orderedStops = RoutePlanner.orderByNearest(displayContainers, start: startPoint);
    final points = orderedStops
        .map((container) => LatLng(container.latitude, container.longitude))
        .toList();

    if (!_simulationOn) {
      _ensureRouteLine(points);
    }

    final linePoints = _routeLine.isNotEmpty ? _routeLine : points;
    final collectedCount = displayContainers.where((c) => _collected.contains(c.id)).length;

    final vehiclePolylines = <Polyline>[];
    if (_simulationOn) {
      for (var i = 0; i < _vehicles.length; i++) {
        final vehicle = _vehicles[i];
        final line = i < _vehicleRouteLines.length ? _vehicleRouteLines[i] : vehicle.straightPoints;
        if (line.length > 1) {
          vehiclePolylines.add(
            Polyline(
              points: line,
              strokeWidth: 4,
              color: vehicle.color,
            ),
          );
        }
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: points.isNotEmpty ? points.first : startPoint,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.my_app',
              ),
              if (!_simulationOn && linePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: linePoints,
                      strokeWidth: 4,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              if (_simulationOn)
                PolylineLayer(
                  polylines: vehiclePolylines,
                ),
              MarkerLayer(
                markers: displayContainers
                    .map(
                      (container) => Marker(
                        width: 46,
                        height: 46,
                        point: LatLng(container.latitude, container.longitude),
                        child: _buildContainerMarker(container),
                      ),
                    )
                    .toList(),
              ),
              if (_simulationOn)
                MarkerLayer(
                  markers: _vehicles
                      .map(
                        (vehicle) => Marker(
                          width: 72,
                          height: 32,
                          point: vehicle.position,
                          child: _buildVehicleMarker(vehicle),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withAlpha(26),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Priority route map',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          '${displayContainers.length} stops',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withAlpha(18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _priorityOnly && priorityContainers.isNotEmpty
                                    ? 'Showing stops above 75%'
                                    : 'Showing all assigned stops',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.muted,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Switch(
                                    value: _priorityOnly,
                                    onChanged: _simulationOn
                                        ? null
                                        : (value) => setState(() => _priorityOnly = value),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Priority only',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => _toggleSimulation(displayContainers, startPoint),
                          child: Text(_simulationOn ? 'Stop' : 'Simulate'),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withAlpha(31),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(31),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.route, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                route.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${route.distanceKm.toStringAsFixed(1)} km ? $collectedCount/${displayContainers.length} collected',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.muted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () {},
                          child: const Text('Navigate'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimVehicle {
  _SimVehicle({
    required this.label,
    required this.color,
    required this.stops,
    required this.position,
  });

  final String label;
  final Color color;
  final List<ContainerModel> stops;
  LatLng position;
  int _currentIndex = 0;

  List<LatLng> get straightPoints =>
      stops.map((stop) => LatLng(stop.latitude, stop.longitude)).toList();

  ContainerModel? advance() {
    if (_currentIndex >= stops.length) {
      return null;
    }
    final stop = stops[_currentIndex];
    position = LatLng(stop.latitude, stop.longitude);
    _currentIndex++;
    return stop;
  }
}
