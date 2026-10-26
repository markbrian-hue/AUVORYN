import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:auvoryn/features/companion/domain/room_companion.dart';
import 'package:auvoryn/features/companion/presentation/room_companion_mesh.dart';
import 'package:auvoryn/features/home_room/domain/room_camera.dart';
import 'package:auvoryn/features/home_room/presentation/room_diorama.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('characters are 3D surfaces with real depth and variable poses', () {
    for (final style in CompanionStyle.values) {
      for (final pose in CompanionPose.values) {
        final faces = <List<RoomPoint>>[];
        RoomCompanionMesh.build(
          RoomCompanion.forStyle(style, pose: pose),
          (points, color) {
            expect(points.length, greaterThanOrEqualTo(3));
            expect(color, isA<Color>());
            faces.add(points);
          },
        );
        expect(faces.length, greaterThan(100));
        final vertices = faces.expand((f) => f).toList();
        expect(vertices.every((v) => v.x.isFinite &&
            v.y.isFinite && v.z.isFinite), isTrue);
        final rangeX = vertices.map((v) => v.x).reduce(
          (a, b) => a > b ? a : b) - vertices.map((v) => v.x).reduce(
          (a, b) => a < b ? a : b);
        final rangeY = vertices.map((v) => v.y).reduce(
          (a, b) => a > b ? a : b) - vertices.map((v) => v.y).reduce(
          (a, b) => a < b ? a : b);
        final rangeZ = vertices.map((v) => v.z).reduce(
          (a, b) => a > b ? a : b) - vertices.map((v) => v.z).reduce(
          (a, b) => a < b ? a : b);
        // A flat sprite might have visible height/width but no z-volume.
        expect(rangeX, greaterThan(.4));
        expect(rangeY, greaterThan(1.4));
        expect(rangeZ, greaterThan(.35));
        for (final orbit in [0.0, .5, 1.0]) {
          final camera = RoomCamera(orbit: orbit);
          for (final v in vertices) {
            final q = camera.project(v, 360, 390);
            expect(q.x.isFinite && q.y.isFinite && q.depth > 1, isTrue);
          }
        }
      }
    }
  });

  test('disabled figure emits no meshes', () {
    var surfaces = 0;
    RoomCompanionMesh.build(
      const RoomCompanion(visible: false),
      (_, _) => surfaces++,
    );
    expect(surfaces, 0);
  });

  test('scene BSP constructs with a seated 3D figure among furniture', () {
    expect(() => RoomDioramaGeometry(
      const RoomSettings(reducedMotion: true),
      .6,
      companion: RoomCompanion.forStyle(CompanionStyle.girl),
    ), returnsNormally);
  });
}
