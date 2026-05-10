import 'package:flutter/material.dart';

class PainStopResult {
  final bool shouldStop;
  final int? painLevel;
  final String? painNote;
  const PainStopResult(
      {required this.shouldStop, this.painLevel, this.painNote});
}

class PainStopDialog extends StatefulWidget {
  const PainStopDialog({super.key});

  @override
  State<PainStopDialog> createState() => _PainStopDialogState();
}

class _PainStopDialogState extends State<PainStopDialog> {
  double _painLevel = 5;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Stop this session?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rate your current pain level:'),
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
          Text('Pain level: ${_painLevel.round()}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
              hintText: 'e.g. sharp pain in knee',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
              context, const PainStopResult(shouldStop: false)),
          child: const Text('Continue'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(
            context,
            PainStopResult(
              shouldStop: true,
              painLevel: _painLevel.round(),
              painNote: _noteCtrl.text.trim().isEmpty
                  ? null
                  : _noteCtrl.text.trim(),
            ),
          ),
          child: const Text('Stop Session'),
        ),
      ],
    );
  }
}
