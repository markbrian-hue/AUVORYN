import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/widgets/auvoryn_logo.dart';
import 'package:flutter/material.dart';

/// An offline, user-facing explanation of the data this version stores.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & storage')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          children: [
            const AuvorynLogo(),
            const SizedBox(height: 26),
            Text('Your files stay here.', style: AppTheme.editorial(size: 38)),
            const SizedBox(height: 12),
            const Text(
              'AUVORYN is an offline-first space for the music you choose. '
              'No account, cloud music upload, or internet connection is '
              'required to listen.',
              style: TextStyle(color: AuvorynColors.mist, height: 1.55),
            ),
            const SizedBox(height: 25),
            const _DataSection(
              icon: Icons.library_music_outlined,
              title: 'Imported music',
              detail: 'Music selected through the system file picker is copied '
                  'into this app\'s private storage. Album covers extracted from '
                  'your files are stored there too.',
            ),
            const SizedBox(height: 12),
            const _DataSection(
              icon: Icons.auto_stories_outlined,
              title: 'Listening memories',
              detail: 'Listening time, recent tracks, favorites, queues and '
                  'playlists are stored locally. You can clear listening '
                  'statistics from the Memories tab without deleting songs.',
            ),
            const SizedBox(height: 12),
            const _DataSection(
              icon: Icons.cloud_off_outlined,
              title: 'Offline ambience',
              detail: 'Room weather audio is bundled with the app; AUVORYN '
                  'does not stream the soundscapes.',
            ),
            const SizedBox(height: 12),
            const _DataSection(
              icon: Icons.warning_amber_outlined,
              title: 'Before uninstalling',
              detail: 'Uninstalling AUVORYN or clearing its app data can '
                  'permanently remove imported copies, playlists and listening '
                  'history. Keep your original music files elsewhere.',
            ),
            const SizedBox(height: 25),
            const Text(
              'This build contains no AUVORYN analytics or advertising '
              'integration. Android system services and installed playback '
              'plugins still handle media and file-picker operations.',
              style: TextStyle(color: AuvorynColors.mist, fontSize: 12,
                  height: 1.55),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('AUVORYN  •  RELEASE QA 0.7.0',
                style: TextStyle(fontSize: 10, letterSpacing: 1.4,
                    color: AuvorynColors.mist)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AuvorynColors.slate,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AuvorynColors.champagne, size: 25),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(detail, style: const TextStyle(
                  color: AuvorynColors.mist, height: 1.5, fontSize: 13,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
