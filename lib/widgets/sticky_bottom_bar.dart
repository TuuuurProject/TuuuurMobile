import 'package:flutter/material.dart';

import '../theme/tuuuur_theme.dart';

class StickyBottomBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final double maxWidth;

  const StickyBottomBar({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(24, 0, 24, 16),
    this.maxWidth = 720,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: margin,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TuuurTheme.brandDarkGray.withOpacity(0.70),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: TuuurTheme.brandPurple.withOpacity(0.25),
                  ),
                  boxShadow: TuuurTheme.cardShadow,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
