import 'dart:math' as math;

import 'package:auvoryn/features/companion/domain/room_companion.dart';
import 'package:auvoryn/features/home_room/domain/room_camera.dart';
import 'package:flutter/material.dart';

/// Authored, perspective-anchored 2.5D figure. No network image, extra audio
/// engine or constantly ticking animation. Paints only when settings/orbit change.
class RoomCompanionPainter extends CustomPainter {
  const RoomCompanionPainter({
    required this.companion,
    required this.camera,
    required this.lampBrightness,
  });

  final RoomCompanion companion;
  final RoomCamera camera;
  final double lampBrightness;

  @override
  void paint(Canvas canvas, Size size) {
    if (!companion.visible) return;
    final seated = companion.pose == CompanionPose.sofa;
    final x = switch (companion.pose) {
      CompanionPose.sofa => -1.91,
      CompanionPose.standing => 1.44,
      CompanionPose.window => 2.14,
    };
    final z = switch (companion.pose) {
      CompanionPose.sofa => 1.13,
      CompanionPose.standing => 1.87,
      CompanionPose.window => -1.34,
    };
    final y = seated ? .76 : .035;
    final ground = camera.project(RoomPoint(x, y, z), size.width, size.height);
    final crown = camera.project(
      RoomPoint(x, y + (seated ? 1.22 : 1.76), z),
      size.width, size.height,
    );
    final unit = ((ground.y - crown.y) / (seated ? 145 : 190))
        .clamp(.28, 2.4).toDouble();
    canvas.save();
    canvas.translate(ground.x, ground.y);
    // The existing camera drives placement and apparent size on every orbit.
    canvas.scale(unit * 1.10);
    _drawPerson(canvas, seated);
    canvas.restore();
  }

