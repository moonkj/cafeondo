import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ---------------------------------------------------------------------------
// 광고 유닛 ID 상수
// ---------------------------------------------------------------------------

abstract class _AdUnitIds {
  _AdUnitIds._();

  // ── AdMob 앱 ID ────────────────────────────────────────────────────────
  // AndroidManifest.xml <meta-data> 에 설정 필요:
  //   Android: ca-app-pub-9059891578497774~5647595539
  //   iOS:     TODO - iOS AdMob 앱 등록 후 입력

  // ── 테스트 광고 ID (Google 공식 테스트 ID) ──────────────────────────────
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _testNativeAndroid =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _testNativeIos =
      'ca-app-pub-3940256099942544/3986624511';

  // ── 프로덕션 광고 ID (Android) ─────────────────────────────────────────
  // 배너형
  static const String _prodBannerHomeAndroid =
      'ca-app-pub-9059891578497774/8659607960';
  static const String _prodBannerDetailAndroid =
      'ca-app-pub-9059891578497774/9542133153';
  // 네이티브 고급형
  static const String _prodNativeHomeAndroid =
      'ca-app-pub-9059891578497774/7154954600';
  static const String _prodNativeDetailAndroid =
      'ca-app-pub-9059891578497774/1987076768';
  static const String _prodNativeRankingAndroid =
      'ca-app-pub-9059891578497774/9945457839';

  // ── 프로덕션 광고 ID (iOS) ─────────────────────────────────────────────
  // 배너형
  static const String _prodBannerHomeIos =
      'ca-app-pub-9059891578497774/8803766556';
  static const String _prodBannerDetailIos =
      'ca-app-pub-9059891578497774/7016517525';
  // 네이티브 고급형
  static const String _prodNativeHomeIos =
      'ca-app-pub-9059891578497774/3787243598';
  static const String _prodNativeDetailIos =
      'ca-app-pub-9059891578497774/3595671903';
  static const String _prodNativeRankingIos =
      'ca-app-pub-9059891578497774/5374969075';

  // ── 위치별 배너 ID 반환 ────────────────────────────────────────────────
  static String bannerForPlacement(AdPlacement placement) {
    if (kDebugMode) {
      return Platform.isIOS ? _testBannerIos : _testBannerAndroid;
    }
    switch (placement) {
      case AdPlacement.home:
        return Platform.isIOS
            ? _prodBannerHomeIos
            : _prodBannerHomeAndroid;
      case AdPlacement.cafeDetail:
        return Platform.isIOS
            ? _prodBannerDetailIos
            : _prodBannerDetailAndroid;
      default:
        // 기본값: 홈 배너 ID 사용
        return Platform.isIOS
            ? _prodBannerHomeIos
            : _prodBannerHomeAndroid;
    }
  }

  // ── 네이티브 ID 반환 ───────────────────────────────────────────────────
  static String nativeForPlacement(AdPlacement placement) {
    if (kDebugMode) {
      return Platform.isIOS ? _testNativeIos : _testNativeAndroid;
    }
    switch (placement) {
      case AdPlacement.home:
        return Platform.isIOS
            ? _prodNativeHomeIos
            : _prodNativeHomeAndroid;
      case AdPlacement.cafeDetail:
        return Platform.isIOS
            ? _prodNativeDetailIos
            : _prodNativeDetailAndroid;
      case AdPlacement.cafeList:
      case AdPlacement.ranking:
        return Platform.isIOS
            ? _prodNativeRankingIos
            : _prodNativeRankingAndroid;
      default:
        return Platform.isIOS
            ? _prodNativeRankingIos
            : _prodNativeRankingAndroid;
    }
  }
}

// ---------------------------------------------------------------------------
// 광고 노출 위치 enum
// ---------------------------------------------------------------------------

/// 광고가 표시되는 화면/위치를 나타냅니다.
/// - [home]: 홈(지도) 화면 → 배너 광고 허용
/// - [ranking]: 랭킹 화면 → 배너 광고 허용
/// - [cafeList]: 카페 목록 → 네이티브 광고 허용
/// - [other]: 그 외 화면 → 광고 비표시
enum AdPlacement { home, ranking, cafeDetail, cafeList, other }

