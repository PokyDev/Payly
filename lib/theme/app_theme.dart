import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Light
  static const Color bgLight = Color(0xFFF8F5ED);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardAltLight = Color(0xFFEFECE3);
  static const Color cardHoverLight = Color(0xFFF5F2EA);
  static const Color textLight = Color(0xFF1C1A14);
  static const Color textSecLight = Color(0xFF7A7668);
  static const Color textTerLight = Color(0xFFB8B4A8);
  static const Color borderLight = Color(0x12000000);
  static const Color borderMedLight = Color(0x1C000000);
  static const Color inputLight = Color(0xFFF0EDE5);
  static const Color tabBgLight = Color(0xEBFFFFFF);
  static const Color dangerLight = Color(0xFFD93025);
  static const Color successLight = Color(0xFF2A7D4F);
  static const Color badgeGreenLight = Color(0xFFE6F4ED);
  static const Color badgeGreenTextLight = Color(0xFF1A6B3C);
  static const Color badgeAmberLight = Color(0xFFFEF3DC);
  static const Color badgeAmberTextLight = Color(0xFF8A5A00);

  // Dark
  static const Color bgDark = Color(0xFF141210);
  static const Color cardDark = Color(0xFF1E1C18);
  static const Color cardAltDark = Color(0xFF2A2820);
  static const Color cardHoverDark = Color(0xFF252320);
  static const Color textDark = Color(0xFFF2EFE4);
  static const Color textSecDark = Color(0xFF9A9688);
  static const Color textTerDark = Color(0xFF5A5850);
  static const Color borderDark = Color(0x0FFFFFFF);
  static const Color borderMedDark = Color(0x1AFFFFFF);
  static const Color inputDark = Color(0xFF2A2820);
  static const Color tabBgDark = Color(0xF2141210);
  static const Color dangerDark = Color(0xFFEF5350);
  static const Color successDark = Color(0xFF4CAF82);
  static const Color badgeGreenDark = Color(0xFF152A1E);
  static const Color badgeGreenTextDark = Color(0xFF4CAF82);
  static const Color badgeAmberDark = Color(0xFF2A1E00);
  static const Color badgeAmberTextDark = Color(0xFFF5C518);

  // Shared
  static const Color yellow = Color(0xFFF5C518);
  static const Color yellowMid = Color(0xFFE6B800);
  static const Color yellowLightColor = Color(0xFFFDF4C7);
  static const Color yellowLightDark = Color(0xFF2C2500);
  static const Color yellowText = Color(0xFF1C1A14);
}

class AppTheme {
  static TextTheme _textTheme(Color base) => GoogleFonts.dmSansTextTheme(
        TextTheme(
          bodyMedium: TextStyle(color: base),
        ),
      );

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme: _textTheme(AppColors.textLight),
      colorScheme: const ColorScheme.light(
        primary: AppColors.yellow,
        secondary: AppColors.yellow,
        surface: AppColors.cardLight,
        onPrimary: AppColors.yellowText,
        onSurface: AppColors.textLight,
        error: AppColors.dangerLight,
      ),
      extensions: const [PaylyColors.light],
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: _textTheme(AppColors.textDark),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.yellow,
        secondary: AppColors.yellow,
        surface: AppColors.cardDark,
        onPrimary: AppColors.yellowText,
        onSurface: AppColors.textDark,
        error: AppColors.dangerDark,
      ),
      extensions: const [PaylyColors.dark],
    );
  }
}

@immutable
class PaylyColors extends ThemeExtension<PaylyColors> {
  const PaylyColors({
    required this.bg,
    required this.card,
    required this.cardAlt,
    required this.text,
    required this.textSec,
    required this.textTer,
    required this.border,
    required this.borderMed,
    required this.input,
    required this.tabBg,
    required this.danger,
    required this.success,
    required this.badgeGreen,
    required this.badgeGreenText,
    required this.badgeAmber,
    required this.badgeAmberText,
    required this.yellowLight,
  });

  final Color bg;
  final Color card;
  final Color cardAlt;
  final Color text;
  final Color textSec;
  final Color textTer;
  final Color border;
  final Color borderMed;
  final Color input;
  final Color tabBg;
  final Color danger;
  final Color success;
  final Color badgeGreen;
  final Color badgeGreenText;
  final Color badgeAmber;
  final Color badgeAmberText;
  final Color yellowLight;

