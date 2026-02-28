import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cafe_providers.dart';
import 'widgets/atmosphere_chart.dart';

// Color constants
const Color _kNavy = Color(0xFF091717);
const Color _kDarkTeal = Color(0xFF13343B);
const Color _kDeepTeal = Color(0xFF115058);
const Color _kMutedTeal = Color(0xFF20808D);
const Color _kLightTeal = Color(0xFFD6F5FA);
const Color _kOffWhite = Color(0xFFFCFAF6);
const Color _kPaperWhite = Color(0xFFF3F3EE);
const Color _kWarmBeige = Color(0xFFE5E3D4);
const Color _kTerra = Color(0xFFA84B2F);
const Color _kMauve = Color(0xFF9C6B8A);

class CafeDetailScreen extends ConsumerWidget {
  final String cafeId;

  const CafeDetailScreen({super.key, required this.cafeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cafeAsync = ref.watch(cafeDetailProvider(cafeId));

    return cafeAsync.when(
      data: (cafe) {
        if (cafe == null) {
          return Scaffold(
            backgroundColor: _kOffWhite,
            appBar: AppBar(
              backgroundColor: _kOffWhite,
              elevation: 0,
              leading: _BackButton(),
            ),
            body: const Center(
              child: Text(
                '카페 정보를 찾을 수 없어요',
                style: TextStyle(fontFamily: 'Pretendard'),
              ),
            ),
          );
        }
        return _CafeDetailContent(cafe: cafe);
      },
      loading: () => Scaffold(
        backgroundColor: _kOffWhite,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _kMutedTeal,
          ),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: _kOffWhite,
        appBar: AppBar(
          backgroundColor: _kOffWhite,
          elevation: 0,
          leading: _BackButton(),
        ),
        body: const Center(
          child: Text(
            '오류가 발생했어요',
            style: TextStyle(fontFamily: 'Pretendard'),
          ),
        ),
      ),
    );
  }
}

class _CafeDetailContent extends StatelessWidget {
  final CafeModel cafe;

