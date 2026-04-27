import 'package:flutter/material.dart';

class BodyAreaSelector extends StatelessWidget {
  const BodyAreaSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  static const List<String> _bodyAreas = [
    'shoulder',
    'lower_back',
    'knee',
    'hip',
    'neck',
    'ankle',
  ];

  String _formatLabel(String area) {
    final words = area.split('_');
    return words
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _bodyAreas.map((area) {
        final isSelected = selected.contains(area);
        return FilterChip(
          label: Text(_formatLabel(area)),
          selected: isSelected,
          onSelected: (bool value) {
            final newList = List<String>.from(selected);
            if (value) {
              newList.add(area);
            } else {
              newList.remove(area);
            }
            onChanged(newList);
          },
          selectedColor: const Color(0xFFe0f2f1),
          checkmarkColor: const Color(0xFF00897B),
        );
      }).toList(),
    );
  }
}
