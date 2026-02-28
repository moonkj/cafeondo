import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// 상품 ID 상수
// ---------------------------------------------------------------------------

abstract class PurchaseProductIds {
  PurchaseProductIds._();

  /// 월간 구독 ID — $0.99/month
  static const String monthly = 'cafeondo_premium_monthly';

  /// 연간 구독 ID — $9.99/year
  static const String yearly = 'cafeondo_premium_yearly';

  static const Set<String> all = {monthly, yearly};
}

// ---------------------------------------------------------------------------
// PremiumStatus 모델
// ---------------------------------------------------------------------------

/// 구독 플랜 타입
enum PlanType { monthly, yearly, none }

/// 현재 프리미엄 상태를 나타내는 모델
class PremiumStatus {
  final bool isPremium;
  final DateTime? expiryDate;
  final PlanType planType;

  const PremiumStatus({
    required this.isPremium,
    this.expiryDate,
    required this.planType,
  });

  /// 프리미엄이 아닌 기본 상태
  factory PremiumStatus.free() => const PremiumStatus(
        isPremium: false,
        expiryDate: null,
        planType: PlanType.none,
      );

  /// 활성 프리미엄 상태
  factory PremiumStatus.active({
    required PlanType planType,
    DateTime? expiryDate,
  }) =>
      PremiumStatus(
        isPremium: true,
        expiryDate: expiryDate,
        planType: planType,
      );

  String get planLabel {
    switch (planType) {
      case PlanType.monthly:
        return '월간 구독';
      case PlanType.yearly:
        return '연간 구독';
      case PlanType.none:
        return '무료';
    }
  }

  String get expiryLabel {
    if (expiryDate == null) return '';
    final y = expiryDate!.year;
    final m = expiryDate!.month.toString().padLeft(2, '0');
    final d = expiryDate!.day.toString().padLeft(2, '0');
    return '$y년 ${m}월 ${d}일까지';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PremiumStatus &&
          other.isPremium == isPremium &&
          other.planType == planType &&
          other.expiryDate == expiryDate);

  @override
  int get hashCode =>
      isPremium.hashCode ^ planType.hashCode ^ expiryDate.hashCode;
}

// ---------------------------------------------------------------------------
// SharedPreferences 키
// ---------------------------------------------------------------------------

abstract class _PrefKeys {
  _PrefKeys._();
  static const String isPremium = 'cafeondo_is_premium';
  static const String planType = 'cafeondo_plan_type';
  static const String expiryDate = 'cafeondo_expiry_date';
}

// ---------------------------------------------------------------------------
// PurchaseService
// ---------------------------------------------------------------------------

