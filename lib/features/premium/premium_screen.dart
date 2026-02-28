import 'package:cafeondo/core/constants/app_colors.dart';
import 'package:cafeondo/core/constants/app_strings.dart';
import 'package:cafeondo/data/services/purchase_service.dart';
import 'package:cafeondo/features/premium/premium_viewmodel.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// PremiumScreen
// ---------------------------------------------------------------------------

/// 카페온도 프리미엄 구독 화면.
///
/// - 헤더: 골드 강조의 프리미엄 브랜딩
/// - 혜택 목록
/// - 월간/연간 가격 카드 선택
/// - 구독하기 CTA 버튼
/// - 구매 복원 버튼
/// - 구독 약관 안내
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(premiumViewModelProvider);
    final notifier = ref.read(premiumViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 구매 복원 텍스트 버튼 (상단)
          TextButton(
            onPressed:
                vm.isPurchasing ? null : () => notifier.restorePurchases(),
            child: Text(
              '구매 복원',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: _PremiumBody(vm: vm, notifier: notifier),
    );
  }
}

// ---------------------------------------------------------------------------
// 본문
// ---------------------------------------------------------------------------

class _PremiumBody extends StatelessWidget {
  final PremiumViewModel vm;
  final PremiumViewModelNotifier notifier;

