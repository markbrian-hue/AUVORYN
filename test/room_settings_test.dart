import 'package:auvoryn/core/settings/room_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to quiet midnight, lamp on and full motion', () {
    const settings = RoomSettings();
    expect(settings.mood, RoomMood.quietMidnight);
    expect(settings.lampOn, isTrue);
    expect(settings.reducedMotion, isFalse);
  });

  test('copyWith changes only the supplied field', () {
    const settings = RoomSettings();
    final changed = settings.copyWith(mood: RoomMood.heavyRain);
    expect(changed.mood, RoomMood.heavyRain);
    expect(changed.lampOn, isTrue);
    expect(changed.reducedMotion, isFalse);
  });

  test('roundtrip serializes values without losing preference fields', () {
    const settings = RoomSettings(
      mood: RoomMood.warmSunset,
      lampOn: false,
      reducedMotion: true,
    );
    final restored = RoomSettings.fromMap(settings.toMap());
    expect(restored.mood, settings.mood);
    expect(restored.lampOn, settings.lampOn);
    expect(restored.reducedMotion, settings.reducedMotion);
  });

  test('unknown saved mood falls back safely', () {
    final restored = RoomSettings.fromMap({'mood': 'no-longer-exists'});
    expect(restored.mood, RoomMood.quietMidnight);
    expect(restored.lampOn, isTrue);
  });
}
