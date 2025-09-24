import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cool_music_player/pages/Audio_Player.dart';
import 'package:cool_music_player/services/audio_services.dart';
import 'package:cool_music_player/Models/current_track.dart';
import 'package:just_audio/just_audio.dart';

class DraggableMiniPlayer extends ConsumerStatefulWidget {
  final CurrentTrack track;
  const DraggableMiniPlayer({super.key, required this.track});

  @override
  ConsumerState<DraggableMiniPlayer> createState() => _DraggableMiniPlayerState();
}

class _DraggableMiniPlayerState extends ConsumerState<DraggableMiniPlayer> {
  Offset _pos = const Offset(16, 300);
  bool _dragging = false;
  bool _hasInitialized = false;

  static const double _bubbleSize = 64;
  static const double _padding = 16;
  static const double _deleteSize = 88;
  static const double _deleteBottomMargin = 32;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      final size = MediaQuery.of(context).size;
      _pos = Offset(
        _padding,
        size.height - _bubbleSize - 100,
      );
      _hasInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioNotifier = ref.read(audioServiceProvider.notifier);
    final player = ref.read(audioServiceProvider); // AudioPlayer instance

    return LayoutBuilder(
      builder: (context, constraints) {
        // delete target rectangle
        final Rect deleteRect = Rect.fromLTWH(
          (constraints.maxWidth - _deleteSize) / 2,
          constraints.maxHeight - _deleteSize - _deleteBottomMargin,
          _deleteSize,
          _deleteSize,
        );

        // bubble center to check overlap with delete rect
        final Offset bubbleCenter = Offset(
          _pos.dx + _bubbleSize / 2,
          _pos.dy + _bubbleSize / 2,
        );
        final bool overDelete = deleteRect.inflate(16).contains(bubbleCenter);

        return Stack(
          children: [
            // delete zone shown only while dragging
            if (_dragging)
              Positioned(
                left: deleteRect.left,
                top: deleteRect.top,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: _deleteSize,
                  width: _deleteSize,
                  decoration: BoxDecoration(
                    color: overDelete ? Colors.red : Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 12,
                        spreadRadius: 2,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.delete, color: Colors.white, size: 40),
                ),
              ),

            // draggable bubble
            Positioned(
              left: _pos.dx.clamp(_padding, constraints.maxWidth - _bubbleSize - _padding),
              top: _pos.dy.clamp(_padding, constraints.maxHeight - _bubbleSize - _padding),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => setState(() => _dragging = true),
                onPanUpdate: (details) {
                  final double maxX = constraints.maxWidth - _bubbleSize - _padding;
                  final double maxY = constraints.maxHeight - _bubbleSize - _padding;
                  final double minX = _padding;
                  final double minY = _padding;

                  setState(() {
                    _pos = Offset(
                      (_pos.dx + details.delta.dx).clamp(minX, maxX),
                      (_pos.dy + details.delta.dy).clamp(minY, maxY),
                    );
                  });
                },
                onPanEnd: (_) {
                  if (overDelete) {
                    // dropped on trash -> stop and clear
                    audioNotifier.stopAudio();
                    ref.read(currentTrackProvider.notifier).state = null;
                  } else {
                    // snap to left edge and clamp Y
                    final double maxY = constraints.maxHeight - _bubbleSize - _padding;
                    final double minY = _padding;
                    setState(() {
                      _pos = Offset(_padding, _pos.dy.clamp(minY, maxY));
                    });
                  }
                  setState(() => _dragging = false);
                },
                onTap: () async {
                  // toggle play/pause
                  final nowPlaying = ref.read(audioServiceProvider).playing;
                  if (nowPlaying) {
                    audioNotifier.pauseAudio();
                  } else {
                    audioNotifier.resumeAudio();
                  }
                },
                onLongPress: () {
                  // open full player
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AudioPlayerScreen()),
                  );
                },
                child: _buildBubble(context, player),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBubble(BuildContext context, AudioPlayer player) {
    // listen to the actual player stream for immediate icon updates
    return Material(
      elevation: 6,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.primary,
      child: SizedBox(
        height: _bubbleSize,
        width: _bubbleSize,
        child: Center(
          child: StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processing = playerState?.processingState;
              final isPlaying = playerState?.playing ?? false;

              if (processing == ProcessingState.loading ||
                  processing == ProcessingState.buffering) {
                return const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              }

              return Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32,
                color: Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }
}
