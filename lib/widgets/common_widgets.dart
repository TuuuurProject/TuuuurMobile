import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/tuuuur_theme.dart';
import '../widgets/gaming_widgets.dart';

// Modal Dialog équivalent au ModalDialog.vue
class GamingModal extends StatelessWidget {
  final String title;
  final Widget child;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showActions;

  const GamingModal({
    super.key,
    required this.title,
    required this.child,
    this.confirmText = 'Confirmer',
    this.cancelText = 'Annuler',
    this.onConfirm,
    this.onCancel,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
          color: TuuurTheme.brandDark.withOpacity(0.8),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: TuuurStyles.gamingCard.copyWith(
                border: Border.all(
                  color: TuuurTheme.brandPurple.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: TuuurTheme.neonShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: TuuurTheme.brandLightGray,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onCancel ?? () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: TuuurStyles.pill,
                            child: const Icon(
                              Icons.close,
                              color: TuuurTheme.brandLightGray,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        color: TuuurTheme.brandGray,
                        fontSize: 16,
                      ),
                      child: child,
                    ),
                  ),

                  // Actions
                  if (showActions)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GamingButtonGhost(
                            text: cancelText ?? 'Annuler',
                            onPressed:
                                onCancel ?? () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          GamingButtonPrimary(
                            text: confirmText ?? 'Confirmer',
                            onPressed: onConfirm,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeOutBack,
          duration: 300.ms,
        );
  }

  // Méthode statique pour afficher la modal
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool showActions = true,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (context) => GamingModal(
        title: title,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        showActions: showActions,
        child: child,
      ),
    );
  }
}

// Toast Notification équivalent au toast dans App.vue
class ToastManager {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;

  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    if (_isVisible) {
      hide();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) =>
          Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: TuuurStyles.pill.copyWith(
                      color:
                          backgroundColor ??
                          TuuurTheme.brandDarkGray.withOpacity(0.9),
                      border: Border.all(
                        color: TuuurTheme.brandPurple.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: TuuurTheme.neonShadow,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: TuuurTheme.brandLightGray,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 250.ms)
              .slideY(
                begin: 1.0,
                end: 0.0,
                curve: Curves.easeOutBack,
                duration: 300.ms,
              ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;

    // Auto-hide after duration
    Future.delayed(duration, () {
      hide();
    });
  }

  static void hide() {
    if (_isVisible && _overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isVisible = false;
    }
  }
}

// Loading Indicator
class GamingLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const GamingLoadingIndicator({super.key, this.message, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  TuuurTheme.brandPurple,
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 1000.ms, curve: Curves.linear),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(color: TuuurTheme.brandGray, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// Empty State Widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TuuurTheme.brandPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, size: 40, color: TuuurTheme.brandPurple),
            ).animate().scale(
              begin: const Offset(0.8, 0.8),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: TuuurTheme.brandLightGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, color: TuuurTheme.brandGray),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// Progress Bar Gaming
class GamingProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final String? label;

  const GamingProgressBar({
    super.key,
    required this.progress,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor =
        color ??
        (progress < 0.33 ? TuuurTheme.brandOrange : TuuurTheme.brandGreen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? TuuurTheme.brandDark.withOpacity(0.3),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: const TextStyle(fontSize: 12, color: TuuurTheme.brandGray),
          ),
        ],
      ],
    );
  }
}
