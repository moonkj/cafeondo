import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cafeondo/core/constants/app_colors.dart';
import 'package:cafeondo/core/constants/app_dimensions.dart';
import 'package:cafeondo/app.dart';
import 'onboarding_viewmodel.dart';

// ── Page Data ─────────────────────────────────────────────────────────────────

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData primaryIcon;
  final List<IconData> decorativeIcons;
  final Color accentColor;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.primaryIcon,
    required this.decorativeIcons,
    required this.accentColor,
  });
}

const _pages = [
  _OnboardingPageData(
    title: '카페의 소음,\n직접 측정해보세요',
    subtitle: '스마트폰 마이크로 카페의 실제 소음을\n측정하고 데이터를 쌓아가요',
    primaryIcon: Icons.graphic_eq,
    decorativeIcons: [
      Icons.mic,
      Icons.volume_up_outlined,
      Icons.surround_sound_outlined,
    ],
    accentColor: AppColors.mutedTeal,
  ),
  _OnboardingPageData(
    title: '당신만의 조용한\n카페를 찾아보세요',
    subtitle: '지도에서 주변 카페의 소음 수준을\n한눈에 확인할 수 있어요',
    primaryIcon: Icons.location_on,
    decorativeIcons: [
      Icons.map_outlined,
      Icons.search,
      Icons.near_me_outlined,
    ],
    accentColor: AppColors.deepTeal,
  ),
  _OnboardingPageData(
    title: '측정하고 공유하고\n보상받으세요',
    subtitle: '측정할수록 레벨이 올라가고\n뱃지와 포인트를 획득해요',
    primaryIcon: Icons.emoji_events,
    decorativeIcons: [
      Icons.star_outline,
      Icons.workspace_premium_outlined,
      Icons.celebration_outlined,
    ],
    accentColor: AppColors.gold,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final vm = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Skip 버튼
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppDimensions.paddingStandard,
                  right: AppDimensions.paddingStandard,
                ),
                child: state.isLastPage
                    ? const SizedBox(height: 40)
                    : TextButton(
                        onPressed: () async {
                          await vm.completeOnboarding();
                          if (context.mounted) {
                            context.go(AppRoutes.home);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textHint,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingSmall,
                            vertical: 6,
                          ),
                        ),
                        child: const Text(
                          '건너뛰기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: vm.pageController,
                onPageChanged: vm.onPageChanged,
                itemCount: kOnboardingPageCount,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: _pages[index],
                    isActive: index == state.currentPage,
                  );
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingSection,
                AppDimensions.paddingStandard,
                AppDimensions.paddingSection,
                AppDimensions.paddingLarge,
              ),
              child: Column(
                children: [
                  // Dot indicators
                  _DotIndicator(
                    count: kOnboardingPageCount,
                    currentIndex: state.currentPage,
                  ),
                  const SizedBox(height: AppDimensions.paddingSection),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isCompleting
                          ? null
                          : () async {
                              if (state.isLastPage) {
                                await vm.completeOnboarding();
                                if (context.mounted) {
                                  context.go(AppRoutes.home);
                                }
                              } else {
                                vm.nextPage();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusButton),
                        ),
                      ),
                      child: state.isCompleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              state.isLastPage ? '시작하기' : '다음',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single Onboarding Page ────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isActive;

  const _OnboardingPage({
    required this.data,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSection,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon illustration area
          _IconIllustration(data: data, isActive: isActive),

          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.15, end: 0),

          const SizedBox(height: AppDimensions.paddingStandard),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 250.ms, duration: 400.ms)
              .slideY(begin: 0.15, end: 0),
        ],
      ),
    );
  }
}

// ── Icon Illustration ─────────────────────────────────────────────────────────

class _IconIllustration extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isActive;

  const _IconIllustration({required this.data, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: data.accentColor.withOpacity(0.15),
                width: 1,
              ),
              color: data.accentColor.withOpacity(0.06),
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),

          // Inner circle
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.accentColor.withOpacity(0.12),
              border: Border.all(
                color: data.accentColor.withOpacity(0.25),
                width: 1,
              ),
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1.0, 1.0),
                duration: 450.ms,
                delay: 50.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 350.ms, delay: 50.ms),

          // Main icon
          Icon(
            data.primaryIcon,
            size: 72,
            color: data.accentColor,
          )
              .animate(
                onPlay: (controller) =>
                    isActive ? controller.repeat(reverse: true) : null,
              )
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.06, 1.06),
                duration: 1800.ms,
                curve: Curves.easeInOut,
              )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.0, 1.0),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),

          // Decorative icon - top right
          Positioned(
            top: 24,
            right: 20,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: data.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                data.decorativeIcons[0],
                size: 22,
                color: data.accentColor,
              ),
            )
                .animate(target: isActive ? 1 : 0)
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: -0.3, end: 0),
          ),

          // Decorative icon - bottom left
          Positioned(
            bottom: 28,
            left: 18,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: data.accentColor.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Icon(
                data.decorativeIcons[1],
                size: 20,
                color: data.accentColor.withOpacity(0.7),
              ),
            )
                .animate(target: isActive ? 1 : 0)
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0),
          ),

          // Decorative icon - bottom right
          Positioned(
            bottom: 42,
            right: 14,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusBadge),
                border: Border.all(
                  color: data.accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                data.decorativeIcons[2],
                size: 18,
                color: data.accentColor.withOpacity(0.6),
              ),
            )
                .animate(target: isActive ? 1 : 0)
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideX(begin: 0.3, end: 0),
          ),
        ],
      ),
    );
  }
}

// ── Dot Indicator ─────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _DotIndicator({
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            color: isActive ? AppColors.deepTeal : AppColors.warmBeige,
          ),
        );
      }),
    );
  }
}
