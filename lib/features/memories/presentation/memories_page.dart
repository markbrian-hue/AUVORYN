import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/widgets/auvoryn_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MemoriesPage extends StatelessWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AuvorynLogo(),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.tune_rounded),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: AuvorynColors.slate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          const Text(
            'YOUR JOURNAL  /  003',
            style: TextStyle(
              color: AuvorynColors.champagne,
              fontSize: 11,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Text('Moments in music.', style: AppTheme.editorial(size: 39)),
          const SizedBox(height: 12),
          const Text(
            'One day, this will be the place for the soundtracks that stayed with you.',
            style: TextStyle(color: AuvorynColors.mist, height: 1.6, fontSize: 15),
          ),
          const SizedBox(height: 42),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AuvorynColors.slate,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.auto_stories_outlined,
                  color: AuvorynColors.champagne,
                  size: 51,
                ),
                const SizedBox(height: 22),
                Text(
                  'Your story starts with a song.',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Listening history will appear here once real playback and '
                  'on-device tracking are implemented. No invented statistics.',
                  style: TextStyle(color: AuvorynColors.mist, height: 1.55),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
