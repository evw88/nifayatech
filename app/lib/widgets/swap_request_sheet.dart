import 'package:flutter/material.dart';

import 'package:my_app/data/driver_actions.dart';
import 'package:my_app/models/models.dart';
import 'package:my_app/theme/app_theme.dart';

Future<void> showSwapRequestSheet({
  required BuildContext context,
  required DriverActions actions,
  required int requesterId,
  required int scheduleId,
  VoidCallback? onSubmitted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return _SwapRequestSheet(
        actions: actions,
        requesterId: requesterId,
        scheduleId: scheduleId,
        onSubmitted: onSubmitted,
      );
    },
  );
}

class _SwapRequestSheet extends StatefulWidget {
  const _SwapRequestSheet({
    required this.actions,
    required this.requesterId,
    required this.scheduleId,
    this.onSubmitted,
  });

  final DriverActions actions;
  final int requesterId;
  final int scheduleId;
  final VoidCallback? onSubmitted;

  @override
  State<_SwapRequestSheet> createState() => _SwapRequestSheetState();
}

class _SwapRequestSheetState extends State<_SwapRequestSheet> {
  late final Future<List<DriverOption>> _driversFuture;
  final TextEditingController _messageController = TextEditingController();
  DriverOption? _selected;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _driversFuture = widget.actions.fetchAvailableDrivers(scheduleId: widget.scheduleId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null || _submitting) {
      _showSnack('Select a driver to swap with.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.actions.createSwapRequest(
        requesterId: widget.requesterId,
        targetId: _selected!.employeeId,
        scheduleId: widget.scheduleId,
        targetScheduleId: _selected!.scheduleId,
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.pop(context);
      _showSnack('Swap request sent.');
    } catch (error) {
      _showSnack(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request shift swap',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose another driver scheduled for the same date.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<DriverOption>>(
            future: _driversFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text(
                  _cleanError(snapshot.error ?? 'Unable to load drivers.'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                );
              }
              final drivers = snapshot.data ?? [];
              if (drivers.isEmpty) {
                return Text(
                  'No available drivers found for this date.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                );
              }
              return Column(
                children: drivers
                    .map(
                      (driver) => RadioListTile<DriverOption>(
                        value: driver,
                        groupValue: _selected,
                        onChanged: (value) => setState(() => _selected = value),
                        title: Text(driver.fullName),
                        subtitle: Text(
                          '${driver.employeeCode} · ${driver.scheduledDate} · ${driver.scheduledStartTime}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                        ),
                        activeColor: AppColors.primary,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message (optional)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Sending...' : 'Send request'),
            ),
          ),
        ],
      ),
    );
  }
}
