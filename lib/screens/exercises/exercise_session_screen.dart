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
  Timer? _countdownTimer;

  // Video is loaded ONCE from exercise.videoUrl and loops throughout
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
      _sessionStart = DateTime.now();
      _argsInitialized = true;
      _initVideo();
    }
  }

  ExerciseStep get _currentStep => _exercise.steps[_currentStepIndex];

  /// Loads exercise.videoUrl once and loops it for the entire session.
  /// Never reloaded between steps — the video stays in place.
  Future<void> _initVideo() async {
    final url = _exercise.videoUrl;
    if (url.isEmpty) return;

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
    if (mounted) setState(() => _videoInitializing = false);
  }

  void _goToStep(int index) {
    _countdownTimer?.cancel();
    setState(() => _currentStepIndex = index);
    // Video keeps playing — no reload
  }

  void _advanceStep() {
    if (_currentStepIndex < _exercise.steps.length - 1) {
      _goToStep(_currentStepIndex + 1);
    } else {
      _completeSession();
    }
  }

  Future<void> _completeSession() async {
    _countdownTimer?.cancel();
    _disposeVideo();
    final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
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

    if (!mounted) return;

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final total = _exercise.steps.length;
    final progress = ((_currentStepIndex + 1) / total).clamp(0.0, 1.0);
    final isLastStep = _currentStepIndex == total - 1;

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
          // ── Video slot — loads once, loops throughout ──────────────────
          _buildVideoSection(),

          // ── Step header + progress ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step ${_currentStepIndex + 1} of $total',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${(progress * 100).round()}% complete',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: AppColors.primary,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // ── Step description ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                _currentStep.description,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ),
          ),

          // ── Navigation button (always visible) ────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _advanceStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isLastStep ? 'Finish' : 'Next Step',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
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
          child:
              const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
    if (_chewieController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: _chewieController!),
      );
    }
    // No video uploaded yet
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
