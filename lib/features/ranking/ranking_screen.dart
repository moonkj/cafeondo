import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cafeondo/core/constants/app_colors.dart';
import 'package:cafeondo/core/constants/app_dimensions.dart';
import 'ranking_viewmodel.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(text: '조용한 카페 TOP'),
    Tab(text: '측정왕 TOP'),
    Tab(text: '이번 주 활발한 카페'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      ref.read(rankingSelectedTabProvider.notifier).state =
          _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '랭킹',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.deepTeal,
              unselectedLabelColor: AppColors.textHint,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: AppColors.deepTeal,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: _tabs,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _QuietCafesTab(),
          _TopMeasurersTab(),
          _ActiveCafesTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: Quiet Cafes ────────────────────────────────────────────────────────

class _QuietCafesTab extends ConsumerWidget {
  const _QuietCafesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(quietCafesRankingProvider);

    return async.when(
      loading: () => const _LoadingBody(),
      error: (e, _) => _ErrorBody(onRetry: () => ref.invalidate(quietCafesRankingProvider)),
      data: (cafes) => RefreshIndicator(
        color: AppColors.mutedTeal,
        onRefresh: () async => ref.invalidate(quietCafesRankingProvider),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingStandard,
          ),
          itemCount: cafes.length,
          itemBuilder: (context, index) {
            return _QuietCafeCard(item: cafes[index])
                .animate()
                .fadeIn(delay: (index * 60).ms, duration: 300.ms)
                .slideX(begin: 0.05, end: 0);
          },
        ),
      ),
    );
  }
}

// ── Tab 2: Top Measurers ──────────────────────────────────────────────────────

class _TopMeasurersTab extends ConsumerWidget {
  const _TopMeasurersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topMeasurersRankingProvider);

    return async.when(
      loading: () => const _LoadingBody(),
      error: (e, _) => _ErrorBody(onRetry: () => ref.invalidate(topMeasurersRankingProvider)),
      data: (measurers) => RefreshIndicator(
        color: AppColors.mutedTeal,
        onRefresh: () async => ref.invalidate(topMeasurersRankingProvider),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingStandard,
          ),
          itemCount: measurers.length,
          itemBuilder: (context, index) {
            return _TopMeasurerCard(item: measurers[index])
                .animate()
                .fadeIn(delay: (index * 60).ms, duration: 300.ms)
                .slideX(begin: 0.05, end: 0);
          },
        ),
      ),
    );
  }
}

// ── Tab 3: Active Cafes ───────────────────────────────────────────────────────

class _ActiveCafesTab extends ConsumerWidget {
  const _ActiveCafesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeCafesRankingProvider);

    return async.when(
      loading: () => const _LoadingBody(),
      error: (e, _) => _ErrorBody(onRetry: () => ref.invalidate(activeCafesRankingProvider)),
      data: (cafes) => RefreshIndicator(
        color: AppColors.mutedTeal,
        onRefresh: () async => ref.invalidate(activeCafesRankingProvider),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingStandard,
          ),
          itemCount: cafes.length,
          itemBuilder: (context, index) {
            return _ActiveCafeCard(item: cafes[index])
                .animate()
                .fadeIn(delay: (index * 60).ms, duration: 300.ms)
                .slideX(begin: 0.05, end: 0);
          },
        ),
      ),
    );
  }
}

// ── Rank Badge Widget ─────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool compact;

  const _RankBadge({required this.rank, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String? medalSymbol;

    switch (rank) {
      case 1:
        color = const Color(0xFFB8860B);
        bgColor = const Color(0xFFFFF8DC);
        medalSymbol = '🥇';
        break;
      case 2:
        color = const Color(0xFF708090);
        bgColor = const Color(0xFFF0F0F0);
        medalSymbol = '🥈';
        break;
      case 3:
        color = const Color(0xFFCD7F32);
        bgColor = const Color(0xFFFFF0E0);
        medalSymbol = '🥉';
        break;
      default:
        color = AppColors.textHint;
        bgColor = AppColors.paperWhite;
        medalSymbol = null;
    }

    if (compact) {
      return SizedBox(
        width: 32,
        child: Text(
          '$rank',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
    }

    if (medalSymbol != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            medalSymbol,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ── Quiet Cafe Card ───────────────────────────────────────────────────────────

class _QuietCafeCard extends StatelessWidget {
  final QuietCafeRankItem item;

  const _QuietCafeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isTop3 = item.rank <= 3;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingStandard,
        0,
        AppDimensions.paddingStandard,
        AppDimensions.paddingSmall,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingStandard),
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.offWhite : AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: isTop3 ? AppColors.mutedTeal.withOpacity(0.25) : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _RankBadge(rank: item.rank),
          const SizedBox(width: AppDimensions.paddingStandard),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.cafeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      item.district,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.bar_chart,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${item.measurementCount}회 측정',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // dB + noise badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    item.averageDb.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.noiseQuiet,
                    ),
                  ),
                  const Text(
                    ' dB',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.noiseQuietBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                ),
                child: const Text(
                  '조용함',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.noiseQuiet,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Top Measurer Card ─────────────────────────────────────────────────────────

class _TopMeasurerCard extends StatelessWidget {
  final TopMeasurerItem item;

  const _TopMeasurerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isTop3 = item.rank <= 3;
    final isCurrent = item.isCurrentUser;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingStandard,
        0,
        AppDimensions.paddingStandard,
        AppDimensions.paddingSmall,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingStandard),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.lightTeal.withOpacity(0.4) : AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: isCurrent
              ? AppColors.mutedTeal.withOpacity(0.4)
              : isTop3
                  ? AppColors.mutedTeal.withOpacity(0.2)
                  : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _RankBadge(rank: item.rank),
          const SizedBox(width: AppDimensions.paddingStandard),

          // Avatar circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightTeal,
              border: Border.all(
                color: AppColors.mutedTeal.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                item.levelEmoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),

          const SizedBox(width: AppDimensions.paddingSmall),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.mutedTeal,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusBadge),
                        ),
                        child: const Text(
                          '나',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Lv.${item.levelIndex + 1} ${item.levelLabel}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          // Measurement count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${item.totalMeasurements}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isTop3 ? AppColors.deepTeal : AppColors.navy,
                    ),
                  ),
                  const Text(
                    ' 회',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const Text(
                '총 측정',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Active Cafe Card ──────────────────────────────────────────────────────────

class _ActiveCafeCard extends StatelessWidget {
  final ActiveCafeRankItem item;

  const _ActiveCafeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isTop3 = item.rank <= 3;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingStandard,
        0,
        AppDimensions.paddingStandard,
        AppDimensions.paddingSmall,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingStandard),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(
          color: isTop3 ? AppColors.mutedTeal.withOpacity(0.25) : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _RankBadge(rank: item.rank),
          const SizedBox(width: AppDimensions.paddingStandard),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.cafeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      item.district,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Weekly count + trend
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${item.weeklyMeasurements}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isTop3 ? AppColors.deepTeal : AppColors.navy,
                    ),
                  ),
                  const Text(
                    ' 회',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    item.isTrending
                        ? Icons.trending_up
                        : Icons.trending_flat,
                    size: 14,
                    color: item.isTrending
                        ? AppColors.mutedTeal
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    item.isTrending ? '상승중' : '유지중',
                    style: TextStyle(
                      fontSize: 11,
                      color: item.isTrending
                          ? AppColors.mutedTeal
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Loading / Error bodies ────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.mutedTeal),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorBody({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.paddingStandard),
          const Text(
            '랭킹을 불러오지 못했어요',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.paddingStandard),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
