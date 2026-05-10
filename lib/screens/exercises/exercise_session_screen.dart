import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/models/exercise_step_model.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/widgets/pain_stop_dialog.dart';
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

  int _currentStepIndex = 0;
  bool _isPauseBetweenSteps = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitializing = false;
  bool _videoEnded = false;

  bool _argsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsInitialized) {
      final args = ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
      _exercise = args['exercise'] as ExerciseModel;
      _sessionId = args['sessionId'] as String;
      _sessionStart = DateTime.now();
      _argsInitialized = true;
      if (_exercise.steps.isNotEmpty) _loadStep(0);
    }
  }

  ExerciseStep get _currentStep => _exercise.steps[_currentStepIndex];

  Future<void> _loadStep(int index) async {
    _disposeVideo();
    setState(() {
      _videoInitializing = true;
      _videoEnded = false;
      _countdownSeconds = 0;
    });
    _countdownTimer?.cancel();

    final step = _exercise.steps[index];
    if (step.videoUrl.isNotEmpty) {
      try {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(step.videoUrl));
        _videoController = controller;
        await controller.initialize();
        if (!mounted) return;
        _chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primaryDark,
            backgroundColor: Colors.grey.shade300,
            bufferedColor: const Color(0xFFe0f2f1),
          ),
        );
        controller.addListener(_onVideoUpdate);
      } catch (_) {}
    }

    if (mounted) setState(() => _videoInitializing = false);
  }

  void _onVideoUpdate() {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    if (!c.value.isPlaying &&
        c.value.duration > Duration.zero &&
        c.value.position >= c.value.duration) {
      c.removeListener(_onVideoUpdate);
      if (!_videoEnded) {
        setState(() => _videoEnded = true);
        _startCountdown();
      }
    }
  }

  void _startCountdown() {
    if (_isPauseBetweenSteps) return;
    setState(() => _countdownSeconds = 3);
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        t.cancel();
        setState(() => _countdownSeconds = 0);
        _advanceStep();
      }
    });
  }

  void _advanceStep() {
    _countdownTimer?.cancel();
    if (_currentStepIndex < _exercise.steps.length - 1) {
      setState(() => _currentStepIndex++);
      _loadStep(_currentStepIndex);
    } else {
      _completeSession();
    }
  }

  Future<void> _completeSession() async {
    _countdownTimer?.cancel();
    _disposeVideo();
    final elapsed =
        DateTime.now().difference(_sessionStart).inSeconds;
    final total = _exercise.steps.length;
    final progressProvider = context.read<ProgressProvider>();
    await progressProvider.completeSession(_sessionId, DateTime.now(), total);
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.sessionComplete,
        arguments: {
          'stepsCompleted': total,
          'totalSteps': total,
          'elapsedSeconds': elapsed,
          'exerciseTitle': _exercise.title,
        },
      );
    }
  }

  Future<void> _onPainPressed() async {
    _countdownTimer?.cancel();
    _videoController?.pause();

    final progressProvider = context.read<ProgressProvider>();

    final result = await showDialog<PainStopResult>(
      context: context,
      builder: (_) => const PainStopDialog(),
    );

    if (result == null || !result.shouldStop) {
      _videoController?.play();
      return;
    }

    await progressProvider.stopSession(
      sessionId: _sessionId,
      stepsCompleted: _currentStepIndex,
      totalSteps: _exercise.steps.length,
      painLevel: result.painLevel,
      painNote: result.painNote,
    );

    if (mounted) Navigator.pop(context);
  }

  void _disposeVideo() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_argsInitialized || _exercise.steps.isEmpty) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final total = _exercise.steps.length;
    final progress = ((_currentStepIndex + 1) / total).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              const Text('Pause between steps',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
              Switch(
                value: _isPauseBetweenSteps,
                activeThumbColor: Colors.white,
                onChanged: (v) =>
                    setState(() => _isPauseBetweenSteps = v),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onPainPressed,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text("I'm in pain",
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Step ${_currentStepIndex + 1} of $total',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          _buildVideoSection(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  color: AppColors.primary,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text('${(progress * 100).round()}% complete',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentStep.description,
                      style:
                          const TextStyle(fontSize: 16, height: 1.5)),
                  const SizedBox(height: 24),
                  if (_countdownSeconds > 0)
                    Center(
                      child: Text(
                        'Next step in $_countdownSeconds...',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  if ((_isPauseBetweenSteps && _videoEnded) ||
                      (_currentStep.videoUrl.isEmpty && !_videoInitializing))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                        ),
                        onPressed: _advanceStep,
                        child: Text(
                          _currentStepIndex < total - 1
                              ? 'Next Step'
                              : 'Finish',
                        ),
                      ),
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
          child: Icon(Icons.videocam_off,
              color: Colors.white70, size: 48),
        ),
      ),
    );
  }
}
