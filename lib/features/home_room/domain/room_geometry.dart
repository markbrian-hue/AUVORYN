import 'dart:math' as math;

import 'room_camera.dart';

/// A convex planar surface. Material data remains attached when it is split.
class RoomPolygon<T> {
  const RoomPolygon(this.points, this.material);
  final List<RoomPoint> points;
  final T material;
}

/// A cached binary-space partition: crossing surfaces are split before ordering.
/// Average-distance sorting cannot correctly resolve a wall, shelf and floor
/// whose projected bounds overlap. This tree orders their actual planes instead.
class RoomBsp<T> {
  RoomBsp(List<RoomPolygon<T>> polygons) : _root = _BspNode.build<T>(polygons);
  final _BspNode<T>? _root;
  Iterable<RoomPolygon<T>> backToFront(RoomPoint eye) sync* {
    if (_root != null) {
      yield* _root.order(eye);
    }
  }
}

class _Plane {
  const _Plane(this.x, this.y, this.z, this.distance);
  final double x, y, z, distance;
  double side(RoomPoint p) => x * p.x + y * p.y + z * p.z - distance;
  static _Plane? from<T>(RoomPolygon<T> polygon) {
    final p = polygon.points;
    if (p.length < 3) {
      return null;
    }
    for (var i = 1; i < p.length - 1; i++) {
      final ax = p[i].x - p[0].x, ay = p[i].y - p[0].y, az = p[i].z - p[0].z;
      final bx = p[i + 1].x - p[0].x,
          by = p[i + 1].y - p[0].y,
          bz = p[i + 1].z - p[0].z;
      final nx = ay * bz - az * by,
          ny = az * bx - ax * bz,
          nz = ax * by - ay * bx;
      final length = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (length > 1e-10) {
        return _Plane(
          nx / length,
          ny / length,
          nz / length,
          (nx * p[0].x + ny * p[0].y + nz * p[0].z) / length,
        );
      }
    }
    return null;
  }
}

class _BspNode<T> {
  _BspNode(this.plane, this.coplanar, this.front, this.back);
  final _Plane plane;
  final List<RoomPolygon<T>> coplanar;
  final _BspNode<T>? front, back;
  static const epsilon = 1e-6;

  static _BspNode<T>? build<T>(List<RoomPolygon<T>> polygons) {
    if (polygons.isEmpty) {
      return null;
    }
    _Plane? plane;
    for (final polygon in polygons) {
      plane = _Plane.from(polygon);
      if (plane != null) {
        break;
      }
    }
    if (plane == null) {
      return null;
    }
    final front = <RoomPolygon<T>>[],
        back = <RoomPolygon<T>>[],
        coplanar = <RoomPolygon<T>>[];
    for (final polygon in polygons) {
      final distances = [for (final p in polygon.points) plane.side(p)];
      final positive = distances.any((d) => d > epsilon);
      final negative = distances.any((d) => d < -epsilon);
      if (!positive && !negative) {
        coplanar.add(polygon);
      } else if (!negative) {
        front.add(polygon);
      } else if (!positive) {
        back.add(polygon);
      } else {
        final f = <RoomPoint>[], b = <RoomPoint>[];
        for (var i = 0; i < polygon.points.length; i++) {
          final j = (i + 1) % polygon.points.length;
          final a = polygon.points[i], next = polygon.points[j];
          final da = distances[i], db = distances[j];
          if (da >= -epsilon) {
            f.add(a);
          }
          if (da <= epsilon) {
            b.add(a);
          }
          if ((da > epsilon && db < -epsilon) ||
              (da < -epsilon && db > epsilon)) {
            final t = da / (da - db);
            final split = RoomPoint(
              a.x + (next.x - a.x) * t,
              a.y + (next.y - a.y) * t,
              a.z + (next.z - a.z) * t,
            );
            f.add(split);
            b.add(split);
          }
        }
        if (f.length >= 3) {
          front.add(RoomPolygon(f, polygon.material));
        }
        if (b.length >= 3) {
          back.add(RoomPolygon(b, polygon.material));
        }
      }
    }
    return _BspNode(plane, coplanar, build(front), build(back));
  }

  Iterable<RoomPolygon<T>> order(RoomPoint eye) sync* {
    final near = plane.side(eye) >= 0 ? front : back;
    final far = plane.side(eye) >= 0 ? back : front;
    if (far != null) {
      yield* far.order(eye);
    }
    yield* coplanar;
    if (near != null) {
      yield* near.order(eye);
    }
  }
}
