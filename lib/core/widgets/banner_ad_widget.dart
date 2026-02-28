import 'package:cafeondo/core/constants/app_colors.dart';
import 'package:cafeondo/data/services/ad_service.dart';
import 'package:cafeondo/providers/premium_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ---------------------------------------------------------------------------
// BannerAdWidget
// ---------------------------------------------------------------------------

/// 재사용 가능한 배너 광고 위젯.
///
/// - 프리미엄 사용자: 광고 미표시 (빈 SizedBox 반환)
/// - 로딩 중: 심머(shimmer) 플레이스홀더 표시
/// - 오류 발생: 빈 SizedBox 반환 (광고 공간 낭비 없음)
/// - 위젯 제거 시 BannerAd 자동 해제
///
/// 사용 예:
/// ```dart
/// BannerAdWidget(placement: AdPlacement.home)
/// BannerAdWidget(placement: AdPlacement.ranking, large: true)
/// ```
class BannerAdWidget extends ConsumerStatefulWidget {
  final AdPlacement placement;

  /// true → 큰 배너(320×100), false → 표준 배너(320×50)
  final bool large;

  const BannerAdWidget({
    super.key,
    required this.placement,
    this.large = false,
  });

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _hasError = false;

  double get _adHeight => widget.large ? 100.0 : 50.0;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adService = ref.read(adServiceProvider);

    final listener = BannerAdListener(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isLoaded = true;
            _hasError = false;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('[BannerAd] 로드 실패: ${error.message}');
        ad.dispose();
        if (mounted) {
          setState(() {
            _bannerAd = null;
            _hasError = true;
          });
        }
      },
    );

    final ad = widget.large
        ? adService.createLargeBannerAd(
            placement: widget.placement,
            listener: listener,
          )
        : adService.createBannerAd(
            placement: widget.placement,
            listener: listener,
          );

    if (ad == null) {
      // 빈도 제어에 의해 광고 미표시
      return;
    }

    _bannerAd = ad;
    await adService.loadBannerAd(ad);
  }

  @override
  void dispose() {
    ref.read(adServiceProvider).disposeBannerAd(_bannerAd);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 프리미엄 사용자 → 광고 숨김
    final showAds = ref.watch(showAdsProvider);
    if (!showAds) return const SizedBox.shrink();

    // 오류 또는 광고 없음 → 빈 공간 반환
    if (_hasError || _bannerAd == null) return const SizedBox.shrink();

    // 로딩 중 → 심머 플레이스홀더
    if (!_isLoaded) {
      return _ShimmerPlaceholder(height: _adHeight);
    }

    // 광고 표시
    return _AdContainer(
      height: _adHeight,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// ---------------------------------------------------------------------------
// 내부 위젯: 광고 컨테이너
// ---------------------------------------------------------------------------

class _AdContainer extends StatelessWidget {
  final double height;
  final Widget child;

  const _AdContainer({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// 내부 위젯: 심머 플레이스홀더
// ---------------------------------------------------------------------------

class _ShimmerPlaceholder extends StatefulWidget {
  final double height;
  const _ShimmerPlaceholder({required this.height});

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.warmBeige.withOpacity(_animation.value),
                  AppColors.paperWhite.withOpacity(_animation.value + 0.1),
                  AppColors.warmBeige.withOpacity(_animation.value),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}
