import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:flutter/material.dart';

/// First-release scene: deterministic, lightweight 2.5D vector composition.
/// This is *not* a music-reactive renderer or an animated playback simulation.
class RoomScene extends StatelessWidget {
  const RoomScene({
    required this.settings,
    required this.onRecordTap,
    required this.onWindowTap,
    required this.onLampTap,
    required this.onShelfTap,
    super.key,
  });

  final RoomSettings settings;
  final VoidCallback onRecordTap;
  final VoidCallback onWindowTap;
  final VoidCallback onLampTap;
  final VoidCallback onShelfTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: AspectRatio(
        aspectRatio: .84,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _MidnightPainter(settings)),
                _hotspot(
                  'Browse the music library',
                  Icons.album_outlined,
                  const Alignment(-.07, .66),
                  onRecordTap,
                ),
                _hotspot(
                  'Change the weather',
                  Icons.cloud_outlined,
                  const Alignment(.67, -.47),
                  onWindowTap,
                ),
                _hotspot(
                  settings.lampOn ? 'Turn lamp off' : 'Turn lamp on',
                  Icons.lightbulb_outline,
                  const Alignment(.82, .40),
                  onLampTap,
                ),
                _hotspot(
                  'Open the library',
                  Icons.queue_music,
                  const Alignment(-.70, .50),
                  onShelfTap,
                ),
                Positioned(
                  left: 18,
                  bottom: 16,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AuvorynColors.ink.withValues(alpha: .75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: AuvorynColors.champagne),
                          SizedBox(width: 7),
                          Text(
                            'MIDNIGHT APARTMENT',
                            style: TextStyle(fontSize: 10, letterSpacing: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hotspot(
    String label,
    IconData icon,
    Alignment alignment,
    VoidCallback action,
  ) =>
      Align(
        alignment: alignment,
        child: Semantics(
          button: true,
          label: label,
          child: Tooltip(
            message: label,
            child: Material(
              color: AuvorynColors.ink.withValues(alpha: .65),
              shape: const CircleBorder(
                side: BorderSide(color: Color(0x88D8B78B)),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: action,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(icon, size: 21, color: AuvorynColors.ivory),
                ),
              ),
            ),
          ),
        ),
      );
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

    if (settings.mood.hasRain) {
      final amount = settings.mood == RoomMood.lightRain ? 39 : 105;
      for (var i = 0; i < amount; i++) {
        final x = 63.0 + (i * 71 % 262);
        final y = 38.0 + (i * 47 % 280);
        final length = 7.0 + (i % 5) * 3.0;
        canvas.drawLine(
          Offset(x, y),
          Offset(x - 3, y + length),
          Paint()
            ..color = const Color(0x5CB8C8E6)
            ..strokeWidth = settings.mood == RoomMood.lightRain ? .7 : 1.2,
        );
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

    // The warm desk and turntable silhouette.
    _rounded(canvas, const Rect.fromLTWH(54, 367, 290, 70), 11, const Color(0xFF49372F));
    _rounded(canvas, const Rect.fromLTWH(47, 350, 298, 31), 8, const Color(0xFF826550));
    _rounded(canvas, const Rect.fromLTWH(55, 351, 282, 8), 3, const Color(0xFFA37B5D));
    _rounded(canvas, const Rect.fromLTWH(127, 329, 133, 54), 9, const Color(0xFF22242D));
    _rounded(canvas, const Rect.fromLTWH(131, 331, 125, 45), 7, const Color(0xFF353741));
    canvas.drawCircle(const Offset(189, 353), 38, Paint()..color = const Color(0xFF0C0C10));
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        const Offset(189, 353),
        32.0 - i * 6,
        Paint()
          ..color = const Color(0x335E6274)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawCircle(const Offset(189, 353), 11, Paint()..color = _copper);
    canvas.drawCircle(const Offset(189, 353), 2.5, Paint()..color = const Color(0xFF1A1A20));
    canvas.drawLine(
      const Offset(238, 340),
      const Offset(223, 350),
      Paint()
        ..color = const Color(0xFFE2D5C6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(239, 339), 4, Paint()..color = _copper);

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
