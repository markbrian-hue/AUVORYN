import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ambience stays opt-in for old saved settings', () {
    final previous = RoomSettings.fromMap({
      'mood': 'heavyRain', 'lampOn': false, 'reducedMotion': true,
    });
    expect(previous.mood, RoomMood.heavyRain);
    expect(previous.ambienceEnabled, isFalse);
    expect(previous.ambienceVolume, .36);
    expect(previous.musicVolume, 1.0);
    expect(previous.lampPalette, LampPalette.amber);
    expect(previous.lampBrightness, .8);
  });

  test('new audio and lighting settings round-trip', () {
    const settings = RoomSettings(
      mood: RoomMood.lightRain, ambienceEnabled: true,
      ambienceVolume: .21, musicVolume: .87,
      lampPalette: LampPalette.moonlight, lampBrightness: .53,
      lampOn: true, reducedMotion: true,
    );
    final restored = RoomSettings.fromMap(settings.toMap());
    expect(restored.mood, settings.mood);
    expect(restored.ambienceEnabled, settings.ambienceEnabled);
    expect(restored.ambienceVolume, settings.ambienceVolume);
    expect(restored.musicVolume, settings.musicVolume);
    expect(restored.lampPalette, settings.lampPalette);
    expect(restored.lampBrightness, settings.lampBrightness);
    expect(restored.reducedMotion, isTrue);
  });

  test('volumes are bounded even if saved state is corrupt', () {
    final settings = RoomSettings.fromMap({
      'musicVolume': -2,
      'ambienceVolume': 9,
      'lampBrightness': double.nan,
      'lampPalette': 'unknown',
      'ambienceEnabled': 'yes',
    });
    expect(settings.musicVolume, 0);
    expect(settings.ambienceVolume, 1);
    expect(settings.lampBrightness, .8);
    expect(settings.lampPalette, LampPalette.amber);
    expect(settings.ambienceEnabled, isFalse);
    expect(const RoomSettings().copyWith(musicVolume: 3).musicVolume, 1);
  });

  test('weather presets map to actual bundled offline sound files', () {
    expect(RoomMood.lightRain.ambienceAsset, 'ambience/light_rain.ogg');
    expect(RoomMood.heavyRain.ambienceAsset, 'ambience/heavy_rain.ogg');
    expect(RoomMood.thunderstorm.ambienceAsset, 'ambience/thunderstorm.ogg');
    expect(RoomMood.quietMidnight.ambienceAsset, 'ambience/city_night.ogg');
    expect(RoomMood.warmSunset.ambienceAsset, 'ambience/city_night.ogg');
  });
}
