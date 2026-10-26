import 'dart:math' as math;

import 'package:auvoryn/features/companion/domain/room_companion.dart';
import 'package:auvoryn/features/home_room/domain/room_camera.dart';
import 'package:flutter/material.dart';

/// Each surface is inserted into the apartment's existing BSP, so the person
/// rotates in real 3D and is depth-ordered with furniture and walls.
typedef CompanionSurface = void Function(List<RoomPoint> points, Color color);

class RoomCompanionMesh {
  RoomCompanionMesh._();

  static void build(RoomCompanion companion, CompanionSurface addSurface) {
    if (!companion.visible) return;

    final mesh = _Builder(addSurface);
    final seated = companion.pose == CompanionPose.sofa;
    final origin = switch (companion.pose) {
      CompanionPose.sofa => const _Vec(-1.94, 0, .87),
      CompanionPose.standing => const _Vec(1.40, 0, 1.76),
      CompanionPose.window => const _Vec(1.92, 0, -1.38),
    };
    _Vec p(double x, double y, double z) =>
        _Vec(origin.x + x, y, origin.z + z);

    final complexion = switch (companion.skin) {
      CompanionSkin.light => const Color(0xFFE5BFA7),
      CompanionSkin.warm => const Color(0xFFB98566),
      CompanionSkin.deep => const Color(0xFF825641),
    };
    final sweater = switch (companion.outfit) {
      CompanionOutfit.oatmeal => const Color(0xFFC0AC93),
      CompanionOutfit.sage => const Color(0xFF80958A),
      CompanionOutfit.charcoal => const Color(0xFF3C424B),
      CompanionOutfit.plum => const Color(0xFF765463),
    };
    final isEmo = companion.style == CompanionStyle.emoBoy ||
        companion.style == CompanionStyle.emoGirl;
    final pants = isEmo
        ? const Color(0xFF282C34) : const Color(0xFF4A535A);
    final hair = switch (companion.style) {
      CompanionStyle.boy => const Color(0xFF392D29),
      CompanionStyle.girl => const Color(0xFF513B34),
      CompanionStyle.emoBoy || CompanionStyle.emoGirl =>
        const Color(0xFF212027),
    };

    final hipY = seated ? .94 : .96;
    final shoulderY = seated ? 1.44 : 1.45;
    final headY = seated ? 1.70 : 1.72;

    // Soft planar floor shadows are included in the same perspective scene.
    mesh.shadow(p(0, .025, seated ? .57 : .04),
        seated ? .48 : .37);

    if (seated) {
      // Hips on the sofa, bent knees forward, legs descending to the floor.
      mesh.ellipsoid(p(0, .88, .08), const _Vec(.24, .15, .21), pants);
      for (final sign in [-1.0, 1.0]) {
        mesh.limb(p(sign * .13, .87, .05),
            p(sign * .16, .66, .51), .115, pants);
        mesh.limb(p(sign * .16, .66, .51),
            p(sign * .18, .14, .64), .085, pants);
        mesh.ellipsoid(p(sign * .18, .10, .76),
            const _Vec(.12, .09, .21), const Color(0xFF32343A));
      }
    } else {
      mesh.ellipsoid(p(0, hipY, 0), const _Vec(.23, .15, .17), pants);
      for (final sign in [-1.0, 1.0]) {
        mesh.limb(p(sign * .13, .92, 0),
            p(sign * .14, .53, .02), .115, pants);
        mesh.limb(p(sign * .14, .53, .02),
            p(sign * .15, .13, .07), .09, pants);
        mesh.ellipsoid(p(sign * .15, .09, .16),
            const _Vec(.12, .085, .21), const Color(0xFF32343A));
      }
    }

    // Anatomical, shaded 3D volumes rather than an image billboard.
    mesh.ellipsoid(p(0, 1.20, 0),
        const _Vec(.30, .35, .18), sweater);
    mesh.ellipsoid(p(0, hipY, 0),
        const _Vec(.24, .10, .16),
        Color.lerp(sweater, Colors.black, .13)!);

    for (final sign in [-1.0, 1.0]) {
      if (seated) {
        mesh.limb(p(sign * .27, shoulderY - .06, 0),
            p(sign * .33, 1.12, .16), .103, sweater);
        mesh.limb(p(sign * .33, 1.12, .16),
            p(sign * .18, .96, .36), .084, sweater);
        mesh.ellipsoid(p(sign * .18, .94, .38),
            const _Vec(.065, .095, .07), complexion);
      } else {
        mesh.limb(p(sign * .27, shoulderY - .06, 0),
            p(sign * .32, 1.10, .01), .104, sweater);
        mesh.limb(p(sign * .32, 1.10, .01),
            p(sign * .32, .83, .09), .082, sweater);
        mesh.ellipsoid(p(sign * .32, .78, .10),
            const _Vec(.065, .10, .067), complexion);
      }
    }

    // Collar and head have actual z-depth, including nose and facial planes.
    mesh.ellipsoid(p(0, 1.52, 0), const _Vec(.095, .10, .10),
        Color.lerp(sweater, Colors.black, .19)!);
    mesh.ellipsoid(p(0, 1.55, .012),
        const _Vec(.075, .115, .077), complexion);
    mesh.ellipsoid(p(0, headY, .013),
        const _Vec(.173, .225, .165), complexion);
    mesh.ellipsoid(p(0, headY - .036, .175),
        const _Vec(.035, .041, .045),
        Color.lerp(complexion, const Color(0xFFFFD9BF), .06)!);

    final ink = Color.lerp(hair, Colors.black, .45)!;
    for (final sign in [-1.0, 1.0]) {
      mesh.ellipsoid(p(sign * .075, headY + .027, .169),
          const _Vec(.023, .013, .012), ink, bands: 3, slices: 7);
      mesh.ellipsoid(p(sign * .078, headY + .078, .164),
          const _Vec(.055, .012, .012), hair, bands: 3, slices: 7);
    }
    mesh.ellipsoid(p(0, headY - .109, .165),
        const _Vec(.047, .011, .008),
        Color.lerp(complexion, const Color(0xFF6A373D), .52)!,
        bands: 3, slices: 7);

    // Scalp, side locks and an optional volumetric fringe.
    mesh.ellipsoid(p(0, headY + .138, -.005),
        const _Vec(.187, .137, .184), hair);
    if (companion.hair == CompanionHair.long ||
        companion.hair == CompanionHair.waves) {
      for (final sign in [-1.0, 1.0]) {
        mesh.limb(p(sign * .155, headY + .07, -.055),
            p(sign * .183, headY - .32, -.065),
            companion.hair == CompanionHair.waves ? .105 : .087, hair);
      }
    }
    if (companion.hair == CompanionHair.fringe) {
      mesh.limb(p(-.10, headY + .18, .133),
          p(.068, headY + .005, .172), .065, hair);
      mesh.limb(p(.08, headY + .20, .120),
          p(.137, headY + .03, .15), .053, hair);
    } else if (companion.hair == CompanionHair.cropped) {
      mesh.ellipsoid(p(0, headY + .171, .028),
          const _Vec(.169, .073, .139), hair);
    }
    if (isEmo) {
      // Headphone cups are separate, shaded solids attached to the head.
      for (final sign in [-1.0, 1.0]) {
        mesh.ellipsoid(p(sign * .185, headY + .005, .005),
            const _Vec(.05, .105, .072),
            const Color(0xFF30343D));
      }
    }
  }
}

