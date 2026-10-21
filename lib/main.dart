import 'package:auvoryn/app/app.dart';
import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/core/settings/room_settings_controller.dart';
import 'package:auvoryn/core/settings/room_settings_store.dart';
import 'package:auvoryn/core/widgets/auvoryn_logo.dart';
import 'package:auvoryn/features/music/application/music_controller.dart';
import 'package:auvoryn/features/music/data/local_music_store.dart';
import 'package:auvoryn/features/music/domain/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Render a Flutter frame immediately. If native audio or SQLite initialization
  // fails, the user sees an actionable error instead of a frozen native splash.
  runApp(const _AuvorynBootstrap());
}

class _BootData {
  const _BootData({
    required this.roomStore,
    required this.roomSettings,
    required this.musicStore,
    required this.music,
  });

  final RoomSettingsStore roomStore;
  final RoomSettings roomSettings;
  final LocalMusicStore musicStore;
  final MusicBootstrap music;
}

class _StartupFailure implements Exception {
  const _StartupFailure(this.phase, this.cause);
  final String phase;
  final Object cause;

  @override
  String toString() => '$phase failed: $cause';
}

class _AuvorynBootstrap extends StatefulWidget {
  const _AuvorynBootstrap();

  @override
  State<_AuvorynBootstrap> createState() => _AuvorynBootstrapState();
}

class _AuvorynBootstrapState extends State<_AuvorynBootstrap> {
  late final Future<_BootData> _initialization;
  String _phase = 'Restoring your room';

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  void _report(String phase) {
    debugPrint('AUVORYN startup: $phase');
    if (mounted && _phase != phase) {
      setState(() => _phase = phase);
    }
  }

  Future<T> _runStage<T>(
    String phase,
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 40),
  }) async {
    _report(phase);
    try {
      final result = await operation().timeout(timeout);
      debugPrint('AUVORYN startup: $phase — ready');
      return result;
    } catch (error, stack) {
      debugPrint('AUVORYN startup: $phase — FAILED: $error');
      debugPrintStack(stackTrace: stack);
      throw _StartupFailure(phase, error);
    }
  }

  Future<_BootData> _initialize() async {
    final settingsStore = RoomSettingsStore(SharedPreferencesAsync());
    RoomSettings settings;
    try {
      settings = await _runStage(
        'Restoring your room',
        settingsStore.load,
        timeout: const Duration(seconds: 15),
      );
    } catch (error) {
      // Room preferences should never prevent access to local music.
      debugPrint('AUVORYN startup: using default room settings: $error');
      settings = const RoomSettings();
    }

    // Background controls must be initialized before an AudioPlayer is created.
    // A failed plugin setup is displayed, never silently bypassed.
    await _runStage(
      'Starting background audio',
      () => JustAudioBackground.init(
        androidNotificationChannelId: 'app.auvoryn.music',
        androidNotificationChannelName: 'AUVORYN playback',
        androidNotificationOngoing: true,
      ),
    );

    final musicStore = await _runStage(
      'Opening your offline music library',
      LocalMusicStore.open,
    );
    final music = await _runStage(
      'Loading your songs and playlists',
      musicStore.load,
    );

    return _BootData(
      roomStore: settingsStore,
      roomSettings: settings,
      musicStore: musicStore,
      music: music,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootData>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          return ProviderScope(
            overrides: [
              initialRoomSettingsProvider.overrideWithValue(data.roomSettings),
              roomSettingsStoreProvider.overrideWithValue(data.roomStore),
              musicStoreProvider.overrideWithValue(data.musicStore),
              initialMusicProvider.overrideWithValue(data.music),
            ],
            child: const AuvorynApp(),
          );
        }

        final failed = snapshot.hasError;
        final reason = snapshot.error?.toString() ?? '';
        return MaterialApp(
          title: 'Auvoryn',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AuvorynLogo(),
                        const SizedBox(height: 22),
                        Text(
                          failed ? 'We couldn\'t open Auvoryn.' : 'Your room is almost ready.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 15),
                        if (!failed) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 22),
                          Text(_phase, textAlign: TextAlign.center),
                        ] else ...[
                          const Icon(Icons.error_outline_rounded,
                              size: 36, color: Color(0xFFD8B78B)),
                          const SizedBox(height: 16),
                          const Text(
                            'Your music and saved settings have not been deleted. '
                            'Check the VS Code terminal for the AUVORYN startup error.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SelectableText(
                            reason,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'If this mentions background audio, rerun '
                            'scripts/configure_android_audio.ps1 from the project root, '
                            'then stop and fully restart the app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
