/// 카페온도 앱 치수(Dimension) 상수
abstract class AppDimensions {
  AppDimensions._();

  // ── Border Radius ───────────────────────────────────────────────────────────
  /// 카드용 기본 라운드 (16px)
  static const double radiusCard = 16.0;

  /// 버튼용 라운드 (24px)
  static const double radiusButton = 24.0;

  /// 작은 요소 라운드 (12px)
  static const double radiusSmall = 12.0;

  /// 배지/칩 라운드 (8px)
  static const double radiusBadge = 8.0;

  /// 아주 작은 요소 (4px)
  static const double radiusXSmall = 4.0;

  /// 원형 (완전한 타원)
  static const double radiusFull = 999.0;

  // ── Padding ─────────────────────────────────────────────────────────────────
  /// 기본 패딩 (16px)
  static const double paddingStandard = 16.0;

  /// 섹션 패딩 (24px)
  static const double paddingSection = 24.0;

  /// 작은 패딩 (8px)
  static const double paddingSmall = 8.0;

  /// 아주 작은 패딩 (4px)
  static const double paddingXSmall = 4.0;

  /// 큰 패딩 (32px)
  static const double paddingLarge = 32.0;

  // ── Icon Sizes ───────────────────────────────────────────────────────────────
  /// 기본 아이콘 크기 (24px)
  static const double iconStandard = 24.0;

  /// 중간 아이콘 크기 (20px)
  static const double iconMedium = 20.0;

  /// 작은 아이콘 크기 (16px)
  static const double iconSmall = 16.0;

  /// 큰 아이콘 크기 (32px)
  static const double iconLarge = 32.0;

  // ── Card ────────────────────────────────────────────────────────────────────
  /// 플랫 디자인 - elevation 없음 (미세한 border 사용)
  static const double cardElevation = 0.0;

  /// 카드 border 두께
  static const double cardBorderWidth = 1.0;

  // ── Bottom Sheet ─────────────────────────────────────────────────────────────
  static const double bottomSheetMinHeight = 120.0;
  static const double bottomSheetMaxHeight = 0.85; // 화면 비율

  // ── AppBar ──────────────────────────────────────────────────────────────────
  static const double appBarHeight = 56.0;

  // ── Map Markers ─────────────────────────────────────────────────────────────
  static const double markerSize = 40.0;

  // ── Noise Gauge ─────────────────────────────────────────────────────────────
  static const double gaugeSize = 240.0;

  // ── Avatar ───────────────────────────────────────────────────────────────────
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 80.0;
}
