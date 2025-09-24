import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class CurrentTrack {
  final String title;
  final String thumbnailUrl;
  final String audioUrl;

  CurrentTrack({
    required this.title,
    required this.thumbnailUrl,
    required this.audioUrl,
  });
}

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final bubblePositionProvider = StateProvider<Offset>(
      (ref) => const Offset(16, 300),
);

// Is bubble currently being dragged?
final bubbleDraggingProvider = StateProvider<bool>(
      (ref) => false,
);