// ---------------------------------------------------------------------------
// AdService
// ---------------------------------------------------------------------------

/// Google Mobile Ads SDK 초기화 및 배너/네이티브 광고 헬퍼를 제공합니다.
///
/// - 전면/인터스티셜 광고는 정책상 사용하지 않습니다.
/// - 프리미엄 사용자는 광고를 표시하지 않습니다.
/// - [AdPlacement] 기반 빈도 제어 → 허용된 화면에서만 광고 로드.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  bool _initialized = false;

  // ── SDK 초기화 ──────────────────────────────────────────────────────────

  /// 앱 시작 시 한 번 호출하세요. (main.dart 또는 앱 초기화 시점)
  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    debugPrint('[AdService] Google Mobile Ads SDK 초기화 완료');
  }

  // ── 배너 광고 ───────────────────────────────────────────────────────────

  /// 표준 배너(320×50)를 생성합니다.
  ///
  /// [placement]가 [AdPlacement.home] 또는 [AdPlacement.ranking]이 아니면
  /// null을 반환합니다. (빈도 제어)
  BannerAd? createBannerAd({
    required AdPlacement placement,
    required BannerAdListener listener,
    AdSize size = AdSize.banner, // 320×50
  }) {
    if (!_isBannerAllowed(placement)) return null;

    return BannerAd(
      adUnitId: _AdUnitIds.bannerForPlacement(placement),
      size: size,
      request: const AdRequest(),
      listener: listener,
    );
  }

  /// 큰 배너(320×100)를 생성합니다.
  BannerAd? createLargeBannerAd({
    required AdPlacement placement,
    required BannerAdListener listener,
  }) {
    if (!_isBannerAllowed(placement)) return null;

    return BannerAd(
      adUnitId: _AdUnitIds.bannerForPlacement(placement),
      size: AdSize.largeBanner, // 320×100
      request: const AdRequest(),
      listener: listener,
    );
  }

  /// 네이티브 광고를 생성합니다.
  ///
  /// [placement]가 [AdPlacement.cafeList]가 아니면 null을 반환합니다.
  NativeAd? createNativeAd({
    required AdPlacement placement,
    required NativeAdListener listener,
    required NativeTemplateStyle templateStyle,
  }) {
    if (!_isNativeAllowed(placement)) return null;

    return NativeAd(
      adUnitId: _AdUnitIds.nativeForPlacement(placement),
      listener: listener,
      request: const AdRequest(),
      nativeTemplateStyle: templateStyle,
    );
  }

  // ── 광고 로드 ───────────────────────────────────────────────────────────

  /// [BannerAd]를 로드합니다.
  Future<void> loadBannerAd(BannerAd ad) async {
    await ad.load();
  }

  /// [NativeAd]를 로드합니다.
  Future<void> loadNativeAd(NativeAd ad) async {
    await ad.load();
  }

  // ── 광고 해제 ───────────────────────────────────────────────────────────

  /// [BannerAd]를 안전하게 해제합니다.
  Future<void> disposeBannerAd(BannerAd? ad) async {
    await ad?.dispose();
  }

  /// [NativeAd]를 안전하게 해제합니다.
  Future<void> disposeNativeAd(NativeAd? ad) async {
    await ad?.dispose();
  }

  // ── 빈도 제어 내부 로직 ─────────────────────────────────────────────────

  bool _isBannerAllowed(AdPlacement placement) {
    return placement == AdPlacement.home ||
        placement == AdPlacement.ranking ||
        placement == AdPlacement.cafeDetail;
  }

  bool _isNativeAllowed(AdPlacement placement) {
    return placement == AdPlacement.cafeList ||
        placement == AdPlacement.home ||
        placement == AdPlacement.cafeDetail ||
        placement == AdPlacement.ranking;
  }
}

// ---------------------------------------------------------------------------
// Riverpod 프로바이더
// ---------------------------------------------------------------------------

/// [AdService] 싱글톤 프로바이더.
final adServiceProvider = Provider<AdService>((ref) {
  return AdService.instance;
});
