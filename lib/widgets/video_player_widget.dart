import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.isNotEmpty) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitializing = true;
    });

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

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: const Color(0xFF00897B),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: const Color(0xFF00897B),
          child: const Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
}
