import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/models/session_model.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/widgets/video_player_widget.dart';
import 'package:physiocare/widgets/pain_slider.dart';
import 'package:physiocare/utils/app_constants.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _isStarting = false;

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<int?> _askInitialPainLevel() async {
    double painValue = 5.0;
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Before you start'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rate your current pain level:'),
              const SizedBox(height: 12),
              PainSlider(
                value: painValue,
                onChanged: (v) => setDialogState(() => painValue = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, painValue.round()),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startExercise(ExerciseModel exercise) async {
    if (_isStarting) return;

    final initialPainLevel = await _askInitialPainLevel();
    if (!mounted || initialPainLevel == null) return;

    setState(() => _isStarting = true);

    try {
      final authProvider = context.read<AppAuthProvider>();
      final progressProvider = context.read<ProgressProvider>();

      final userId = authProvider.userModel?.id ?? '';
      if (userId.isEmpty) {
        throw Exception('User not logged in. Please sign in and try again.');
      }

      final session = SessionModel(
        id: '',
        userId: userId,
        exerciseId: exercise.id,
        exerciseTitle: exercise.title,
        startedAt: DateTime.now(),
        durationSeconds: exercise.duration,
        completed: false,
        totalSteps: exercise.steps.length,
        stepsCompleted: 0,
        status: 'in_progress',
        completionPercent: 0.0,
      );

      final sessionId = await progressProvider.startSession(session);

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        AppRoutes.exerciseSession,
        arguments: {
          'exercise': exercise,
          'sessionId': sessionId,
          'initialPainLevel': initialPainLevel,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise =
        ModalRoute.of(context)!.settings.arguments as ExerciseModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video preview
            VideoPlayerWidget(videoUrl: exercise.videoUrl),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + difficulty badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          exercise.difficulty[0].toUpperCase() +
                              exercise.difficulty.substring(1),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor:
                            _difficultyColor(exercise.difficulty),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Duration + body area
                  Row(
                    children: [
                      const Icon(Icons.timer,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        exercise.duration > 0
                            ? '${exercise.duration ~/ 60} min'
                            : 'No duration set',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.place,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        exercise.bodyArea.isNotEmpty
                            ? exercise.bodyArea[0].toUpperCase() +
                                exercise.bodyArea.substring(1)
                            : exercise.bodyArea,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Body area chip + target pain types
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(
                          exercise.bodyArea.isNotEmpty
                              ? exercise.bodyArea[0].toUpperCase() +
                                  exercise.bodyArea.substring(1)
                              : exercise.bodyArea,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                      ),
                      ...exercise.targetPainTypes.map(
                        (pt) => Chip(
                          label: Text(pt,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey.shade200,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise.description.isNotEmpty
                        ? exercise.description
                        : 'No description provided.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Steps
                  if (exercise.steps.isNotEmpty) ...[
                    const Text(
                      'Steps',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: exercise.steps.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                              exercise.steps[index].description),
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Start Exercise button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isStarting
                          ? null
                          : () => _startExercise(exercise),
                      child: _isStarting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Start Exercise',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
