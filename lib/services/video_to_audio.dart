import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class VideoToAudio {
  static final YoutubeExplode _yt = YoutubeExplode();

  /// Attempts to get audio-only stream with retries, then falls back to muxed.
  static Future<String?> getAudioUrl(String videoUrl, {int retries = 3}) async {
    final videoId = VideoId(videoUrl);
    print("🔍 Extracted Video ID: $videoId");

    // Step 1: Try audio-only stream up to [retries] times
    for (int attempt = 0; attempt < retries; attempt++) {
      print("🔁 Attempt ${attempt + 1} to get audio-only stream...");

      try {
        final manifest = await _yt.videos.streamsClient.getManifest(videoId);
        print("📦 Manifest loaded.");

        final audioStreams = manifest.audioOnly;
        if (audioStreams.isNotEmpty) {
          final bestAudio = audioStreams.withHighestBitrate();
          if (bestAudio != null) {
            print("🎵 Using audio-only stream: ${bestAudio.url}");
            return bestAudio.url.toString();
          }
        }
      } catch (e) {
        print("❗ Error on audio-only attempt: $e");
      }

      await Future.delayed(Duration(seconds: 1));
    }

    // Step 2: Fallback — try muxed stream once
    print("🔁 Attempting fallback to muxed stream...");

    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      print("📦 Manifest loaded for muxed.");

      final muxedStreams = manifest.muxed;
      if (muxedStreams.isNotEmpty) {
        final bestMuxed = muxedStreams.withHighestBitrate();
        if (bestMuxed != null) {
          print("🎬 Fallback to muxed stream: ${bestMuxed.url}");
          return bestMuxed.url.toString();
        }
      }
    } catch (e) {
      print("❗ Error on muxed stream fallback: $e");
    }

    print("❌ No usable stream found for: $videoUrl");
    return null;
  }

  static void close() {
    _yt.close();
  }
}
