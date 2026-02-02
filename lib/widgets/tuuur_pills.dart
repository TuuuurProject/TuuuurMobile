import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/tuuuur_theme.dart';

class TuuurPill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;
  final double? width;
  final double height;
  final VoidCallback? onTap;

  const TuuurPill({
    super.key,
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    this.icon,
    this.width,
    this.height = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bounded = width != null;

    final content = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: bounded ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (icon != null) ...[
            FaIcon(icon!, size: 10, color: textColor),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: bounded ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: content,
    );
  }
}

class DifficultyPill extends StatelessWidget {
  final int difficultyId;
  final double width;
  final double height;

  const DifficultyPill({
    super.key,
    required this.difficultyId,
    this.width = 140,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    final label = TuuurTheme.labelForDifficulty(difficultyId);
    final color = TuuurTheme.colorForDifficulty(id: difficultyId);
    final icon = TuuurTheme.iconForDifficulty(id: difficultyId);

    return TuuurPill(
      label: label,
      bgColor: color.withOpacity(0.20),
      borderColor: color.withOpacity(0.45),
      textColor: color,
      icon: icon,
      width: width,
      height: height,
    );
  }
}

class ThemePill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const ThemePill({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TuuurPill(
      label: label,
      bgColor: TuuurTheme.brandPurple.withOpacity(0.10),
      borderColor: TuuurTheme.brandPurple.withOpacity(0.30),
      textColor: TuuurTheme.brandPurple,
      onTap: onTap,
    );
  }
}
