import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens ─────────────────────────────────────────────────────────────

/// All color tokens used across the app. Never use raw Color() literals in
/// widgets — always reference these constants.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDark = Color(0xFF1240A8);
  static const Color primaryLight = Color(0xFF4D80F0);
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentDark = Color(0xFF5B21B6);
  static const Color accentLight = Color(0xFF9D6EF8);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF1A1D27);
  static const Color darkSurfaceVariant = Color(0xFF252836);
  static const Color darkSurfaceElevated = Color(0xFF2D3147);
  static const Color darkBorder = Color(0xFF2E3347);
  static const Color darkBorderSubtle = Color(0xFF1F2535);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF1F8);
  static const Color lightSurfaceElevated = Color(0xFFE8EDF7);
  static const Color lightBorder = Color(0xFFD1D9E6);
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);

  // Dark text
  static const Color darkTextPrimary = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextDisabled = Color(0xFF475569);

  // Light text
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextDisabled = Color(0xFFCBD5E1);

  // Semantic / Status
  static const Color success = Color(0xFF22C55E);
  static const Color successMuted = Color(0xFF166534);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningMuted = Color(0xFF92400E);
  static const Color error = Color(0xFFEF4444);
  static const Color errorMuted = Color(0xFF7F1D1D);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoMuted = Color(0xFF1E3A8A);

  // Code editor token colors
  static const Color codeKeyword = Color(0xFF7C3AED);
  static const Color codeString = Color(0xFF22C55E);
  static const Color codeComment = Color(0xFF6B7280);
  static const Color codeNumber = Color(0xFFF59E0B);
  static const Color codeFunction = Color(0xFF60A5FA);
  static const Color codeType = Color(0xFF34D399);
  static const Color codePunctuation = Color(0xFF94A3B8);
  static const Color codePreprocessor = Color(0xFFF97316);

  // Difficulty badge colors
  static const Color beginnerColor = Color(0xFF22C55E);
  static const Color intermediateColor = Color(0xFFF59E0B);
  static const Color advancedColor = Color(0xFFEF4444);
}

// ─── Spacing Tokens ───────────────────────────────────────────────────────────

/// Consistent spacing scale. Use these instead of raw numbers.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double huge = 64.0;
}

// ─── Border Radius Tokens ─────────────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}

// ─── Animation Tokens ─────────────────────────────────────────────────────────

class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);
}

// ─── Text Styles ───────────────────────────────────────────────────────────────

/// All text styles. Inter for UI, Fira Code for code.
/// Always apply a `color` on top from the theme.
///
/// IMPORTANT: GoogleFonts fonts are cached here as static finals.
/// Never call GoogleFonts.inter() / GoogleFonts.firaCode() inline inside
/// widgets — doing so triggers font-cache work on every build.
class AppTextStyles {
  AppTextStyles._();

  // ── Cached base styles (font lookup done ONCE) ────────────────────────────
  static final TextStyle _inter = GoogleFonts.inter();
  static final TextStyle _firaCode = GoogleFonts.firaCode();

  // ── Display ──
  static TextStyle get displayLarge => _inter.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get displayMedium => _inter.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.25,
  );

  // ── Headline ──
  static TextStyle get headlineLarge => _inter.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle get headlineMedium => _inter.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static TextStyle get headlineSmall =>
      _inter.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  // ── Title ──
  static TextStyle get titleLarge =>
      _inter.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);

  static TextStyle get titleMedium =>
      _inter.copyWith(fontSize: 15, fontWeight: FontWeight.w500, height: 1.45);

  static TextStyle get titleSmall =>
      _inter.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5);

  // ── Body ──
  static TextStyle get bodyLarge =>
      _inter.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);

  static TextStyle get bodyMedium =>
      _inter.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.6);

  static TextStyle get bodySmall =>
      _inter.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.55);

  // ── Label ──
  static TextStyle get labelLarge => _inter.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle get labelMedium => _inter.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static TextStyle get labelSmall => _inter.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // ── Code (Fira Code) ──
  static TextStyle get code => _firaCode.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static TextStyle get codeBold => _firaCode.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.6,
  );

  static TextStyle get codeSmall => _firaCode.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get codeLarge => _firaCode.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  // ── Badge / Chip ──
  static TextStyle get badge => _inter.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
}

