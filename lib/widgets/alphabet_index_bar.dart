import 'package:flutter/material.dart';
import '../theme.dart';

class AlphabetIndexBar extends StatelessWidget {
  final List<String> letters;
  final Function(String) onLetterSelected;
  final String? activeLetter;

  const AlphabetIndexBar({
    super.key,
    required this.letters,
    required this.onLetterSelected,
    this.activeLetter,
  });

  void _onGestureAt(Offset localPosition, double itemHeight) {
    final int index = (localPosition.dy / itemHeight).floor().clamp(0, letters.length - 1);
    onLetterSelected(letters[index]);
  }

  @override
  Widget build(BuildContext context) {
    // Each letter will have a fixed vertical space
    const double itemHeight = 18.0;
    
    return IntrinsicWidth(
      child: GestureDetector(
        onVerticalDragUpdate: (details) => _onGestureAt(details.localPosition, itemHeight),
        onVerticalDragDown: (details) => _onGestureAt(details.localPosition, itemHeight),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: letters.map((letter) {
            final isActive = letter == activeLetter;
            return Container(
              height: itemHeight,
              width: 32, // Wider hit area
              alignment: Alignment.center,
              child: Text(
                letter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppTheme.primaryColor : AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
