import 'package:flutter/material.dart';

class CustomStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const CustomStepper({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF5F5F4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: value > 0 ? () => onChanged(value - 1) : null,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.remove_rounded,
              size: 16,
              color: value > 0
                  ? theme.colorScheme.primary
                  : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFD6D3D1)),
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: value > 0
                  ? theme.colorScheme.primary
                  : (isDark ? const Color(0xFF44403C) : const Color(0xFFC7C5C1)),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(value + 1),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.add_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ]),
    );
  }
}