/// 인앱 구매(구독) 서비스.
///
/// - 상품 조회, 구매, 구매 복원 기능을 제공합니다.
/// - 구독 가격: 월간 $0.99 / 연간 $9.99
/// - 클라이언트 사이드 기본 검증 수행.
///   TODO: 서버 사이드 검증(Receipt Validation)을 추가하세요.
/// - [PremiumStatus]는 [SharedPreferences]에 캐시됩니다.
class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;

  // 상품 목록
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => List.unmodifiable(_products);

  // 구매 스트림 구독
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // 상태 변경 콜백 (뷰모델에서 등록)
  void Function(PremiumStatus)? onPremiumStatusChanged;
  void Function(String message, {bool isError})? onPurchaseMessage;

  // ── 초기화 ──────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[PurchaseService] 인앱 구매를 사용할 수 없습니다.');
      return;
    }

    // 구매 스트림 리스너 등록
    _purchaseSubscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        debugPrint('[PurchaseService] 구매 스트림 오류: $error');
        onPurchaseMessage?.call('구매 중 오류가 발생했어요.', isError: true);
      },
    );

    await queryProducts();
    debugPrint('[PurchaseService] 초기화 완료');
  }

  // ── 상품 조회 ──────────────────────────────────────────────────────────

  Future<void> queryProducts() async {
    final response = await _iap.queryProductDetails(PurchaseProductIds.all);

    if (response.error != null) {
      debugPrint('[PurchaseService] 상품 조회 오류: ${response.error}');
      return;
    }

    _products = response.productDetails;
    debugPrint('[PurchaseService] 조회된 상품: ${_products.map((p) => p.id).toList()}');
  }

  // ── 구매 ────────────────────────────────────────────────────────────────

  /// [productId]에 해당하는 구독 상품을 구매합니다.
  ///
  /// 반환값: 구매 시도 성공 여부 (실제 결과는 [onPremiumStatusChanged]로 전달)
  Future<bool> purchase(String productId) async {
    final product = _products.where((p) => p.id == productId).firstOrNull;
    if (product == null) {
      debugPrint('[PurchaseService] 상품을 찾을 수 없음: $productId');
      onPurchaseMessage?.call('상품 정보를 불러올 수 없어요.', isError: true);
      return false;
    }

    final param = PurchaseParam(productDetails: product);
    try {
      // 구독 상품은 buyNonConsumable 사용 (iOS/Android 공통)
      final result = await _iap.buyNonConsumable(purchaseParam: param);
      return result;
    } catch (e) {
      debugPrint('[PurchaseService] 구매 오류: $e');
      onPurchaseMessage?.call('구매 중 오류가 발생했어요.', isError: true);
      return false;
    }
  }

  // ── 구매 복원 ──────────────────────────────────────────────────────────

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      debugPrint('[PurchaseService] 구매 복원 요청 완료');
    } catch (e) {
      debugPrint('[PurchaseService] 구매 복원 오류: $e');
      onPurchaseMessage?.call('구매 복원 중 오류가 발생했어요.', isError: true);
    }
  }

  // ── 구매 스트림 처리 ───────────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _processPurchase(purchase);
    }
  }

  Future<void> _processPurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        debugPrint('[PurchaseService] 구매 대기 중: ${purchase.productID}');
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // ── 클라이언트 사이드 기본 검증 ──────────────────────────────────
        // TODO: 실제 서비스에서는 서버 사이드 영수증 검증(Apple/Google)을 구현하세요.
        //       서버 API 엔드포인트에 purchase.verificationData를 전송하여
        //       유효성을 확인하고 구독 만료일을 업데이트하세요.
        final isValid = _basicClientSideVerification(purchase);

        if (isValid) {
          final planType = _getPlanType(purchase.productID);
          final status = PremiumStatus.active(planType: planType);
          await _savePremiumStatus(status);
          onPremiumStatusChanged?.call(status);
          onPurchaseMessage?.call(
            purchase.status == PurchaseStatus.restored
                ? '구매가 복원되었어요!'
                : '프리미엄 구독이 시작되었어요!',
          );
        }
        break;

      case PurchaseStatus.error:
        debugPrint('[PurchaseService] 구매 오류: ${purchase.error?.message}');
        onPurchaseMessage?.call('구매에 실패했어요. 다시 시도해주세요.', isError: true);
        break;

      case PurchaseStatus.canceled:
        debugPrint('[PurchaseService] 구매 취소됨');
        break;
    }

    // 구매 완료 처리 (필수)
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  // ── 클라이언트 사이드 기본 검증 ───────────────────────────────────────

  /// 기본적인 클라이언트 사이드 검증.
  ///
  /// 실제 프로덕션에서는 서버로 [PurchaseDetails.verificationData]를 전달하여
  /// Apple App Store / Google Play 서버에서 검증받아야 합니다.
  bool _basicClientSideVerification(PurchaseDetails purchase) {
    // 상품 ID가 알려진 상품인지 확인
    if (!PurchaseProductIds.all.contains(purchase.productID)) {
      debugPrint('[PurchaseService] 알 수 없는 상품 ID: ${purchase.productID}');
      return false;
    }
    // 검증 데이터 존재 여부 확인
    if (purchase.verificationData.serverVerificationData.isEmpty) {
      debugPrint('[PurchaseService] 검증 데이터 없음');
      return false;
    }
    return true;
  }

  // ── 프리미엄 상태 영속화 ───────────────────────────────────────────────

  Future<void> _savePremiumStatus(PremiumStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefKeys.isPremium, status.isPremium);
    await prefs.setString(_PrefKeys.planType, status.planType.name);
    if (status.expiryDate != null) {
      await prefs.setString(
          _PrefKeys.expiryDate, status.expiryDate!.toIso8601String());
    }
  }

  Future<PremiumStatus> loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(_PrefKeys.isPremium) ?? false;
    if (!isPremium) return PremiumStatus.free();

    final planTypeStr = prefs.getString(_PrefKeys.planType) ?? 'none';
    final planType = PlanType.values.firstWhere(
      (e) => e.name == planTypeStr,
      orElse: () => PlanType.none,
    );

    final expiryStr = prefs.getString(_PrefKeys.expiryDate);
    final expiryDate =
        expiryStr != null ? DateTime.tryParse(expiryStr) : null;

    return PremiumStatus.active(planType: planType, expiryDate: expiryDate);
  }

  // ── 유틸리티 ───────────────────────────────────────────────────────────

  PlanType _getPlanType(String productId) {
    switch (productId) {
      case PurchaseProductIds.monthly:
        return PlanType.monthly;
      case PurchaseProductIds.yearly:
        return PlanType.yearly;
      default:
        return PlanType.none;
    }
  }

  // ── 해제 ────────────────────────────────────────────────────────────────

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }
}

// ---------------------------------------------------------------------------
// Riverpod 프로바이더
// ---------------------------------------------------------------------------

/// [PurchaseService] 프로바이더.
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

/// 현재 [PremiumStatus] 상태 프로바이더 (Riverpod 3.0 Notifier 패턴).
final premiumStatusNotifierProvider =
    NotifierProvider<PremiumStatusNotifier, PremiumStatus>(
  PremiumStatusNotifier.new,
);

class PremiumStatusNotifier extends Notifier<PremiumStatus> {
  @override
  PremiumStatus build() {
    _init();
    return PremiumStatus.free();
  }

  Future<void> _init() async {
    final service = ref.read(purchaseServiceProvider);

    // 캐시에서 프리미엄 상태 로드
    final cached = await service.loadPremiumStatus();
    if (!ref.mounted) return;
    state = cached;

    // 콜백 등록: 구매 완료 시 상태 업데이트
    service.onPremiumStatusChanged = (status) {
      if (ref.mounted) state = status;
    };
  }

  void update(PremiumStatus status) {
    state = status;
  }
}
