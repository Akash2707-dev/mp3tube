import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cool_music_player/Notifiers/offlinesongs_notifier.dart';
import '../pages/Audio_Player.dart';
import 'package:cool_music_player/services/audio_services.dart';
import 'package:cool_music_player/Models/current_track.dart';

class OfflinePage extends ConsumerStatefulWidget {
  const OfflinePage({super.key});

  @override
  ConsumerState<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends ConsumerState<OfflinePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(offlineSongsProvider.notifier).loadSongs());
    ref.read(offlineSongsProvider.notifier).loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    final songs = ref.watch(offlineSongsProvider);

    return Scaffold(
      body: songs.isEmpty
          ? const Center(
        child: Text(
          "No offline songs yet.\nSave songs to view them here.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final CurrentTrack track = songs[index];

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                //  Update currentTrackProvider
                ref.read(currentTrackProvider.notifier).state =
                    CurrentTrack(
                      title: track.title,
                      thumbnailUrl: track.thumbnailUrl,
                      audioUrl: track.audioUrl, // local file path
                    );
                // ⚡️ Set the current index for skip logic
                ref.read(currentOfflineIndexProvider.notifier).state = index;

                //  Use playOffline to play local file
                await ref
                    .read(audioServiceProvider.notifier)
                    .playOffline(track.audioUrl);

                //  Navigate to AudioPlayerScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AudioPlayerScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  // Thumbnail (or music note if missing)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: track.thumbnailUrl.isNotEmpty &&
                        File(track.thumbnailUrl).existsSync()
                        ? Image.file(
                      File(track.thumbnailUrl),
                      width: 120,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 120,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.music_note,
                          size: 40, color: Colors.black54),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title + Local indicator
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Offline File",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
