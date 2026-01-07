import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    required this.driverId,
  });

  final String baseUrl;
  final int driverId;
}

class ApiService {
  ApiService(this.config);

  final ApiConfig config;

  Uri _buildUri(String path, [Map<String, String>? query]) {
    return Uri.parse('${config.baseUrl}$path').replace(queryParameters: query);
  }

  dynamic _decodeBody(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  void _ensureSuccess(http.Response response, dynamic body, {int expectedStatus = 200}) {
    if (response.statusCode == expectedStatus) {
      return;
    }
    if (body is Map<String, dynamic>) {
      final errorMessage = body['error']?.toString();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }
    }
    throw Exception('API error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> fetchDriverDashboard() async {
    final uri = _buildUri('/driver/dashboard', {'driver_id': config.driverId.toString()});
    final response = await http.get(uri);
    final body = _decodeBody(response);
    _ensureSuccess(response, body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected API response');
    }
    if (body['error'] != null) {
      throw Exception(body['error']);
    }
    return body;
  }

  Future<List<dynamic>> fetchAvailableDrivers({int? scheduleId}) async {
    final query = {'driver_id': config.driverId.toString()};
    if (scheduleId != null && scheduleId > 0) {
      query['schedule_id'] = scheduleId.toString();
    }
    final uri = _buildUri('/driver/available-drivers', query);
    final response = await http.get(uri);
    final body = _decodeBody(response);
    _ensureSuccess(response, body);
    if (body is List<dynamic>) {
      return body;
    }
    throw Exception('Unexpected API response');
  }

  Future<List<dynamic>> fetchSwapRequests() async {
    final uri = _buildUri('/driver/swap-requests', {'driver_id': config.driverId.toString()});
    final response = await http.get(uri);
    final body = _decodeBody(response);
    _ensureSuccess(response, body);
    if (body is List<dynamic>) {
      return body;
    }
    throw Exception('Unexpected API response');
  }

  Future<void> createSwapRequest({
    required int requesterId,
    required int targetId,
    required int scheduleId,
    int? targetScheduleId,
    String? message,
  }) async {
    final uri = _buildUri('/driver/swap-requests');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requester_id': requesterId,
        'target_id': targetId,
        'schedule_id': scheduleId,
        'target_schedule_id': targetScheduleId,
        'message': message,
      }),
    );
    final body = _decodeBody(response);
    _ensureSuccess(response, body, expectedStatus: 201);
  }

  Future<void> respondSwapRequest({
    required int requestId,
    required String action,
  }) async {
    final uri = _buildUri('/driver/swap-requests/$requestId/respond');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'action': action}),
    );
    final body = _decodeBody(response);
    _ensureSuccess(response, body);
  }

  Future<void> startShift({
    required int driverId,
    required int scheduleId,
  }) async {
    final uri = _buildUri('/driver/shift/start');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'driver_id': driverId,
        'schedule_id': scheduleId,
      }),
    );
    final body = _decodeBody(response);
    _ensureSuccess(response, body);
  }

  Future<void> completeShift({
    required int driverId,
    required int scheduleId,
  }) async {
    final uri = _buildUri('/driver/shift/complete');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'driver_id': driverId,
        'schedule_id': scheduleId,
      }),
    );
    final body = _decodeBody(response);
    _ensureSuccess(response, body);
  }

  Future<void> reportIssue({
    required String title,
    required String message,
    String severity = 'medium',
    int? routeId,
    int? vehicleId,
    int? containerId,
  }) async {
    final uri = _buildUri('/driver/report-issue');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'message': message,
        'severity': severity,
        'route_id': routeId,
        'vehicle_id': vehicleId,
        'container_id': containerId,
      }),
    );
    final body = _decodeBody(response);
    _ensureSuccess(response, body, expectedStatus: 201);
  }
}