class _Vec {
  const _Vec(this.x, this.y, this.z);
  final double x, y, z;
  _Vec operator +(_Vec o) => _Vec(x + o.x, y + o.y, z + o.z);
  _Vec operator -(_Vec o) => _Vec(x - o.x, y - o.y, z - o.z);
  _Vec operator *(double d) => _Vec(x * d, y * d, z * d);
  double dot(_Vec o) => x * o.x + y * o.y + z * o.z;
  _Vec cross(_Vec o) =>
      _Vec(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(dot(this));
  _Vec get normal => length < 1e-7
      ? const _Vec(0, 1, 0) : this * (1 / length);
  RoomPoint get point => RoomPoint(x, y, z);
}

class _Builder {
  const _Builder(this.addSurface);
  final CompanionSurface addSurface;
  static final light = const _Vec(-.45, .80, 1).normal;

  void face(List<_Vec> corners, Color color) {
    // Physically consistent directional diffuse lighting across facets.
    final normal = (corners[1] - corners[0])
        .cross(corners[2] - corners[0]).normal;
    final brightness = .73 + math.max(0.0, normal.dot(light)) * .32;
    final shaded = brightness >= 1
        ? Color.lerp(color, Colors.white, (brightness - 1) * .23)!
        : Color.lerp(color, Colors.black, 1 - brightness)!;
    addSurface([for (final corner in corners) corner.point], shaded);
  }

  void shadow(_Vec center, double radius) {
    addSurface([
      for (var i = 0; i < 14; i++)
        _Vec(center.x + radius * math.cos(i * math.pi / 7),
            center.y, center.z + radius * .54 * math.sin(i * math.pi / 7)).point,
    ], const Color(0x66171A1E));
  }

  void ellipsoid(
    _Vec center,
    _Vec radius,
    Color color, {
    int slices = 9,
    int bands = 5,
  }) {
    for (var row = 0; row < bands; row++) {
      final t0 = -math.pi / 2 + math.pi * row / bands;
      final t1 = -math.pi / 2 + math.pi * (row + 1) / bands;
      for (var s = 0; s < slices; s++) {
        final a0 = 2 * math.pi * s / slices;
        final a1 = 2 * math.pi * (s + 1) / slices;
        _Vec sample(double t, double a) => _Vec(
          center.x + radius.x * math.cos(t) * math.cos(a),
          center.y + radius.y * math.sin(t),
          center.z + radius.z * math.cos(t) * math.sin(a),
        );
        face([
          sample(t0, a0), sample(t0, a1),
          sample(t1, a1), sample(t1, a0),
        ], color);
      }
    }
  }

  void limb(_Vec start, _Vec end, double radius, Color color) {
    final axis = (end - start).normal;
    final guide = axis.y.abs() > .85
        ? const _Vec(0, 0, 1) : const _Vec(0, 1, 0);
    final side = axis.cross(guide).normal;
    final forward = axis.cross(side).normal;
    final center = (start + end) * .5;
    final half = (end - start).length * .5 + radius * .40;
    // Mesh the limb as a capsule-like oriented ellipsoid; unlike a billboard,
    // near/far surfaces separate correctly as the room camera rotates.
    const bands = 4, slices = 8;
    for (var row = 0; row < bands; row++) {
      final t0 = -math.pi / 2 + math.pi * row / bands;
      final t1 = -math.pi / 2 + math.pi * (row + 1) / bands;
      for (var i = 0; i < slices; i++) {
        final a0 = math.pi * 2 * i / slices;
        final a1 = math.pi * 2 * (i + 1) / slices;
        _Vec sample(double t, double a) =>
            center + axis * (half * math.sin(t)) +
            side * (radius * math.cos(t) * math.cos(a)) +
            forward * (radius * math.cos(t) * math.sin(a));
        face([sample(t0, a0), sample(t0, a1),
            sample(t1, a1), sample(t1, a0)], color);
      }
    }
  }
}
