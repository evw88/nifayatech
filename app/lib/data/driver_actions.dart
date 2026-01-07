import 'package:my_app/data/api_service.dart';
import 'package:my_app/models/models.dart';

class DriverActions {
  DriverActions(this._service);

  final ApiService _service;

  Future<List<DriverOption>> fetchAvailableDrivers({int? scheduleId}) async {
    final items = await _service.fetchAvailableDrivers(scheduleId: scheduleId);
    return items.map((item) {
      final data = _asMap(item);
      return DriverOption(
        employeeId: _asInt(data['employee_id']),
        employeeCode: _asString(data['employee_code']),
        fullName: _asString(data['full_name']),
        scheduleId: _asInt(data['schedule_id']),
        scheduledDate: _asString(data['scheduled_date']),
        scheduledStartTime: _asString(data['scheduled_start_time']),
      );
    }).toList();
  }

  Future<List<SwapRequest>> fetchSwapRequests() async {
    final items = await _service.fetchSwapRequests();
    return items.map((item) {
      final data = _asMap(item);
      return SwapRequest(
        id: _asInt(data['request_id']),
        status: _asString(data['status']),
        message: _asString(data['message']),
        createdAt: _asDateTime(data['created_at']),
        respondedAt: _asNullableDateTime(data['responded_at']),
        requesterId: _asInt(data['requester_id']),
        requesterName: _asString(data['requester_name']),
        requesterCode: _asString(data['requester_code']),
        targetId: _asInt(data['target_id']),
        targetName: _asString(data['target_name']),
        targetCode: _asString(data['target_code']),
        scheduleId: _asInt(data['schedule_id']),
        targetScheduleId: _asInt(data['target_schedule_id']),
        scheduledDate: _asString(data['scheduled_date']),
        scheduledStartTime: _asString(data['scheduled_start_time']),
      );
    }).toList();
  }

  Future<void> createSwapRequest({
    required int requesterId,
    required int targetId,
    required int scheduleId,
    int? targetScheduleId,
    String? message,
  }) {
    return _service.createSwapRequest(
      requesterId: requesterId,
      targetId: targetId,
      scheduleId: scheduleId,
      targetScheduleId: targetScheduleId,
      message: message,
    );
  }

  Future<void> respondSwapRequest({
    required int requestId,
    required String action,
  }) {
    return _service.respondSwapRequest(requestId: requestId, action: action);
  }

  Future<void> startShift({
    required int driverId,
    required int scheduleId,
  }) {
    return _service.startShift(driverId: driverId, scheduleId: scheduleId);
  }

  Future<void> completeShift({
    required int driverId,
    required int scheduleId,
  }) {
    return _service.completeShift(driverId: driverId, scheduleId: scheduleId);
  }

  Future<void> reportIssue({
    required String title,
    required String message,
    String severity = 'medium',
    int? routeId,
    int? vehicleId,
    int? containerId,
  }) {
    return _service.reportIssue(
      title: title,
      message: message,
      severity: severity,
      routeId: routeId,
      vehicleId: vehicleId,
      containerId: containerId,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return {};
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static DateTime _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.parse(_asString(value));
  }

  static DateTime? _asNullableDateTime(dynamic value) {
    final text = _asString(value);
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}
