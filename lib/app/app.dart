import 'package:auvoryn/app/routing/app_router.dart';
import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuvorynApp extends StatelessWidget {
  const AuvorynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Auvoryn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
