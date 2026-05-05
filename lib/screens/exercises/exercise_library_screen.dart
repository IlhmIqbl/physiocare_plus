import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/providers/exercise_provider.dart';
import 'package:physiocare/widgets/exercise_card.dart';
import 'package:physiocare/utils/app_constants.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  static const List<String> _bodyAreas = [
    'shoulder',
    'lower_back',
    'knee',
    'hip',
    'neck',
    'ankle',
  ];

  static const List<String> _difficulties = ['easy', 'medium', 'hard'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ExerciseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final exercises = provider.exercises;

          return Column(
            children: [
              // Filter section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Body Area filter
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(
                          labelText: 'Body Area',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        initialValue: provider.selectedBodyArea,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All'),
                          ),
                          ..._bodyAreas.map(
                            (area) => DropdownMenuItem<String?>(
                              value: area,
                              child: Text(
                                area[0].toUpperCase() + area.substring(1),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          provider.setBodyAreaFilter(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Difficulty filter
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        initialValue: provider.selectedDifficulty,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All'),
                          ),
                          ..._difficulties.map(
                            (d) => DropdownMenuItem<String?>(
                              value: d,
                              child: Text(
                                d[0].toUpperCase() + d.substring(1),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          provider.setDifficultyFilter(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Exercises grid or empty state
              Expanded(
                child: exercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.fitness_center,
                              color: Colors.grey,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No exercises found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return ExerciseCard(
                            exercise: exercise,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.exerciseDetail,
                              arguments: exercise,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
