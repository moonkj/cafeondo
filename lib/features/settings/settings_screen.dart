import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cafeondo/core/constants/app_colors.dart';
import 'package:cafeondo/core/constants/app_dimensions.dart';
import 'package:cafeondo/core/constants/app_strings.dart';
import 'settings_viewmodel.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      appBar: AppBar(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.navy,
          ),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.paddingStandard,
        ),
        children: [
          // ── 프로필 섹션 ─────────────────────────────────────────────────
          _Section(
            title: '계정 정보',
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                label: '이름',
                value: '카페 탐험가',
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.email_outlined,
                label: '이메일',
                value: 'user@example.com',
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.badge_outlined,
                label: '계정 유형',
                trailing: _PlanBadge(isPremium: state.isPremium),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingStandard),

          // ── 알림 설정 ──────────────────────────────────────────────────
          _Section(
            title: '알림 설정',
            children: [
              _ToggleTile(
                icon: Icons.notifications_outlined,
                label: '측정 알림',
                subtitle: '측정 완료 시 결과를 알려드려요',
                value: state.notifications.measurementAlert,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setMeasurementAlert(v),
              ),
              _Divider(),
              _ToggleTile(
                icon: Icons.leaderboard_outlined,
                label: '랭킹 변동',
                subtitle: '내 랭킹이 변동되면 알려드려요',
                value: state.notifications.rankingChange,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setRankingChange(v),
              ),
              _Divider(),
              _ToggleTile(
                icon: Icons.add_location_outlined,
                label: '새 카페 등록',
                subtitle: '주변에 새 카페가 등록되면 알려드려요',
                value: state.notifications.newCafeAlert,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setNewCafeAlert(v),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingStandard),

          // ── 앱 설정 ────────────────────────────────────────────────────
          _Section(
            title: '앱 설정',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                label: '다크 모드',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warmBeige,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusBadge),
                  ),
                  child: const Text(
                    '준비 중',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              _Divider(),
              _SettingsTile(
                icon: Icons.language_outlined,
                label: '언어',
                value: '한국어',
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingStandard),

          // ── 프리미엄 ───────────────────────────────────────────────────
          _Section(
            title: '프리미엄',
            children: [
              _SettingsTile(
                icon: Icons.workspace_premium_outlined,
                label: '현재 플랜',
                trailing: _PlanBadge(isPremium: state.isPremium),
              ),
              if (!state.isPremium) ...[
                _Divider(),
                _PremiumUpgradeTile(),
              ],
            ],
          ),

          const SizedBox(height: AppDimensions.paddingStandard),

          // ── 정보 ───────────────────────────────────────────────────────
          _Section(
            title: '정보',
            children: [
              _SettingsTile(
                icon: Icons.info_outlined,
                label: '앱 버전',
                value: state.appVersion,
              ),
              _Divider(),
              _TappableTile(
                icon: Icons.privacy_tip_outlined,
                label: '개인정보 처리방침',
                onTap: () => _showWebviewSheet(
                  context,
                  '개인정보 처리방침',
                  AppStrings.urlPrivacy,
                ),
              ),
              _Divider(),
              _TappableTile(
                icon: Icons.description_outlined,
                label: '이용약관',
                onTap: () => _showWebviewSheet(
                  context,
                  '이용약관',
                  AppStrings.urlTerms,
                ),
              ),
              _Divider(),
              _TappableTile(
                icon: Icons.code_outlined,
                label: '오픈소스 라이선스',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: '카페온도',
                  applicationVersion: state.appVersion,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingStandard),

          // ── 계정 ───────────────────────────────────────────────────────
          _Section(
            title: '계정',
            children: [
              _TappableTile(
                icon: Icons.logout,
                label: '로그아웃',
                iconColor: AppColors.terra,
                labelColor: AppColors.terra,
                onTap: () => _confirmSignOut(context, ref),
              ),
              _Divider(),
              _TappableTile(
                icon: Icons.person_remove_outlined,
                label: '회원탈퇴',
                iconColor: AppColors.mauve,
                labelColor: AppColors.mauve,
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.paddingLarge),
        ],
      ),
    );
  }

  void _showWebviewSheet(BuildContext context, String title, String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => _WebviewPlaceholder(
          title: title,
          url: url,
          scrollController: controller,
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
      await ref.read(settingsProvider.notifier).signOut();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원탈퇴'),
        content: const Text(
          '탈퇴하면 모든 측정 기록과 포인트가 삭제되며 복구할 수 없어요.\n정말 탈퇴하시겠어요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.mauve),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).deleteAccount();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// ── Section Widget ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingStandard,
            0,
            AppDimensions.paddingStandard,
            AppDimensions.paddingSmall,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingStandard),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingStandard,
        vertical: 14,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.paddingStandard),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.navy,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (value != null)
            Text(
              value!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Toggle Tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingStandard,
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.paddingStandard),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.white,
            activeTrackColor: AppColors.mutedTeal,
            inactiveTrackColor: AppColors.warmBeige,
            inactiveThumbColor: AppColors.white,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// ── Tappable Tile ─────────────────────────────────────────────────────────────

class _TappableTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _TappableTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingStandard,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? AppColors.textSecondary,
            ),
            const SizedBox(width: AppDimensions.paddingStandard),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? AppColors.navy,
                ),
              ),
            ),
            if (iconColor == null)
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: AppColors.divider,
      height: 1,
      thickness: 1,
      indent: 52,
      endIndent: 0,
    );
  }
}

// ── Plan Badge ────────────────────────────────────────────────────────────────

class _PlanBadge extends StatelessWidget {
  final bool isPremium;

  const _PlanBadge({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPremium ? AppColors.gold.withOpacity(0.12) : AppColors.paperWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
        border: Border.all(
          color: isPremium
              ? AppColors.gold.withOpacity(0.4)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Text(
        isPremium ? '프리미엄' : '무료',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isPremium ? AppColors.gold : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Premium Upgrade Tile ──────────────────────────────────────────────────────

class _PremiumUpgradeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingStandard),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingStandard),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.deepTeal.withOpacity(0.08),
              AppColors.mutedTeal.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: AppColors.mutedTeal.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.lightTeal,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 22,
                color: AppColors.deepTeal,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingStandard),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '프리미엄으로 업그레이드',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepTeal,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '광고 없이 더 많은 기능을 사용하세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.mutedTeal,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Webview Placeholder (Bottom Sheet) ────────────────────────────────────────

class _WebviewPlaceholder extends StatelessWidget {
  final String title;
  final String url;
  final ScrollController scrollController;

  const _WebviewPlaceholder({
    required this.title,
    required this.url,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: AppDimensions.paddingSmall),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.warmBeige,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingStandard),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Placeholder content
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingSection),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.web_outlined,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: AppDimensions.paddingStandard),
                  Text(
                    url,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
