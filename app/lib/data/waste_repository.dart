import 'package:my_app/models/models.dart';

abstract class WasteRepository {
  AppUser get currentUser;
  Employee get currentEmployee;
  Employee get partnerEmployee;
  Vehicle get currentVehicle;
  List<Zone> get zones;
  List<ContainerType> get containerTypes;
  List<ContainerModel> get containers;
  List<RouteModel> get routes;
  List<WorkShift> get shifts;
  List<WorkTimelineEntry> get timeline;
  List<CollectionSchedule> get schedules;
  List<AlertModel> get alerts;

  List<ContainerModel> containersForRoute(RouteModel route);
}





