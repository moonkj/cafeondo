import 'package:cafeondo/data/services/purchase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// premium_providers.dart
//
// 앱 전체에서 프리미엄 상태를 참조할 수 있는 파생 프로바이더 모음.
// purchase_service.dart의 [premiumStatusNotifierProvider]를 기반으로 합니다.
// ---------------------------------------------------------------------------

// [premiumStatusNotifierProvider]는 purchase_service.dart에서 정의됩니다.
// 다른 파일에서 import 편의를 위해 re-export합니다.
export 'package:cafeondo/data/services/purchase_service.dart'
    show
        premiumStatusNotifierProvider,
        PremiumStatus,
        PremiumStatusNotifier,
        PlanType,
        PurchaseProductIds;

/// 현재 [PremiumStatus]를 노출합니다.
///
/// 사용 예:
/// ```dart
/// final status = ref.watch(premiumStatusProvider);
/// if (status.isPremium) { ... }
/// ```
final premiumStatusProvider = Provider<PremiumStatus>((ref) {
  return ref.watch(premiumStatusNotifierProvider);
});

/// 사용자가 프리미엄 구독 중인지 여부.
///
/// 사용 예:
/// ```dart
/// final isPremium = ref.watch(isPremiumProvider);
/// ```
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(premiumStatusProvider).isPremium;
});

/// 광고를 표시해야 하는지 여부.
///
/// - 프리미엄 사용자: false (광고 미표시)
/// - 무료 사용자: true (광고 표시)
///
/// 사용 예:
/// ```dart
/// final showAds = ref.watch(showAdsProvider);
/// if (showAds) { /* 광고 표시 */ }
/// ```
final showAdsProvider = Provider<bool>((ref) {
  return !ref.watch(isPremiumProvider);
});

/// 현재 구독 플랜 타입.
final currentPlanTypeProvider = Provider<PlanType>((ref) {
  return ref.watch(premiumStatusProvider).planType;
});

/// 구독 만료일 (없으면 null).
final subscriptionExpiryProvider = Provider<DateTime?>((ref) {
  return ref.watch(premiumStatusProvider).expiryDate;
});
