import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/cafe.dart';

/// 소음 수준 배지 위젯
///
/// [noiseCategory] 또는 [decibelLevel]로 배지를 생성할 수 있다.
/// 애니메이션이 포함된 모던 디자인.
///
/// 사용 예시:
/// ```dart
/// NoiseIndicator(noiseCategory: NoiseCategory.quiet)
/// NoiseIndicator.fromDecibels(decibelLevel: 55.0)
/// NoiseIndicator(noiseCategory: NoiseCategory.loud, size: NoiseIndicatorSize.large)
/// ```
class NoiseIndicator extends StatelessWidget {
  final NoiseCategory noiseCategory;
  final NoiseIndicatorSize size;

  /// 숫자(dB 수치)를 같이 표시할지 여부
  final bool showDecibels;

  /// 표시할 dB 수치 (showDecibels=true일 때 사용)
  final double? decibelLevel;

  /// 애니메이션 활성화 여부
  final bool animate;

  const NoiseIndicator({
    super.key,
    required this.noiseCategory,
    this.size = NoiseIndicatorSize.medium,
    this.showDecibels = false,
    this.decibelLevel,
    this.animate = true,
  });

  /// dB 수치에서 직접 생성
  factory NoiseIndicator.fromDecibels({
    Key? key,
    required double decibelLevel,
    NoiseIndicatorSize size = NoiseIndicatorSize.medium,
    bool animate = true,
  }) {
    return NoiseIndicator(
      key: key,
      noiseCategory: NoiseCategory.fromDecibels(decibelLevel),
      size: size,
      showDecibels: true,
      decibelLevel: decibelLevel,
      animate: animate,
    );
  }

  // ── Colors ──────────────────────────────────────────────────────────────────

  Color get _bgColor {
    switch (noiseCategory) {
      case NoiseCategory.quiet:
        return AppColors.noiseQuietBg;
      case NoiseCategory.moderate:
        return AppColors.noiseModerateBg;
      case NoiseCategory.noisy:
        return AppColors.noiseNoisyBg;
      case NoiseCategory.loud:
        return AppColors.noiseLoudBg;
    }
  }

  Color get _fgColor {
    switch (noiseCategory) {
      case NoiseCategory.quiet:
        return AppColors.noiseQuiet;
      case NoiseCategory.moderate:
        return AppColors.noiseModerate;
      case NoiseCategory.noisy:
        return AppColors.noiseNoisy;
      case NoiseCategory.loud:
        return AppColors.noiseLoud;
    }
  }

  Color get _borderColor => _fgColor.withAlpha(60);

  // ── Icon ─────────────────────────────────────────────────────────────────────

  IconData get _icon {
    switch (noiseCategory) {
      case NoiseCategory.quiet:
        return Icons.self_improvement_rounded; // 딥 포커스
      case NoiseCategory.moderate:
        return Icons.local_cafe_rounded;        // 소프트 바이브
      case NoiseCategory.noisy:
        return Icons.groups_rounded;            // 소셜 버즈
      case NoiseCategory.loud:
        return Icons.whatshot_rounded;          // 라이브 에너지
    }
  }

  // ── Dimensions by size ───────────────────────────────────────────────────────

  double get _iconSize {
    switch (size) {
      case NoiseIndicatorSize.small:
        return 12;
      case NoiseIndicatorSize.medium:
        return 16;
      case NoiseIndicatorSize.large:
        return 20;
    }
  }

  double get _fontSize {
    switch (size) {
      case NoiseIndicatorSize.small:
        return 10;
      case NoiseIndicatorSize.medium:
        return 12;
      case NoiseIndicatorSize.large:
        return 14;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case NoiseIndicatorSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
      case NoiseIndicatorSize.medium:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
      case NoiseIndicatorSize.large:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    }
  }

