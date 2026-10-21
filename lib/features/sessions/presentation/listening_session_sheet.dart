import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/features/scenes/application/listening_scenes_controller.dart';
import 'package:auvoryn/features/scenes/domain/listening_scene.dart';
import 'package:auvoryn/features/sessions/application/listening_session_controller.dart';
import 'package:auvoryn/features/sessions/domain/listening_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showListeningSessionSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AuvorynColors.slate,
      builder: (_) => const FractionallySizedBox(
        heightFactor: .85,
        child: ListeningSessionSheet(),
      ),
    );

String sessionTime(int milliseconds) {
  final seconds = (milliseconds / 1000).ceil().clamp(0, 864000);
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remaining = seconds % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  return hours > 0
      ? '${two(hours)}:${two(minutes)}:${two(remaining)}'
      : '${two(minutes)}:${two(remaining)}';
}

/// Read-only home countdown: wall-clock deadline controls its truthfulness.
class HomeSessionCard extends ConsumerWidget {
  const HomeSessionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(listeningSessionProvider);
    final session = status.active;
    if (session == null) return const SizedBox.shrink();

    final progress = (1 - status.remainingMs / session.durationMs).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Material(
        color: AuvorynColors.raised,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: () => showListeningSessionSheet(context),
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.hourglass_bottom_rounded,
                    size: 18, color: AuvorynColors.champagne),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  session.kind == SessionKind.sleep ? 'Sleep timer' : 'Focus session',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
                Text(sessionTime(status.remainingMs),
                    style: const TextStyle(fontFeatures: [
                      FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600)),
                const SizedBox(width: 7),
                const Icon(Icons.chevron_right_rounded, size: 17),
              ]),
              const SizedBox(height: 11),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AuvorynColors.slate,
                minHeight: 3,
              ),
              if (session.paused) const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Paused', style: TextStyle(
                    color: AuvorynColors.mist, fontSize: 12)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class ListeningSessionSheet extends ConsumerStatefulWidget {
  const ListeningSessionSheet({super.key});
  @override
  ConsumerState<ListeningSessionSheet> createState() => _ListeningSessionSheetState();
}

class _ListeningSessionSheetState extends ConsumerState<ListeningSessionSheet> {
  SessionKind _kind = SessionKind.focus;
  int _minutes = 25;
  SessionEndBehavior _end = SessionEndBehavior.keepPlaying;
  String _sceneId = '';

