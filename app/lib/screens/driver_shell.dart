import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_app/data/api_repository.dart';
import 'package:my_app/data/api_service.dart';
import 'package:my_app/data/waste_repository.dart';
import 'package:my_app/theme/app_theme.dart';
import 'package:my_app/screens/alerts_screen.dart';
import 'package:my_app/screens/home_screen.dart';
import 'package:my_app/screens/map_screen.dart';
import 'package:my_app/screens/profile_screen.dart';
import 'package:my_app/screens/routes_screen.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({
    super.key,
    this.repositoryOverride,
  });

  final WasteRepository? repositoryOverride;

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  static const _driverId = 5;
  static const _webBaseUrl = 'http://localhost/ast/public/api';
  static const _emulatorBaseUrl = 'http://10.0.2.2/ast/public/api';

  static ApiConfig _buildConfig() {
    return ApiConfig(
      baseUrl: kIsWeb ? _webBaseUrl : _emulatorBaseUrl,
      driverId: _driverId,
    );
  }

  static final _apiConfig = _buildConfig();
  late final Future<WasteRepository> _repositoryFuture;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _repositoryFuture = _loadRepository();
  }

  Future<WasteRepository> _loadRepository() async {
    if (widget.repositoryOverride != null) {
      return widget.repositoryOverride!;
    }
    return ApiWasteRepository.load(_apiConfig);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WasteRepository>(
      future: _repositoryFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final rawError = snapshot.error?.toString();
          final errorMessage = rawError?.replaceFirst('Exception: ', '');
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: AppColors.muted),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load driver data.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (errorMessage != null && errorMessage.isNotEmpty)
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Check the API at /ast/public/api/driver/dashboard?driver_id=${_apiConfig.driverId} and your network settings.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final repository = snapshot.data!;
        final screens = [
          HomeScreen(repository: repository, apiConfig: _apiConfig),
          RoutesScreen(repository: repository),
          MapScreen(repository: repository),
          AlertsScreen(repository: repository),
          ProfileScreen(repository: repository, apiConfig: _apiConfig),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withAlpha(20),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (value) => setState(() => _currentIndex = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Routes'),
                NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
                NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
                NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            ),
          ),
        );
      },
    );
  }
}





