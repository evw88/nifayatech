import 'package:flutter/material.dart';

import 'package:my_app/data/waste_repository.dart';
import 'package:my_app/screens/driver_shell.dart';
import 'package:my_app/theme/app_theme.dart';

void main() {
  runApp(const WasteDriverApp());
}

class WasteDriverApp extends StatelessWidget {
  const WasteDriverApp({super.key, this.repositoryOverride});

  final WasteRepository? repositoryOverride;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nifayatech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: DriverShell(repositoryOverride: repositoryOverride),
    );
  }
}





