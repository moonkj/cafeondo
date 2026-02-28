import 'package:cafeondo/data/services/purchase_service.dart';
import 'package:cafeondo/providers/premium_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// PremiumViewModel 상태
// ---------------------------------------------------------------------------

class PremiumViewModel {
  final List<ProductInfo> products;
  final PlanType selectedPlan;
  final bool isPurchasing;
  final PremiumStatus premiumStatus;

  const PremiumViewModel({
    required this.products,
    required this.selectedPlan,
    required this.isPurchasing,
    required this.premiumStatus,
  });

  bool get isPremium => premiumStatus.isPremium;

  PremiumViewModel copyWith({
    List<ProductInfo>? products,
    PlanType? selectedPlan,
    bool? isPurchasing,
    PremiumStatus? premiumStatus,
  }) {
    return PremiumViewModel(
      products: products ?? this.products,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      premiumStatus: premiumStatus ?? this.premiumStatus,
    );
  }
}

// ---------------------------------------------------------------------------
// 상품 정보 표시 모델
// ---------------------------------------------------------------------------

class ProductInfo {
  final String id;
  final String title;
  final String price;
  final PlanType planType;

  const ProductInfo({
    required this.id,
    required this.title,
    required this.price,
    required this.planType,
  });
}

// ---------------------------------------------------------------------------
// PremiumViewModelNotifier
// ---------------------------------------------------------------------------

class PremiumViewModelNotifier extends StateNotifier<PremiumViewModel> {
  final PurchaseService _purchaseService;
  final Ref _ref;

  PremiumViewModelNotifier(this._purchaseService, this._ref)
      : super(PremiumViewModel(
          products: const [],
          selectedPlan: PlanType.yearly, // 기본 선택: 연간 (더 유리)
          isPurchasing: false,
          premiumStatus: PremiumStatus.free(),
        )) {
    _init();
  }

  Future<void> _init() async {
    // 상품 목록 로드
    await _loadProducts();

    // 현재 프리미엄 상태 반영
    final currentStatus =
        _ref.read(premiumStatusNotifierProvider);
    state = state.copyWith(premiumStatus: currentStatus);

    // 구매 결과 콜백 등록
    _purchaseService.onPremiumStatusChanged = (status) {
      state = state.copyWith(premiumStatus: status, isPurchasing: false);
      // 전역 프리미엄 상태 업데이트
      _ref.read(premiumStatusNotifierProvider.notifier).update(status);
    };
  }

  Future<void> _loadProducts() async {
    final rawProducts = _purchaseService.products;

    final infos = rawProducts.map((p) {
      final planType = p.id == PurchaseProductIds.yearly
          ? PlanType.yearly
          : PlanType.monthly;

      return ProductInfo(
        id: p.id,
        title: planType == PlanType.yearly ? '연간 구독' : '월간 구독',
        price: p.price, // 스토어에서 가져온 현지화 가격
        planType: planType,
      );
    }).toList();

    // 상품 목록을 월간 → 연간 순으로 정렬
    infos.sort((a, b) => a.planType == PlanType.monthly ? -1 : 1);

    state = state.copyWith(products: infos);
  }

  // ── 플랜 선택 ────────────────────────────────────────────────────────────

  void selectPlan(PlanType planType) {
    state = state.copyWith(selectedPlan: planType);
  }

  // ── 구매 ─────────────────────────────────────────────────────────────────

  Future<void> purchase(BuildContext context) async {
    if (state.isPurchasing) return;

    final productId = state.selectedPlan == PlanType.yearly
        ? PurchaseProductIds.yearly
        : PurchaseProductIds.monthly;

    state = state.copyWith(isPurchasing: true);

    final success = await _purchaseService.purchase(productId);

    if (!success) {
      // 구매 시작 실패 시 즉시 상태 복구
      // 실제 구매 결과는 onPremiumStatusChanged 콜백으로 처리됨
      state = state.copyWith(isPurchasing: false);
    }
    // 성공 시에는 콜백에서 isPurchasing = false 처리
  }

  // ── 구매 복원 ─────────────────────────────────────────────────────────────

  Future<void> restorePurchases() async {
    if (state.isPurchasing) return;
    state = state.copyWith(isPurchasing: true);
    await _purchaseService.restorePurchases();
    // 복원 결과는 콜백에서 처리. 결과가 없을 경우 상태 복구.
    await Future.delayed(const Duration(seconds: 3));
    if (mounted && state.isPurchasing) {
      state = state.copyWith(isPurchasing: false);
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod 프로바이더
// ---------------------------------------------------------------------------

/// [PremiumViewModelNotifier] 프로바이더.
final premiumViewModelProvider =
    StateNotifierProvider<PremiumViewModelNotifier, PremiumViewModel>((ref) {
  final purchaseService = ref.watch(purchaseServiceProvider);
  return PremiumViewModelNotifier(purchaseService, ref);
});
