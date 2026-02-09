import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuuuur_flutter/theme/tuuuur_theme.dart';

void main() {
  group('TuuurTheme Colors', () {
    test('brandDark est défini', () {
      expect(TuuurTheme.brandDark, equals(const Color(0xFF0A0B1E)));
    });

    test('brandPurple est défini', () {
      expect(TuuurTheme.brandPurple, equals(const Color(0xFF6C5CE7)));
    });

    test('brandOrange est défini', () {
      expect(TuuurTheme.brandOrange, equals(const Color(0xFFFF6B35)));
    });

    test('brandGreen est défini', () {
      expect(TuuurTheme.brandGreen, equals(const Color(0xFF00D084)));
    });

    test('brandWhite est défini', () {
      expect(TuuurTheme.brandWhite, equals(const Color(0xFFFFFFFF)));
    });
  });

  group('TuuurTheme Gradients', () {
    test('gamingGradient a les bonnes couleurs', () {
      expect(TuuurTheme.gamingGradient.colors.length, equals(3));
      expect(TuuurTheme.gamingGradient.colors[0], equals(TuuurTheme.brandDark));
    });

    test('purpleGradient a les bonnes couleurs', () {
      expect(TuuurTheme.purpleGradient.colors.length, equals(2));
      expect(TuuurTheme.purpleGradient.colors[0], equals(TuuurTheme.brandPurple));
    });

    test('orangeGradient a les bonnes couleurs', () {
      expect(TuuurTheme.orangeGradient.colors.length, equals(2));
      expect(TuuurTheme.orangeGradient.colors[0], equals(TuuurTheme.brandOrange));
    });
  });

  group('TuuurTheme Shadows', () {
    test('neonShadow est défini', () {
      expect(TuuurTheme.neonShadow, isNotEmpty);
      expect(TuuurTheme.neonShadow, isA<List<BoxShadow>>());
    });
  });

  group('TuuurStyles', () {
    test('gamingCard est défini', () {
      expect(TuuurStyles.gamingCard, isNotNull);
      expect(TuuurStyles.gamingCard, isA<BoxDecoration>());
    });

    test('gamingButtonPrimary est défini', () {
      expect(TuuurStyles.gamingButtonPrimary, isNotNull);
      expect(TuuurStyles.gamingButtonPrimary, isA<BoxDecoration>());
    });

    test('gamingButtonSecondary est défini', () {
      expect(TuuurStyles.gamingButtonSecondary, isNotNull);
      expect(TuuurStyles.gamingButtonSecondary, isA<BoxDecoration>());
    });

    test('pill est défini', () {
      expect(TuuurStyles.pill, isNotNull);
      expect(TuuurStyles.pill, isA<BoxDecoration>());
    });
  });
}
