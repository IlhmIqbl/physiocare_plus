import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:physiocare/models/exercise_model.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({super.key, required this.exercise, this.onTap});

  final ExerciseModel exercise;
  final VoidCallback? onTap;

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

  Widget _difficultyBadge(String difficulty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _difficultyColor(difficulty),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        difficulty,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: exercise.thumbnailUrl.isEmpty
                  ? Container(
                      height: 120,
                      width: double.infinity,
                      color: const Color(0xFF00897B),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 48,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: exercise.thumbnailUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 120,
                        width: double.infinity,
                        color: const Color(0xFF00897B),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 120,
                        width: double.infinity,
                        color: const Color(0xFF00897B),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      _difficultyBadge(exercise.difficulty),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${exercise.duration ~/ 60} min',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.bodyArea.isNotEmpty
                        ? exercise.bodyArea[0].toUpperCase() +
                            exercise.bodyArea.substring(1)
                        : exercise.bodyArea,
                    style: const TextStyle(
                      color: Color(0xFF00897B),
                      fontSize: 12,
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
