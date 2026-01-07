import 'package:flutter/material.dart';

import 'package:my_app/data/waste_repository.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/common.dart';
import 'package:my_app/screens/route_detail_screen.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key, required this.repository});

  final WasteRepository repository;
  static const double _priorityThreshold = 75;

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.secondary;
      case 'urgent':
        return AppColors.danger;
      case 'low':
        return AppColors.muted;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const GradientHeader(
            title: 'Routes',
            subtitle: 'Manage assigned collection routes and optimize stops.',
          ),
          const SizedBox(height: 18),
          ...repository.routes.map(
            (route) {
              final containers = repository.containersForRoute(route);
              final priorityCount =
                  containers.where((container) => container.fillPercent >= _priorityThreshold).length;
              return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailScreen(
                        repository: repository,
                        route: route,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            route.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          StatusPill(
                            label: route.status,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${route.zone.name} - ${route.distanceKm.toStringAsFixed(1)} km',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          StatusPill(
                            label: '${route.durationMinutes} min',
                            color: AppColors.primary,
                          ),
                          StatusPill(
                            label: route.priority,
                            color: _priorityColor(route.priority),
                          ),
                          if (priorityCount > 0)
                            StatusPill(
                              label: '$priorityCount priority',
                              color: AppColors.danger,
                            ),
                          StatusPill(
                            label: '${route.containerIds.length} stops',
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            },
          ),
        ],
      ),
    );
  }
}





