import 'package:auvoryn/app/routing/navigation_shell.dart';
import 'package:auvoryn/features/home_room/presentation/room_page.dart';
import 'package:auvoryn/features/library/presentation/library_page.dart';
import 'package:auvoryn/features/memories/presentation/memories_page.dart';
import 'package:auvoryn/features/settings/presentation/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/room',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => NavigationShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/room', builder: (_, _) => const RoomPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/library', builder: (_, _) => const LibraryPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/memories', builder: (_, _) => const MemoriesPage()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => const MaterialPage(
        child: SettingsPage(),
      ),
    ),
  ],
);
