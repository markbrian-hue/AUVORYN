import 'dart:math' as math;

import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:flutter/material.dart';

/// One offline 2.5D room. It contains no audio player of its own.
/// Motion is strictly time/weather or play-state driven, never fake beat data.
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
  late final AnimationController _vinyl;
  late final AnimationController _rain;
  bool _foreground = true;
  bool _tickerEnabled = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _vinyl = AnimationController(vsync: this, duration: const Duration(seconds: 9));
    _rain = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final platformReduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _reduceMotion = widget.settings.reducedMotion || platformReduced;
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant RoomScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reduceMotion = widget.settings.reducedMotion ||
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    final active = _foreground && _tickerEnabled && !_reduceMotion;
    if (active && widget.isPlaying && widget.hasTrack) {
      if (!_vinyl.isAnimating) _vinyl.repeat();
    } else {
      _vinyl.stop(canceled: false);
    }
    if (active && widget.settings.mood.hasRain) {
      if (!_rain.isAnimating) _rain.repeat();
    } else {
      _rain.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vinyl.dispose();
    _rain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: AspectRatio(
        aspectRatio: .84,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: AnimatedSwitcher(
                duration: _reduceMotion ? Duration.zero : AuvorynMotion.atmosphere,
                child: SizedBox.expand(
                  key: ValueKey('${widget.settings.mood.name}-${widget.settings.lampOn}'),
                  child: CustomPaint(painter: _MidnightPainter(widget.settings)),
                ),
              ),
            ),
            // Animated rain is clipped to the real window. This layer repaints
            // independently from the static furniture and architectural scene.
            if (widget.settings.mood.hasRain)
              IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _rain,
                    builder: (_, _) => CustomPaint(
                      painter: _WindowRainPainter(widget.settings.mood, _rain.value),
                    ),
                  ),
                ),
              ),
            IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _vinyl,
                  builder: (_, _) => CustomPaint(
                    painter: _RecordDetailsPainter(
                      angle: _vinyl.value * 2 * math.pi,
                      hasTrack: widget.hasTrack,
                      playing: widget.isPlaying,
                    ),
                  ),
                ),
              ),
            ),
            _hotspot(
              widget.hasTrack ? 'Open now playing' : 'Browse music',
              Icons.album_outlined,
              const Alignment(-.05, .52), widget.onRecordTap,
            ),
            _hotspot('Change weather', Icons.cloud_outlined,
              const Alignment(.57, -.55), widget.onWindowTap),
            _hotspot(widget.settings.lampOn ? 'Turn lamp off' : 'Turn lamp on',
              Icons.lightbulb_outline, const Alignment(.69, .31), widget.onLampTap),
            _hotspot('Open playlists', Icons.queue_music_rounded,
              const Alignment(-.73, .09), widget.onShelfTap),
            _hotspot(widget.hasTrack
                ? (widget.isPlaying ? 'Pause music at speakers' : 'Play music at speakers')
                : 'Choose music at speakers',
              widget.isPlaying ? Icons.pause_rounded : Icons.speaker_rounded,
              const Alignment(-.59, .51), widget.onSpeakerTap),
            Positioned(
              left: 15, right: 15, bottom: 14,
              child: IgnorePointer(
                child: Row(children: [
                  _sceneLabel('MIDNIGHT APARTMENT', Icons.circle),
                  const Spacer(),
                  _sceneLabel(widget.isPlaying ? 'PLAYING' : 'QUIET',
                    widget.isPlaying ? Icons.graphic_eq : Icons.nightlight_round),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sceneLabel(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AuvorynColors.ink.withValues(alpha: .83),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 9, color: AuvorynColors.champagne),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(
        fontSize: 8, letterSpacing: 1.0,
        fontWeight: FontWeight.w600, color: AuvorynColors.ivory,
      )),
    ]),
  );

  Widget _hotspot(
    String label, IconData icon, Alignment alignment, VoidCallback action,
  ) => Align(
    alignment: alignment,
    child: Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: AuvorynColors.ink.withValues(alpha: .72),
          shape: const CircleBorder(side: BorderSide(color: Color(0x88D8B78B))),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: action,
            child: SizedBox(
              width: 48, height: 48,
              child: Icon(icon, size: 20, color: AuvorynColors.ivory),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Two animated layers share the original 390x464 logical-pixel scene map.
/// No frames are scheduled when motion is disabled, backgrounded or offscreen.
class _WindowRainPainter extends CustomPainter {
  _WindowRainPainter(this.mood, this.progress);
  final RoomMood mood;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 390, size.height / 464);
    canvas.clipRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(62, 36, 264, 295), const Radius.circular(7),
    ));
    final total = mood == RoomMood.lightRain ? 28 : 74;
    final opacity = mood == RoomMood.thunderstorm ? 0.58 : 0.42;
    final ink = Paint()
      ..color = const Color(0xFFC1D5EE).withValues(alpha: opacity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = mood == RoomMood.lightRain ? .85 : 1.2;
    for (var i = 0; i < total; i++) {
      final x = 64.0 + (i * 71 % 260);
      final y = 36.0 + ((i * 79 + progress * (250 + i % 4 * 30)) % 300);
      final length = 8.0 + i % 5 * 3.2;
      canvas.drawLine(Offset(x, y), Offset(x - 3.2, y + length), ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WindowRainPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mood != mood;
}

class _RecordDetailsPainter extends CustomPainter {
  const _RecordDetailsPainter({
    required this.angle, required this.hasTrack, required this.playing,
  });
  final double angle;
  final bool hasTrack;
  final bool playing;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 390, size.height / 464);
    const center = Offset(189, 353);
    canvas.drawCircle(center, 38, Paint()..color = const Color(0xFF111118));
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawCircle(Offset.zero, 35, Paint()
      ..shader = const SweepGradient(colors: [
        Color(0xFF15151B), Color(0xFF363641), Color(0xFF121218),
        Color(0xFF292A35), Color(0xFF15151B),
      ]).createShader(const Rect.fromLTWH(-35, -35, 70, 70)));
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(Offset.zero, 14.0 + i * 2.35, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .5
        ..color = const Color(0x66777A89));
    }
    canvas.drawLine(const Offset(17, -12), const Offset(25, -17), Paint()
      ..color = const Color(0xFF8F8A99)..strokeWidth = 1.1);
    canvas.drawCircle(Offset.zero, 11, Paint()
      ..color = const Color(0xFFD8B78B));
    canvas.drawCircle(Offset.zero, 4, Paint()..color = const Color(0xFF202028));
    canvas.restore();
    // The stylus rests outside the platter until a song is selected.
    final stylus = hasTrack ? const Offset(211, 342) : const Offset(246, 329);
    canvas.drawLine(const Offset(242, 332), stylus, Paint()
      ..color = const Color(0xFFE3D8C8)
      ..strokeWidth = 2.6..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(242, 332), 3.5,
      Paint()..color = const Color(0xFFD8B78B));
    if (hasTrack) {
      canvas.drawCircle(const Offset(249, 365), 1.8, Paint()
        ..color = playing ? const Color(0xFFD8B78B) : const Color(0xFF6C727D));
    }
    // Stereo LEDs indicate transport state only, not an artificial beat.
    for (final x in [82.0, 307.0]) {
      canvas.drawCircle(Offset(x, 366), 2, Paint()
        ..color = playing ? const Color(0xFFD8B78B) : const Color(0xFF5A626B));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RecordDetailsPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.hasTrack != hasTrack ||
      oldDelegate.playing != playing;
}

class _MidnightPainter extends CustomPainter {
  _MidnightPainter(this.settings);

  final RoomSettings settings;

  static const _wall = Color(0xFF151A26);
  static const _copper = Color(0xFFCCA574);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 390, size.height / 464);
    const scene = Rect.fromLTWH(0, 0, 390, 464);
    final sunset = settings.mood == RoomMood.warmSunset;
    final storm = settings.mood == RoomMood.thunderstorm;
    final skyTop = sunset ? const Color(0xFFAA627A) : const Color(0xFF111A3E);
    final skyBottom = sunset ? const Color(0xFFE8A57A) : const Color(0xFF4B4F70);

    canvas.drawRect(
      scene,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_wall, Color(0xFF27212A), Color(0xFF16151C)],
        ).createShader(scene),
    );

    // Architectural window and a soft distant skyline.
    const window = Rect.fromLTWH(62, 36, 264, 295);
    canvas.drawRRect(
      RRect.fromRectAndRadius(window.inflate(11), const Radius.circular(13)),
      Paint()..color = const Color(0xFF0C101B),
    );
    final inner = RRect.fromRectAndRadius(window, const Radius.circular(7));
    canvas.drawRRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyBottom],
        ).createShader(window),
    );
    canvas.save();
    canvas.clipRRect(inner);

    if (!storm && !sunset) {
      canvas.drawCircle(
        const Offset(270, 98),
        23,
        Paint()..color = const Color(0x55F7E2C6),
      );
      canvas.drawCircle(
        const Offset(270, 98),
        12,
        Paint()..color = const Color(0xFFEEDDD1),
      );
    }
    for (var i = 0; i < 26; i++) {
      if (storm || sunset) break;
      final x = 73.0 + (i * 47 % 241);
      final y = 49.0 + (i * 23 % 117);
      canvas.drawCircle(
        Offset(x, y),
        i % 5 == 0 ? 1.1 : .55,
        Paint()..color = const Color(0x99FFF3DD),
      );
    }

    for (var i = 0; i < 17; i++) {
      final x = 62.0 + i * 17;
      final h = 72.0 + (i * 29 % 95);
      final building = Rect.fromLTWH(x, 331 - h, 14.5, h);
      canvas.drawRect(
        building,
        Paint()..color = i.isEven ? const Color(0xFF1B2032) : const Color(0xFF272737),
      );
      for (var j = 0; j < 8; j++) {
        if ((i * 7 + j * 3) % 5 != 0) {
          canvas.drawRect(
            Rect.fromLTWH(x + 4, 339 - h + j * 11, 3.5, 4.5),
            Paint()..color = const Color(0x88E6BF8C),
          );
        }
      }
    }

    canvas.restore();

    // Frames and subtle reflective strokes.
    final framePaint = Paint()
      ..color = const Color(0xFF12151C)
      ..strokeWidth = 8;
    canvas.drawLine(const Offset(195, 36), const Offset(195, 331), framePaint);
    canvas.drawLine(const Offset(62, 199), const Offset(326, 199), framePaint);
    canvas.drawLine(
      const Offset(82, 36),
      const Offset(82, 330),
      Paint()
        ..color = const Color(0x28FFFFFF)
        ..strokeWidth = 1.4,
    );

    // Floor boards and low furnishing silhouettes.
    final floorPath = Path()
      ..moveTo(0, 338)
      ..lineTo(390, 338)
      ..lineTo(390, 464)
      ..lineTo(0, 464)
      ..close();
    canvas.drawPath(
      floorPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF28252C), Color(0xFF141318)],
        ).createShader(const Rect.fromLTWH(0, 338, 390, 126)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(35, 395, 321, 68),
      Paint()..color = const Color(0x334B3F4B),
    );

    // Floating shelf, decorative books, and a lamp-like collectible.
    _rounded(canvas, const Rect.fromLTWH(15, 280, 100, 10), 3, const Color(0xFF5C473B));
    for (var i = 0; i < 7; i++) {
      final x = 23.0 + i * 12;
      _rounded(
        canvas,
        Rect.fromLTWH(x, 245.0 - (i % 3) * 7, 8, 35.0 + (i % 3) * 7),
        1.5,
        Color.lerp(const Color(0xFF73647A), _copper, (i % 5) / 5)!,
      );
    }

    // A compact plant, hanging art, and small highlights give depth without
    // requiring bundled textures or remote imagery.
    _rounded(canvas, const Rect.fromLTWH(13, 80, 34, 55), 3,
        const Color(0xFF443743));
    _rounded(canvas, const Rect.fromLTWH(17, 84, 26, 47), 2,
        const Color(0xFF262634));
    canvas.drawLine(const Offset(21, 113), const Offset(39, 94),
        Paint()..color = const Color(0xFFBA9472)..strokeWidth = 1.6);
    _rounded(canvas, const Rect.fromLTWH(344, 318, 35, 11), 2,
        const Color(0xFF806554));
    canvas.drawLine(const Offset(360, 325), const Offset(361, 295),
        Paint()..color = const Color(0xFF7B8A69)..strokeWidth = 2);
    for (final leaf in [
      const Offset(351, 305), const Offset(368, 303),
      const Offset(353, 292), const Offset(370, 289),
    ]) {
      canvas.drawOval(Rect.fromCenter(center: leaf, width: 16, height: 8),
          Paint()..color = const Color(0xFF596E62));
    }

    // The warm desk and turntable silhouette.
    _rounded(canvas, const Rect.fromLTWH(54, 367, 290, 70), 11, const Color(0xFF49372F));
    _rounded(canvas, const Rect.fromLTWH(47, 350, 298, 31), 8, const Color(0xFF826550));
    _rounded(canvas, const Rect.fromLTWH(55, 351, 282, 8), 3, const Color(0xFFA37B5D));
    _rounded(canvas, const Rect.fromLTWH(127, 329, 133, 54), 9, const Color(0xFF22242D));
    _rounded(canvas, const Rect.fromLTWH(131, 331, 125, 45), 7, const Color(0xFF353741));
    // Stereo cabinets.
    for (final x in [67.0, 292.0]) {
      _rounded(canvas, Rect.fromLTWH(x, 310, 31, 60), 5, const Color(0xFF181920));
      canvas.drawCircle(Offset(x + 15.5, 347), 10, Paint()..color = const Color(0xFF33323C));
      canvas.drawCircle(Offset(x + 15.5, 347), 5, Paint()..color = const Color(0xFF15141B));
      canvas.drawCircle(Offset(x + 15.5, 324), 4, Paint()..color = const Color(0xFF554D4C));
    }

    // Lamp base, stem, conical shade, and a practical lighting state.
    if (settings.lampOn) {
      canvas.drawCircle(
        const Offset(326, 291),
        83,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x65F5C995), Color(0x00F5C995)],
          ).createShader(const Rect.fromLTWH(243, 208, 166, 166)),
      );
    }
    canvas.drawLine(
      const Offset(325, 289),
      const Offset(325, 351),
      Paint()
        ..color = const Color(0xFFBC9C82)
        ..strokeWidth = 3,
    );
    canvas.drawOval(const Rect.fromLTWH(309, 347, 32, 8), Paint()..color = _copper);
    final shade = Path()
      ..moveTo(310, 278)
      ..lineTo(339, 278)
      ..lineTo(348, 303)
      ..lineTo(301, 303)
      ..close();
    canvas.drawPath(
      shade,
      Paint()..color = settings.lampOn ? const Color(0xFFE1BC8A) : const Color(0xFF67594D),
    );

    // Soft vignette focuses the room on the window and audio desk.
    canvas.drawRect(
      scene,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.13),
          radius: .92,
          colors: [Color(0x00000000), Color(0x7D05050B)],
          stops: [0.47, 1.0],
        ).createShader(scene),
    );
    canvas.restore();
  }

  void _rounded(Canvas canvas, Rect rect, double radius, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _MidnightPainter oldDelegate) =>
      oldDelegate.settings.mood != settings.mood ||
      oldDelegate.settings.lampOn != settings.lampOn;
}
