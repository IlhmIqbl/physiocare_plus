import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/utils/app_constants.dart';

const int _kBreakSeconds = 30;

class PlanPlayerScreen extends StatefulWidget {
  const PlanPlayerScreen({super.key});

  @override
  State<PlanPlayerScreen> createState() => _PlanPlayerScreenState();
}

class _PlanPlayerScreenState extends State<PlanPlayerScreen> {
  late List<ExerciseModel> _exercises;
  late String _planTitle;

  int _currentIndex = 0;

  // Exercise video
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitializing = false;

  // Break state
  bool _isOnBreak = false;
  int _breakRemaining = _kBreakSeconds;
  Timer? _breakTimer;

  bool _argsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsInitialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _exercises = List<ExerciseModel>.from(args['exercises'] as List);
      _planTitle = args['planTitle'] as String;
      _argsInitialized = true;
      _loadVideo();
    }
  }

  ExerciseModel get _current => _exercises[_currentIndex];

  // ── Video ────────────────────────────────────────────────────────────────

  Future<void> _loadVideo() async {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;

    final url = _current.videoUrl;
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
      debugPrint('Plan player video load failed: $e');
    }
    if (mounted) setState(() => _videoInitializing = false);
  }

  void _disposeVideo() {
    _chewieController?.dispose();
    _chewieController = null;
    _videoController?.dispose();
    _videoController = null;
  }

  // ── Break timer ──────────────────────────────────────────────────────────

  void _startBreak() {
    _videoController?.pause();
    setState(() {
      _isOnBreak = true;
      _breakRemaining = _kBreakSeconds;
    });
    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_breakRemaining <= 1) {
        _breakTimer?.cancel();
        _endBreak();
      } else {
        setState(() => _breakRemaining--);
      }
    });
  }

  void _endBreak() {
    setState(() {
      _isOnBreak = false;
      _currentIndex++;
    });
    _loadVideo();
  }

  void _skipBreak() {
    _breakTimer?.cancel();
    _endBreak();
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _goToNext() {
    if (_currentIndex < _exercises.length - 1) {
      _startBreak();
    } else {
      _onFinishPlan();
    }
  }

  void _goToPrev() {
    if (_isOnBreak) {
      // Cancel break, stay on current exercise
      _breakTimer?.cancel();
      setState(() => _isOnBreak = false);
      _videoController?.play();
      return;
    }
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _loadVideo();
    }
  }

  Future<void> _onFinishPlan() async {
    _disposeVideo();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Plan Complete!'),
        content: const Text(
            'Great work completing all exercises in your recovery plan.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back to Plan'),
          ),
        ],
      ),
    );
  }

  Future<void> _onPainPressed() async {
    _breakTimer?.cancel();
    _videoController?.pause();

    final shouldStop = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Feeling pain?'),
        content: const Text(
            'Listen to your body. Would you like to stop the plan and rest?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop Plan'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldStop == true) {
      Navigator.pop(context);
    } else if (_isOnBreak) {
      // Resume break timer
      _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_breakRemaining <= 1) {
          _breakTimer?.cancel();
          _endBreak();
        } else {
          setState(() => _breakRemaining--);
        }
      });
    } else {
      _videoController?.play();
    }
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    _disposeVideo();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return '$m min';
    return '${m}m ${s}s';
  }

  Color _difficultyColor(String d) {
    if (d == 'easy') return Colors.green.shade600;
    if (d == 'hard') return Colors.red.shade600;
    return Colors.orange.shade700;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_argsInitialized || _exercises.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Progress bar counts breaks as half-steps visually
    final planProgress = (_currentIndex + (_isOnBreak ? 0.5 : 0)) /
        _exercises.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_planTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: planProgress.clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 4,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onPainPressed,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label:
            const Text("I'm in pain", style: TextStyle(color: Colors.white)),
      ),
      body: _isOnBreak ? _buildBreakView() : _buildExerciseView(),
    );
  }

  // ── Break view ───────────────────────────────────────────────────────────

  Widget _buildBreakView() {
    final nextEx = _exercises[_currentIndex + 1];
    final breakProgress = 1.0 - (_breakRemaining / _kBreakSeconds);
    final isLow = _breakRemaining <= 5;

    return Column(
      children: [
        // Counter bar
        Container(
          color: const Color(0xFF00695C),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                'After exercise $_currentIndex of ${_exercises.length}',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13),
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: const Color(0xFFE0F2F1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rest icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.self_improvement,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Rest Time',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Breathe and prepare for the next exercise',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Countdown ring
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: breakProgress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white,
                        color: isLow ? Colors.red : AppColors.primary,
                      ),
                      Center(
                        child: Text(
                          '$_breakRemaining',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: isLow
                                ? Colors.red
                                : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Up next card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fitness_center,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Up next',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nextEx.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                              if (nextEx.duration > 0)
                                Text(
                                  _formatDuration(nextEx.duration),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _difficultyColor(nextEx.difficulty),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            nextEx.difficulty[0].toUpperCase() +
                                nextEx.difficulty.substring(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: const Text('Skip Rest'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _skipBreak,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Exercise view ────────────────────────────────────────────────────────

  Widget _buildExerciseView() {
    final ex = _current;
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _exercises.length - 1;

    return Column(
      children: [
        // Counter bar
        Container(
          color: AppColors.surface,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                'Exercise ${_currentIndex + 1} of ${_exercises.length}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _difficultyColor(ex.difficulty),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ex.difficulty[0].toUpperCase() +
                      ex.difficulty.substring(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // Video
        _buildVideoSection(),

        // Info + steps
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (ex.duration > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer,
                          size: 14,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(ex.duration),
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ],
                if (ex.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    ex.description,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.textSecondary),
                  ),
                ],
                if (ex.steps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Instructions',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  ...ex.steps.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(
                                top: 2, right: 10),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.description,
                              style: const TextStyle(
                                  fontSize: 14, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),

        // Navigation
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (!isFirst) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _goToPrev,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      isLast
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward,
                      size: 18,
                    ),
                    label: Text(isLast ? 'Finish Plan' : 'Next Exercise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _goToNext,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                'No video for this exercise',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
