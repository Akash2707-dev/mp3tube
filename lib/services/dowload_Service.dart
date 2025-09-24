import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../Notifiers/download_notifier.dart';

class DownloadService {
  /// Downloads audio (and thumbnail) with progress reporting to a Riverpod notifier.
  static Future<bool> downloadAudio({
    required WidgetRef ref,
    required String audioUrl,
    required String thumbnailUrl, // 👈 added thumbnail
    required String title,
  }) async {
    try {
      // Step 1: Permission handling
      final permissionGranted = await _requestStoragePermission();
      if (!permissionGranted) {
        print("❌ Storage permission denied.");
        return false;
      }

      // Step 2: Folder selection
      final String? selectedDirectory =
      await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        print("❌ Folder selection cancelled.");
        return false;
      }

      // Step 3: Prepare file paths
      final sanitizedTitle = _sanitizeFilename(title);
      final audioPath = "$selectedDirectory/$sanitizedTitle.m4a";
      final thumbnailPath = "$selectedDirectory/$sanitizedTitle.jpg";

      // Step 4: Start HTTP stream download (AUDIO)
      print("⬇️ Downloading audio from $audioUrl");
      final request = http.Request('GET', Uri.parse(audioUrl));
      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final file = File(audioPath);
        final sink = file.openWrite();

        final notifier = ref.read(downloadProgressProvider.notifier);
        notifier.reset();

        int received = 0;
        final total = response.contentLength ?? 0;

        await for (final chunk in response.stream) {
          received += chunk.length;
          sink.add(chunk);
          notifier.updateProgress(received, total);
        }

        await sink.flush();
        await sink.close();
        notifier.reset();

        print("✅ Audio download complete: $audioPath");

        // Step 5: Download THUMBNAIL
        try {
          print("⬇️ Downloading thumbnail from $thumbnailUrl");
          final thumbResponse = await http.get(Uri.parse(thumbnailUrl));
          if (thumbResponse.statusCode == 200) {
            final thumbFile = File(thumbnailPath);
            await thumbFile.writeAsBytes(thumbResponse.bodyBytes);
            print("✅ Thumbnail saved at $thumbnailPath");
          } else {
            print("⚠️ Failed to download thumbnail: HTTP ${thumbResponse.statusCode}");
          }
        } catch (e) {
          print("❗ Thumbnail download error: $e");
        }

        return true;
      } else {
        print("❌ Download failed. HTTP ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❗ Download error: $e");
      return false;
    }
  }

  /// Android storage permission handling
  static Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return false;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      final status = await Permission.audio.request();
      if (status.isPermanentlyDenied) await openAppSettings();
      return status.isGranted;
    } else {
      final status = await Permission.storage.request();
      if (status.isPermanentlyDenied) await openAppSettings();
      return status.isGranted;
    }
  }

  static String _sanitizeFilename(String input) {
    return input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
