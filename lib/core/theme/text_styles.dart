import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// 카페온도 타이포그래피 스타일 정의
/// Pretendard(Noto Sans KR) 폰트 기반
abstract class AppTextStyles {
  AppTextStyles._();

  // ── Base Font ────────────────────────────────────────────────────────────────
  static TextStyle _base({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.notoSansKr(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
      );

  // ── Display ──────────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => _base(
        fontSize: 57,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.25,
        height: 1.12,
      );

  static TextStyle get displayMedium => _base(
        fontSize: 45,
        fontWeight: FontWeight.w300,
        letterSpacing: 0,
        height: 1.16,
      );

  static TextStyle get displaySmall => _base(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
      );

  // ── Headline ─────────────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => _base(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
      );

  static TextStyle get headlineMedium => _base(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.29,
      );

  static TextStyle get headlineSmall => _base(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.33,
      );

  // ── Title ────────────────────────────────────────────────────────────────────
  static TextStyle get titleLarge => _base(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.27,
      );

  static TextStyle get titleMedium => _base(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.5,
      );

  static TextStyle get titleSmall => _base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      );

  // ── Body ─────────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _base(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle get bodyMedium => _base(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.25,
        height: 1.43,
      );

  static TextStyle get bodySmall => _base(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
        height: 1.33,
      );

  // ── Label ────────────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => _base(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.43,
      );

  static TextStyle get labelMedium => _base(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
        height: 1.33,
      );

  static TextStyle get labelSmall => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
        letterSpacing: 0.5,
        height: 1.45,
      );

  // ── App-specific Styles ───────────────────────────────────────────────────────

  /// 데시벨 숫자 표시용 (큰 숫자)
  static TextStyle get decibelLarge => _base(
        fontSize: 72,
        fontWeight: FontWeight.w700,
        color: AppColors.deepTeal,
        letterSpacing: -2,
        height: 1.0,
      );

  /// 데시벨 단위 표시 (dB)
  static TextStyle get decibelUnit => _base(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0,
      );

  /// 카페명 (카드 제목)
  static TextStyle get cafeName => _base(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
      );

  /// 카페 주소
  static TextStyle get cafeAddress => _base(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
        letterSpacing: 0.2,
        height: 1.4,
      );

  /// 소음 레벨 배지 텍스트
  static TextStyle get noiseBadge => _base(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      );

  /// 차트 축 레이블
  static TextStyle get chartLabel => _base(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
        letterSpacing: 0.3,
      );

  /// 차트 값 레이블
  static TextStyle get chartValue => _base(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  /// 섹션 헤더
  static TextStyle get sectionHeader => _base(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
      );

  /// 작은 캡션 (메타 정보)
  static TextStyle get caption => _base(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textHint,
        letterSpacing: 0.3,
      );

  /// 버튼 텍스트 (기본)
  static TextStyle get button => _base(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      );

  /// 버튼 텍스트 (작은)
  static TextStyle get buttonSmall => _base(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  /// 랭킹 순위 번호
  static TextStyle get rankNumber => _base(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.gold,
        letterSpacing: -0.5,
      );

  /// 레벨 표시
  static TextStyle get levelBadge => _base(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 0.5,
      );

  /// 탭 레이블
  static TextStyle get tabLabel => _base(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  // ── Color Variants ────────────────────────────────────────────────────────────

  /// 기본 스타일에 색상 오버라이드
  static TextStyle withColor(TextStyle style, Color color) =>
      style.copyWith(color: color);

  /// 기본 스타일에 폰트 가중치 오버라이드
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(fontWeight: weight);

  /// primary 색상 적용
  static TextStyle get bodyMediumPrimary =>
      bodyMedium.copyWith(color: AppColors.textPrimary);

  static TextStyle get bodySmallTeal =>
      bodySmall.copyWith(color: AppColors.mutedTeal);

  static TextStyle get labelMediumTerra =>
      labelMedium.copyWith(color: AppColors.terra, fontWeight: FontWeight.w700);
}
