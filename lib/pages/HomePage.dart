import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cool_music_player/services/api_services.dart';
import 'package:cool_music_player/services/video_to_audio.dart';
import 'package:cool_music_player/services/audio_services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cool_music_player/pages/Offline_page.dart';

import '../Models/current_track.dart';
import '../Widgets/draggable.dart';
import 'Audio_Player.dart';

class SearchPage extends ConsumerStatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> videos = [];
  int currentPage = 1;
  bool hasMore = false;
  bool isLoading = false;
  String currentQuery = "latest trending Songs";

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchVideos(); // Initial search
  }

  void _searchVideos({bool isNextPage = false}) async {
    if (!isNextPage) {
      currentPage = 1;
      videos.clear();
    }

    setState(() => isLoading = true);

    String query = _searchController.text.trim();
    if (query.isEmpty) query = "latest trending Songs";
    currentQuery = query;

    try {
      final response = await ApiService.searchVideos(query, currentPage);
      setState(() {
        videos.addAll(response['videos']);
        hasMore = response['has_more'];
        currentPage++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  String formatDuration(dynamic duration) {
    if (duration == null) return "Unknown";
    int seconds = duration.toInt();
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "$minutes min ${remainingSeconds}s";
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search videos",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(40)),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () => _searchVideos(),
                          ),
                        ),
                        onSubmitted: (_) => _searchVideos(),
                      ),
                    ),

                  ],
                ),
                if (currentQuery == "latest trending Songs")
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Popular Music",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: videos.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == videos.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _searchVideos(isNextPage: true),
                      child: Text("Load More"),
                    ),
                  ),
                );
              }

              final video = videos[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    String? audioUrl = await VideoToAudio.getAudioUrl(video['url']);

                    if (audioUrl != null) {
                      final audioNotifier = ref.read(audioServiceProvider.notifier);

                      ref.read(currentTrackProvider.notifier).state = CurrentTrack(
                        title: video['title'],
                        thumbnailUrl: video['thumbnail'],
                        audioUrl: audioUrl,
                      );

                      audioNotifier.playAudio(audioUrl);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerScreen(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to get audio link")),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          video['thumbnail'],
                          width: 120,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image_not_supported, size: 60),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title + Duration
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Duration: ${formatDuration(video['duration'])}",
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

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);
    final audioPlayer = ref.watch(audioServiceProvider);
    final audioNotifier = ref.read(audioServiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Mp3Tube'),
        centerTitle: true,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(themeModeProvider);
              final isDark = themeMode == ThemeMode.dark;

              return IconButton(
                icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                onPressed: () {
                  ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _selectedIndex == 0 ? _buildHomeTab() : OfflinePage(),
          if (currentTrack != null)
            DraggableMiniPlayer(track: currentTrack),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: "Offline"),
        ],
      ),
    );
  }
}
