import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/features/home_room/domain/room_camera.dart';
import 'package:auvoryn/features/home_room/presentation/room_diorama.dart';
import 'package:flutter/material.dart';

/// An offline perspective-projected apartment with an intentionally bounded
/// camera. Horizontal gestures orbit; vertical gestures stay with page scrolling.
class RoomScene extends StatefulWidget {
  const RoomScene({
    required this.settings,
    required this.onRecordTap,
    required this.onWindowTap,
    required this.onLampTap,
    required this.onShelfTap,
    required this.onSpeakerTap,
    this.hasTrack = false,
    this.isPlaying = false,
    super.key,
  });
  final RoomSettings settings;
  final VoidCallback onRecordTap;
  final VoidCallback onWindowTap;
  final VoidCallback onLampTap;
  final VoidCallback onShelfTap;
  final VoidCallback onSpeakerTap;
  final bool hasTrack;
  final bool isPlaying;
  @override
  State<RoomScene> createState() => _RoomSceneState();
}

class _RoomSceneState extends State<RoomScene>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _record = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );
  late final AnimationController _weather = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    value: .5,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _light = AnimationController(
    vsync: this,
    value: widget.settings.lampOn ? widget.settings.lampBrightness : 0,
    duration: const Duration(milliseconds: 650),
  );
  bool _foreground = true;
  bool _reduceMotion = false;
  bool _tickerEnabled = true;
  bool _showControls = true;
  RoomDioramaGeometry? _geometry;

  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didUpdateWidget(covariant RoomScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion();
    final target = widget.settings.lampOn
        ? widget.settings.lampBrightness
        : 0.0;
    if (_light.value != target) {
      if (_reduceMotion || !_foreground || !_tickerEnabled) {
        _light.value = target;
      } else {
        _light.animateTo(target, curve: Curves.easeInOutCubic);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateMotion();
  }

  void _updateMotion() {
    _reduceMotion =
        widget.settings.reducedMotion ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    final active = _foreground && _tickerEnabled && !_reduceMotion;
    if (active && widget.hasTrack && widget.isPlaying) {
      if (!_record.isAnimating) {
        _record.repeat();
      }
    } else {
      _record.stop(canceled: false);
    }
    if (active && widget.settings.mood.hasRain) {
      if (!_weather.isAnimating) {
        _weather.repeat();
      }
    } else {
      _weather.stop(canceled: false);
    }
    if (!active) {
      _orbit.stop(canceled: false);
      _light.value = widget.settings.lampOn
          ? widget.settings.lampBrightness
          : 0;
    }
  }

  void _moveCamera(double value) {
    final target = value.clamp(0.0, 1.0);
    if (_reduceMotion) {
      _orbit.value = target;
    } else {
      _orbit.animateTo(target, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _record.dispose();
    _weather.dispose();
    _orbit.dispose();
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0xFF393D46)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x38000000),
          blurRadius: 28,
          offset: Offset(0, 16),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(29),
      child: AspectRatio(
        aspectRatio: .92,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final size = Size(bounds.maxWidth, bounds.maxHeight);
            return GestureDetector(
              key: const Key('room_camera_gesture'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => _orbit.stop(canceled: false),
              onHorizontalDragUpdate: (details) {
                _orbit.value =
                    (_orbit.value + details.delta.dx / size.width * 1.6).clamp(
                      0.0,
                      1.0,
                    );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(.1, -.4),
                        radius: 1.15,
                        colors: [
                          Color(0xFF353B47),
                          Color(0xFF1A202A),
                          Color(0xFF141921),
                        ],
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: Listenable.merge([_orbit, _light]),
                    builder: (context, _) {
                      final camera = RoomCamera(orbit: _orbit.value);
                      if (_geometry?.settings != widget.settings ||
                          _geometry?.light != _light.value) {
                        _geometry = RoomDioramaGeometry(
                          widget.settings,
                          _light.value,
                        );
                      }
                      final architecture = CustomPaint(
                        key: ValueKey(
                          '${widget.settings.mood.name}-${widget.settings.windowView.name}-${widget.settings.lampPalette.name}',
                        ),
                        painter: RoomDioramaPainter(
                          geometry: _geometry!,
                          camera: camera,
                        ),
                        child: const SizedBox.expand(),
                      );
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          RepaintBoundary(
                            child:
                                _reduceMotion || !_foreground || !_tickerEnabled
                                ? architecture
                                : AnimatedSwitcher(
                                    duration: AuvorynMotion.atmosphere,
                                    switchInCurve: Curves.easeInOutCubic,
                                    switchOutCurve: Curves.easeInOutCubic,
                                    child: architecture,
                                  ),
                          ),
                          IgnorePointer(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: RoomLivingDetailsPainter(
                                  camera: camera,
                                  settings: widget.settings,
                                  record: _record,
                                  weather: _weather,
                                  playing: widget.isPlaying,
                                  hasTrack: widget.hasTrack,
                                ),
                              ),
                            ),
                          ),
                          if (_showControls) ..._hotspots(camera, size),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    top: 14,
                    left: 16,
                    right: 60,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x99101620),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.view_in_ar_rounded,
                              size: 12,
                              color: AuvorynColors.champagne,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.isPlaying
                                    ? 'YOUR ROOM · PLAYING'
                                    : 'YOUR ROOM · AT REST',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1.1,
                                  color: AuvorynColors.ivory,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 6,
                    child: IconButton(
                      tooltip: _showControls
                          ? 'Hide room controls'
                          : 'Show room controls',
                      onPressed: () =>
                          setState(() => _showControls = !_showControls),
                      icon: Icon(
                        _showControls
                            ? Icons.touch_app_outlined
                            : Icons.touch_app,
                        size: 19,
                      ),
                      color: AuvorynColors.ivory,
                    ),
                  ),
                  Positioned(
                    bottom: 7,
                    left: 9,
                    right: 12,
                    child: Row(
                      children: [
                        IconButton(
                          key: const Key('room_view_left'),
                          tooltip: 'Look left',
                          onPressed: () => _moveCamera(_orbit.value - .25),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 21,
                          ),
                        ),
                        IconButton(
                          key: const Key('room_view_reset'),
                          tooltip: 'Center room view',
                          onPressed: () => _moveCamera(.5),
                          icon: const Icon(
                            Icons.center_focus_weak_rounded,
                            size: 18,
                          ),
                        ),
                        IconButton(
                          key: const Key('room_view_right'),
                          tooltip: 'Look right',
                          onPressed: () => _moveCamera(_orbit.value + .25),
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Expanded(
                          child: Text(
                            'Drag to look around',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.3,
                              color: AuvorynColors.mist,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  List<Widget> _hotspots(RoomCamera camera, Size size) {
    final targets = [
      (
        RoomCamera.record,
        widget.hasTrack ? 'Open now playing' : 'Browse music',
        Icons.album_outlined,
        widget.onRecordTap,
        'record',
      ),
      (
        RoomCamera.window,
        'Change weather',
        Icons.cloud_outlined,
        widget.onWindowTap,
        'window',
      ),
      (
        RoomCamera.lamp,
        widget.settings.lampOn ? 'Turn lamp off' : 'Turn lamp on',
        Icons.lightbulb_outline,
        widget.onLampTap,
        'lamp',
      ),
      (
        RoomCamera.shelf,
        'Open playlists',
        Icons.queue_music_rounded,
        widget.onShelfTap,
        'shelf',
      ),
      (
        RoomCamera.speaker,
        widget.hasTrack
            ? (widget.isPlaying
                  ? 'Pause music at speakers'
                  : 'Play music at speakers')
            : 'Choose music at speakers',
        widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        widget.onSpeakerTap,
        'speaker',
      ),
    ];
    final anchors = [
      for (final t in targets) camera.project(t.$1, size.width, size.height),
    ];
    final centers = [for (final p in anchors) Offset(p.x, p.y)];
    // Keep 48px hit regions separate even on compact phones and oblique views.
    // A small leader connects any displaced control to its actual world point.
    for (var pass = 0; pass < 12; pass++) {
      for (var i = 0; i < centers.length; i++) {
        for (var j = i + 1; j < centers.length; j++) {
          final delta = centers[j] - centers[i];
          if (delta.dx.abs() < 52 && delta.dy.abs() < 52) {
            final horizontal = delta.dx.abs() > delta.dy.abs();
            final amount =
                (52 - (horizontal ? delta.dx.abs() : delta.dy.abs())) / 2;
            final sign = (horizontal ? delta.dx : delta.dy) < 0 ? -1.0 : 1.0;
            final shift = horizontal
                ? Offset(amount * sign, 0)
                : Offset(0, amount * sign);
            centers[i] -= shift;
            centers[j] += shift;
          }
        }
      }
      for (var i = 0; i < centers.length; i++) {
        centers[i] = Offset(
          centers[i].dx.clamp(26.0, size.width - 26),
          centers[i].dy.clamp(72.0, size.height - 82),
        );
      }
    }
    return [
      IgnorePointer(
        child: CustomPaint(
          painter: _ControlGuides([
            for (final p in anchors) Offset(p.x, p.y),
          ], centers),
        ),
      ),
      for (var i = 0; i < targets.length; i++)
        _hotspot(
          centers[i],
          targets[i].$2,
          targets[i].$3,
          targets[i].$4,
          targets[i].$5,
        ),
    ];
  }

  Widget _hotspot(
    Offset center,
    String label,
    IconData icon,
    VoidCallback action,
    String id,
  ) {
    return Positioned(
      left: center.dx - 24,
      top: center.dy - 24,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          label: label,
          child: ExcludeSemantics(
            child: Material(
              color: Colors.transparent,
              child: InkResponse(
                key: Key('room_target_$id'),
                onTap: action,
                radius: 25,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xD9141B25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x99E3C89E),
                          width: .8,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 15,
                        color: const Color(0xFFF1D9B8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlGuides extends CustomPainter {
  const _ControlGuides(this.anchors, this.centers);
  final List<Offset> anchors;
  final List<Offset> centers;
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < anchors.length; i++) {
      if ((centers[i] - anchors[i]).distance > 10) {
        canvas.drawLine(
          anchors[i],
          centers[i],
          Paint()
            ..color = const Color(0x99D8B78B)
            ..strokeWidth = .75,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ControlGuides oldDelegate) => true;
}
