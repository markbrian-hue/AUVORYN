import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/widgets/auvoryn_logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        key: const PageStorageKey('library_scroll'),
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
            'YOUR COLLECTION  /  002',
            style: TextStyle(
              color: AuvorynColors.champagne,
              fontSize: 11,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 11),
          Text('Every song, yours.', style: AppTheme.editorial(size: 39)),
          const SizedBox(height: 11),
          const Text(
            'Your library will live on this device. Your listening space will work offline.',
            style: TextStyle(
              fontSize: 15,
              color: AuvorynColors.mist,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 45),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 39),
            decoration: BoxDecoration(
              color: AuvorynColors.slate,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 88,
                  height: 88,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AuvorynColors.raised,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.album_outlined,
                      color: AuvorynColors.champagne,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 21),
                Text(
                  'A collection waiting to happen',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Local music import and real playback are the next development milestone. '
                  'No demo tracks or simulated playback are shown.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AuvorynColors.mist,
                    height: 1.55,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 27),
          Text(
            'COMING WITH YOUR LIBRARY',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.6,
                ),
          ),
          const SizedBox(height: 15),
          const _FeatureRow(Icons.file_open_outlined, 'Import music stored on your device'),
          const _FeatureRow(Icons.queue_music, 'Songs, artists, albums and playlists'),
          const _FeatureRow(Icons.headphones_outlined, 'Reliable background audio playback'),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: AuvorynColors.champagne, size: 21),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          ],
        ),
      );
}
