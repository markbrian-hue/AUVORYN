import 'dart:async';

import 'package:auvoryn/app/routing/app_router.dart';
import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/atmosphere/application/ambience_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuvorynApp extends ConsumerStatefulWidget {
  const AuvorynApp({super.key});

  @override
  ConsumerState<AuvorynApp> createState() => _AuvorynAppState();
}

class _AuvorynAppState extends ConsumerState<AuvorynApp> {
  @override
  void initState() {
    super.initState();
    // Initial opt-in state is restored on boot; do not initialize a second
    // native audio player if the user has never enabled ambience.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initial = ref.read(roomSettingsProvider);
      if (initial.ambienceEnabled) {
        unawaited(ref.read(ambienceProvider.notifier).sync(initial));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RoomSettings>(roomSettingsProvider, (previous, next) {
      if (previous?.ambienceEnabled != next.ambienceEnabled ||
          previous?.mood != next.mood ||
          previous?.ambienceVolume != next.ambienceVolume) {
        unawaited(ref.read(ambienceProvider.notifier).sync(next));
      }
    });

    return MaterialApp.router(
      title: 'Auvoryn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
