import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:auvoryn/features/home_room/domain/room_geometry.dart';

import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/features/home_room/domain/room_camera.dart';
import 'package:flutter/material.dart';

/// Authored 3D surfaces, projected and depth-sorted on Flutter's canvas.
/// No downloaded model, WebView, sensor or separate rendering engine is used.
class RoomDioramaGeometry {
  RoomDioramaGeometry(this.settings, this.light)
    : _model = _Apartment(settings, light);
  final RoomSettings settings;
  final double light;
  final _Apartment _model;
}

class RoomDioramaPainter extends CustomPainter {
  RoomDioramaPainter({required this.geometry, required this.camera});
  final RoomDioramaGeometry geometry;
  final RoomCamera camera;
  @override
  void paint(Canvas canvas, Size size) =>
      geometry._model.paint(canvas, size, camera);
  @override
  bool shouldRepaint(covariant RoomDioramaPainter oldDelegate) =>
      oldDelegate.geometry != geometry ||
      oldDelegate.camera.orbit != camera.orbit;
}

class _Face {
  const _Face(
    this.points,
    this.color, {
    this.endColor,
    this.gradientStart,
    this.gradientEnd,
  });
  final List<RoomPoint> points;
  final Color color;
  final Color? endColor;
  final RoomPoint? gradientStart, gradientEnd;
}

class _Apartment {
  _Apartment(this.settings, this.light) {
    _build();
    _tree = RoomBsp([
      for (final face in _faces) RoomPolygon(face.points, face),
    ]);
  }
  final RoomSettings settings;
  final double light;
  final _faces = <_Face>[];
  late final RoomBsp<_Face> _tree;
  Color get glow => switch (settings.lampPalette) {
    LampPalette.amber => const Color(0xFFFFCF94),
    LampPalette.rose => const Color(0xFFF3A8BB),
    LampPalette.moonlight => const Color(0xFFB1D4FF),
  };
  bool get sunset => settings.mood == RoomMood.warmSunset;

  void face(List<RoomPoint> points, Color color) =>
      _faces.add(_Face(points, color));
  void box(
    double x,
    double y,
    double z,
    double w,
    double h,
    double d,
    Color color,
  ) {
    final a = RoomPoint(x, y, z), b = RoomPoint(x + w, y, z);
    final c = RoomPoint(x + w, y, z + d), e = RoomPoint(x, y, z + d);
    final f = RoomPoint(x, y + h, z), g = RoomPoint(x + w, y + h, z);
    final i = RoomPoint(x + w, y + h, z + d), j = RoomPoint(x, y + h, z + d);
    face([a, b, g, f], Color.lerp(color, Colors.black, .30)!);
    face([a, e, j, f], Color.lerp(color, Colors.black, .13)!);
    face([b, c, i, g], Color.lerp(color, Colors.black, .23)!);
    face([e, c, i, j], color);
    face([f, g, i, j], Color.lerp(color, const Color(0xFFFFE5CA), .16)!);
  }

  void floorRect(
    double x,
    double z,
    double w,
    double d,
    double y,
    Color color,
  ) => face([
    RoomPoint(x, y, z),
    RoomPoint(x + w, y, z),
    RoomPoint(x + w, y, z + d),
    RoomPoint(x, y, z + d),
  ], color);
  void wallRect(
    double x,
    double y,
    double w,
    double h,
    double z,
    Color color,
  ) => face([
    RoomPoint(x, y, z),
    RoomPoint(x + w, y, z),
    RoomPoint(x + w, y + h, z),
    RoomPoint(x, y + h, z),
  ], color);
  void disc(
    RoomPoint p,
    double radius,
    Color color, {
    bool vertical = false,
    int sides = 28,
  }) {
    face([
      for (var i = 0; i < sides; i++)
        RoomPoint(
          p.x + math.cos(i * math.pi * 2 / sides) * radius,
          p.y + (vertical ? math.sin(i * math.pi * 2 / sides) * radius : 0),
          p.z + (vertical ? 0 : math.sin(i * math.pi * 2 / sides) * radius),
        ),
    ], color);
  }

