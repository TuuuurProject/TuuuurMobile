import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class TuuurTheme {
  // Couleurs gaming vibrantes (équivalent Tailwind config)
  static const Color brandDark = Color(0xFF0A0B1E);
  static const Color brandDarkGray = Color(0xFF1A1B2E);
  static const Color brandPurple = Color(0xFF6C5CE7);
  static const Color brandPurpleDark = Color(0xFF5A4FCF);
  static const Color brandOrange = Color(0xFFFF6B35);
  static const Color brandOrangeDark = Color(0xFFE55A2B);
  static const Color brandGreen = Color(0xFF00D084);
  static const Color brandGreenDark = Color(0xFF00B56F);
  static const Color brandYellow = Color(0xFFFFD93D);
  static const Color brandPink = Color(0xFFFF4081);
  static const Color brandCyan = Color(0xFF00E5FF);
  static const Color brandLightGray = Color(0xFFE1E5E9);
  static const Color brandGray = Color(0xFF8B9AA8);
  static const Color brandWhite = Color(0xFFFFFFFF);

  // Couleurs de difficulté (identiques à la version web)
  static const Color difficultyEasy = Color(0xFF10b981); // vert
  static const Color difficultyMedium = Color(0xFFf59e0b); // jaune/ambre
  static const Color difficultyHard = Color(0xFFf97316); // orange
  static const Color difficultyHardcore = Color(0xFFef4444); // rouge

  // Labels de difficulté unifiés
  static const String difficultyEasyLabel = 'Facile';
  static const String difficultyMediumLabel = 'Moyen';
  static const String difficultyHardLabel = 'Difficile';
  static const String difficultyHardcoreLabel = 'Hardcore';

  /// Retourne le label d'une difficulté en fonction de son ID
  static String labelForDifficulty(int id) {
    switch (id) {
      case 1:
        return difficultyEasyLabel;
      case 2:
        return difficultyMediumLabel;
      case 3:
        return difficultyHardLabel;
      case 4:
        return difficultyHardcoreLabel;
      default:
        return 'Inconnu';
    }
  }

  /// Retourne la couleur associée à une difficulté en fonction de son ID ou label
  static Color colorForDifficulty({int? id}) {
    if (id != null) {
      switch (id) {
        case 1:
          return difficultyEasy;
        case 2:
          return difficultyMedium;
        case 3:
          return difficultyHard;
        case 4:
          return difficultyHardcore;
      }
    }

    return brandGray;
  }

  /// Retourne l'icône associée à une difficulté en fonction de son ID ou label
  static IconData iconForDifficulty({int? id}) {
    if (id != null) {
      switch (id) {
        case 1:
          return FontAwesomeIcons.seedling;
        case 2:
          return FontAwesomeIcons.bolt;
        case 3:
          return FontAwesomeIcons.fire;
        case 4:
          return FontAwesomeIcons.skull;
      }
    }

    return FontAwesomeIcons.gaugeHigh;
  }

  // Gradients gaming
  static const LinearGradient gamingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandDark, brandDarkGray, brandDark],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandPurple, brandPurpleDark],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandOrange, brandOrangeDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x80_1A1B2E), // 80% opacity brandDarkGray
      Color(0x90_0A0B1E), // 90% opacity brandDark
    ],
  );

  // Box shadows équivalents aux shadows Tailwind
  static const List<BoxShadow> neonShadow = [
    BoxShadow(
      color: Color(0x80_6C5CE7), // brandPurple with 50% opacity
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x4D_6C5CE7), // brandPurple with 30% opacity
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> neonOrangeShadow = [
    BoxShadow(
      color: Color(0x80_FF6B35), // brandOrange with 50% opacity
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x4D_FF6B35), // brandOrange with 30% opacity
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> neonGreenShadow = [
    BoxShadow(
      color: Color(0x80_00D084), // brandGreen with 50% opacity
      blurRadius: 20,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x4D_00D084), // brandGreen with 30% opacity
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> glowShadow = [
    BoxShadow(
      color: Color(0x66_6C5CE7), // brandPurple with 40% opacity
      blurRadius: 30,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x4D_0A0B1E), // brandDark with 30% opacity
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x33_0A0B1E), // brandDark with 20% opacity
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // Thème principal Flutter
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(brandPurple),

      // Schéma de couleurs
      colorScheme: const ColorScheme.dark(
        primary: brandPurple,
        secondary: brandOrange,
        surface: brandDarkGray,
        onSurface: brandLightGray,
        error: brandOrange,
        onError: brandWhite,
      ),

      // Arrière-plan de l'app
      scaffoldBackgroundColor: brandDark,

      // Police personnalisée (équivalent à Baloo 2)
      textTheme: GoogleFonts.balooBhai2TextTheme()
          .apply(bodyColor: brandLightGray, displayColor: brandLightGray)
          .copyWith(
            // Titres gaming avec Baloo 2
            displayLarge: GoogleFonts.balooBhai2(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: brandLightGray,
            ),
            displayMedium: GoogleFonts.balooBhai2(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: brandLightGray,
            ),
            displaySmall: GoogleFonts.balooBhai2(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: brandLightGray,
            ),
            // Corps de texte avec Nunito
            bodyLarge: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: brandLightGray,
            ),
            bodyMedium: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: brandGray,
            ),
            bodySmall: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: brandGray,
            ),
          ),

      // Style des boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.balooBhai2(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Style des cartes
      cardTheme: CardThemeData(
        color: brandDarkGray,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: brandPurple.withOpacity(0.2), width: 1),
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: brandDarkGray.withOpacity(0.8),
        foregroundColor: brandLightGray,
        elevation: 0,
        titleTextStyle: GoogleFonts.balooBhai2(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: brandLightGray,
        ),
      ),
    );
  }

  // Utilitaire pour créer un MaterialColor à partir d'une Color
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

