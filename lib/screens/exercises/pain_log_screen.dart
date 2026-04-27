import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:physiocare/models/exercise_model.dart';
import 'package:physiocare/models/progress_model.dart';
import 'package:physiocare/providers/progress_provider.dart';
import 'package:physiocare/providers/auth_provider.dart';
import 'package:physiocare/widgets/pain_slider.dart';
import 'package:physiocare/utils/app_constants.dart';

class PainLogScreen extends StatefulWidget {
  const PainLogScreen({super.key});

  @override
  State<PainLogScreen> createState() => _PainLogScreenState();
}

class _PainLogScreenState extends State<PainLogScreen> {
  double _painBefore = 5.0;
  double _painAfter = 5.0;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String sessionId = args['sessionId'] as String;
    final ExerciseModel exercise = args['exercise'] as ExerciseModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pain Log'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'How are you feeling?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tracking your pain helps us improve your plan',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Pain before
            const Text(
              'Pain BEFORE exercise',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            PainSlider(
              value: _painBefore,
              onChanged: (v) => setState(() => _painBefore = v),
              label: 'Before Exercise',
            ),
            const SizedBox(height: 24),

            // Pain after
            const Text(
              'Pain AFTER exercise',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            PainSlider(
              value: _painAfter,
              onChanged: (v) => setState(() => _painAfter = v),
              label: 'After Exercise',
            ),
            const SizedBox(height: 24),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Optional notes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Save & Finish button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  final authProvider = context.read<AppAuthProvider>();
                  final progressProvider = context.read<ProgressProvider>();

                  final userId = authProvider.userModel?.id ?? '';

                  final progress = ProgressModel(
                    id: '',
                    userId: userId,
                    sessionId: sessionId,
                    painLevelBefore: _painBefore.round(),
                    painLevelAfter: _painAfter.round(),
                    notes: _notesController.text.isNotEmpty
                        ? _notesController.text
                        : null,
                    recordedAt: DateTime.now(),
                  );

                  await progressProvider.saveProgress(progress);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Great job! Session saved.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.dashboard,
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  'Save & Finish',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