  void cylinder(
    RoomPoint p,
    double radius,
    double height,
    Color color, {
    double? topRadius,
    int sides = 18,
  }) {
    final top = topRadius ?? radius;
    for (var i = 0; i < sides; i++) {
      final a = i * math.pi * 2 / sides, b = (i + 1) * math.pi * 2 / sides;
      face([
        RoomPoint(p.x + math.cos(a) * radius, p.y, p.z + math.sin(a) * radius),
        RoomPoint(p.x + math.cos(b) * radius, p.y, p.z + math.sin(b) * radius),
        RoomPoint(
          p.x + math.cos(b) * top,
          p.y + height,
          p.z + math.sin(b) * top,
        ),
        RoomPoint(
          p.x + math.cos(a) * top,
          p.y + height,
          p.z + math.sin(a) * top,
        ),
      ], Color.lerp(color, Colors.black, .12 + .22 * (math.cos(a) * .5 + .5))!);
    }
    disc(
      RoomPoint(p.x, p.y + height, p.z),
      top,
      Color.lerp(color, const Color(0xFFFFECD5), .16)!,
      sides: sides,
    );
  }

  void _build() {
    // The open architectural shell and warm individual floorboards.
    box(-3.15, -.20, -2.85, 6.3, .20, 5.7, const Color(0xFF27252A));
    for (var i = 0; i < 16; i++) {
      floorRect(
        -3.10 + i * .388,
        -2.8,
        .379,
        5.6,
        .008,
        Color.lerp(
          const Color(0xFF674D40),
          const Color(0xFF886B54),
          (i % 4) / 4,
        )!,
      );
      for (var j = 0; j < 3; j++) {
        floorRect(
          -3.10 + i * .388,
          -2.5 + j * 1.8 + (i % 2) * .36,
          .379,
          .012,
          .012,
          const Color(0xFF4C3B34),
        );
      }
    }
    box(-3.20, 0, -2.94, 6.4, 4.0, .14, const Color(0xFF343946));
    box(-3.24, 0, -2.82, .14, 4.0, 5.65, const Color(0xFF41434B));
    box(-3.10, .02, -2.78, 6.18, .12, .06, const Color(0xFF79726D));
    box(-3.09, .02, -2.78, .06, .12, 5.5, const Color(0xFF696563));
    // Fine vertical wall joinery, rather than a flat untextured block.
    for (var i = 0; i < 7; i++) {
      box(
        -3.08,
        .18,
        -2.5 + i * .74,
        .018,
        3.65,
        .018,
        const Color(0xFF50525A),
      );
    }
    _window();

    // Framed abstract artwork on the left wall, in the same 3D space.
    box(-3.06, 2.02, .10, .08, 1.32, 1.06, const Color(0xFFB19473));
    face([
      const RoomPoint(-2.97, 2.10, .18),
      const RoomPoint(-2.97, 3.26, .18),
      const RoomPoint(-2.97, 3.26, 1.08),
      const RoomPoint(-2.97, 2.10, 1.08),
    ], const Color(0xFFE1D1B5));
    face([
      const RoomPoint(-2.96, 2.16, .24),
      const RoomPoint(-2.96, 3.12, .69),
      const RoomPoint(-2.96, 2.16, 1.02),
    ], const Color(0xFF9B6654));
    face([
      const RoomPoint(-2.95, 2.16, .24),
      const RoomPoint(-2.95, 2.77, .25),
      const RoomPoint(-2.95, 2.16, 1.02),
    ], const Color(0xFF4D665F));

    // Woven area rug and quiet geometric border.
    floorRect(-1.35, -.05, 3.85, 2.65, .025, const Color(0xFFB4A28C));
    floorRect(-1.23, .07, 3.61, 2.41, .028, const Color(0xFF958B80));
    for (var i = 0; i < 26; i++) {
      floorRect(
        -1.22,
        .08 + i * .091,
        3.58,
        .008,
        .030,
        const Color(0x44675E56),
      );
    }

    // Low walnut music console and slim brass legs.
    for (final x in [-1.28, 1.70]) {
      for (final z in [-1.85, -.98]) {
        box(x, .02, z, .06, .30, .06, const Color(0xFFB4976F));
      }
    }
    box(-1.42, .28, -1.98, 3.34, .77, 1.14, const Color(0xFF745340));
    box(-1.48, 1.05, -2.02, 3.46, .08, 1.22, const Color(0xFFB08D69));
    for (var i = 0; i < 24; i++) {
      box(
        -1.34 + i * .133,
        .35,
        -.831,
        .026,
        .61,
        .012,
        const Color(0xFF4D382F),
      );
    }
    // Turntable plinth, platter and tonearm. Rotation is a separate repaint.
    box(-.44, 1.13, -1.76, 1.18, .065, .93, const Color(0xFF222B31));
    disc(RoomCamera.record, .38, const Color(0xFF11171D));
    box(.55, 1.20, -1.67, .045, .035, .48, const Color(0xFFC7BAA3));
    box(.35, 1.20, -1.21, .24, .025, .035, const Color(0xFFC7BAA3));
    for (final x in [-1.22, 1.34]) {
      box(x, 1.13, -1.64, .43, .71, .52, const Color(0xFF292D33));
      disc(
        RoomPoint(x + .215, 1.40, -1.115),
        .155,
        const Color(0xFF777167),
        vertical: true,
      );
      disc(
        RoomPoint(x + .215, 1.40, -1.108),
        .109,
        const Color(0xFF1A2028),
        vertical: true,
      );
      disc(
        RoomPoint(x + .215, 1.72, -1.108),
        .052,
        const Color(0xFFB6AA92),
        vertical: true,
      );
    }

    // Record shelving. Every spine is geometry, not a texture download.
    box(-2.94, .09, -2.59, 1.13, 1.82, .54, const Color(0xFF4C3A32));
    for (var row = 0; row < 2; row++) {
      box(
        -2.90,
        .18 + row * .79,
        -2.01,
        1.05,
        .045,
        .05,
        const Color(0xFFAE8D6E),
      );
      for (var i = 0; i < 9; i++) {
        final colors = [
          const Color(0xFFB89F7C),
          const Color(0xFF586C6A),
          const Color(0xFFAA796A),
          const Color(0xFF7D798B),
        ];
        box(
          -2.84 + i * .105,
          .23 + row * .79,
          -2.055,
          .072,
          .55 + (i % 3) * .04,
          .045,
          colors[(i + row) % 4],
        );
      }
    }
    // Sofa: back, arms, cushions, seams and feet are volumetric surfaces.
    for (final z in [.02, 1.76]) {
      box(-2.67, .02, z, .08, .20, .09, const Color(0xFF312F2B));
      box(-1.45, .02, z, .08, .20, .09, const Color(0xFF312F2B));
    }
    box(-2.85, .20, -.15, 1.52, .34, 2.18, const Color(0xFF657574));
    box(-2.88, .45, -.15, .29, .84, 2.18, const Color(0xFF71847F));
    for (final z in [-.15, 1.78]) {
      box(-2.84, .51, z, 1.52, .40, .25, const Color(0xFF84938B));
    }
    for (var i = 0; i < 2; i++) {
      box(-2.55, .54, .15 + i * .81, 1.11, .18, .77, const Color(0xFFA2ABA0));
      box(-2.56, .73, .16 + i * .81, .17, .43, .74, const Color(0xFF92A195));
    }
    box(-2.30, .72, .26, .43, .35, .42, const Color(0xFFC4AF8E));
    box(-2.30, .73, 1.20, .38, .30, .40, const Color(0xFF987465));
    // Rounded coffee table and ceramic cup.
    disc(const RoomPoint(.23, .04, 1.23), .69, const Color(0x440C1319));
    cylinder(
      const RoomPoint(.23, .03, 1.23),
      .17,
      .49,
      const Color(0xFF3D342F),
    );
    cylinder(
      const RoomPoint(.23, .50, 1.23),
      .69,
      .09,
      const Color(0xFFB8A28A),
    );
    box(-.13, .60, 1.05, .39, .035, .44, const Color(0xFF485D5C));
    box(-.10, .635, 1.07, .36, .018, .40, const Color(0xFFD5C4A5));
    cylinder(
      const RoomPoint(.54, .60, 1.34),
      .10,
      .15,
      const Color(0xFFD6C2A3),
    );
    disc(const RoomPoint(.54, .752, 1.34), .076, const Color(0xFF443026));

    // Floor lamp, with a shade and a layered pool of light on the floor.
    if (light > 0) {
      for (var i = 5; i >= 0; i--) {
        disc(
          RoomPoint(2.3, .034 + (5 - i) * .001, .25),
          .35 + i * .18,
          glow.withValues(alpha: light * .035),
        );
      }
    }
    cylinder(const RoomPoint(2.3, .04, .25), .30, .07, const Color(0xFF8D7353));
    cylinder(
      const RoomPoint(2.3, .11, .25),
      .026,
      2.12,
      const Color(0xFFC4A37A),
      sides: 8,
    );
    cylinder(
      const RoomPoint(2.3, 2.08, .25),
      .47,
      .49,
      Color.lerp(const Color(0xFF8E8375), glow, light * .85)!,
      topRadius: .28,
    );

    // Sculptural plant in the rear corner.
    cylinder(
      const RoomPoint(2.59, .02, -2.06),
      .24,
      .47,
      const Color(0xFFB5987D),
      topRadius: .31,
    );
    cylinder(
      const RoomPoint(2.59, .49, -2.06),
      .025,
      .95,
      const Color(0xFF556858),
      sides: 6,
    );
    for (var i = 0; i < 8; i++) {
      final angle = i * 2.4, y = .83 + i * .10;
      final tip = RoomPoint(
        2.59 + math.cos(angle) * .51,
        y + .21,
        -2.06 + math.sin(angle) * .40,
      );
      face([
        RoomPoint(2.59, y - .17, -2.06),
        RoomPoint(tip.x - .10, y + .07, tip.z + .10),
        tip,
        RoomPoint(tip.x + .10, y + .11, tip.z - .10),
      ], i.isEven ? const Color(0xFF6D8A73) : const Color(0xFF4F705F));
    }
  }

