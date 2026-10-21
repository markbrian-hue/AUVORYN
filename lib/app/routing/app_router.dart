import 'package:auvoryn/app/routing/navigation_shell.dart';
import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/features/home_room/presentation/room_page.dart';
import 'package:auvoryn/features/library/presentation/library_page.dart';
import 'package:auvoryn/features/library/presentation/playlist_detail_page.dart';
import 'package:auvoryn/features/music/presentation/now_playing_page.dart';
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
        StatefulShellBranch(routes: [
          GoRoute(path: '/room', builder: (_, _) => const RoomPage()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/library',
            builder: (_, _) => const LibraryPage(),
            routes: [
              GoRoute(path: 'playlist/:id', builder: (_, state) =>
                PlaylistDetailPage(playlistId: state.pathParameters['id']!)),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/memories', builder: (_, _) => const MemoriesPage()),
        ]),
      ],
    ),
    GoRoute(
      path: '/now-playing',
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const NowPlayingPage(),
        transitionDuration: AuvorynMotion.player,
        reverseTransitionDuration: AuvorynMotion.normal,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
          if (reduceMotion) {
            return FadeTransition(opacity: animation, child: child);
          }
          final eased = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: eased,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .12),
                end: Offset.zero,
              ).animate(eased),
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => const MaterialPage(
        child: SettingsPage(),
      ),
    ),
  ],
);
