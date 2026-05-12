import 'package:flutter/material.dart';

class ExerciseReviewResult {
  final int painLevel;
  final String? painNote;
  const ExerciseReviewResult({required this.painLevel, this.painNote});
}

class ExerciseReviewDialog extends StatefulWidget {
  const ExerciseReviewDialog({super.key});

  @override
  State<ExerciseReviewDialog> createState() => _ExerciseReviewDialogState();
}

class _ExerciseReviewDialogState extends State<ExerciseReviewDialog> {
  double _painLevel = 3;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exercise Complete!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Great work! Rate your pain level now:'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('1'),
              Expanded(
                child: Slider(
                  value: _painLevel,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: const Color(0xFF00897B),
                  label: _painLevel.round().toString(),
                  onChanged: (v) => setState(() => _painLevel = v),
                ),
              ),
              const Text('10'),
            ],
          ),
          Text(
            'Pain level: ${_painLevel.round()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
              hintText: 'e.g. feeling better after exercise',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(
            context,
            ExerciseReviewResult(
              painLevel: _painLevel.round(),
              painNote: _noteCtrl.text.trim().isEmpty
                  ? null
                  : _noteCtrl.text.trim(),
            ),
          ),
          child: const Text('Save & Finish'),
        ),
      ],
    );
  }
}
