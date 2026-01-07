class AppRole {
  final int id;
  final String name;
  final String description;

  const AppRole({
    required this.id,
    required this.name,
    required this.description,
  });
}

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final AppRole role;
  final String status;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });
}

class Employee {
  final int id;
  final AppUser user;
  final String employeeCode;
  final String employeeType;
  final String status;

  const Employee({
    required this.id,
    required this.user,
    required this.employeeCode,
    required this.employeeType,
    required this.status,
  });
}

class Zone {
  final int id;
  final String name;
  final String code;
  final String city;
  final String district;

  const Zone({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    required this.district,
  });
}

class ContainerType {
  final int id;
  final String name;
  final String colorHex;
  final String description;

  const ContainerType({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.description,
  });
}

class ContainerModel {
  final int id;
  final String code;
  final ContainerType type;
  final int capacityLiters;
  final double fillPercent;
  final double latitude;
  final double longitude;
  final String address;
  final Zone zone;
  final String status;
  final double alertThreshold;

  const ContainerModel({
    required this.id,
    required this.code,
    required this.type,
    required this.capacityLiters,
    required this.fillPercent,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.zone,
    required this.status,
    required this.alertThreshold,
  });
}

class Vehicle {
  final int id;
  final String code;
  final String plate;
  final String type;
  final int capacityKg;
  final String status;
  final double? latitude;
  final double? longitude;

  const Vehicle({
    required this.id,
    required this.code,
    required this.plate,
    required this.type,
    required this.capacityKg,
    required this.status,
    this.latitude,
    this.longitude,
  });
}

class RouteModel {
  final int id;
  final String name;
  final String code;
  final Zone zone;
  final int durationMinutes;
  final double distanceKm;
  final String priority;
  final String status;
  final List<int> containerIds;

  const RouteModel({
    required this.id,
    required this.name,
    required this.code,
    required this.zone,
    required this.durationMinutes,
    required this.distanceKm,
    required this.priority,
    required this.status,
    required this.containerIds,
  });
}

class WorkShift {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final String description;

  const WorkShift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.description,
  });
}

class WorkTimelineEntry {
  final int id;
  final Employee employee;
  final WorkShift shift;
  final DateTime workDate;
  final String status;
  final String notes;

  const WorkTimelineEntry({
    required this.id,
    required this.employee,
    required this.shift,
    required this.workDate,
    required this.status,
    required this.notes,
  });
}

class CollectionSchedule {
  final int id;
  final RouteModel route;
  final Vehicle vehicle;
  final Employee driver;
  final Employee partner;
  final DateTime scheduledDate;
  final String scheduledStartTime;
  final String status;

  const CollectionSchedule({
    required this.id,
    required this.route,
    required this.vehicle,
    required this.driver,
    required this.partner,
    required this.scheduledDate,
    required this.scheduledStartTime,
    required this.status,
  });
}

class AlertModel {
  final int id;
  final String type;
  final String severity;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });
}

class DriverOption {
  final int employeeId;
  final String fullName;
  final String employeeCode;
  final int scheduleId;
  final String scheduledDate;
  final String scheduledStartTime;

  const DriverOption({
    required this.employeeId,
    required this.fullName,
    required this.employeeCode,
    required this.scheduleId,
    required this.scheduledDate,
    required this.scheduledStartTime,
  });
}

class SwapRequest {
  final int id;
  final String status;
  final String message;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final int requesterId;
  final String requesterName;
  final String requesterCode;
  final int targetId;
  final String targetName;
  final String targetCode;
  final int scheduleId;
  final int targetScheduleId;
  final String scheduledDate;
  final String scheduledStartTime;

  const SwapRequest({
    required this.id,
    required this.status,
    required this.message,
    required this.createdAt,
    required this.respondedAt,
    required this.requesterId,
    required this.requesterName,
    required this.requesterCode,
    required this.targetId,
    required this.targetName,
    required this.targetCode,
    required this.scheduleId,
    required this.targetScheduleId,
    required this.scheduledDate,
    required this.scheduledStartTime,
  });
}





