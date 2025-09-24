import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cool_music_player/services/audio_services.dart';

import '../Notifiers/download_notifier.dart';
import '../Notifiers/offlinesongs_notifier.dart';
import '../services/dowload_Service.dart';

class AudioPlayerScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    final audioPlayer = ref.watch(audioServiceProvider);
    final audioNotifier = ref.read(audioServiceProvider.notifier);
    final progress = ref.watch(downloadProgressProvider);
    final isDownloading = progress > 0 && progress < 1.0;

    if (track == null) {
      return Scaffold(
        appBar: AppBar(title: Text("No Track")),
        body: Center(child: Text("No track selected")),
      );
    }

    final bool isOnline = track.audioUrl.startsWith("http");

    return Scaffold(
      appBar: AppBar(title: Text("Now Playing")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: isOnline
                ? Image.network(
              track.thumbnailUrl,
              height: 250,
              width: 250,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.image),
            )
                : (File(track.thumbnailUrl).existsSync()
                ? Image.file(
              File(track.thumbnailUrl),
              height: 250,
              width: 250,
              fit: BoxFit.cover,
            )
                : Icon(Icons.music_note, size: 100)),
          ),
          SizedBox(height: 20),
          Text(
            track.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),

          // Progress Slider
          StreamBuilder<Duration>(
            stream: audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = audioPlayer.duration ?? Duration.zero;

              String formatDuration(Duration d) {
                final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
                final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
                return '$minutes:$seconds';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Slider(
                    min: 0,
                    max: duration.inSeconds.toDouble(),
                    value: position.inSeconds.clamp(0, duration.inSeconds).toDouble(),
                    onChanged: (value) {
                      audioNotifier.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDuration(position)),
                        Text(formatDuration(duration)),
                      ],
                    ),
                  ),

                  // Download button (only if online)
                  if (isOnline)
                    Row(
                      children: [
                        Spacer(),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isDownloading)
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 3,
                                ),
                              ),
                            IconButton(
                              icon: Icon(Icons.download_rounded),
                              onPressed: isDownloading
                                  ? null
                                  : () async {
                                final currentTrack = ref.read(currentTrackProvider);
                                if (currentTrack == null) return;

                                final success = await DownloadService.downloadAudio(
                                  ref: ref,
                                  audioUrl: currentTrack.audioUrl,
                                  thumbnailUrl: currentTrack.thumbnailUrl,
                                  title: currentTrack.title,
                                );

                                final message = success
                                    ? " Download complete!"
                                    : " Download failed.";
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(message)));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              );
            },
          ),

          // Playback Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous, size: 40),
                onPressed: () {
                  final songs = ref.read(offlineSongsProvider);
                  if (songs.isEmpty) return;

                  final currentTrack = ref.read(currentTrackProvider);
                  final isOnline = currentTrack?.audioUrl.startsWith("http") ?? false;

                  if (isOnline) {
                    // Switch cleanly to offline mode at index 0
                    ref.read(currentOfflineIndexProvider.notifier).state = 0;
                    final firstSong = songs[0];
                    ref.read(currentTrackProvider.notifier).state = firstSong;
                    ref.read(audioServiceProvider.notifier).playOffline(firstSong.audioUrl);
                    return;
                  }

                  // Normal offline navigation
                  final index = ref.read(currentOfflineIndexProvider);
                  if (index > 0) {
                    final newIndex = index - 1;
                    ref.read(currentOfflineIndexProvider.notifier).state = newIndex;

                    final newTrack = songs[newIndex];
                    ref.read(currentTrackProvider.notifier).state = newTrack;
                    ref.read(audioServiceProvider.notifier).playOffline(newTrack.audioUrl);
                  }
                }, // implement later
              ),
              StreamBuilder<PlayerState>(
                stream: audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final isPlaying = playerState?.playing ?? false;

                  return IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 50),
                    onPressed: () {
                      if (isPlaying) {
                        audioNotifier.pauseAudio();
                      } else {
                        audioNotifier.resumeAudio();
                      }
                    },
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.skip_next, size: 40),
                onPressed: () {
                  final songs = ref.read(offlineSongsProvider);
                  if (songs.isEmpty) return;

                  final currentTrack = ref.read(currentTrackProvider);
                  final isOnline = currentTrack?.audioUrl.startsWith("http") ?? false;

                  if (isOnline) {
                    // Switch to the first offline song
                    ref.read(currentOfflineIndexProvider.notifier).state = 0;
                    final firstSong = songs[0];
                    ref.read(currentTrackProvider.notifier).state = firstSong;
                    ref.read(audioServiceProvider.notifier).playOffline(firstSong.audioUrl);
                    return;
                  }

                  final index = ref.read(currentOfflineIndexProvider);
                  if (index < songs.length - 1) {
                    final newIndex = index + 1;
                    ref.read(currentOfflineIndexProvider.notifier).state = newIndex;

                    final newTrack = songs[newIndex];
                    ref.read(currentTrackProvider.notifier).state = newTrack;
                    ref.read(audioServiceProvider.notifier).playOffline(newTrack.audioUrl);
                  }
                }, // implement later
              ),
            ],
          ),
        ],
      ),
    );
  }
}
