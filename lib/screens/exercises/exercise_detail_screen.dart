import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/models/session_model.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/widgets/video_player_widget.dart';
import 'package:physiocare/utils/app_constants.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key});

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
            // Video player
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
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: _difficultyColor(exercise.difficulty),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Duration + body area
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${exercise.duration ~/ 60} min',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.place, size: 16, color: Colors.grey),
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

                  // Body area chip + target pain types chips
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
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                      ),
                      ...exercise.targetPainTypes.map(
                        (pt) => Chip(
                          label: Text(
                            pt,
                            style: const TextStyle(fontSize: 12),
                          ),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise.description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Steps
                  const Text(
                    'Steps',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                        title: Text(exercise.steps[index].description),
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Start Exercise button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final authProvider =
                            context.read<AppAuthProvider>();
                        final progressProvider =
                            context.read<ProgressProvider>();

                        final userId =
                            authProvider.userModel?.id ?? '';

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

                        final sessionId =
                            await progressProvider.startSession(session);

                        if (context.mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.exerciseSession,
                            arguments: {
                              'exercise': exercise,
                              'sessionId': sessionId,
                            },
                          );
                        }
                      },
                      child: const Text(
                        'Start Exercise',
                        style: TextStyle(fontSize: 16),
                      ),
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
