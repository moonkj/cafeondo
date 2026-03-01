import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cafeondo/core/constants/app_colors.dart';
import 'package:cafeondo/core/constants/app_dimensions.dart';
import 'package:cafeondo/data/models/user_profile.dart';
import 'package:cafeondo/app.dart';
import 'profile_viewmodel.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);

    // No inner Scaffold — nested Scaffold doesn't render on iOS 26 beta.
    // Instead: Column with manual AppBar + Expanded body.
    return Container(
      color: AppColors.offWhite,
      child: Column(
        children: [
          // ── AppBar (manual) ─────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.offWhite,
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    '프로필',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    child: IconButton(
                      onPressed: () => context.push(AppRoutes.settings),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.mutedTeal),
                  )
                : state.isLoggedIn
                    ? _LoggedInBody(state: state)
                    : const _LoginPrompt(),
          ),
        ],
      ),
    );
  }
}

// ── Logged-in Body ────────────────────────────────────────────────────────────

class _LoggedInBody extends ConsumerWidget {
  final ProfileState state;

  const _LoggedInBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = state.userProfile!;
    final registeredCount = ref.watch(registeredCafesCountProvider);

    return RefreshIndicator(
      color: AppColors.mutedTeal,
      onRefresh: () => ref.read(profileProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────
            _ProfileHeader(profile: profile),

            const SizedBox(height: AppDimensions.paddingStandard),

            // ── Level Card ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingStandard),
              child: _LevelCard(profile: profile),
            ),

            const SizedBox(height: AppDimensions.paddingStandard),

            // ── Stats Row ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingStandard),
              child: _StatsRow(
                measurements: profile.totalMeasurements,
                registeredCafes: registeredCount,
                points: profile.points,
              ),
            ),

            const SizedBox(height: AppDimensions.paddingSection),

            // ── 내 측정 기록 ──────────────────────────────────────────────
            _SectionHeader(title: '내 측정 기록'),

            if (state.recentMeasurements.isEmpty)
              _EmptyMeasurements()
            else
              ...state.recentMeasurements.map(
                (record) => _MeasurementItem(record: record),
              ),

            const SizedBox(height: AppDimensions.paddingSection),

            // ── 뱃지 ──────────────────────────────────────────────────────
            _SectionHeader(title: '뱃지'),

            _BadgeSection(badges: state.badges),

            const SizedBox(height: AppDimensions.paddingSection),

            // ── 로그아웃 ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingStandard,
              ),
              child: OutlinedButton(
                onPressed: () => _confirmSignOut(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.terra,
                  side: const BorderSide(color: AppColors.terra, width: 1),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusButton),
                  ),
                ),
                child: const Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingLarge),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.terra),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(profileProvider.notifier).signOut();
    }
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingSection,
        AppDimensions.paddingSection,
        AppDimensions.paddingSection,
        AppDimensions.paddingSection,
      ),
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: AppDimensions.avatarLarge,
            height: AppDimensions.avatarLarge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightTeal,
              border: Border.all(
                color: AppColors.mutedTeal.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: profile.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      profile.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _DefaultAvatar(
                        name: profile.displayName,
                      ),
                    ),
                  )
                : _DefaultAvatar(name: profile.displayName),
          ),

          const SizedBox(width: AppDimensions.paddingStandard),

          // Name + Email + Level badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    _LevelBadgeSmall(level: profile.level),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textHint,
                  ),
                ),
                if (profile.joinedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${profile.joinedAt!.year}년 ${profile.joinedAt!.month}월 가입',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
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

// ── Default Avatar ────────────────────────────────────────────────────────────

class _DefaultAvatar extends StatelessWidget {
  final String name;

  const _DefaultAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0] : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.deepTeal,
        ),
      ),
    );
  }
}

// ── Level Badge Small ─────────────────────────────────────────────────────────

class _LevelBadgeSmall extends StatelessWidget {
  final UserLevel level;

  const _LevelBadgeSmall({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.lightTeal,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
        border: Border.all(
          color: AppColors.mutedTeal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        'Lv.${level.index + 1}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.deepTeal,
        ),
      ),
    );
  }
}

