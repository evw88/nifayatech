import 'package:my_app/data/waste_repository.dart';
import 'package:my_app/models/models.dart';

class MockWasteRepository implements WasteRepository {
  MockWasteRepository() {
    _seed();
  }

  late final AppRole _driverRole;
  late final AppUser currentUser;
  late final Employee currentEmployee;
  late final Employee partnerEmployee;
  late final Vehicle currentVehicle;
  late final List<Zone> zones;
  late final List<ContainerType> containerTypes;
  late final List<ContainerModel> containers;
  late final List<RouteModel> routes;
  late final List<WorkShift> shifts;
  late final List<WorkTimelineEntry> timeline;
  late final List<CollectionSchedule> schedules;
  late final List<AlertModel> alerts;

  void _seed() {
    _driverRole = const AppRole(
      id: 4,
      name: 'driver',
      description: 'Access to assigned routes and collection tasks',
    );

    zones = const [
      Zone(id: 1, name: 'Central Zone', code: 'CZ', city: 'Metro City', district: 'Central'),
      Zone(id: 2, name: 'North Zone', code: 'NZ', city: 'Metro City', district: 'North'),
    ];

    containerTypes = const [
      ContainerType(id: 1, name: 'general', colorHex: '#808080', description: 'General mixed waste'),
      ContainerType(id: 2, name: 'plastic', colorHex: '#FFEB3B', description: 'Plastic waste'),
      ContainerType(id: 3, name: 'metal', colorHex: '#9E9E9E', description: 'Metal waste'),
      ContainerType(id: 4, name: 'glass', colorHex: '#4CAF50', description: 'Glass waste'),
    ];

    currentUser = AppUser(
      id: 12,
      username: 'driver_ali',
      fullName: 'Ali Ben',
      email: 'ali@wastefleet.io',
      phone: '+212 600 000 000',
      role: _driverRole,
      status: 'active',
    );

    currentEmployee = Employee(
      id: 7,
      user: currentUser,
      employeeCode: 'DRV-007',
      employeeType: 'driver',
      status: 'active',
    );

    partnerEmployee = Employee(
      id: 8,
      user: AppUser(
        id: 13,
        username: 'partner_sara',
        fullName: 'Sara Imani',
        email: 'sara@wastefleet.io',
        phone: '+212 600 000 111',
        role: _driverRole,
        status: 'active',
      ),
      employeeCode: 'COL-021',
      employeeType: 'collector',
      status: 'active',
    );

    currentVehicle = const Vehicle(
      id: 3,
      code: 'TRK-03',
      plate: 'MC-1987-AD',
      type: 'truck',
      capacityKg: 4500,
      status: 'in_use',
      latitude: 33.5902,
      longitude: -7.6167,
    );

    containers = [
      ContainerModel(
        id: 101,
        code: 'CNT-101',
        type: containerTypes[1],
        capacityLiters: 1100,
        fillPercent: 82.5,
        latitude: 33.5909,
        longitude: -7.6178,
        address: 'Rue Atlas 12',
        zone: zones[0],
        status: 'active',
        alertThreshold: 80,
      ),
      ContainerModel(
        id: 102,
        code: 'CNT-102',
        type: containerTypes[0],
        capacityLiters: 1100,
        fillPercent: 64.2,
        latitude: 33.5881,
        longitude: -7.6121,
        address: 'Avenue Horizon 5',
        zone: zones[0],
        status: 'active',
        alertThreshold: 80,
      ),
      ContainerModel(
        id: 103,
        code: 'CNT-103',
        type: containerTypes[3],
        capacityLiters: 900,
        fillPercent: 91.0,
        latitude: 33.5927,
        longitude: -7.6214,
        address: 'Boulevard Ocean 88',
        zone: zones[0],
        status: 'active',
        alertThreshold: 80,
      ),
      ContainerModel(
        id: 104,
        code: 'CNT-104',
        type: containerTypes[2],
        capacityLiters: 1000,
        fillPercent: 73.5,
        latitude: 33.5972,
        longitude: -7.6235,
        address: 'Rue des Palmiers 2',
        zone: zones[1],
        status: 'active',
        alertThreshold: 80,
      ),
    ];

    routes = [
      RouteModel(
        id: 1,
        name: 'Central Loop A',
        code: 'CL-A',
        zone: zones[0],
        durationMinutes: 140,
        distanceKm: 22.4,
        priority: 'high',
        status: 'active',
        containerIds: const [101, 102, 103],
      ),
      RouteModel(
        id: 2,
        name: 'North Transfer',
        code: 'NT-2',
        zone: zones[1],
        durationMinutes: 90,
        distanceKm: 14.8,
        priority: 'medium',
        status: 'active',
        containerIds: const [104],
      ),
    ];

    shifts = const [
      WorkShift(
        id: 1,
        name: 'Morning Shift',
        startTime: '06:00',
        endTime: '14:00',
        description: 'Early morning collection',
      ),
      WorkShift(
        id: 2,
        name: 'Day Shift',
        startTime: '08:00',
        endTime: '16:00',
        description: 'Regular day operations',
      ),
    ];

    timeline = [
      WorkTimelineEntry(
        id: 1,
        employee: currentEmployee,
        shift: shifts[0],
        workDate: DateTime.now(),
        status: 'scheduled',
        notes: 'Focus on central zone pickups.',
      ),
    ];

    schedules = [
      CollectionSchedule(
        id: 1001,
        route: routes[0],
        vehicle: currentVehicle,
        driver: currentEmployee,
        partner: partnerEmployee,
        scheduledDate: DateTime.now(),
        scheduledStartTime: '06:15',
        status: 'scheduled',
      ),
    ];

    alerts = [
      AlertModel(
        id: 201,
        type: 'container_full',
        severity: 'high',
        title: 'Container CNT-103 full',
        message: 'Fill level at 91%. Prioritize collection.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      AlertModel(
        id: 202,
        type: 'maintenance_due',
        severity: 'medium',
        title: 'Vehicle TRK-03 service due',
        message: 'Next maintenance within 5 days.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  List<ContainerModel> containersForRoute(RouteModel route) {
    return route.containerIds
        .map((id) => containers.firstWhere((container) => container.id == id))
        .toList();
  }
}





