import 'package:flutter/material.dart';

class PainSlider extends StatelessWidget {
  const PainSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Pain Level',
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String label;

  Color _colorForValue(double v) {
    if (v <= 3) return Colors.green;
    if (v <= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${value.round()}/10',
              style: const TextStyle(
                color: Color(0xFF00897B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _colorForValue(value),
            thumbColor: _colorForValue(value),
            inactiveTrackColor: Colors.grey.shade300,
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '1\nMild',
              textAlign: TextAlign.left,
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            Text(
              '5\nModerate',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            Text(
              '10\nSevere',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
