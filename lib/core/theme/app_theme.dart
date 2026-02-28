import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// 카페온도 앱 테마
/// Material 3 기반, 모던 미니멀리즘 디자인
abstract class AppTheme {
  AppTheme._();

  /// Pretendard 폰트 (한글 최적화 산세리프)
  /// google_fonts 패키지를 통해 접근. 없으면 Noto Sans KR fallback.
  static TextTheme _buildTextTheme(TextTheme base) {
    final pretendard = GoogleFonts.notoSansKr;
    return base.copyWith(
      displayLarge: pretendard(
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
        color: AppColors.textPrimary,
      ),
      displayMedium: pretendard(
        fontSize: 45,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      ),
      displaySmall: pretendard(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.textPrimary,
      ),
      headlineLarge: pretendard(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
      headlineMedium: pretendard(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      ),
      headlineSmall: pretendard(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      ),
      titleLarge: pretendard(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      ),
      titleMedium: pretendard(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
      ),
      titleSmall: pretendard(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
      ),
      bodyLarge: pretendard(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: AppColors.textPrimary,
      ),
      bodyMedium: pretendard(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: AppColors.textSecondary,
      ),
      bodySmall: pretendard(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      ),
      labelLarge: pretendard(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
      ),
      labelMedium: pretendard(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      ),
      labelSmall: pretendard(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textHint,
      ),
    );
  }

  /// 라이트 테마 (현재 지원)
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.deepTeal,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.lightTeal,
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.mutedTeal,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.lightTeal,
      onSecondaryContainer: AppColors.darkTeal,
      tertiary: AppColors.terra,
      onTertiary: AppColors.white,
      tertiaryContainer: Color(0xFFF5DDD7),
      onTertiaryContainer: AppColors.terra,
      error: AppColors.mauve,
      onError: AppColors.white,
      errorContainer: AppColors.noiseLoudBg,
      onErrorContainer: AppColors.mauve,
      surface: AppColors.offWhite,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.warmBeige,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      shadow: AppColors.navy,
      scrim: AppColors.navy,
      inverseSurface: AppColors.navy,
      onInverseSurface: AppColors.offWhite,
      inversePrimary: AppColors.lightTeal,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    );

    final textTheme = _buildTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.paperWhite,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.offWhite,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.border,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.navy,
          size: AppDimensions.iconStandard,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.offWhite,
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusCard),
          side: const BorderSide(
            color: AppColors.border,
            width: AppDimensions.cardBorderWidth,
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: AppDimensions.paddingXSmall,
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Elevated Button ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepTeal,
          foregroundColor: AppColors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusButton),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSection,
            vertical: AppDimensions.paddingStandard,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          minimumSize: const Size(0, 52),
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepTeal,
          side: const BorderSide(color: AppColors.deepTeal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusButton),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSection,
            vertical: AppDimensions.paddingStandard,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          minimumSize: const Size(0, 52),
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mutedTeal,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingStandard,
            vertical: AppDimensions.paddingSmall,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.offWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingStandard,
          vertical: AppDimensions.paddingStandard,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.mutedTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.mauve, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.mauve, width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.mutedTeal,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Bottom Navigation Bar ────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.offWhite,
        selectedItemColor: AppColors.deepTeal,
        unselectedItemColor: AppColors.textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),

      // ── Navigation Bar (Material 3) ──────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.offWhite,
        indicatorColor: AppColors.lightTeal,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.deepTeal, size: 24);
          }
          return const IconThemeData(color: AppColors.textHint, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = GoogleFonts.notoSansKr(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
          if (states.contains(WidgetState.selected)) {
            return style.copyWith(color: AppColors.deepTeal);
          }
          return style.copyWith(color: AppColors.textHint);
        }),
        elevation: 0,
        shadowColor: AppColors.border,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paperWhite,
        selectedColor: AppColors.lightTeal,
        disabledColor: AppColors.warmBeige,
        labelStyle: textTheme.labelMedium,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingStandard,
          vertical: AppDimensions.paddingXSmall,
        ),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.offWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusCard),
          ),
        ),
        elevation: 0,
        dragHandleColor: AppColors.warmBeige,
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.offWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ── Snack Bar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.offWhite,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Progress Indicator ───────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.mutedTeal,
        linearTrackColor: AppColors.lightTeal,
        circularTrackColor: AppColors.lightTeal,
      ),

      // ── List Tile ────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.offWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingStandard,
          vertical: AppDimensions.paddingXSmall,
        ),
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: AppColors.textSecondary,
      ),

      // ── Icon ─────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: AppDimensions.iconStandard,
      ),

      // ── Float Action Button ──────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.deepTeal,
        foregroundColor: AppColors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),
    );
  }
}
