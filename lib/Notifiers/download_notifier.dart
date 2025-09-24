// download_progress_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadProgressNotifier extends StateNotifier<double> {
  DownloadProgressNotifier() : super(0.0);

  void updateProgress(int received, int total) {
    if (total == 0) return;
    state = received / total;
  }

  void reset() {
    state = 0.0;
  }
}

final downloadProgressProvider =
StateNotifierProvider<DownloadProgressNotifier, double>(
      (ref) => DownloadProgressNotifier(),
);
