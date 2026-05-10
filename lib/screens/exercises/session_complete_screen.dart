import 'package:flutter/material.dart';
import 'package:physiocare/utils/app_constants.dart';

class SessionCompleteScreen extends StatelessWidget {
  const SessionCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final stepsCompleted = args['stepsCompleted'] as int;
    final totalSteps = args['totalSteps'] as int;
    final elapsedSeconds = args['elapsedSeconds'] as int;
    final exerciseTitle = args['exerciseTitle'] as String;

    final m = elapsedSeconds ~/ 60;
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF00897B), size: 96),
              const SizedBox(height: 24),
              const Text(
                'Session Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exerciseTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _StatRow(
                  label: 'Steps completed',
                  value: '$stepsCompleted / $totalSteps'),
              const SizedBox(height: 12),
              _StatRow(label: 'Time taken', value: '${m}m ${s}s'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.exerciseLibrary,
                    (route) =>
                        route.settings.name == AppRoutes.dashboard,
                  ),
                  child: const Text('Back to Exercises',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D40))),
        ],
      ),
    );
  }
}