  void _window() {
    const x = -1.48, y = 1.63, w = 4.12, h = 2.02;
    wallRect(
      x - .09,
      y - .10,
      w + .18,
      h + .20,
      -2.772,
      const Color(0xFF141E2A),
    );
    final top = sunset ? const Color(0xFF8E6179) : const Color(0xFF182A49);
    final bottom = sunset ? const Color(0xFFE1AB84) : const Color(0xFF647C97);
    _faces.add(
      _Face(
        [
          const RoomPoint(x, y, -2.760),
          const RoomPoint(x + w, y, -2.760),
          const RoomPoint(x + w, y + h, -2.760),
          const RoomPoint(x, y + h, -2.760),
        ],
        top,
        endColor: bottom,
        gradientStart: const RoomPoint(x + w / 2, y + h, -2.760),
        gradientEnd: const RoomPoint(x + w / 2, y, -2.760),
      ),
    );
    if (settings.mood != RoomMood.thunderstorm) {
      disc(
        const RoomPoint(1.89, 3.19, -2.752),
        .26,
        sunset ? const Color(0x88FFE5BB) : const Color(0x22F1E8D4),
        vertical: true,
      );
      disc(
        const RoomPoint(1.89, 3.19, -2.746),
        sunset ? .16 : .105,
        const Color(0xFFF3DFC2),
        vertical: true,
      );
    }
    if (!sunset) {
      for (var i = 0; i < 17; i++) {
        disc(
          RoomPoint(
            -1.35 + (i * 43 % 380) / 100,
            2.60 + (i * 37 % 85) / 100,
            -2.744,
          ),
          .009 + (i % 3) * .003,
          const Color(0xAACDD7E3),
          vertical: true,
          sides: 5,
        );
      }
    }
    if (settings.windowView == WindowView.skyline) {
      for (var i = 0; i < 18; i++) {
        final bx = x + i * .23, bh = .29 + (i * 31 % 65) / 100;
        wallRect(
          bx,
          y,
          .205,
          bh,
          -2.738,
          i.isEven ? const Color(0xFF28384C) : const Color(0xFF33475D),
        );
        for (var j = 0; j < 5; j++) {
          if (j * .11 + .12 < bh && (i + j) % 3 != 0) {
            wallRect(
              bx + .045,
              y + .06 + j * .11,
              .035,
              .04,
              -2.733,
              const Color(0xDDDFC49B),
            );
            wallRect(
              bx + .12,
              y + .06 + j * .11,
              .035,
              .04,
              -2.733,
              const Color(0x88DFC49B),
            );
          }
        }
      }
    } else if (settings.windowView == WindowView.mountain) {
      for (var ridge = 0; ridge < 2; ridge++) {
        for (var i = 0; i < 8; i++) {
          final z = -2.738 + ridge * .004;
          final left = x + i * w / 8, right = x + (i + 1) * w / 8;
          final h1 = y + .28 + ((i * 37 + ridge * 29) % 80) / 100;
          final h2 = y + .28 + (((i + 1) * 37 + ridge * 29) % 80) / 100;
          face([
            RoomPoint(left, y, z),
            RoomPoint(right, y, z),
            RoomPoint(right, h2, z),
            RoomPoint(left, h1, z),
          ], ridge == 0 ? const Color(0xFF52647A) : const Color(0xFF344A5E));
        }
      }
    } else {
      wallRect(x, y, w, .67, -2.738, const Color(0xFF4E6B80));
      for (var i = 0; i < 18; i++) {
        wallRect(
          x + .12 + (i * 47 % 360) / 100,
          y + .08 + (i * 19 % 48) / 100,
          .22,
          .008,
          -2.734,
          const Color(0x77B4C3CB),
        );
      }
    }
    // Frames sit in front of the view; the casement has actual depth.
    for (final bx in [x - .035, x + w / 2 - .025, x + w - .025]) {
      box(bx, y - .06, -2.71, .055, h + .12, .065, const Color(0xFF9A9892));
    }
    box(x - .05, y - .065, -2.70, w + .1, .055, .15, const Color(0xFFB4A58F));
    box(x - .05, y + h, -2.70, w + .1, .045, .08, const Color(0xFF9E9F9B));
    box(x - .035, y + .65, -2.70, w + .07, .025, .045, const Color(0xFF8E9699));
  }

