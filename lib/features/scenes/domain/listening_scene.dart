import 'package:auvoryn/core/settings/room_settings.dart';

/// A named, locally stored snapshot of the room and its optional music link.
/// Applying a scene never changes the music queue or starts playback.
class ListeningScene {
  const ListeningScene({
    required this.id,
    required this.name,
    required this.room,
    this.playlistId,
    this.starter = false,
  });

  final String id;
  final String name;
  final RoomSettings room;
  final String? playlistId;
  final bool starter;

  ListeningScene copyWith({
    String? id,
    String? name,
    RoomSettings? room,
    String? playlistId,
    bool clearPlaylist = false,
    bool? starter,
  }) => ListeningScene(
        id: id ?? this.id,
        name: name ?? this.name,
        room: room ?? this.room,
        playlistId: clearPlaylist ? null : playlistId ?? this.playlistId,
        starter: starter ?? this.starter,
      );

  /// Reduced motion is a device accessibility preference, not a scene setting.
  RoomSettings applyTo(RoomSettings current) => current.copyWith(
        mood: room.mood,
        windowView: room.windowView,
        lampOn: room.lampOn,
        lampPalette: room.lampPalette,
        lampBrightness: room.lampBrightness,
        ambienceEnabled: room.ambienceEnabled,
        ambienceVolume: room.ambienceVolume,
        musicVolume: room.musicVolume,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'room': room.toMap(),
        'playlistId': playlistId,
      };

  factory ListeningScene.fromJson(Map<String, dynamic> raw) {
    final id = raw['id'];
    final name = raw['name'];
    final room = raw['room'];
    if (id is! String || id.isEmpty || name is! String ||
        name.trim().isEmpty || room is! Map) {
      throw const FormatException('Invalid saved listening scene.');
    }
    return ListeningScene(
      id: id,
      name: name.trim(),
      room: RoomSettings.fromMap(Map<String, Object?>.from(room)),
      playlistId: raw['playlistId'] is String
          ? raw['playlistId'] as String
          : null,
    );
  }

  /// Starter scenes are templates, not database entries. They remain available
  /// even when the user has no imported music or saved playlists.
  static const starters = <ListeningScene>[
    ListeningScene(
      id: 'starter-rainy-study',
      name: 'Rainy Study Night',
      room: RoomSettings(
        mood: RoomMood.lightRain,
        windowView: WindowView.skyline,
        lampPalette: LampPalette.amber,
        lampBrightness: .58,
        ambienceEnabled: true,
        ambienceVolume: .27,
      ),
      starter: true,
    ),
    ListeningScene(
      id: 'starter-sunday',
      name: 'Sunday Morning',
      room: RoomSettings(
        mood: RoomMood.warmSunset,
        windowView: WindowView.coast,
        lampPalette: LampPalette.rose,
        lampBrightness: .82,
        ambienceEnabled: false,
      ),
      starter: true,
    ),
    ListeningScene(
      id: 'starter-after-hours',
      name: 'After Hours',
      room: RoomSettings(
        mood: RoomMood.quietMidnight,
        windowView: WindowView.skyline,
        lampPalette: LampPalette.moonlight,
        lampBrightness: .35,
        ambienceEnabled: true,
        ambienceVolume: .16,
      ),
      starter: true,
    ),
  ];
}