// ─── Shadow Tokens ────────────────────────────────────────────────────────────

class AppShadows {
  AppShadows._();

  static List<BoxShadow> sm(bool isDark) => [
    BoxShadow(
      color: isDark ? Colors.black.withAlpha(77) : Colors.black.withAlpha(15),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> md(bool isDark) => [
    BoxShadow(
      color: isDark ? Colors.black.withAlpha(102) : Colors.black.withAlpha(20),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> lg(bool isDark) => [
    BoxShadow(
      color: isDark ? Colors.black.withAlpha(128) : Colors.black.withAlpha(25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(color: color.withAlpha(51), blurRadius: 12, spreadRadius: 0),
  ];
}

// ─── Theme Factory ────────────────────────────────────────────────────────────

/// Central theme factory. Always use AppTheme.darkTheme / lightTheme
/// as the source of truth for the MaterialApp.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _buildTheme(isDark: true);
  static ThemeData get lightTheme => _buildTheme(isDark: false);

  static ThemeData _buildTheme({required bool isDark}) {
    final cs = isDark ? _darkColorScheme : _lightColorScheme;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,

      // ── Text ──
      textTheme: _buildTextTheme(cs, textColor),

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: textColor),
        iconTheme: IconThemeData(color: textColor),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: border),
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      // ── Icons ──
      iconTheme: IconThemeData(color: textColor, size: 20),

      // ── ElevatedButton ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(0, 44),
        ),
      ),

      // ── OutlinedButton ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTextStyles.labelLarge,
          minimumSize: const Size(0, 44),
        ),
      ),

      // ── TextButton ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── InputDecoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark
              ? AppColors.darkTextDisabled
              : AppColors.lightTextDisabled,
        ),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        selectedColor: cs.primary.withAlpha(51),
        side: BorderSide(color: border),
        labelStyle: AppTextStyles.labelSmall.copyWith(color: textColor),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textColor),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceElevated
              : const Color(0xFF1E293B),
          borderRadius: AppRadius.smAll,
        ),
        textStyle: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),

      // ── ProgressIndicator ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        circularTrackColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return cs.primary.withAlpha(77);
          }
          return isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant;
        }),
      ),
    );
  }

  // ── Color Schemes ──

  static ColorScheme get _darkColorScheme => const ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: Color(0xFFBFD4FF),
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF4C1D95),
    onSecondaryContainer: Color(0xFFDDD6FE),
    tertiary: Color(0xFF22C55E),
    onTertiary: Colors.white,
    surface: AppColors.darkBackground,
    onSurface: AppColors.darkTextPrimary,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkTextSecondary,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFECACA),
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkBorderSubtle,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.lightBackground,
    onInverseSurface: AppColors.lightTextPrimary,
    inversePrimary: AppColors.primaryLight,
  );

  static ColorScheme get _lightColorScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDCEAFD),
    onPrimaryContainer: Color(0xFF1E3A8A),
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFEDE9FE),
    onSecondaryContainer: Color(0xFF4C1D95),
    tertiary: Color(0xFF16A34A),
    onTertiary: Colors.white,
    surface: AppColors.lightBackground,
    onSurface: AppColors.lightTextPrimary,
    surfaceContainerHighest: AppColors.lightSurfaceVariant,
    onSurfaceVariant: AppColors.lightTextSecondary,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    outline: AppColors.lightBorder,
    outlineVariant: AppColors.lightBorderSubtle,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.darkBackground,
    onInverseSurface: AppColors.darkTextPrimary,
    inversePrimary: AppColors.primaryLight,
  );

  // ── Text Theme ──

  static TextTheme _buildTextTheme(ColorScheme cs, Color primary) {
    final secondary = cs.onSurfaceVariant;
    return TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: primary),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: primary),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: primary),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: primary),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: primary),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: primary),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: primary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: primary),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: secondary),
    );
  }
}
