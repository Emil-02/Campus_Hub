import 'package:flutter/material.dart';

/// Palette offered when tagging a course with a color.
const courseColorPalette = <String>[
  '#4A90D9',
  '#D94A4A',
  '#4AD97E',
  '#D9A44A',
  '#9B4AD9',
  '#D94AB8',
  '#4AC7D9',
  '#7ED94A',
  '#D97E4A',
  '#4A5FD9',
  '#8A8A8A',
  '#2E7D6B',
];

/// Parses `#RRGGBB` into a [Color], falling back to the first palette entry.
Color courseColorFromHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (cleaned.length != 6 || value == null) {
    return courseColorFromHex(courseColorPalette.first);
  }
  return Color(0xFF000000 | value);
}

/// Grid of selectable course colors.
final class CourseColorPicker extends StatelessWidget {
  const CourseColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final hex in courseColorPalette)
          _ColorDot(
            hex: hex,
            isSelected: hex.toUpperCase() == selectedColor.toUpperCase(),
            onTap: () => onColorSelected(hex),
          ),
      ],
    );
  }
}

final class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.hex,
    required this.isSelected,
    required this.onTap,
  });

  final String hex;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = courseColorFromHex(hex);
    return Semantics(
      label: 'Warna $hex',
      selected: isSelected,
      button: true,
      child: InkWell(
        key: ValueKey('course-color-$hex'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 3,
                  )
                : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}