  void paint(Canvas canvas, Size size, RoomCamera camera) {
    Offset project(RoomPoint p) {
      final q = camera.project(p, size.width, size.height);
      return Offset(q.x, q.y);
    }

    for (final polygon in _tree.backToFront(camera.eye)) {
      final material = polygon.material;
      final path = Path()
        ..addPolygon([for (final p in polygon.points) project(p)], true);
      final paint = Paint()..color = material.color;
      if (material.endColor != null) {
        paint.shader = ui.Gradient.linear(
          project(material.gradientStart!),
          project(material.gradientEnd!),
          [material.color, material.endColor!],
        );
      }
      canvas.drawPath(path, paint);
      // Cover subpixel seams between adjacent opaque mesh fragments.
      if (material.color.a == 1 && material.endColor == null) {
        canvas.drawPath(
          path,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = .45
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }
}

/// Only the record and weather repaint continuously. No fake beat response.
class RoomLivingDetailsPainter extends CustomPainter {
  RoomLivingDetailsPainter({
    required this.camera,
    required this.settings,
    required this.record,
    required this.weather,
    required this.playing,
    required this.hasTrack,
  }) : super(repaint: Listenable.merge([record, weather]));
  final RoomCamera camera;
  final RoomSettings settings;
  final Animation<double> record;
  final Animation<double> weather;
  final bool playing;
  final bool hasTrack;

  @override
  void paint(Canvas canvas, Size size) {
    Offset point(RoomPoint p) {
      final q = camera.project(p, size.width, size.height);
      return Offset(q.x, q.y);
    }

    Path circle(double r) => Path()
      ..addPolygon([
        for (var i = 0; i < 44; i++)
          point(
            RoomPoint(
              RoomCamera.record.x + math.cos(i * math.pi / 22) * r,
              RoomCamera.record.y + .007,
              RoomCamera.record.z + math.sin(i * math.pi / 22) * r,
            ),
          ),
      ], true);
    canvas.drawPath(circle(.37), Paint()..color = const Color(0xFF151B23));
    for (var i = 0; i < 7; i++) {
      canvas.drawPath(
        circle(.15 + i * .029),
        Paint()
          ..color = const Color(0xFF424751)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .45,
      );
    }
    canvas.drawPath(circle(.115), Paint()..color = const Color(0xFFD4AE80));
    final angle = record.value * 2 * math.pi;
    canvas.drawLine(
      point(
        RoomPoint(
          RoomCamera.record.x + math.cos(angle) * .05,
          1.21,
          RoomCamera.record.z + math.sin(angle) * .05,
        ),
      ),
      point(
        RoomPoint(
          RoomCamera.record.x + math.cos(angle) * .10,
          1.21,
          RoomCamera.record.z + math.sin(angle) * .10,
        ),
      ),
      Paint()
        ..color = const Color(0xFF4D3C2F)
        ..strokeWidth = 1.3,
    );
    final led = point(const RoomPoint(.62, 1.21, -.96));
    canvas.drawCircle(
      led,
      1.5,
      Paint()
        ..color = hasTrack && playing
            ? const Color(0xFFDFCAA4)
            : const Color(0xFF58636A),
    );
    if (settings.mood.hasRain) {
      canvas.save();
      canvas.clipPath(
        Path()..addPolygon([
          point(const RoomPoint(-1.44, 1.68, -2.70)),
          point(const RoomPoint(2.60, 1.68, -2.70)),
          point(const RoomPoint(2.60, 3.60, -2.70)),
          point(const RoomPoint(-1.44, 3.60, -2.70)),
        ], true),
      );
      final count = settings.mood == RoomMood.lightRain ? 30 : 66;
      for (var i = 0; i < count; i++) {
        final x = -1.40 + (i * 67 % 399) / 100;
        final y = 1.68 + ((i * .17 + weather.value * 2.0) % 1.92);
        canvas.drawLine(
          point(RoomPoint(x, y, -2.69)),
          point(RoomPoint(x - .025, y - .10, -2.69)),
          Paint()
            ..color = const Color(0x66C5D9E8)
            ..strokeWidth = .65,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant RoomLivingDetailsPainter oldDelegate) =>
      oldDelegate.camera.orbit != camera.orbit ||
      oldDelegate.settings != settings ||
      oldDelegate.playing != playing ||
      oldDelegate.hasTrack != hasTrack;
}
