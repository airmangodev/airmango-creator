import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/media.dart';
import '../../core/theme/app_theme.dart';

class MediaViewer extends StatefulWidget {
  final Media media;

  const MediaViewer({super.key, required this.media});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.media.type == MediaType.video) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.file(File(widget.media.filePath));
    try {
      await _videoController!.initialize();
      setState(() {
        _isInitialized = true;
      });
      _videoController!.play();
      _videoController!.setLooping(true);
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Content
          Center(
            child: widget.media.type == MediaType.video
                ? _buildVideoPlayer()
                : _buildImageViewer(),
          ),

          // Header
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Metadata/Notes
          if (widget.media.note != null && widget.media.note!.isNotEmpty)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.media.note!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    return Hero(
      tag: 'media_${widget.media.id}',
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          File(widget.media.filePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_isInitialized) {
      return const CircularProgressIndicator(color: AppTheme.primary);
    }

    return Hero(
      tag: 'media_${widget.media.id}',
      child: GestureDetector(
        onTap: () {
          setState(() {
            _videoController!.value.isPlaying
                ? _videoController!.pause()
                : _videoController!.play();
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            if (!_videoController!.value.isPlaying)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
              ),
          ],
        ),
      ),
    );
  }
}
