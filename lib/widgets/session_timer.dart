import 'package:flutter/material.dart';

class SessionTimer extends StatelessWidget {
  const SessionTimer({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  final int secondsRemaining;
  final int totalSeconds;

  String _formatTime(int seconds) {
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 8,
            value: totalSeconds > 0 ? secondsRemaining / totalSeconds : 0,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00897B)),
          ),
          Text(
            _formatTime(secondsRemaining),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00897B),
            ),
          ),
        ],
      ),
    );
  }
}