  double get _gap {
    switch (size) {
      case NoiseIndicatorSize.small:
        return 3;
      case NoiseIndicatorSize.medium:
        return 4;
      case NoiseIndicatorSize.large:
        return 6;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _icon,
            size: _iconSize,
            color: _fgColor,
          ),
          SizedBox(width: _gap),
          Text(
            _label,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
              color: _fgColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );

    if (!animate) return badge;

    return badge
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        );
  }

  String get _label {
    if (showDecibels && decibelLevel != null) {
      return '${decibelLevel!.toStringAsFixed(0)}dB';
    }
    return noiseCategory.label;
  }
}

/// 크기 옵션
enum NoiseIndicatorSize {
  small,
  medium,
  large,
}

// ─────────────────────────────────────────────────────────────────────────────

/// 소음 수준 원형 도트 인디케이터 (지도 마커 등에 사용)
class NoiseDot extends StatelessWidget {
  final NoiseCategory noiseCategory;
  final double size;
  final bool animate;

  const NoiseDot({
    super.key,
    required this.noiseCategory,
    this.size = 12,
    this.animate = false,
  });

  Color get _color {
    switch (noiseCategory) {
      case NoiseCategory.quiet:
        return AppColors.noiseQuiet;
      case NoiseCategory.moderate:
        return AppColors.noiseModerate;
      case NoiseCategory.noisy:
        return AppColors.noiseNoisy;
      case NoiseCategory.loud:
        return AppColors.noiseLoud;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _color.withAlpha(80),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    if (!animate) return dot;

    return dot
        .animate(
          onPlay: (ctrl) => ctrl.repeat(reverse: true),
        )
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.3, 1.3),
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// 소음 수준 상세 카드 (카페 상세화면 등에서 큰 배지로 사용)
class NoiseIndicatorCard extends StatelessWidget {
  final NoiseCategory noiseCategory;
  final double? averageDecibels;
  final int? measurementCount;

  const NoiseIndicatorCard({
    super.key,
    required this.noiseCategory,
    this.averageDecibels,
    this.measurementCount,
  });

  Color get _bgColor {
    switch (noiseCategory) {
      case NoiseCategory.quiet:
        return AppColors.noiseQuietBg;
      case NoiseCategory.moderate:
        return AppColors.noiseModerateBg;
      case NoiseCategory.noisy:
        return AppColors.noiseNoisyBg;
      case NoiseCategory.loud:
        return AppColors.noiseLoudBg;
    }
  }

  Color get _fgColor {
    switch (noiseCategory) {
      case NoiseCategory.quiet:
        return AppColors.noiseQuiet;
      case NoiseCategory.moderate:
        return AppColors.noiseModerate;
      case NoiseCategory.noisy:
        return AppColors.noiseNoisy;
      case NoiseCategory.loud:
        return AppColors.noiseLoud;
    }
  }

  IconData get _icon {
    switch (noiseCategory) {
      case NoiseCategory.quiet:
        return Icons.self_improvement_rounded; // 딥 포커스
      case NoiseCategory.moderate:
        return Icons.local_cafe_rounded;        // 소프트 바이브
      case NoiseCategory.noisy:
        return Icons.groups_rounded;            // 소셜 버즈
      case NoiseCategory.loud:
        return Icons.whatshot_rounded;          // 라이브 에너지
    }
  }

  String get _description {
    switch (noiseCategory) {
      case NoiseCategory.quiet:
        return '완전한 집중이 가능한 몰입 공간이에요';
      case NoiseCategory.moderate:
        return '여유롭고 편안한 카페 분위기예요';
      case NoiseCategory.noisy:
        return '에너지 넘치는 소셜 공간이에요';
      case NoiseCategory.loud:
        return '열정적이고 생동감 넘치는 공간이에요';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingStandard),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: _fgColor.withAlpha(40), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _fgColor.withAlpha(20),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(_icon, color: _fgColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      noiseCategory.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _fgColor,
                      ),
                    ),
                    if (averageDecibels != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${averageDecibels!.toStringAsFixed(1)} dB',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _fgColor.withAlpha(180),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _description,
                  style: TextStyle(
                    fontSize: 12,
                    color: _fgColor.withAlpha(160),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (measurementCount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${measurementCount}회 측정',
                    style: TextStyle(
                      fontSize: 11,
                      color: _fgColor.withAlpha(120),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
