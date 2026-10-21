import 'dart:math' as math;

/// Small, dependency-free perspective camera shared by drawing and hit targets.
/// Coordinates use metres: x right, y up, z toward the open side of the room.
class RoomPoint {
  const RoomPoint(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

class RoomProjection {
  const RoomProjection(this.x, this.y, this.depth);
  final double x;
  final double y;
  final double depth;
}

class RoomCamera {
  const RoomCamera({this.orbit = .5});
  final double orbit;

  RoomProjection project(RoomPoint point, double width, double height) {
    final yaw = .12 + orbit.clamp(0.0, 1.0) * .60;
    const pitch = .36;
    final x = point.x * math.cos(yaw) - point.z * math.sin(yaw);
    final z = point.x * math.sin(yaw) + point.z * math.cos(yaw);
    final y = point.y - 1.45;
    final vertical = y * math.cos(pitch) - z * math.sin(pitch);
    final depth = 13 - y * math.sin(pitch) - z * math.cos(pitch);
    // All authored vertices remain well in front of the near plane.
    final scale = math.min(width, height) * 1.30 / depth.clamp(1.0, 30.0);
    return RoomProjection(
      width * .5 + x * scale,
      height * .49 - vertical * scale,
      depth,
    );
  }

  static const record = RoomPoint(.15, 1.2, -1.25);
  static const speaker = RoomPoint(-1.02, 1.48, -.98);
  static const window = RoomPoint(.85, 2.75, -2.72);
  static const lamp = RoomPoint(2.3, 2.25, .25);
  static const shelf = RoomPoint(-2.35, 1.6, -2.15);
}
