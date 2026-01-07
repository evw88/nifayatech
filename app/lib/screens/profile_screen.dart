import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:my_app/data/api_service.dart';
import 'package:my_app/data/driver_actions.dart';
import 'package:my_app/data/waste_repository.dart';
import 'package:my_app/models/models.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/widgets/common.dart';
import 'package:my_app/widgets/swap_request_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.repository,
    required this.apiConfig,
  });

  final WasteRepository repository;
  final ApiConfig apiConfig;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final DriverActions _actions;
  late Future<List<SwapRequest>> _swapRequestsFuture;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    _actions = DriverActions(ApiService(widget.apiConfig));
    _swapRequestsFuture = _actions.fetchSwapRequests();
  }

  void _refreshSwapRequests() {
    setState(() {
      _swapRequestsFuture = _actions.fetchSwapRequests();
    });
  }

  Future<void> _respondSwap(SwapRequest request, String action) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      await _actions.respondSwapRequest(requestId: request.id, action: action);
      _showSnack('Request ${_actionLabel(action)}.');
      _refreshSwapRequests();
    } catch (error) {
      _showSnack(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _actionBusy = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'accept':
        return 'accepted';
      case 'decline':
        return 'declined';
      case 'cancel':
        return 'cancelled';
      default:
        return action;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'declined':
      case 'cancelled':
        return AppColors.muted;
      case 'pending':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.repository.currentUser;
    final employee = widget.repository.currentEmployee;
    final vehicle = widget.repository.currentVehicle;
    final shift = widget.repository.timeline.first;
    final schedule = widget.repository.schedules.first;
    final dateFormat = DateFormat('MMM d, yyyy');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GradientHeader(
            title: user.fullName,
            subtitle: 'Driver - ${employee.employeeCode}',
            trailing: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Text(
                user.fullName.substring(0, 1),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Driver profile',
            action: TextButton(onPressed: () {}, child: const Text('Edit')),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(label: 'Email', value: user.email),
                  const Divider(height: 24),
                  _InfoRow(label: 'Phone', value: user.phone),
                  const Divider(height: 24),
                  _InfoRow(label: 'Status', value: user.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Assigned vehicle',
            action: StatusPill(label: vehicle.status, color: AppColors.success),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.code} - ${vehicle.plate}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${vehicle.type} - ${vehicle.capacityKg} kg capacity',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Upcoming shift',
            action: StatusPill(label: shift.status, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.shift.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${dateFormat.format(shift.workDate)} - ${shift.shift.startTime} - ${shift.shift.endTime}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => showSwapRequestSheet(
                      context: context,
                      actions: _actions,
                      requesterId: employee.id,
                      scheduleId: schedule.id,
                      onSubmitted: _refreshSwapRequests,
                    ),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Request shift swap'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Swap requests',
            action: TextButton(
              onPressed: () => showSwapRequestSheet(
                context: context,
                actions: _actions,
                requesterId: employee.id,
                scheduleId: schedule.id,
                onSubmitted: _refreshSwapRequests,
              ),
              child: const Text('New request'),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<SwapRequest>>(
            future: _swapRequestsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text(
                  _cleanError(snapshot.error ?? 'Unable to load swap requests.'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                );
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return Text(
                  'No swap requests yet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                );
              }
              return Column(
                children: requests.map((request) {
                  final isIncoming = request.targetId == employee.id;
                  final isOutgoing = request.requesterId == employee.id;
                  final counterpartName = isIncoming ? request.requesterName : request.targetName;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Swap with $counterpartName',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              StatusPill(
                                label: request.status,
                                color: _statusColor(request.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${request.scheduledDate} ? ${request.scheduledStartTime}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                          ),
                          if (request.message.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              request.message,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (request.status == 'pending')
                            Row(
                              children: [
                                if (isIncoming) ...[
                                  OutlinedButton(
                                    onPressed: _actionBusy
                                        ? null
                                        : () => _respondSwap(request, 'decline'),
                                    child: const Text('Decline'),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton(
                                    onPressed: _actionBusy
                                        ? null
                                        : () => _respondSwap(request, 'accept'),
                                    child: const Text('Accept'),
                                  ),
                                ] else if (isOutgoing)
                                  OutlinedButton(
                                    onPressed: _actionBusy
                                        ? null
                                        : () => _respondSwap(request, 'cancel'),
                                    child: const Text('Cancel'),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
