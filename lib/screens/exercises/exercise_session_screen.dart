import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/models/progress_model.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/widgets/pain_stop_dialog.dart';
import 'package:physiocare/widgets/exercise_review_dialog.dart';
import 'package:physiocare/utils/app_constants.dart';

class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({super.key});

  @override
  State<ExerciseSessionScreen> createState() =>
      _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  late ExerciseModel _exercise;
  late String _sessionId;
  late DateTime _sessionStart;
  int _initialPainLevel = 5;

  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  bool _isPaused = false;
  Timer? _timer;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitializing = false;

  bool _argsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsInitialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _exercise = args['exercise'] as ExerciseModel;
      _sessionId = args['sessionId'] as String;
      _initialPainLevel = (args['initialPainLevel'] as int?) ?? 5;
      _sessionStart = DateTime.now();
      _totalSeconds = _exercise.duration > 0 ? _exercise.duration : 0;
      _remainingSeconds = _totalSeconds;
      _argsInitialized = true;
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final url = _exercise.videoUrl;
    if (url.isEmpty) {
      if (_totalSeconds > 0) _startTimer();
      return;
    }

    setState(() => _videoInitializing = true);
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = controller;
      await controller.initialize();
      if (!mounted) return;
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: true,
        aspectRatio: 16 / 9,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primaryDark,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: const Color(0xFFe0f2f1),
        ),
      );
    } catch (e) {
      debugPrint('Exercise video failed to load: $e');
    }
    if (mounted) {
      setState(() => _videoInitializing = false);
      if (_totalSeconds > 0) _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        setState(() => _remainingSeconds = 0);
        _onTimerComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _togglePause() {
    if (_isPaused) {
      _videoController?.play();
      if (_remainingSeconds > 0) _startTimer();
      setState(() => _isPaused = false);
    } else {
      _timer?.cancel();
      _videoController?.pause();
      setState(() => _isPaused = true);
    }
  }

  Future<void> _onEndSessionPressed() async {
    _timer?.cancel();
    _videoController?.pause();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text(
            'Your progress so far will be saved. Are you sure you want to end this session?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false);
            },
            child: const Text('Continue'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      await _finishSession(null, null, ended: true);
    } else {
      if (!_isPaused) {
        _videoController?.play();
        if (_remainingSeconds > 0) _startTimer();
      }
    }
  }

  Future<void> _onTimerComplete() async {
    _videoController?.pause();
    final result = await showDialog<ExerciseReviewResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ExerciseReviewDialog(),
    );
    if (!mounted) return;
    await _finishSession(result?.painLevel, result?.painNote);
  }

  Future<void> _finishSession(int? painLevel, String? painNote,
      {bool ended = false}) async {
    _timer?.cancel();
    _disposeVideo();

    final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
    final progressProvider = context.read<ProgressProvider>();

    if (ended) {
      final elapsedSteps = _totalSeconds > 0 && _exercise.steps.isNotEmpty
          ? ((_totalSeconds - _remainingSeconds) /
                      _totalSeconds *
                      _exercise.steps.length)
                  .round()
                  .clamp(0, _exercise.steps.length)
          : 0;
      await progressProvider.stopSession(
        sessionId: _sessionId,
        stepsCompleted: elapsedSteps,
        totalSteps: _exercise.steps.length,
        painLevel: painLevel,
        painNote: painNote,
      );
    } else {
      await progressProvider.completeSession(
        _sessionId,
        DateTime.now(),
        _exercise.steps.length,
        painLevel: painLevel,
        painNote: painNote,
      );

      if (painLevel != null) {
        await progressProvider.saveProgress(ProgressModel(
          id: '',
          userId: progressProvider.userId ?? '',
          sessionId: _sessionId,
          painLevelBefore: _initialPainLevel,
          painLevelAfter: painLevel,
          notes: painNote,
          recordedAt: DateTime.now(),
        ));
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.sessionComplete,
        arguments: {
          'elapsedSeconds': elapsed,
          'exerciseTitle': _exercise.title,
          'durationSeconds': _totalSeconds,
        },
      );
    }
  }

  Future<void> _onPainPressed() async {
    _timer?.cancel();
    _videoController?.pause();
    setState(() => _isPaused = true);

    final progressProvider = context.read<ProgressProvider>();

    final result = await showDialog<PainStopResult>(
      context: context,
      builder: (_) => const PainStopDialog(),
    );

    if (!mounted) return;

    if (result == null || !result.shouldStop) {
      setState(() => _isPaused = false);
      _videoController?.play();
      if (_remainingSeconds > 0) _startTimer();
      return;
    }

    final elapsed = _totalSeconds - _remainingSeconds;
    final stoppedAt = _totalSeconds > 0 && _exercise.steps.isNotEmpty
        ? (elapsed / _totalSeconds * _exercise.steps.length)
            .round()
            .clamp(0, _exercise.steps.length)
        : 0;

    _disposeVideo();

    await progressProvider.stopSession(
      sessionId: _sessionId,
      stepsCompleted: stoppedAt,
      totalSteps: _exercise.steps.length,
      painLevel: result.painLevel,
      painNote: result.painNote,
    );

    if (mounted) Navigator.pop(context);
  }

  void _disposeVideo() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposeVideo();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (!_argsInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final timerProgress = _totalSeconds > 0
        ? 1.0 - (_remainingSeconds / _totalSeconds)
        : 0.0;
    final isLow = _remainingSeconds <= 10 && _remainingSeconds > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onPainPressed,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label:
            const Text("I'm in pain", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // ── Video — fixed at top ──────────────────────────────────────
          _buildVideoSection(),

          // ── Scrollable content below video ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timer or Finish button
                  _totalSeconds == 0
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _onTimerComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Finish Exercise',
                                style: TextStyle(fontSize: 16)),
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isPaused
                                          ? Icons.pause_circle
                                          : Icons.timer,
                                      color: isLow
                                          ? Colors.red
                                          : AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isPaused
                                          ? 'Paused'
                                          : 'Time Remaining',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                Text(
                                  _formatTime(_remainingSeconds),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: isLow
                                        ? Colors.red
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: timerProgress,
                              backgroundColor: Colors.grey.shade300,
                              color: isLow ? Colors.red : AppColors.primary,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),

                  const SizedBox(height: 12),

                  // ── Pause / End Session controls ───────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _totalSeconds > 0
                              ? _togglePause
                              : null,
                          icon: Icon(_isPaused
                              ? Icons.play_arrow
                              : Icons.pause),
                          label: Text(_isPaused ? 'Resume' : 'Pause'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _onEndSessionPressed,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('End Session'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Steps section ──────────────────────────────────
                  if (_exercise.steps.isNotEmpty) ...[
                    const Text(
                      'Steps',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ..._exercise.steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              margin:
                                  const EdgeInsets.only(top: 2, right: 10),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                step.description,
                                style: const TextStyle(
                                    fontSize: 15, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else
                    const Center(
                      child: Text('No instructions provided.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    if (_videoInitializing) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.primary,
          child: const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
    if (_chewieController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: _chewieController!),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: const Color(0xFF004D40),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, color: Colors.white70, size: 48),
              SizedBox(height: 8),
              Text(
                'No video uploaded yet',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
