import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/widgets/video_player_widget.dart';
import 'package:physiocare/widgets/session_timer.dart';
import 'package:physiocare/utils/app_constants.dart';

class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({super.key});

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  late ExerciseModel _exercise;
  late String _sessionId;

  int _secondsRemaining = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _timer;

  int _restSeconds = 0;
  bool _isResting = false;

  bool _argsInitialized = false;

  void _initArgs() {
    if (_argsInitialized) return;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _exercise = args['exercise'] as ExerciseModel;
    _sessionId = args['sessionId'] as String;
    _secondsRemaining = _exercise.duration;
    _argsInitialized = true;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
          _completeSession();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _startTimer();
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    _timer = null;

    final progressProvider = context.read<ProgressProvider>();
    await progressProvider.completeSession(_sessionId, DateTime.now());

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.painLog,
        arguments: {
          'sessionId': _sessionId,
          'exercise': _exercise,
        },
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initArgs();

    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Video player
            VideoPlayerWidget(videoUrl: _exercise.videoUrl),
            const SizedBox(height: 24),

            // Timer section
            if (_isResting) ...[
              Text(
                'Rest Time',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              SessionTimer(
                secondsRemaining: _restSeconds,
                totalSeconds: 30,
              ),
            ] else
              SessionTimer(
                secondsRemaining: _secondsRemaining,
                totalSeconds: _exercise.duration,
              ),

            const SizedBox(height: 24),

            // Control buttons
            if (!_isRunning && !_isPaused)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      _isRunning = true;
                    });
                    _startTimer();
                  },
                  child: const Text(
                    'Start',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else if (_isRunning)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _pauseTimer,
                      child: const Text(
                        'Pause',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _completeSession,
                      child: const Text(
                        'Complete',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              )
            else if (_isPaused)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _resumeTimer,
                  child: const Text(
                    'Resume',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Steps count
            Text(
              '${_exercise.steps.length} steps',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