  void _drawPerson(Canvas c, bool seated) {
    final skin = switch (companion.skin) {
      CompanionSkin.light => const Color(0xFFE8C6AB),
      CompanionSkin.warm => const Color(0xFFBD8769),
      CompanionSkin.deep => const Color(0xFF80523E),
    };
    final cloth = switch (companion.outfit) {
      CompanionOutfit.oatmeal => const Color(0xFFB6A58F),
      CompanionOutfit.sage => const Color(0xFF718781),
      CompanionOutfit.charcoal => const Color(0xFF333943),
      CompanionOutfit.plum => const Color(0xFF735360),
    };
    final hair = switch (companion.style) {
      CompanionStyle.girl => const Color(0xFF51372F),
      CompanionStyle.boy => const Color(0xFF382B27),
      CompanionStyle.emoBoy || CompanionStyle.emoGirl =>
        const Color(0xFF1D1C22),
    };
    final lowLight = Color.lerp(
      const Color(0xFF3B4350),
      const Color(0xFFDEB58C),
      lampBrightness.clamp(0, 1),
    )!;
    final isEmo = companion.style == CompanionStyle.emoBoy ||
        companion.style == CompanionStyle.emoGirl;
    final jeans = isEmo ? const Color(0xFF252831) :
        const Color(0xFF4B5A62);
    final head = seated ? -124.0 : -163.0;
    final shoulders = head + 36;
    final waist = seated ? -28.0 : -77.0;

    Paint fill(Color color) => Paint()..color = color;
    Paint line(Color color, double width) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void capsule(Offset a, Offset b, double width, Color color) =>
      c.drawLine(a, b, line(color, width));

    // Shadow receives the same room-relative perspective as the figure.
    c.drawOval(
      Rect.fromCenter(center: Offset(1, seated ? 32 : 1),
          width: seated ? 67 : 54, height: 12),
      fill(const Color(0x660B0F16)),
    );

    // Lower-body silhouettes, with lighter trouser seams and soft shoe tips.
    if (seated) {
      capsule(Offset(-13, waist + 8), const Offset(-21, 13), 21, jeans);
      capsule(Offset(13, waist + 8), const Offset(25, 13), 21, jeans);
      capsule(const Offset(-21, 13), const Offset(-18, 30), 14, jeans);
      capsule(const Offset(25, 13), const Offset(26, 31), 14, jeans);
      capsule(const Offset(-20, 32), const Offset(-32, 36), 11,
          const Color(0xFF303038));
      capsule(const Offset(27, 33), const Offset(40, 37), 11,
          const Color(0xFF303038));
    } else {
      capsule(Offset(-11, waist + 6), const Offset(-14, -8), 20, jeans);
      capsule(Offset(11, waist + 6), const Offset(14, -8), 20, jeans);
      capsule(const Offset(-14, -6), const Offset(-20, 0), 12,
          const Color(0xFF292A32));
      capsule(const Offset(14, -6), const Offset(24, 0), 12,
          const Color(0xFF292A32));
    }

    // Back hair: layered silhouettes read as hair rather than a solid helmet.
    final longHair = companion.hair == CompanionHair.long ||
        companion.hair == CompanionHair.waves;
    if (longHair) {
      final back = Path()
        ..moveTo(-19, head - 10)
        ..quadraticBezierTo(-31, head + 12, -24, shoulders + 42)
        ..quadraticBezierTo(-10, shoulders + 32, 0, head + 18)
        ..quadraticBezierTo(20, shoulders + 32, 27, shoulders + 37)
        ..quadraticBezierTo(30, head + 1, 17, head - 13)
        ..close();
      c.drawPath(back, fill(hair));
    }

    // Relaxed knit body with rounded shoulder drops and hand-drawn folds.
    final top = Path()
      ..moveTo(-17, shoulders - 11)
      ..quadraticBezierTo(-31, shoulders - 6, -31, shoulders + 10)
      ..lineTo(-24, waist - 3)
      ..quadraticBezierTo(0, waist + 9, 24, waist - 3)
      ..lineTo(31, shoulders + 10)
      ..quadraticBezierTo(31, shoulders - 6, 17, shoulders - 11)
      ..quadraticBezierTo(0, shoulders - 2, -17, shoulders - 11)
      ..close();
    c.drawPath(top, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          Color.lerp(cloth, lowLight, .17)!,
          cloth,
          Color.lerp(cloth, Colors.black, .29)!,
        ],
      ).createShader(Rect.fromLTWH(-33, shoulders - 14, 68, waist - shoulders + 30)));
    c.drawPath(top, line(Color.lerp(cloth, Colors.black, .32)!, 1.25));

    // Arms, cuffs, fingers: quiet pose variations, without animation.
    if (seated) {
      capsule(Offset(-28, shoulders + 8), Offset(-29, waist - 2), 16, cloth);
      capsule(Offset(28, shoulders + 8), Offset(24, waist - 1), 16, cloth);
      capsule(Offset(-29, waist - 2), Offset(-15, waist + 16), 12, cloth);
      capsule(Offset(24, waist - 1), Offset(11, waist + 16), 12, cloth);
      c.drawOval(Rect.fromCenter(center: Offset(-14, waist + 16),
          width: 10, height: 12), fill(skin));
      c.drawOval(Rect.fromCenter(center: Offset(12, waist + 16),
          width: 10, height: 12), fill(skin));
    } else {
      capsule(Offset(-29, shoulders + 7), Offset(-34, waist + 5), 15, cloth);
      capsule(Offset(29, shoulders + 7), Offset(32, waist + 5), 15, cloth);
      c.drawOval(Rect.fromCenter(center: Offset(-34, waist + 11),
          width: 10, height: 17), fill(skin));
      c.drawOval(Rect.fromCenter(center: Offset(32, waist + 11),
          width: 10, height: 17), fill(skin));
    }
    c.drawLine(Offset(-15, waist - 6), Offset(13, waist - 4),
        line(Color.lerp(cloth, Colors.black, .26)!, 1.2));
    c.drawLine(Offset(-9, shoulders + 30), Offset(-5, waist - 12),
        line(Color.lerp(cloth, Colors.white, .12)!, 1));
    c.drawLine(Offset(10, shoulders + 33), Offset(15, waist - 10),
        line(Color.lerp(cloth, Colors.black, .19)!, 1));

    // Collar, neck and subtly shaded, non-cartoon human face.
    c.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, head + 25), width: 13, height: 18),
        const Radius.circular(5)), fill(skin));
    c.drawOval(Rect.fromCenter(center: Offset(0, head), width: 39, height: 47),
        fill(Color.lerp(skin, const Color(0xFFFFE5CD), .11)!));
    c.drawOval(Rect.fromCenter(center: Offset(7, head + 2),
        width: 31, height: 42),
        fill(skin.withValues(alpha: .30)));
    for (final dx in [-18.0, 18.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(dx, head + 4),
          width: 6, height: 10), fill(skin));
    }
    c.drawLine(Offset(-10, head + 3), Offset(-5, head + 3),
        line(const Color(0xFF463630), 1.4));
    c.drawLine(Offset(6, head + 3), Offset(11, head + 3),
        line(const Color(0xFF463630), 1.4));
    c.drawLine(Offset(1, head + 7), Offset(0, head + 15),
        line(Color.lerp(skin, const Color(0xFF51352F), .38)!, 1.1));
    c.drawLine(Offset(-4, head + 19), Offset(5, head + 19),
        line(const Color(0xFF7E524B), .85));

    // Crown and style-specific fringe. Small strand highlights add texture.
    final crown = Path()
      ..moveTo(-20, head + 4)
      ..quadraticBezierTo(-27, head - 29, -10, head - 28)
      ..quadraticBezierTo(10, head - 38, 22, head - 17)
      ..quadraticBezierTo(24, head - 4, 19, head + 5)
      ..lineTo(15, head - 13)
      ..quadraticBezierTo(-6, head - 5, -20, head + 4)
      ..close();
    c.drawPath(crown, fill(hair));
    if (companion.hair == CompanionHair.fringe) {
      c.drawPath(
        Path()
          ..moveTo(-20, head - 17)
          ..quadraticBezierTo(10, head - 37, 21, head - 14)
          ..quadraticBezierTo(15, head - 4, -9, head + 14)
          ..lineTo(-13, head + 4)
          ..quadraticBezierTo(-5, head - 9, -20, head - 2)
          ..close(),
        fill(hair),
      );
    } else if (companion.hair == CompanionHair.waves) {
      for (final dx in [-22.0, 22.0]) {
        c.drawArc(Rect.fromCenter(center: Offset(dx, head + 14),
            width: 14, height: 50), -.5, math.pi,
            false, line(Color.lerp(hair, Colors.white, .13)!, 3.0));
      }
    }
    c.drawArc(Rect.fromLTWH(-17, head - 29, 33, 28),
        math.pi * 1.13, 1.12, false,
        line(Color.lerp(hair, lowLight, .24)!, 1.2));
    if (isEmo) {
      // Slim over-ear headphones, not an audio-reactive animation.
      c.drawArc(Rect.fromCenter(center: Offset(0, head - 7),
          width: 48, height: 57), math.pi * 1.04, math.pi * .95,
          false, line(const Color(0xFF161B23), 3.8));
      c.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(18, head - 6, 8, 19),
          const Radius.circular(4)), fill(const Color(0xFF303641)));
    }
  }

  @override
  bool shouldRepaint(covariant RoomCompanionPainter oldDelegate) =>
      oldDelegate.companion.visible != companion.visible ||
      oldDelegate.companion.style != companion.style ||
      oldDelegate.companion.hair != companion.hair ||
      oldDelegate.companion.skin != companion.skin ||
      oldDelegate.companion.outfit != companion.outfit ||
      oldDelegate.companion.pose != companion.pose ||
      oldDelegate.camera.orbit != camera.orbit ||
      oldDelegate.lampBrightness != lampBrightness;
}
