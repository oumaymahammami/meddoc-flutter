import 'package:flutter/material.dart';
import 'router.dart';
import 'theme_config.dart';

class MedDocApp extends StatelessWidget {
  const MedDocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MedDoc',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
