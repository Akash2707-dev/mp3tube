import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../Models/current_track.dart'; // make sure this path matches your project

class OfflineSongsNotifier extends StateNotifier<List<CurrentTrack>> {
  OfflineSongsNotifier() : super([]);

  Future<void> loadSongs() async {
    Directory? songsDir;

    if (Platform.isAndroid) {
      songsDir = Directory("/storage/emulated/0/Download/Songs");
    } else {
      // Fallback for iOS/macOS
      final dir = await getApplicationDocumentsDirectory();
      songsDir = Directory("${dir.path}/Songs");
    }

    if (await songsDir.exists()) {
      final files = songsDir.listSync();

      // Filter only audio files
      final audioFiles = files.where((f) =>
      f.path.endsWith(".m4a") || f.path.endsWith(".mp3"));

      final List<CurrentTrack> loadedSongs = [];

      for (final audio in audioFiles) {
        final fileName = audio.uri.pathSegments.last;
        final baseName = fileName.replaceAll(RegExp(r'\.(m4a|mp3)$'), "");

        // Look for a thumbnail with the same base name
        final thumbJpg = File("${songsDir.path}/$baseName.jpg");
        final thumbPng = File("${songsDir.path}/$baseName.png");

        String? thumbPath;
        if (thumbJpg.existsSync()) {
          thumbPath = thumbJpg.path;
        } else if (thumbPng.existsSync()) {
          thumbPath = thumbPng.path;
        }

        loadedSongs.add(
          CurrentTrack(
            title: baseName,
            thumbnailUrl: thumbPath ?? "", // empty string if no image
            audioUrl: audio.path,
          ),
        );
      }

      state = loadedSongs;
    } else {
      await songsDir.create(recursive: true);
      state = [];
    }
  }
}

final offlineSongsProvider =
StateNotifierProvider<OfflineSongsNotifier, List<CurrentTrack>>(
      (ref) => OfflineSongsNotifier(),
);

final currentOfflineIndexProvider = StateProvider<int>((ref) => 0);