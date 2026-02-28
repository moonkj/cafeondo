import 'package:flutter/material.dart';

/// 카페온도 앱 컬러 팔레트
/// 모던 & 클린 디자인 시스템
abstract class AppColors {
  AppColors._();

  // ── Primary Dark Tones ──────────────────────────────────────────────────────
  /// 가장 어두운 네이비. 헤더, 텍스트 등에 사용
  static const Color navy = Color(0xFF091717);

  /// 다크 틸. 앱바, 카드 헤더 등에 사용
  static const Color darkTeal = Color(0xFF13343B);

  /// 딥 틸. 주요 강조색
  static const Color deepTeal = Color(0xFF115058);

  // ── Accent Tones ────────────────────────────────────────────────────────────
  /// 뮤트 틸. 버튼, 배지, 인터랙티브 요소
  static const Color mutedTeal = Color(0xFF20808D);

  /// 라이트 틸. 배경 강조, 칩, 뱃지 배경
  static const Color lightTeal = Color(0xFFD6F5FA);

  // ── Surface / Background ────────────────────────────────────────────────────
  /// 오프 화이트. 메인 배경
  static const Color offWhite = Color(0xFFFCFAF6);

  /// 페이퍼 화이트. 카드 배경
  static const Color paperWhite = Color(0xFFF3F3EE);

  /// 웜 베이지. 보조 카드, 구분선
  static const Color warmBeige = Color(0xFFE5E3D4);

  // ── Warm Accent / Status ────────────────────────────────────────────────────
  /// 테라코타. CTA 버튼, 경고(noisy)
  static const Color terra = Color(0xFFA84B2F);

  /// 모브. 에러, loud 소음 등급
  static const Color mauve = Color(0xFF944454);

  /// 골드. 프리미엄 요소, 랭킹
  static const Color gold = Color(0xFFB8860B);

  /// 올리브. 보통(moderate) 소음 등급
  static const Color olive = Color(0xFF848456);

  // ── Semantic Noise Colors ───────────────────────────────────────────────────
  /// quiet (0–40dB): 초록빛 틸
  static const Color noiseQuiet = mutedTeal;

  /// quiet 배경
  static const Color noiseQuietBg = lightTeal;

  /// moderate (40–60dB): 올리브
  static const Color noiseModerate = olive;

  /// moderate 배경
  static const Color noiseModerateBg = warmBeige;

  /// noisy (60–75dB): 테라코타
  static const Color noiseNoisy = terra;

  /// noisy 배경
  static const Color noiseNoisyBg = Color(0xFFF5DDD7);

  /// loud (75+dB): 모브
  static const Color noiseLoud = mauve;

  /// loud 배경
  static const Color noiseLoudBg = Color(0xFFF5D9DE);

  // ── Neutral / UI ────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE0DDD3);
  static const Color border = Color(0xFFD8D5C8);
  static const Color textPrimary = navy;
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textHint = Color(0xFF9AA3AE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Chart Colors ─────────────────────────────────────────────────────────────
  static const Color chartLine = mutedTeal;
  static const Color chartFillTop = Color(0x6020808D);
  static const Color chartFillBottom = Color(0x0020808D);
}
