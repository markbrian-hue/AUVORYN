import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

/// A pure-Dart parser isolates tag processing from the animation/UI isolate.
/// Corrupt or unsupported tags are not a reason to reject playable audio.
class MusicTagReader {
  const MusicTagReader._();

  static Future<MusicTags?> fromFile(String path) async {
    try {
      final map = await Isolate.run(() => _readTagMap(path));
      if (map == null) return null;
      return MusicTags(
        title: map['title'] as String?,
        artist: map['artist'] as String?,
        album: map['album'] as String?,
        picture: map['picture'] as Uint8List?,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, Object?>? _readTagMap(String path) {
    try {
      final metadata = readMetadata(File(path), getImage: true);
      final covers = metadata.pictures;
      final front = covers.where((picture) =>
        picture.pictureType == PictureType.coverFront);
      final picture = front.isNotEmpty ? front.first :
        (covers.isEmpty ? null : covers.first);
      // Covers over 8 MiB are skipped to avoid expensive decoding/caching.
      final bytes = picture?.bytes;
      return {
        'title': cleanTag(metadata.title),
        'artist': cleanTag(metadata.artist),
        'album': cleanTag(metadata.album),
        'picture': bytes != null && bytes.lengthInBytes <= 8 * 1024 * 1024
            ? bytes : null,
      };
    } catch (_) {
      return null;
    }
  }

  static String? cleanTag(String? text) {
    final cleaned = text?.replaceAll('\u0000', '').trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  /// Returns the extension based on an image's actual signature, never its
  /// untrusted metadata MIME string. Other bytes should not reach Image.file.
  static String? pictureExtension(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E &&
        bytes[3] == 0x47 && bytes[4] == 0x0D && bytes[5] == 0x0A &&
        bytes[6] == 0x1A && bytes[7] == 0x0A) {
      return 'png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'webp';
    }
    return null;
  }
}

class MusicTags {
  const MusicTags({this.title, this.artist, this.album, this.picture});
  final String? title;
  final String? artist;
  final String? album;
  final Uint8List? picture;
}