  static const PaylyColors light = PaylyColors(
    bg: AppColors.bgLight,
    card: AppColors.cardLight,
    cardAlt: AppColors.cardAltLight,
    text: AppColors.textLight,
    textSec: AppColors.textSecLight,
    textTer: AppColors.textTerLight,
    border: AppColors.borderLight,
    borderMed: AppColors.borderMedLight,
    input: AppColors.inputLight,
    tabBg: AppColors.tabBgLight,
    danger: AppColors.dangerLight,
    success: AppColors.successLight,
    badgeGreen: AppColors.badgeGreenLight,
    badgeGreenText: AppColors.badgeGreenTextLight,
    badgeAmber: AppColors.badgeAmberLight,
    badgeAmberText: AppColors.badgeAmberTextLight,
    yellowLight: AppColors.yellowLightColor,
  );

  static const PaylyColors dark = PaylyColors(
    bg: AppColors.bgDark,
    card: AppColors.cardDark,
    cardAlt: AppColors.cardAltDark,
    text: AppColors.textDark,
    textSec: AppColors.textSecDark,
    textTer: AppColors.textTerDark,
    border: AppColors.borderDark,
    borderMed: AppColors.borderMedDark,
    input: AppColors.inputDark,
    tabBg: AppColors.tabBgDark,
    danger: AppColors.dangerDark,
    success: AppColors.successDark,
    badgeGreen: AppColors.badgeGreenDark,
    badgeGreenText: AppColors.badgeGreenTextDark,
    badgeAmber: AppColors.badgeAmberDark,
    badgeAmberText: AppColors.badgeAmberTextDark,
    yellowLight: AppColors.yellowLightDark,
  );

  @override
  PaylyColors copyWith({
    Color? bg, Color? card, Color? cardAlt, Color? text, Color? textSec,
    Color? textTer, Color? border, Color? borderMed, Color? input, Color? tabBg,
    Color? danger, Color? success, Color? badgeGreen, Color? badgeGreenText,
    Color? badgeAmber, Color? badgeAmberText, Color? yellowLight,
  }) => PaylyColors(
    bg: bg ?? this.bg, card: card ?? this.card, cardAlt: cardAlt ?? this.cardAlt,
    text: text ?? this.text, textSec: textSec ?? this.textSec, textTer: textTer ?? this.textTer,
    border: border ?? this.border, borderMed: borderMed ?? this.borderMed, input: input ?? this.input,
    tabBg: tabBg ?? this.tabBg, danger: danger ?? this.danger, success: success ?? this.success,
    badgeGreen: badgeGreen ?? this.badgeGreen, badgeGreenText: badgeGreenText ?? this.badgeGreenText,
    badgeAmber: badgeAmber ?? this.badgeAmber, badgeAmberText: badgeAmberText ?? this.badgeAmberText,
    yellowLight: yellowLight ?? this.yellowLight,
  );

  @override
  PaylyColors lerp(PaylyColors? other, double t) {
    if (other == null) return this;
    return PaylyColors(
      bg: Color.lerp(bg, other.bg, t)!, card: Color.lerp(card, other.card, t)!,
      cardAlt: Color.lerp(cardAlt, other.cardAlt, t)!, text: Color.lerp(text, other.text, t)!,
      textSec: Color.lerp(textSec, other.textSec, t)!, textTer: Color.lerp(textTer, other.textTer, t)!,
      border: Color.lerp(border, other.border, t)!, borderMed: Color.lerp(borderMed, other.borderMed, t)!,
      input: Color.lerp(input, other.input, t)!, tabBg: Color.lerp(tabBg, other.tabBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!, success: Color.lerp(success, other.success, t)!,
      badgeGreen: Color.lerp(badgeGreen, other.badgeGreen, t)!,
      badgeGreenText: Color.lerp(badgeGreenText, other.badgeGreenText, t)!,
      badgeAmber: Color.lerp(badgeAmber, other.badgeAmber, t)!,
      badgeAmberText: Color.lerp(badgeAmberText, other.badgeAmberText, t)!,
      yellowLight: Color.lerp(yellowLight, other.yellowLight, t)!,
    );
  }
}

extension BuildContextTheme on BuildContext {
  PaylyColors get pc => Theme.of(this).extension<PaylyColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
