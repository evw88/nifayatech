import 'package:my_app/data/api_service.dart';
import 'package:my_app/data/waste_repository.dart';
import 'package:my_app/models/models.dart';

class ApiWasteRepository implements WasteRepository {
  ApiWasteRepository._(this._service);

  final ApiService _service;

  @override
  late final AppUser currentUser;
  @override
  late final Employee currentEmployee;
  @override
  late final Employee partnerEmployee;
  @override
  late final Vehicle currentVehicle;
  @override
  late final List<Zone> zones;
  @override
  late final List<ContainerType> containerTypes;
  @override
  late final List<ContainerModel> containers;
  @override
  late final List<RouteModel> routes;
  @override
  late final List<WorkShift> shifts;
  @override
  late final List<WorkTimelineEntry> timeline;
  @override
  late final List<CollectionSchedule> schedules;
  @override
  late final List<AlertModel> alerts;

  static Future<ApiWasteRepository> load(ApiConfig config) async {
    final repository = ApiWasteRepository._(ApiService(config));
    await repository._loadData();
    return repository;
  }

  Future<void> _loadData() async {
    final data = await _service.fetchDriverDashboard();

    final role = AppRole(
      id: _asInt(data['user']['role_id']),
      name: _asString(data['user']['role_name']),
      description: _asString(data['user']['role_description']),
    );
    currentUser = AppUser(
      id: _asInt(data['user']['user_id']),
      username: _asString(data['user']['username']),
      fullName: _asString(data['user']['full_name']),
      email: _asString(data['user']['email']),
      phone: _asString(data['user']['phone']),
      role: role,
      status: _asString(data['user']['status']),
    );

    currentEmployee = Employee(
      id: _asInt(data['employee']['employee_id']),
      user: currentUser,
      employeeCode: _asString(data['employee']['employee_code']),
      employeeType: _asString(data['employee']['employee_type']),
      status: _asString(data['employee']['status']),
    );

    partnerEmployee = Employee(
      id: _asInt(data['partner']['employee_id']),
      user: AppUser(
        id: _asInt(data['partner']['user_id']),
        username: _asString(data['partner']['username']),
        fullName: _asString(data['partner']['full_name']),
        email: _asString(data['partner']['email']),
        phone: _asString(data['partner']['phone']),
        role: AppRole(
          id: _asInt(data['partner']['role_id']),
          name: _asString(data['partner']['role_name']),
          description: _asString(data['partner']['role_description']),
        ),
        status: _asString(data['partner']['status']),
      ),
      employeeCode: _asString(data['partner']['employee_code']),
      employeeType: _asString(data['partner']['employee_type']),
      status: _asString(data['partner']['status']),
    );

    final vehicleData = data['vehicle'];
    currentVehicle = Vehicle(
      id: _asInt(vehicleData['vehicle_id']),
      code: _asString(vehicleData['vehicle_code']),
      plate: _asString(vehicleData['license_plate']),
      type: _asString(vehicleData['vehicle_type']),
      capacityKg: _asInt(vehicleData['capacity_kg']),
      status: _asString(vehicleData['operational_status']),
      latitude: _asDouble(vehicleData['current_latitude']),
      longitude: _asDouble(vehicleData['current_longitude']),
    );

    final zoneList = (data['zones'] as List<dynamic>)
        .map(
          (zone) => Zone(
            id: _asInt(zone['zone_id']),
            name: _asString(zone['zone_name']),
            code: _asString(zone['zone_code']),
            city: _asString(zone['city']),
            district: _asString(zone['district']),
          ),
        )
        .toList();
    zones = zoneList.isNotEmpty
        ? zoneList
        : [
            const Zone(
              id: 0,
              name: 'Unknown',
              code: '',
              city: '',
              district: '',
            ),
          ];

    final typeList = (data['container_types'] as List<dynamic>)
        .map(
          (type) => ContainerType(
            id: _asInt(type['type_id']),
            name: _asString(type['type_name']),
            colorHex: _asString(type['color_code']),
            description: _asString(type['description']),
          ),
        )
        .toList();
    containerTypes = typeList.isNotEmpty
        ? typeList
        : [
            const ContainerType(
              id: 0,
              name: 'general',
              colorHex: '#808080',
              description: 'General waste',
            ),
          ];

    containers = (data['containers'] as List<dynamic>)
        .map(
          (container) => ContainerModel(
            id: _asInt(container['container_id']),
            code: _asString(container['container_code']),
            type: containerTypes.firstWhere(
              (type) => type.id == _asInt(container['type_id']),
              orElse: () => containerTypes.first,
            ),
            capacityLiters: _asInt(container['capacity_liters']),
            fillPercent: _asDouble(container['current_fill_percentage']),
            latitude: _asDouble(container['latitude']),
            longitude: _asDouble(container['longitude']),
            address: _asString(container['address']),
            zone: zones.firstWhere(
              (zone) => zone.id == _asInt(container['zone_id']),
              orElse: () => zones.first,
            ),
            status: _asString(container['status']),
            alertThreshold: _asDouble(container['alert_threshold']),
          ),
        )
        .toList();

    final routeData = data['route'];
    final route = RouteModel(
      id: _asInt(routeData['route_id']),
      name: _asString(routeData['route_name']),
      code: _asString(routeData['route_code']),
      zone: zones.firstWhere(
        (zone) => zone.id == _asInt(routeData['zone_id']),
        orElse: () => zones.first,
      ),
      durationMinutes: _asInt(routeData['estimated_duration_minutes']),
      distanceKm: _asDouble(routeData['total_distance_km']),
      priority: _asString(routeData['priority_level']),
      status: _asString(routeData['status']),
      containerIds: containers.map((container) => container.id).toList(),
    );
    routes = [route];

    final shiftList = (data['shifts'] as List<dynamic>)
        .map(
          (shift) => WorkShift(
            id: _asInt(shift['shift_id']),
            name: _asString(shift['shift_name']),
            startTime: _asString(shift['start_time']),
            endTime: _asString(shift['end_time']),
            description: _asString(shift['description']),
          ),
        )
        .toList();
    shifts = shiftList.isNotEmpty
        ? shiftList
        : [
            const WorkShift(
              id: 0,
              name: 'Shift',
              startTime: '00:00',
              endTime: '00:00',
              description: '',
            ),
          ];

    final timelineList = (data['timeline'] as List<dynamic>)
        .map(
          (entry) => WorkTimelineEntry(
            id: _asInt(entry['timeline_id']),
            employee: currentEmployee,
            shift: shifts.firstWhere(
              (shift) => shift.id == _asInt(entry['shift_id']),
              orElse: () => shifts.first,
            ),
            workDate: DateTime.parse(_asString(entry['work_date'])),
            status: _asString(entry['status']),
            notes: _asString(entry['notes']),
          ),
        )
        .toList();
    timeline = timelineList.isNotEmpty
        ? timelineList
        : [
            WorkTimelineEntry(
              id: 0,
              employee: currentEmployee,
              shift: shifts.first,
              workDate: DateTime.now(),
              status: 'scheduled',
              notes: '',
            ),
          ];

    final scheduleData = data['schedule'];
    schedules = [
      CollectionSchedule(
        id: _asInt(scheduleData['schedule_id']),
        route: route,
        vehicle: currentVehicle,
        driver: currentEmployee,
        partner: partnerEmployee,
        scheduledDate: DateTime.parse(_asString(scheduleData['scheduled_date'])),
        scheduledStartTime: _asString(scheduleData['scheduled_start_time']),
        status: _asString(scheduleData['status']),
      ),
    ];

    alerts = (data['alerts'] as List<dynamic>)
        .map(
          (alert) => AlertModel(
            id: _asInt(alert['alert_id']),
            type: _asString(alert['alert_type']),
            severity: _asString(alert['severity']),
            title: _asString(alert['title']),
            message: _asString(alert['message']),
            isRead: _asBool(alert['is_read']),
            createdAt: DateTime.parse(_asString(alert['created_at'])),
          ),
        )
        .toList();
  }

  @override
  List<ContainerModel> containersForRoute(RouteModel route) {
    return containers
        .where((container) => route.containerIds.contains(container.id))
        .toList();
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }
}




