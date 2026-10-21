/// AUVORYN's on-device atmosphere preferences. These never depend on a server.
enum RoomMood {
  clearNight,
  lightRain,
  heavyRain,
  thunderstorm,
  warmSunset,
  quietMidnight;

  String get title => switch (this) {
        clearNight => 'Clear night',
        lightRain => 'Light rain',
        heavyRain => 'Heavy rain',
        thunderstorm => 'Thunderstorm',
        warmSunset => 'Warm sunset',
        quietMidnight => 'Quiet midnight',
      };

  String get description => switch (this) {
        clearNight => 'A sky full of stillness',
        lightRain => 'Soft reflections on the glass',
        heavyRain => 'Let the city disappear',
        thunderstorm => 'A dramatic night indoors',
        warmSunset => 'Last light over the skyline',
        quietMidnight => 'Just you and the city',
      };

  bool get hasRain => switch (this) {
        lightRain || heavyRain || thunderstorm => true,
        _ => false,
      };

  /// Original, bundled, offline-only looping soundscape for this visual mood.
  String get ambienceAsset => switch (this) {
        lightRain => 'ambience/light_rain.ogg',
        heavyRain => 'ambience/heavy_rain.ogg',
        thunderstorm => 'ambience/thunderstorm.ogg',
        _ => 'ambience/city_night.ogg',
      };
}

enum LampPalette {
  amber,
  rose,
  moonlight;

  String get title => switch (this) {
        amber => 'Amber',
        rose => 'Rose',
        moonlight => 'Moonlight',
      };
}

class RoomSettings {
  const RoomSettings({
    this.mood = RoomMood.quietMidnight,
    this.lampOn = true,
    this.reducedMotion = false,
    this.ambienceEnabled = false,
    this.ambienceVolume = 0.36,
    this.musicVolume = 1.0,
    this.lampPalette = LampPalette.amber,
    this.lampBrightness = 0.8,
  });

  final RoomMood mood;
  final bool lampOn;
  final bool reducedMotion;
  final bool ambienceEnabled;
  final double ambienceVolume;
  final double musicVolume;
  final LampPalette lampPalette;
  final double lampBrightness;

  RoomSettings copyWith({
    RoomMood? mood,
    bool? lampOn,
    bool? reducedMotion,
    bool? ambienceEnabled,
    double? ambienceVolume,
    double? musicVolume,
    LampPalette? lampPalette,
    double? lampBrightness,
  }) => RoomSettings(
        mood: mood ?? this.mood,
        lampOn: lampOn ?? this.lampOn,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        ambienceEnabled: ambienceEnabled ?? this.ambienceEnabled,
        ambienceVolume: (ambienceVolume ?? this.ambienceVolume).clamp(0.0, 1.0),
        musicVolume: (musicVolume ?? this.musicVolume).clamp(0.0, 1.0),
        lampPalette: lampPalette ?? this.lampPalette,
        lampBrightness: (lampBrightness ?? this.lampBrightness).clamp(0.0, 1.0),
      );

  Map<String, Object> toMap() => {
        'mood': mood.name,
        'lampOn': lampOn,
        'reducedMotion': reducedMotion,
        'ambienceEnabled': ambienceEnabled,
        'ambienceVolume': ambienceVolume,
        'musicVolume': musicVolume,
        'lampPalette': lampPalette.name,
        'lampBrightness': lampBrightness,
      };

  static double _volume(Object? raw, double fallback) {
    if (raw is! num) return fallback;
    final value = raw.toDouble();
    if (!value.isFinite) return fallback;
    return value.clamp(0.0, 1.0);
  }

  factory RoomSettings.fromMap(Map<String, Object?> values) {
    final mood = RoomMood.values.firstWhere(
      (value) => value.name == values['mood'],
      orElse: () => RoomMood.quietMidnight,
    );
    final palette = LampPalette.values.firstWhere(
      (value) => value.name == values['lampPalette'],
      orElse: () => LampPalette.amber,
    );
    return RoomSettings(
      mood: mood,
      lampOn: values['lampOn'] is bool ? values['lampOn']! as bool : true,
      reducedMotion: values['reducedMotion'] is bool
          ? values['reducedMotion']! as bool
          : false,
      ambienceEnabled: values['ambienceEnabled'] is bool
          ? values['ambienceEnabled']! as bool
          : false,
      ambienceVolume: _volume(values['ambienceVolume'], 0.36),
      musicVolume: _volume(values['musicVolume'], 1.0),
      lampPalette: palette,
      lampBrightness: _volume(values['lampBrightness'], 0.8),
    );
  }
}
