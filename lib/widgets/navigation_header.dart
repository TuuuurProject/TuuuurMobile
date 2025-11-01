import 'package:flutter/material.dart';
import '../theme/tuuuur_theme.dart';
import '../navigation/app_router.dart';

/// Header de navigation identique à Vue.js avec logo, titre et pills
/// Équivalent au header dans App.vue (lignes 184-225)
class NavigationHeader extends StatelessWidget implements PreferredSizeWidget {
  const NavigationHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TuuurTheme.brandDarkGray.withOpacity(0.8),
        // Backdrop blur effect équivalent à backdrop-blur-xl
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
              // Logo et titre - équivalent au bouton home Vue.js
              _buildLogoTitle(context),

              // Spacer pour pousser la navigation à droite
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
      onTap: () => context.goHome(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo avec gradient identique à Vue.js
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

            // Titre avec police display identique à Vue.js
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
