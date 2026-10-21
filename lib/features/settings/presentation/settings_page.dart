import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/features/atmosphere/presentation/atmosphere_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(roomSettingsProvider);
    Future<void> update(Future<bool> operation) async {
      final saved = await operation;
      if (!saved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your preference.')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AuvorynColors.ink,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 45),
          children: [
            Text('Make it yours.', style: AppTheme.editorial(size: 39)),
            const SizedBox(height: 9),
            const Text(
              'The things that make this space feel like home.',
              style: TextStyle(color: AuvorynColors.mist),
            ),
            const SizedBox(height: 35),
            const _SectionLabel('YOUR SPACE'),
            const SizedBox(height: 12),
            _SettingsTile(
              title: 'Atmosphere',
              subtitle: '${settings.mood.title} · ${settings.ambienceEnabled ? 'sound on' : 'sound off'}',
              icon: Icons.nights_stay_outlined,
              onTap: () => showAtmosphereSheet(context),
            ),
            const SizedBox(height: 11),
            _SettingsSwitch(
              title: 'Desk lamp',
              subtitle: '${settings.lampPalette.title} room lighting',
              icon: Icons.lightbulb_outline,
              value: settings.lampOn,
              onChanged: (value) => update(
                ref.read(roomSettingsProvider.notifier).setLamp(value),
              ),
            ),
            const SizedBox(height: 30),
            const _SectionLabel('ACCESSIBILITY'),
            const SizedBox(height: 12),
            _SettingsSwitch(
              title: 'Reduce motion',
              subtitle: 'Prefers gentler transitions and effects',
              icon: Icons.motion_photos_off_outlined,
              value: settings.reducedMotion,
              onChanged: (value) => update(
                ref.read(roomSettingsProvider.notifier).setReducedMotion(value),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Device accessibility settings are respected where Flutter exposes them. '
              'Expanded motion controls and reactive visual effects are planned for later milestones.',
              style: TextStyle(
                color: AuvorynColors.mist,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'AUVORYN  •  ATMOSPHERE 0.5.0',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: AuvorynColors.mist,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AuvorynColors.champagne,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AuvorynColors.slate,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          minTileHeight: 72,
          leading: Icon(icon, color: AuvorynColors.champagne),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      );
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AuvorynColors.slate,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          secondary: Icon(icon, color: AuvorynColors.champagne),
          title: Text(title),
          subtitle: Text(subtitle),
          value: value,
          onChanged: onChanged,
          activeThumbColor: AuvorynColors.champagne,
        ),
      );
}
