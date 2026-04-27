import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({
    super.key,
    required this.child,
    required this.isPremium,
  });

  final Widget child;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return child;
    }

    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: child,
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black54,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Premium Feature',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Upgrade to unlock',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