  const _PremiumBody({required this.vm, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 히어로 섹션 ──────────────────────────────────────────────
          _HeroSection(),
          const SizedBox(height: 32.0),

          // ── 혜택 목록 ──────────────────────────────────────────────
          _BenefitsList(),
          const SizedBox(height: 32.0),

          // ── 가격 카드 ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '플랜 선택',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12.0),
                _PricingCard(
                  planType: PlanType.monthly,
                  isSelected: vm.selectedPlan == PlanType.monthly,
                  onTap: () => notifier.selectPlan(PlanType.monthly),
                ),
                const SizedBox(height: 10.0),
                _PricingCard(
                  planType: PlanType.yearly,
                  isSelected: vm.selectedPlan == PlanType.yearly,
                  onTap: () => notifier.selectPlan(PlanType.yearly),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28.0),

          // ── CTA 버튼 ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _SubscribeButton(vm: vm, notifier: notifier),
          ),
          const SizedBox(height: 16.0),

          // ── 약관 안내 ─────────────────────────────────────────────
          _TermsNote(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 히어로 섹션
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 28.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepTeal.withOpacity(0.06),
            AppColors.offWhite,
          ],
        ),
      ),
      child: Column(
        children: [
          // 왕관 아이콘
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withOpacity(0.18),
                  AppColors.gold.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 36,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 16.0),

          // 앱 이름
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '카페온도 ',
                  style: TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepTeal,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: '프리미엄',
                  style: TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          Text(
            '광고 없이, 더 깊이 카페를 탐색하세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 혜택 목록
// ---------------------------------------------------------------------------

class _BenefitsList extends StatelessWidget {
  static const List<_Benefit> _benefits = [
    _Benefit(
      icon: Icons.block_rounded,
      iconColor: AppColors.terra,
      title: '광고 없는 깔끔한 환경',
      subtitle: '배너, 네이티브 광고 완전 제거',
    ),
    _Benefit(
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.deepTeal,
      title: '상세 소음 분석 리포트',
      subtitle: '시간대별 상세 통계와 트렌드 분석',
    ),
    _Benefit(
      icon: Icons.save_rounded,
      iconColor: AppColors.mutedTeal,
      title: '무제한 측정 기록 저장',
      subtitle: '모든 측정 이력을 클라우드에 영구 보관',
    ),
    _Benefit(
      icon: Icons.workspace_premium_rounded,
      iconColor: AppColors.gold,
      title: '프리미엄 뱃지',
      subtitle: '프로필에 특별한 프리미엄 뱃지 표시',
    ),
    _Benefit(
      icon: Icons.headset_mic_rounded,
      iconColor: AppColors.olive,
      title: '우선 고객 지원',
      subtitle: '전용 채널을 통한 빠른 문의 처리',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프리미엄 혜택',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12.0),
          Container(
            decoration: BoxDecoration(
              color: AppColors.paperWhite,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _benefits.length; i++) ...[
                  _BenefitTile(benefit: _benefits[i]),
                  if (i < _benefits.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 52,
                      color: AppColors.divider,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _Benefit({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class _BenefitTile extends StatelessWidget {
  final _Benefit benefit;

  const _BenefitTile({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 13.0),
      child: Row(
        children: [
          // 아이콘 컨테이너
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: benefit.iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9.0),
            ),
            child: Icon(benefit.icon, size: 18, color: benefit.iconColor),
          ),
          const SizedBox(width: 12.0),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '✓  ',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        benefit.title,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  benefit.subtitle,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: AppColors.textHint,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 가격 카드
// ---------------------------------------------------------------------------

class _PricingCard extends StatelessWidget {
  final PlanType planType;
  final bool isSelected;
  final VoidCallback onTap;

  const _PricingCard({
    required this.planType,
    required this.isSelected,
    required this.onTap,
  });

  bool get _isYearly => planType == PlanType.yearly;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.deepTeal.withOpacity(0.06)
              : AppColors.paperWhite,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? AppColors.deepTeal : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.deepTeal.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              // 선택 라디오
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.deepTeal : AppColors.border,
                    width: 2.0,
                  ),
                  color: isSelected ? AppColors.deepTeal : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12.0),

              // 플랜 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _isYearly ? '연간 구독' : '월간 구독',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_isYearly) ...[
                          const SizedBox(width: 8.0),
                          _SavingsBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      _isYearly
                          ? '매년 자동 갱신'
                          : '매월 자동 갱신 · 언제든 취소 가능',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),

              // 가격
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isYearly ? '₩13,000' : '₩1,300',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.deepTeal
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _isYearly ? '/ 년' : '/ 월',
                    style: TextStyle(
                      fontSize: 11.0,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavingsBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold, Color(0xFFD4A017)],
        ),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        '16% 할인',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 구독하기 버튼
// ---------------------------------------------------------------------------

class _SubscribeButton extends StatelessWidget {
  final PremiumViewModel vm;
  final PremiumViewModelNotifier notifier;

  const _SubscribeButton({required this.vm, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.0,
      child: ElevatedButton(
        onPressed: vm.isPurchasing ? null : () => notifier.purchase(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terra,
          disabledBackgroundColor: AppColors.terra.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
        child: vm.isPurchasing
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withOpacity(0.8),
                ),
              )
            : Text(
                vm.selectedPlan == PlanType.yearly
                    ? '연간 구독하기 — ₩13,000/년'
                    : '월간 구독하기 — ₩1,300/월',
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 구독 약관 안내
// ---------------------------------------------------------------------------

class _TermsNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text(
            '구독은 현재 기기에서 확인 후 자동으로 갱신됩니다.\n'
            '갱신일 24시간 전에 취소하지 않으면 자동으로 결제됩니다.\n'
            'App Store / Google Play 계정 설정에서 언제든지 구독을 관리하거나 취소할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.0,
              color: AppColors.textHint,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8.0),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(fontSize: 11.0, color: AppColors.textHint),
              children: [
                TextSpan(
                  text: '이용약관',
                  style: TextStyle(
                    color: AppColors.mutedTeal,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: 이용약관 URL로 교체
                      launchUrl(Uri.parse(AppStrings.urlTerms));
                    },
                ),
                const TextSpan(text: ' 및 '),
                TextSpan(
                  text: '개인정보 처리방침',
                  style: TextStyle(
                    color: AppColors.mutedTeal,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: 개인정보 처리방침 URL로 교체
                      launchUrl(Uri.parse(AppStrings.urlPrivacy));
                    },
                ),
                const TextSpan(text: ' 에 동의합니다.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