// ── Level Card ────────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final UserProfile profile;

  const _LevelCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final progress = profile.levelProgress;
    final isMax = profile.level == UserLevel.grandmaster;
    final toNext = profile.measurementsToNextLevel;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingStandard),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Level icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(
                    color: AppColors.mutedTeal.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    profile.level.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingStandard),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lv.${profile.level.index + 1} ${profile.level.label}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMax
                          ? '최고 레벨 달성!'
                          : '다음 레벨까지 ${toNext}회 더 측정',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingStandard),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.lightTeal,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.mutedTeal,
              ),
            ),
          ),

          if (!isMax) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${profile.level.label}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                Text(
                  '${UserLevel.values[profile.level.index + 1].label}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int measurements;
  final int registeredCafes;
  final int points;

  const _StatsRow({
    required this.measurements,
    required this.registeredCafes,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(
              value: '$measurements',
              label: '총 측정',
              unit: '회',
            ),
            const VerticalDivider(
              color: AppColors.divider,
              width: 1,
              thickness: 1,
            ),
            _StatCell(
              value: '$registeredCafes',
              label: '등록 카페',
              unit: '곳',
            ),
            const VerticalDivider(
              color: AppColors.divider,
              width: 1,
              thickness: 1,
            ),
            _StatCell(
              value: '$points',
              label: '획득 포인트',
              unit: 'P',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final String unit;

  const _StatCell({
    required this.value,
    required this.label,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingStandard),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingStandard,
        0,
        AppDimensions.paddingStandard,
        AppDimensions.paddingSmall,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

// ── Measurement Item ──────────────────────────────────────────────────────────

class _MeasurementItem extends StatelessWidget {
  final MeasurementRecord record;

  const _MeasurementItem({required this.record});

  Color _dbColor(double db) {
    if (db <= 50) return AppColors.noiseQuiet;
    if (db <= 65) return AppColors.noiseModerate;
    if (db <= 75) return AppColors.noiseNoisy;
    return AppColors.noiseLoud;
  }

  Color _dbBgColor(double db) {
    if (db <= 50) return AppColors.noiseQuietBg;
    if (db <= 65) return AppColors.noiseModerateBg;
    if (db <= 75) return AppColors.noiseNoisyBg;
    return AppColors.noiseLoudBg;
  }

  String _dbLabel(double db) {
    if (db <= 50) return '조용함';
    if (db <= 65) return '보통';
    if (db <= 75) return '시끄러움';
    return '매우 시끄러움';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final color = _dbColor(record.db);
    final bgColor = _dbBgColor(record.db);

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
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // dB indicator
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  record.db.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  'dB',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppDimensions.paddingStandard),

          // Cafe info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.cafeName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.cafeAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          // Right side: noise label + date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusBadge),
                ),
                child: Text(
                  _dbLabel(record.db),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(record.timestamp),
                style: const TextStyle(
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

// ── Empty Measurements ────────────────────────────────────────────────────────

class _EmptyMeasurements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingStandard,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingSection),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.graphic_eq_outlined,
            size: 40,
            color: AppColors.textHint,
          ),
          SizedBox(height: AppDimensions.paddingSmall),
          Text(
            '아직 측정 기록이 없어요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '카페에 가서 소음을 측정해보세요!',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge Section ─────────────────────────────────────────────────────────────

class _BadgeSection extends StatelessWidget {
  final List<UserBadge> badges;

  const _BadgeSection({required this.badges});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingStandard,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.paddingSmall),
        itemBuilder: (context, index) {
          return _BadgeItem(badge: badges[index]);
        },
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final UserBadge badge;

  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: badge.isEarned ? 1.0 : 0.4,
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(AppDimensions.paddingSmall),
        decoration: BoxDecoration(
          color: badge.isEarned ? AppColors.lightTeal : AppColors.paperWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: badge.isEarned
                ? AppColors.mutedTeal.withOpacity(0.3)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 6),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badge.isEarned ? AppColors.deepTeal : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Login Prompt ──────────────────────────────────────────────────────────────

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingSection),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingSection),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_outline,
                size: 56,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.paddingStandard),
              const Text(
                '로그인이 필요해요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              const Text(
                '측정 기록을 저장하고\n커뮤니티와 함께 소음을 측정해보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSection),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Google로 로그인'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
