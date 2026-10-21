import 'dart:io';

import 'package:auvoryn/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Shows real imported art when available; otherwise a branded offline cover.
/// Image decoding is bounded to the displayed size to avoid large memory use.
class SongArtwork extends StatelessWidget {
  const SongArtwork({
    this.artworkPath,
    this.title = '',
    this.size = 54,
    this.radius = 14,
    super.key,
  });

  final String? artworkPath;
  final String title;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final side = size.round();
    return Semantics(
      image: true,
      label: artworkPath == null ? 'Artwork unavailable' : 'Album artwork for $title',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox.square(
          dimension: size,
          child: artworkPath == null
              ? const _ArtworkFallback()
              : Image.file(
                  File(artworkPath!),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  cacheWidth: (side * MediaQuery.devicePixelRatioOf(context))
                      .round().clamp(64, 1024),
                  errorBuilder: (_, _, _) => const _ArtworkFallback(),
                ),
        ),
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF634D57), AuvorynColors.raised, AuvorynColors.slate],
      ),
    ),
    child: Center(
      child: Icon(Icons.album_rounded, color: AuvorynColors.champagne, size: 26),
    ),
  );
}
