/// Room settings stored on-device. No account or server is involved.
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
}

class RoomSettings {
  const RoomSettings({
    this.mood = RoomMood.quietMidnight,
    this.lampOn = true,
    this.reducedMotion = false,
  });

  final RoomMood mood;
  final bool lampOn;
  final bool reducedMotion;

  RoomSettings copyWith({
    RoomMood? mood,
    bool? lampOn,
    bool? reducedMotion,
  }) =>
      RoomSettings(
        mood: mood ?? this.mood,
        lampOn: lampOn ?? this.lampOn,
        reducedMotion: reducedMotion ?? this.reducedMotion,
      );

  Map<String, Object> toMap() => {
        'mood': mood.name,
        'lampOn': lampOn,
        'reducedMotion': reducedMotion,
      };

  factory RoomSettings.fromMap(Map<String, Object?> values) {
    final rawMood = values['mood'];
    final mood = RoomMood.values.firstWhere(
      (value) => value.name == rawMood,
      orElse: () => RoomMood.quietMidnight,
    );
    return RoomSettings(
      mood: mood,
      lampOn: values['lampOn'] is bool ? values['lampOn']! as bool : true,
      reducedMotion: values['reducedMotion'] is bool
          ? values['reducedMotion']! as bool
          : false,
    );
  }
}
