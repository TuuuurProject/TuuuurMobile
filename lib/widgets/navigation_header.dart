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

  const NavigationHeader({
    super.key,
    this.showBack = false,
    this.confirmOnBack = false,
    this.confirmOnHome = false,
    this.backConfirmMessage = 'Voulez-vous vraiment retourner en arrière ?',
    this.homeConfirmMessage =
        'Êtes-vous sûr de vouloir retourner à l\'accueil ?',
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
                    action: () => context.goBack(),
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
        action: () => context.goHome(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [TuuurTheme.brandPurple, TuuurTheme.brandOrange],
                ),
                boxShadow: [
                  BoxShadow(
                    color: TuuurTheme.brandPurple.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.quiz, color: Colors.white, size: 16),
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
