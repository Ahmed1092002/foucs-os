import 'package:flutter/material.dart';

/// Simple horizontal swatch picker for area/subject colors.
class ColorPickerField extends StatelessWidget {
  const ColorPickerField({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  Color _parse(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: options.map((hex) {
            final selected = hex.toLowerCase() == value.toLowerCase();
            return GestureDetector(
              onTap: () => onChanged(hex),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _parse(hex),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}