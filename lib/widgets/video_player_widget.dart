import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isInitializing = false;

  static String? _extractYouTubeId(String url) {
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final isYouTube = _extractYouTubeId(widget.videoUrl) != null;
    if (!isYouTube && widget.videoUrl.isNotEmpty) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() => _isInitializing = true);
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _controller = controller;
      await controller.initialize();
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF00897B),
          handleColor: const Color(0xFF004D40),
          backgroundColor: Colors.grey.shade300,
          bufferedColor: const Color(0xFFe0f2f1),
        ),
      );
    } catch (_) {}
    if (mounted) setState(() => _isInitializing = false);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl.isEmpty) return const _Placeholder();

    final youtubeId = _extractYouTubeId(widget.videoUrl);
    if (youtubeId != null) {
      return _YouTubeThumbnail(videoUrl: widget.videoUrl, youtubeId: youtubeId);
    }

    if (_isInitializing) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: const Color(0xFF00897B),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const _Placeholder();
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
}

class _YouTubeThumbnail extends StatelessWidget {
  const _YouTubeThumbnail({required this.videoUrl, required this.youtubeId});

  final String videoUrl;
  final String youtubeId;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse(videoUrl),
          mode: LaunchMode.externalApplication,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF00897B)),
            ),
            Container(color: Colors.black.withValues(alpha: 0.3)),
            const Center(
              child: Icon(Icons.play_circle_fill, size: 72, color: Colors.white),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Watch on YouTube',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: const Color(0xFF00897B),
        child: const Center(
          child:
              Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
        ),
      ),
    );
  }
}
