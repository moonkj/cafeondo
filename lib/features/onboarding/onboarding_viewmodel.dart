import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kOnboardingCompletedKey = 'onboarding_completed';
const int kOnboardingPageCount = 3;

// ── Onboarding State ──────────────────────────────────────────────────────────

class OnboardingState {
  final int currentPage;
  final bool isCompleting;

  const OnboardingState({
    this.currentPage = 0,
    this.isCompleting = false,
  });

  bool get isLastPage => currentPage == kOnboardingPageCount - 1;

  OnboardingState copyWith({
    int? currentPage,
    bool? isCompleting,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isCompleting: isCompleting ?? this.isCompleting,
    );
  }
}

// ── Onboarding ViewModel ──────────────────────────────────────────────────────

class OnboardingViewModel extends StateNotifier<OnboardingState> {
  OnboardingViewModel() : super(const OnboardingState());

  final PageController pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void onPageChanged(int page) {
    state = state.copyWith(currentPage: page);
  }

  void nextPage() {
    if (state.isLastPage) return;
    pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> completeOnboarding() async {
    if (state.isCompleting) return;
    state = state.copyWith(isCompleting: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingCompletedKey, true);
    } catch (_) {
      // 저장 실패해도 온보딩은 완료 처리
    } finally {
      state = state.copyWith(isCompleting: false);
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final onboardingProvider =
    StateNotifierProvider.autoDispose<OnboardingViewModel, OnboardingState>(
  (ref) => OnboardingViewModel(),
);

/// 온보딩 완료 여부 확인 (앱 시작 시 사용)
final isOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingCompletedKey) ?? false;
});
