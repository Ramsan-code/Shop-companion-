import 'package:flutter/material.dart';

/// Tamil-first Material 3 theme (PRD 11: 48 dp targets, large numerals,
/// Noto Sans Tamil).
///
/// Android ships Noto Sans Tamil as a system font, so it is listed as a
/// fallback instead of bundled. That keeps the APK under the 25 MB budget.
abstract final class AppTheme {
  static const seed = Color(0xFF0B6E4F);

  static const _tamilFallback = ['Noto Sans Tamil'];

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
    // Tamil glyphs are taller than Latin ones; extra line height stops
    // vowel signs from clipping.
    final text = base.textTheme
        .apply(fontFamilyFallback: _tamilFallback)
        .copyWith(
          bodyLarge: base.textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            height: 1.5,
          ),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(
            fontSize: 16,
            height: 1.5,
          ),
          labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 16),
        );
    const minTarget = Size(48, 48);
    return base.copyWith(
      textTheme: text,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 56)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: minTarget),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minTarget),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      extensions: [AmountStyle.of(scheme)],
    );
  }
}

/// Large tabular numerals for balances (low-literacy mode, N10).
@immutable
class AmountStyle extends ThemeExtension<AmountStyle> {
  const AmountStyle({
    required this.large,
    required this.owed,
    required this.paid,
  });

  factory AmountStyle.of(ColorScheme scheme) => AmountStyle(
    large: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    owed: scheme.error,
    paid: scheme.primary,
  );

  final TextStyle large;
  final Color owed;
  final Color paid;

  @override
  AmountStyle copyWith({TextStyle? large, Color? owed, Color? paid}) =>
      AmountStyle(
        large: large ?? this.large,
        owed: owed ?? this.owed,
        paid: paid ?? this.paid,
      );

  @override
  AmountStyle lerp(AmountStyle? other, double t) {
    if (other == null) return this;
    return AmountStyle(
      large: TextStyle.lerp(large, other.large, t)!,
      owed: Color.lerp(owed, other.owed, t)!,
      paid: Color.lerp(paid, other.paid, t)!,
    );
  }
}
