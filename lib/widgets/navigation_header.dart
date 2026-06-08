import 'package:flutter/material.dart';
import '../theme/tuuuur_theme.dart';
import '../navigation/app_router.dart';
import '../navigation/navigation_utils.dart';

class NavigationHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Affiche ou non la flèche de retour.
  final bool showBack;

  /// Active la confirmation pour la flèche retour.
  final bool confirmOnBack;

  /// Active la confirmation pour le clic sur le logo / texte "Tuuuur".
  final bool confirmOnHome;

  /// Message de confirmation pour la flèche retour.
  final String backConfirmMessage;

  /// Message de confirmation pour le clic sur "Tuuuur" (retour à l'accueil).
  final String homeConfirmMessage;

  /// Callback appelée avant de naviguer en arrière (pour nettoyage).
  final Future<void> Function()? onBackPressed;

  /// Callback appelée avant de naviguer vers l'accueil (pour nettoyage).
  final Future<void> Function()? onHomePressed;

  const NavigationHeader({
    super.key,
    this.showBack = false,
    this.confirmOnBack = false,
    this.confirmOnHome = false,
    this.backConfirmMessage = 'Voulez-vous vraiment retourner en arrière ?',
    this.homeConfirmMessage =
        'Êtes-vous sûr de vouloir retourner à l\'accueil ?',
    this.onBackPressed,
    this.onHomePressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TuuurTheme.brandDarkGray.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: TuuurTheme.brandPurple.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              if (showBack) ...[
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: TuuurTheme.brandLightGray,
                    size: 20,
                  ),
                  tooltip: 'Retour',
                  onPressed: () => runWithConfirmIfNeeded(
                    context,
                    confirm: confirmOnBack,
                    message: backConfirmMessage,
                    action: () async {
                      if (onBackPressed != null) {
                        await onBackPressed!();
                      }
                      if (context.mounted) {
                        context.goBack();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // Logo + titre
              _buildLogoTitle(context),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoTitle(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => runWithConfirmIfNeeded(
        context,
        confirm: confirmOnHome,
        message: homeConfirmMessage,
        action: () async {
          if (onHomePressed != null) {
            await onHomePressed!();
          }
          if (context.mounted) {
            context.goHome();
          }
        },
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover, // remplit le cercle sans déformer
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tuuuur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: TuuurTheme.brandLightGray,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Optionnel : pills de navigation, inchangé si tu veux les réutiliser
  Widget _buildPill({
    required BuildContext context,
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? TuuurTheme.brandPurple.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? TuuurTheme.brandPurple.withOpacity(0.4)
                : TuuurTheme.brandGray.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? TuuurTheme.brandPurple : TuuurTheme.brandGray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
