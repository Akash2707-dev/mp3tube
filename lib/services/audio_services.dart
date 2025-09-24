import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cool_music_player/Models/current_track.dart';

class AudioServiceNotifier extends StateNotifier<AudioPlayer> {
  static final AudioPlayer _globalPlayer = AudioPlayer();

  AudioServiceNotifier() : super(_globalPlayer);

  Future<bool> playAudio(String audioUrl) async {
    try {
      if (state.playing) {
        await state.stop();
      }

      await state.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));

      // Start playing
      await state.play();

      // Wait until the player is actually playing or ready
      // Listen to the player state stream and wait for playing status or ready state
      await state.playerStateStream.firstWhere((playerState) =>
      playerState.playing == true ||
          playerState.processingState == ProcessingState.ready);

      return true;
    } catch (e) {
      print("Error playing audio: $e");
      return false;
    }
  }
  Future<bool> playOffline(String filePath) async {
    try {
      if (state.playing) {
        await state.stop();
      }

      if (!File(filePath).existsSync()) {
        throw Exception("File does not exist: $filePath");
      }

      await state.setAudioSource(AudioSource.uri(Uri.file(filePath)));
      await state.play();

      await state.playerStateStream.firstWhere((playerState) =>
      playerState.playing == true ||
          playerState.processingState == ProcessingState.ready);

      return true;
    } catch (e) {
      print("Error playing offline audio: $e");
      return false;
    }
  }

  void pauseAudio() => state.pause();
  void resumeAudio() => state.play();
  void stopAudio() => state.stop();

  void seek(Duration position) => state.seek(position);
}

// Riverpod provider
final audioServiceProvider = StateNotifierProvider<AudioServiceNotifier, AudioPlayer>(
      (ref) => AudioServiceNotifier(),
);
final currentTrackProvider = StateProvider<CurrentTrack?>((ref) => null);