  void _notify(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(listeningSessionProvider);
    final sceneState = ref.watch(listeningScenesProvider);
    final available = <ListeningScene>[
      ...ListeningScene.starters,
      ...sceneState.saved,
    ];
    final active = status.active;

    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 36),
        children: [
          Row(children: [
            Expanded(child: Text('A little time for yourself.',
                style: AppTheme.editorial(size: 32))),
            IconButton(
              tooltip: 'Close sessions',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ]),
          const SizedBox(height: 7),
          const Text(
            'A quiet timer that keeps its place while you switch apps.',
            style: TextStyle(color: AuvorynColors.mist),
          ),
          const SizedBox(height: 22),
          if (status.error != null)
            Text(status.error!, style: const TextStyle(
                color: Color(0xFFFFA3A3), fontSize: 12)),
          if (active != null) ...[
            Text(active.kind == SessionKind.sleep ? 'SLEEP IS SET' : 'IN YOUR FLOW',
                style: const TextStyle(
                    color: AuvorynColors.champagne, letterSpacing: 1.6,
                    fontSize: 11)),
            const SizedBox(height: 12),
            Text(sessionTime(status.remainingMs),
                key: const Key('session_countdown'),
                style: AppTheme.editorial(size: 58)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              minHeight: 3,
              value: (1 - status.remainingMs / active.durationMs)
                  .clamp(0.0, 1.0),
            ),
            const SizedBox(height: 18),
            Text(active.paused ? 'Timer paused · Audio unchanged' :
                'Your music and room remain under your control.',
                style: const TextStyle(color: AuvorynColors.mist)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: FilledButton.icon(
                key: const Key('session_pause'),
                onPressed: status.busy ? null : () async {
                  final ok = await ref.read(listeningSessionProvider.notifier)
                      .togglePause();
                  if (!ok) {
                    _notify('Unable to update session.');
                  }
                },
                icon: Icon(active.paused ? Icons.play_arrow_rounded :
                    Icons.pause_rounded),
                label: Text(active.paused ? 'Resume timer' : 'Pause timer'),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(
                key: const Key('session_cancel'),
                onPressed: status.busy ? null : () async {
                  final ok = await ref.read(listeningSessionProvider.notifier)
                      .cancel();
                  if (!ok) {
                    _notify('Unable to cancel session.');
                  }
                },
                child: const Text('Cancel'),
              )),
            ]),
          ] else ...[
            const Text('TYPE OF MOMENT', style: TextStyle(
                color: AuvorynColors.champagne, letterSpacing: 1.6,
                fontSize: 11)),
            const SizedBox(height: 10),
            Wrap(spacing: 9, runSpacing: 6, children: [
              ChoiceChip(
                label: const Text('Focus'),
                selected: _kind == SessionKind.focus,
                onSelected: (_) => setState(() {
                  _kind = SessionKind.focus;
                  _minutes = 25;
                  _end = SessionEndBehavior.keepPlaying;
                }),
              ),
              ChoiceChip(
                label: const Text('Fall asleep'),
                selected: _kind == SessionKind.sleep,
                onSelected: (_) => setState(() {
                  _kind = SessionKind.sleep;
                  _minutes = 20;
                  _end = SessionEndBehavior.fadeAndPause;
                }),
              ),
            ]),
            const SizedBox(height: 24),
            const Text('DURATION', style: TextStyle(
                color: AuvorynColors.champagne, letterSpacing: 1.6,
                fontSize: 11)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final value in (_kind == SessionKind.sleep
                  ? const [20, 45, 60] : const [25, 50, 90]))
                ChoiceChip(
                  key: Key('session_preset_$value'),
                  label: Text('$value min'),
                  selected: _minutes == value,
                  onSelected: (_) => setState(() => _minutes = value),
                ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Text('Custom duration',
                  style: TextStyle(fontSize: 13))),
              Text('$_minutes minutes', style: const TextStyle(
                  color: AuvorynColors.mist)),
            ]),
            Slider(
              key: const Key('session_duration'),
              value: _minutes.toDouble().clamp(5, 180),
              min: 5,
              max: 180,
              divisions: 35,
              onChanged: (v) => setState(() => _minutes = (v / 5).round() * 5),
              semanticFormatterCallback: (v) => '${v.round()} minutes',
            ),
            const SizedBox(height: 16),
            const Text('LISTENING SCENE (OPTIONAL)', style: TextStyle(
                color: AuvorynColors.champagne, letterSpacing: 1.6,
                fontSize: 11)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: const Key('session_scene'),
              isExpanded: true,
              initialValue: _sceneId,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Scene for this session'),
              items: [
                const DropdownMenuItem(
                  value: '', child: Text('Keep current room')),
                for (final scene in available)
                  DropdownMenuItem(
                    value: scene.id,
                    child: Text(scene.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: sceneState.loading ? null :
                (value) => setState(() => _sceneId = value ?? ''),
            ),
            const SizedBox(height: 21),
            const Text('WHEN TIME IS UP', style: TextStyle(
                color: AuvorynColors.champagne, letterSpacing: 1.6,
                fontSize: 11)),
            RadioGroup<SessionEndBehavior>(
              groupValue: _end,
              onChanged: (v) => setState(() =>
                  _end = v ?? SessionEndBehavior.keepPlaying),
              child: Column(children: [
                RadioListTile<SessionEndBehavior>(
                  title: const Text('Keep the music playing'),
                  value: SessionEndBehavior.keepPlaying,
                ),
                RadioListTile<SessionEndBehavior>(
                  title: const Text('Fade and pause audio'),
                  subtitle: const Text('Gently silence the music and ambience'),
                  value: SessionEndBehavior.fadeAndPause,
                ),
              ]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('session_start'),
              icon: const Icon(Icons.hourglass_top_rounded),
              label: const Text('Start session'),
              onPressed: status.busy || status.restoring ||
                  sceneState.loading ? null : () async {
                if (_sceneId.isNotEmpty) {
                  final matching = available.where((s) => s.id == _sceneId);
                  if (matching.isNotEmpty) {
                    final applied = await ref.read(listeningScenesProvider.notifier)
                        .apply(matching.first);
                    if (!applied) {
                      _notify('Could not apply the selected scene.');
                      return;
                    }
                  }
                }
                final ok = await ref.read(listeningSessionProvider.notifier).start(
                  kind: _kind,
                  duration: Duration(minutes: _minutes),
                  endBehavior: _end,
                  sceneId: _sceneId.isEmpty ? null : _sceneId,
                );
                _notify(ok ? 'Your session has started. Music stays as it was.' :
                    'Could not start session.');
              },
            ),
            const SizedBox(height: 13),
            const Text(
              'Starting a session never starts playback. A sleep fade works '
              'while the app is active; if Android suspends or terminates the '
              'app, an expired session is resolved when AUVORYN next resumes.',
              style: TextStyle(color: AuvorynColors.mist, fontSize: 12,
                  height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
