import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/tuuuur_theme.dart';

class GamingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  const GamingIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final iconColor = enabled
        ? (color ?? TuuurTheme.brandLightGray)
        : TuuurTheme.brandGray.withOpacity(0.6);

    final btn = InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: TuuurTheme.brandDarkGray.withOpacity(0.35),
          border: Border.all(
            color: enabled
                ? TuuurTheme.brandPurple.withOpacity(0.25)
                : TuuurTheme.brandGray.withOpacity(0.15),
          ),
        ),
        child: Center(
          child: FaIcon(icon, size: 18, color: iconColor),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}