// Styles prédéfinis équivalents aux classes CSS
class TuuurStyles {
  // Gaming Button Primary
  static BoxDecoration get gamingButtonPrimary => BoxDecoration(
    gradient: TuuurTheme.purpleGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: TuuurTheme.neonShadow,
  );

  // Gaming Button Secondary
  static BoxDecoration get gamingButtonSecondary => BoxDecoration(
    gradient: TuuurTheme.orangeGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: TuuurTheme.neonOrangeShadow,
  );

  // Gaming Button Ghost
  static BoxDecoration get gamingButtonGhost => BoxDecoration(
    color: TuuurTheme.brandDarkGray.withOpacity(0.5),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: TuuurTheme.brandPurple.withOpacity(0.3),
      width: 2,
    ),
  );

  // Gaming Card
  static BoxDecoration get gamingCard => BoxDecoration(
    gradient: TuuurTheme.cardGradient,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: TuuurTheme.brandPurple.withOpacity(0.2),
      width: 1,
    ),
    boxShadow: TuuurTheme.cardShadow,
  );

  // Pill/Badge
  static BoxDecoration get pill => BoxDecoration(
    color: TuuurTheme.brandDarkGray.withOpacity(0.8),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: TuuurTheme.brandPurple.withOpacity(0.2),
      width: 1,
    ),
  );

  // Badge Success
  static BoxDecoration get badgeSuccess => BoxDecoration(
    color: TuuurTheme.brandGreen.withOpacity(0.2),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: TuuurTheme.brandGreen.withOpacity(0.3), width: 1),
  );

  // Badge Warning
  static BoxDecoration get badgeWarning => BoxDecoration(
    color: TuuurTheme.brandOrange.withOpacity(0.2),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: TuuurTheme.brandOrange.withOpacity(0.3),
      width: 1,
    ),
  );

  // Badge Info
  static BoxDecoration get badgeInfo => BoxDecoration(
    color: TuuurTheme.brandCyan.withOpacity(0.2),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: TuuurTheme.brandCyan.withOpacity(0.3), width: 1),
  );

  // Category Button
  static BoxDecoration categoryButton({required bool selected}) =>
      BoxDecoration(
        gradient: selected ? TuuurTheme.purpleGradient : null,
        color: selected ? null : TuuurTheme.brandDarkGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? TuuurTheme.brandPurple
              : TuuurTheme.brandPurple.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: selected ? TuuurTheme.neonShadow : null,
      );

  // Category Button avec couleur personnalisée (pour les difficultés)
  static BoxDecoration categoryButtonWithColor({
    required bool selected,
    required Color color,
  }) => BoxDecoration(
    // Fond sombre semi-transparent (plus opaque si sélectionné)
    color: selected
        ? TuuurTheme.brandDarkGray.withOpacity(0.8)
        : TuuurTheme.brandDarkGray.withOpacity(0.5),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      // Bordure de la couleur si sélectionné, sinon bordure claire transparente
      color: selected ? color : TuuurTheme.brandLightGray.withOpacity(0.1),
      width: 2,
    ),
    boxShadow: selected
        ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ]
        : null,
  );
}
