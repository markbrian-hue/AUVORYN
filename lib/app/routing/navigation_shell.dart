import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationShell extends StatelessWidget {
  const NavigationShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AuvorynColors.slate,
          border: Border(
            top: BorderSide(color: AuvorynColors.raised, width: .7),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 4),
            child: Row(
              children: [
                _Destination(
                  label: 'Room',
                  icon: Icons.chair_outlined,
                  selectedIcon: Icons.chair,
                  selected: shell.currentIndex == 0,
                  onTap: () => shell.goBranch(0),
                ),
                _Destination(
                  label: 'Library',
                  icon: Icons.library_music_outlined,
                  selectedIcon: Icons.library_music,
                  selected: shell.currentIndex == 1,
                  onTap: () => shell.goBranch(1),
                ),
                _Destination(
                  label: 'Memories',
                  icon: Icons.auto_stories_outlined,
                  selectedIcon: Icons.auto_stories,
                  selected: shell.currentIndex == 2,
                  onTap: () => shell.goBranch(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AuvorynColors.champagne : AuvorynColors.mist;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          key: Key('tab_${label.toLowerCase()}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? selectedIcon : icon, size: 22, color: color),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
