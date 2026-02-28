import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_dimensions.dart';
import 'features/splash/splash_screen.dart';
import 'features/home/home_screen.dart';
import 'features/cafe_detail/cafe_detail_screen.dart';
import 'features/measurement/measurement_screen.dart';
import 'features/ranking/ranking_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/premium/premium_screen.dart';

// ── Route Path Constants ──────────────────────────────────────────────────────

abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String cafeDetail = '/cafe/:id';
  static const String measurement = '/measure';
  static const String ranking = '/ranking';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String premium = '/premium';

  /// cafeDetail 경로에 cafeId를 주입
  static String cafeDetailPath(String cafeId) => '/cafe/$cafeId';
}

// ── Router ────────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    // Splash
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SplashScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // Onboarding
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const OnboardingScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // Shell route: routes sharing a bottom nav bar
    ShellRoute(
      builder: (context, state, child) {
        return _MainShell(child: child, location: state.uri.path);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.measurement,
          name: 'measurement',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const MeasurementScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.ranking,
          name: 'ranking',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const RankingScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          name: 'profile',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ProfileScreen(),
          ),
        ),
      ],
    ),

    // Cafe Detail (full-screen push, no shell)
    GoRoute(
      path: AppRoutes.cafeDetail,
      name: 'cafeDetail',
      pageBuilder: (context, state) {
        final cafeId = state.pathParameters['id'] ?? '';
        return CustomTransitionPage(
          key: state.pageKey,
          child: CafeDetailScreen(cafeId: cafeId),
          transitionsBuilder: _slideTransition,
        );
      },
    ),

    // Settings (full-screen push)
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),

    // Premium (full-screen push)
    GoRoute(
      path: AppRoutes.premium,
      name: 'premium',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PremiumScreen(),
        transitionsBuilder: _slideTransition,
      ),
    ),
  ],
);

// ── Transition Helpers ────────────────────────────────────────────────────────

Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  );
}

Widget _slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  );
}

// ── Bottom Navigation Shell ───────────────────────────────────────────────────

class _MainShell extends StatelessWidget {
  final Widget child;
  final String location;

  const _MainShell({required this.child, required this.location});

  int _selectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/measure')) return 1;
    if (location.startsWith('/ranking')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: _CafeOndoBottomNav(
        currentIndex: idx,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.measurement);
            case 2:
              context.go(AppRoutes.ranking);
            case 3:
              context.go(AppRoutes.profile);
          }
        },
      ),
    );
  }
}

class _CafeOndoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CafeOndoBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: AppStrings.navHome),
      _NavItem(icon: Icons.graphic_eq_outlined, activeIcon: Icons.graphic_eq, label: AppStrings.navMeasure),
      _NavItem(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard, label: AppStrings.navRanking),
      _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: AppStrings.navProfile),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == currentIndex;
              final isMeasure = i == 1;

              if (isMeasure) {
                // 측정 버튼: 강조 FAB 스타일
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.deepTeal,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSmall),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: AppColors.white,
                            size: AppDimensions.iconMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? AppColors.deepTeal
                            : AppColors.textHint,
                        size: AppDimensions.iconStandard,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isSelected
                                      ? AppColors.deepTeal
                                      : AppColors.textHint,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ── Root App Widget ───────────────────────────────────────────────────────────

class CafeOndoApp extends ConsumerWidget {
  const CafeOndoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      // 한국어 기본 로케일
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
    );
  }
}
