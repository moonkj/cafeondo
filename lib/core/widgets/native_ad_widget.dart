import 'package:cafeondo/core/constants/app_colors.dart';
import 'package:cafeondo/data/services/ad_service.dart';
import 'package:cafeondo/providers/premium_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ---------------------------------------------------------------------------
// NativeAdWidget
// ---------------------------------------------------------------------------

/// 카페 목록에 삽입되는 네이티브 광고 위젯.
///
/// - CafeCard 디자인(둥근 모서리, 테두리, 동일 패딩)과 일치
/// - 오른쪽 상단에 "광고" 레이블 표시 (Google 정책 준수)
/// - 프리미엄 사용자: 광고 미표시
/// - 오류 발생: 빈 SizedBox 반환
class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({super.key});

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adService = ref.read(adServiceProvider);

    // 앱 색상과 어울리는 네이티브 템플릿 스타일
    final templateStyle = NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: AppColors.paperWhite,
      cornerRadius: 12.0,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.white,
        backgroundColor: AppColors.terra,
        style: NativeTemplateFontStyle.bold,
        size: 13.0,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textPrimary,
        backgroundColor: AppColors.paperWhite,
        style: NativeTemplateFontStyle.bold,
        size: 14.0,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textSecondary,
        backgroundColor: AppColors.paperWhite,
        style: NativeTemplateFontStyle.normal,
        size: 12.0,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textHint,
        backgroundColor: AppColors.paperWhite,
        style: NativeTemplateFontStyle.normal,
        size: 11.0,
      ),
    );

    final listener = NativeAdListener(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isLoaded = true;
            _hasError = false;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('[NativeAd] 로드 실패: ${error.message}');
        ad.dispose();
        if (mounted) {
          setState(() {
            _nativeAd = null;
            _hasError = true;
          });
        }
      },
    );

    final ad = adService.createNativeAd(
      placement: AdPlacement.cafeList,
      listener: listener,
      templateStyle: templateStyle,
    );

    if (ad == null) return;

    _nativeAd = ad;
    await adService.loadNativeAd(ad);
  }

  @override
  void dispose() {
    ref.read(adServiceProvider).disposeNativeAd(_nativeAd);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 프리미엄 사용자 → 광고 숨김
    final showAds = ref.watch(showAdsProvider);
    if (!showAds) return const SizedBox.shrink();

    // 오류 또는 광고 없음
    if (_hasError || _nativeAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }

    return _NativeAdCard(nativeAd: _nativeAd!);
  }
}

// ---------------------------------------------------------------------------
// 내부 위젯: 네이티브 광고 카드
// ---------------------------------------------------------------------------

class _NativeAdCard extends StatelessWidget {
  final NativeAd nativeAd;

  const _NativeAdCard({required this.nativeAd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 네이티브 광고 콘텐츠
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80.0),
            child: AdWidget(ad: nativeAd),
          ),

          // "광고" 레이블 (정책 필수 표시)
          Positioned(
            top: 8.0,
            right: 10.0,
            child: _AdLabel(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "광고" 레이블 위젯
// ---------------------------------------------------------------------------

class _AdLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: AppColors.warmBeige,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Text(
        '광고',
        style: TextStyle(
          fontSize: 9.0,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
