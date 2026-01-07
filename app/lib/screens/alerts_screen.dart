import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:my_app/data/waste_repository.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/common.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.repository});

  final WasteRepository repository;

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.danger;
      case 'high':
        return AppColors.secondary;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d - HH:mm');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const GradientHeader(
            title: 'Alerts',
            subtitle: 'Track issues and operational warnings in real time.',
          ),
          const SizedBox(height: 18),
          ...repository.alerts.map(
            (alert) => Card(
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _severityColor(alert.severity).withAlpha(38),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: _severityColor(alert.severity),
                  ),
                ),
                title: Text(
                  alert.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                subtitle: Text(
                  '${alert.message}\n${formatter.format(alert.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                isThreeLine: true,
                trailing: StatusPill(
                  label: alert.severity,
                  color: _severityColor(alert.severity),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}