  const _CafeDetailContent({required this.cafe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kOffWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sliver App Bar with parallax photo
          _CafeSliverAppBar(cafe: cafe),

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Name + noise level row
                  _CafeHeader(cafe: cafe),

                  const SizedBox(height: 24),

                  // Atmosphere chart section
                  _SectionCard(
                    title: '시간대별 소음 수준',
                    subtitle: '오전 8시 ~ 오후 10시',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        // dB axis label
                        Row(
                          children: [
                            Text(
                              'dB',
                              style: TextStyle(
                                color: _kNavy.withOpacity(0.35),
                                fontSize: 11,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            const Spacer(),
                            _dbRangeChip(
                              cafe.hourlyNoise
                                  .map((h) => h.db)
                                  .reduce((a, b) => a < b ? a : b)
                                  .round(),
                              cafe.hourlyNoise
                                  .map((h) => h.db)
                                  .reduce((a, b) => a > b ? a : b)
                                  .round(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AtmosphereChart(hourlyData: cafe.hourlyNoise),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Atmosphere tags section
                  _SectionCard(
                    title: '분위기 태그',
                    child: _TagsWrap(tags: cafe.tags),
                  ),

                  const SizedBox(height: 16),

                  // Recent measurements section
                  _SectionCard(
                    title: '최근 측정',
                    subtitle: '${cafe.measurementCount}회 측정됨',
                    child: _RecentMeasurementsList(
                      measurements: cafe.recentMeasurements,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CTA Button
                  _MeasureCTAButton(cafeId: cafe.id),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dbRangeChip(int min, int max) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kPaperWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kWarmBeige),
      ),
      child: Text(
        '범위: ${min}–${max}dB',
        style: TextStyle(
          color: _kNavy.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sliver App Bar
// ---------------------------------------------------------------------------

class _CafeSliverAppBar extends StatelessWidget {
  final CafeModel cafe;

  const _CafeSliverAppBar({required this.cafe});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: _kOffWhite,
      elevation: 0,
      leading: _BackButton(),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _ShareButton(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _CafeHeroImage(cafe: cafe),
        title: Text(
          cafe.name,
          style: TextStyle(
            color: _kNavy,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
            letterSpacing: -0.2,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 64, bottom: 16, right: 64),
      ),
    );
  }
}

class _CafeHeroImage extends StatelessWidget {
  final CafeModel cafe;

  const _CafeHeroImage({required this.cafe});

  Color get _bgColor {
    switch (cafe.noiseLevel) {
      case NoiseLevel.quiet:
        return _kLightTeal;
      case NoiseLevel.moderate:
        return _kWarmBeige;
      case NoiseLevel.noisy:
        return const Color(0xFFFFDDD6);
      case NoiseLevel.loud:
        return const Color(0xFFEDD6E8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        cafe.imageUrl != null
            ? Image.network(
                cafe.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: _bgColor),
              )
            : Container(
                color: _bgColor,
                child: Center(
                  child: Text(
                    cafe.name.isNotEmpty ? cafe.name[0] : '☕',
                    style: TextStyle(
                      fontSize: 80,
                      color: _kDeepTeal.withOpacity(0.3),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
        // Gradient overlay for text readability
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _kOffWhite.withOpacity(0.9),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Back/Share Buttons
// ---------------------------------------------------------------------------

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kOffWhite.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: _kWarmBeige),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _kNavy),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _kOffWhite.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: _kWarmBeige),
        ),
        child: Icon(Icons.ios_share_rounded, size: 16, color: _kNavy),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cafe Header
// ---------------------------------------------------------------------------

class _CafeHeader extends StatelessWidget {
  final CafeModel cafe;

  const _CafeHeader({required this.cafe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          cafe.name,
          style: TextStyle(
            color: _kNavy,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 6),

        // Address
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: _kMutedTeal),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                cafe.address,
                style: TextStyle(
                  color: _kNavy.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Overall noise level row
        Row(
          children: [
            // Large dB display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _noiseBgColor(cafe.noiseLevel),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: _noiseTextColor(cafe.noiseLevel),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '평균 ${cafe.averageDb.toStringAsFixed(1)}dB',
                    style: TextStyle(
                      color: _noiseTextColor(cafe.noiseLevel),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cafe.noiseLevel.label,
                    style: TextStyle(
                      color: _noiseTextColor(cafe.noiseLevel).withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${cafe.measurementCount}회 측정',
              style: TextStyle(
                color: _kNavy.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _noiseBgColor(NoiseLevel level) {
    switch (level) {
      case NoiseLevel.quiet:
        return _kLightTeal;
      case NoiseLevel.moderate:
        return _kWarmBeige;
      case NoiseLevel.noisy:
        return const Color(0xFFFFDDD6);
      case NoiseLevel.loud:
        return const Color(0xFFEDD6E8);
    }
  }

  Color _noiseTextColor(NoiseLevel level) {
    switch (level) {
      case NoiseLevel.quiet:
        return _kDeepTeal;
      case NoiseLevel.moderate:
        return const Color(0xFF6B6350);
      case NoiseLevel.noisy:
        return _kTerra;
      case NoiseLevel.loud:
        return _kMauve;
    }
  }
}

// ---------------------------------------------------------------------------
// Section Card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kOffWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kWarmBeige, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _kNavy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  fontFamily: 'Pretendard',
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: _kNavy.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tags Wrap
// ---------------------------------------------------------------------------

class _TagsWrap extends StatelessWidget {
  final List<String> tags;

  const _TagsWrap({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map((tag) => _AtmosphereChip(label: tag))
          .toList(),
    );
  }
}

class _AtmosphereChip extends StatelessWidget {
  final String label;

  const _AtmosphereChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kPaperWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kWarmBeige),
      ),
      child: Text(
        '# $label',
        style: TextStyle(
          color: _kNavy.withOpacity(0.65),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Measurements List
// ---------------------------------------------------------------------------

class _RecentMeasurementsList extends StatelessWidget {
  final List<RecentMeasurement> measurements;

  const _RecentMeasurementsList({required this.measurements});

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '아직 측정 기록이 없어요',
            style: TextStyle(
              color: _kNavy.withOpacity(0.4),
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(measurements.length, (i) {
        final m = measurements[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i < measurements.length - 1 ? 12 : 0),
          child: _MeasurementItem(measurement: m),
        );
      }),
    );
  }
}

class _MeasurementItem extends StatelessWidget {
  final RecentMeasurement measurement;

  const _MeasurementItem({required this.measurement});

  String _timeAgo() {
    final diff = DateTime.now().difference(measurement.timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kLightTeal,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              measurement.userName.isNotEmpty
                  ? measurement.userName[0]
                  : '?',
              style: TextStyle(
                color: _kDeepTeal,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    measurement.userName,
                    style: TextStyle(
                      color: _kNavy,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _timeAgo(),
                    style: TextStyle(
                      color: _kNavy.withOpacity(0.35),
                      fontSize: 11,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  _SmallNoiseBadge(noiseLevel: measurement.noiseLevel),
                  const SizedBox(width: 6),
                  Text(
                    '${measurement.db.round()}dB',
                    style: TextStyle(
                      color: _kNavy.withOpacity(0.5),
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
              if (measurement.comment != null) ...[
                const SizedBox(height: 4),
                Text(
                  measurement.comment!,
                  style: TextStyle(
                    color: _kNavy.withOpacity(0.6),
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallNoiseBadge extends StatelessWidget {
  final NoiseLevel noiseLevel;

  const _SmallNoiseBadge({required this.noiseLevel});

  Color get _bg {
    switch (noiseLevel) {
      case NoiseLevel.quiet: return _kLightTeal;
      case NoiseLevel.moderate: return _kWarmBeige;
      case NoiseLevel.noisy: return const Color(0xFFFFDDD6);
      case NoiseLevel.loud: return const Color(0xFFEDD6E8);
    }
  }

  Color get _fg {
    switch (noiseLevel) {
      case NoiseLevel.quiet: return _kDeepTeal;
      case NoiseLevel.moderate: return const Color(0xFF6B6350);
      case NoiseLevel.noisy: return _kTerra;
      case NoiseLevel.loud: return _kMauve;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        noiseLevel.label,
        style: TextStyle(
          color: _fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Measure CTA Button
// ---------------------------------------------------------------------------

class _MeasureCTAButton extends StatelessWidget {
  final String cafeId;

  const _MeasureCTAButton({required this.cafeId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: GestureDetector(
        onTap: () => context.push('/measure', extra: cafeId),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kDeepTeal, _kMutedTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.graphic_eq_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                '소음 측정하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
