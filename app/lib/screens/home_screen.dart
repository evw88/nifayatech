import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:my_app/data/api_service.dart';
import 'package:my_app/data/driver_actions.dart';
import 'package:my_app/data/waste_repository.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/common.dart';
import 'package:my_app/widgets/swap_request_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.apiConfig,
  });

  final WasteRepository repository;
  final ApiConfig apiConfig;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DriverActions _actions;
  late String _scheduleStatus;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _actions = DriverActions(ApiService(widget.apiConfig));
    _scheduleStatus = widget.repository.schedules.first.status;
  }

  Future<void> _handleShift() async {
    if (_busy) return;
    setState(() => _busy = true);
    final schedule = widget.repository.schedules.first;
    final driverId = widget.repository.currentEmployee.id;

    try {
      if (_scheduleStatus == 'scheduled') {
        await _actions.startShift(driverId: driverId, scheduleId: schedule.id);
        setState(() => _scheduleStatus = 'in_progress');
        _showSnack('Shift started.');
      } else if (_scheduleStatus == 'in_progress') {
        await _actions.completeShift(driverId: driverId, scheduleId: schedule.id);
        setState(() => _scheduleStatus = 'completed');
        _showSnack('Shift completed.');
      }
    } catch (error) {
      _showSnack(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showReportIssueDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final schedule = widget.repository.schedules.first;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report issue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Details'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (submitted != true) {
      return;
    }

    final title = titleController.text.trim();
    final message = messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      _showSnack('Please add a title and details.');
      return;
    }

    try {
      await _actions.reportIssue(
        title: title,
        message: message,
        routeId: schedule.route.id,
        vehicleId: schedule.vehicle.id,
      );
      _showSnack('Issue reported.');
    } catch (error) {
      _showSnack(_cleanError(error));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.repository.schedules.first;
    final route = schedule.route;
    final containers = widget.repository.containersForRoute(route);
    final unreadAlerts = widget.repository.alerts.where((alert) => !alert.isRead).length;
    final dateLabel = DateFormat('EEE, MMM d').format(DateTime.now());
    final shiftActionLabel = _scheduleStatus == 'scheduled'
        ? 'Start shift'
        : _scheduleStatus == 'in_progress'
            ? 'Complete shift'
            : 'Shift done';
    final shiftActionEnabled = _scheduleStatus == 'scheduled' || _scheduleStatus == 'in_progress';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GradientHeader(
            title: 'Hello, ${widget.repository.currentUser.fullName}',
            subtitle: 'Today: $dateLabel - Shift ${widget.repository.timeline.first.shift.startTime}',
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusPill(
                  label: _scheduleStatus.toUpperCase(),
                  color: _scheduleStatus == 'completed' ? AppColors.muted : AppColors.success,
                ),
                const SizedBox(height: 12),
                Text(
                  route.name,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              MetricTile(
                label: 'Next route',
                value: '${route.distanceKm.toStringAsFixed(1)} km',
                icon: Icons.route_outlined,
                color: AppColors.primary,
              ),
              MetricTile(
                label: 'Containers',
                value: containers.length.toString(),
                icon: Icons.delete_outline,
                color: AppColors.secondary,
              ),
              MetricTile(
                label: 'Alerts',
                value: unreadAlerts.toString(),
                icon: Icons.notifications_active_outlined,
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Today schedule',
            action: TextButton(
              onPressed: () {},
              child: const Text('View details'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text('${schedule.scheduledStartTime} - ${route.durationMinutes} min'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 18, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text('Vehicle ${schedule.vehicle.code} - ${schedule.vehicle.plate}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.group_outlined, size: 18, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        schedule.partner.user.fullName.isEmpty
                            ? 'Partner not assigned'
                            : 'Partner ${schedule.partner.user.fullName}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: shiftActionEnabled && !_busy ? _handleShift : null,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(shiftActionLabel),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => showSwapRequestSheet(
                          context: context,
                          actions: _actions,
                          requesterId: widget.repository.currentEmployee.id,
                          scheduleId: schedule.id,
                        ),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Request swap'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showReportIssueDialog,
                        icon: const Icon(Icons.report_outlined),
                        label: const Text('Report issue'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Next containers',
            action: TextButton(
              onPressed: () {},
              child: const Text('See all'),
            ),
          ),
          const SizedBox(height: 12),
          ...containers.map(
            (container) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withAlpha(31),
                  child: Text(
                    container.type.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(container.code),
                subtitle: Text('${container.address} - ${container.fillPercent.toStringAsFixed(0)}% full'),
                trailing: StatusPill(
                  label: container.status,
                  color: container.fillPercent >= container.alertThreshold
                      ? AppColors.danger
                      : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
