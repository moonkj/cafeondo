import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/cafe_providers.dart';
import '../../providers/measurement_providers.dart';
import 'widgets/decibel_gauge.dart';

// Color constants
const Color _kNavy = Color(0xFF091717);
const Color _kDeepTeal = Color(0xFF115058);
const Color _kMutedTeal = Color(0xFF20808D);
const Color _kLightTeal = Color(0xFFD6F5FA);
const Color _kOffWhite = Color(0xFFFCFAF6);
const Color _kPaperWhite = Color(0xFFF3F3EE);
const Color _kWarmBeige = Color(0xFFE5E3D4);
const Color _kTerra = Color(0xFFA84B2F);
const Color _kMauve = Color(0xFF9C6B8A);

class MeasurementScreen extends ConsumerStatefulWidget {
  final String? cafeId;

  const MeasurementScreen({super.key, this.cafeId});

  @override
  ConsumerState<MeasurementScreen> createState() => _MeasurementScreenState();
}

class _MeasurementScreenState extends ConsumerState<MeasurementScreen> {
  @override
  void dispose() {
    // Ensure measurement stops when leaving screen
    final isMeasuring = ref.read(isMeasuringProvider);
    if (isMeasuring) {
      ref
          .read(measurementNotifierProvider.notifier)
          .stopMeasurement(cafeId: widget.cafeId ?? '');
    }
    super.dispose();
  }

  void _toggleMeasurement() {
    final isMeasuring = ref.read(isMeasuringProvider);
    final notifier = ref.read(measurementNotifierProvider.notifier);
    if (isMeasuring) {
      notifier.stopMeasurement(cafeId: widget.cafeId ?? '');
    } else {
      notifier.startMeasurement(cafeId: widget.cafeId ?? '');
    }
  }

  void _reset() {
    ref.read(measurementNotifierProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final isMeasuring = ref.watch(isMeasuringProvider);
    final currentDb = ref.watch(currentDecibelProvider);
    final duration = ref.watch(measurementDurationProvider);
    final result = ref.watch(measurementResultProvider);

    final double displayDb = currentDb.maybeWhen(
      data: (db) => db,
      orElse: () => result?.averageDb ?? 30.0,
    );

    return Scaffold(
      backgroundColor: _kOffWhite,
      appBar: AppBar(
        backgroundColor: _kOffWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: _kPaperWhite,
                shape: BoxShape.circle,
                border: Border.all(color: _kWarmBeige),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: _kNavy,
              ),
            ),
          ),
        ),
        title: Text(
          '소음 측정',
          style: TextStyle(
            color: _kNavy,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        actions: [
          if (result != null && !isMeasuring)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: _reset,
                child: Text(
                  '다시 측정',
                  style: TextStyle(
                    color: _kMutedTeal,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: result != null && !isMeasuring
            ? _ResultView(result: result, cafeId: widget.cafeId, onReset: _reset)
            : _MeasuringView(
                displayDb: displayDb,
                isMeasuring: isMeasuring,
                duration: duration,
                onToggle: _toggleMeasurement,
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Measuring View (live gauge)
// ---------------------------------------------------------------------------

class _MeasuringView extends StatelessWidget {
  final double displayDb;
  final bool isMeasuring;
  final Duration duration;
  final VoidCallback onToggle;

  const _MeasuringView({
    required this.displayDb,
    required this.isMeasuring,
    required this.duration,
    required this.onToggle,
  });

  String _formatDuration(Duration d) {
    final seconds = d.inSeconds % 60;
    final minutes = d.inMinutes;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Instruction text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              isMeasuring
                  ? '주변 소리를 측정하고 있어요'
                  : '버튼을 눌러 측정을 시작하세요',
              key: ValueKey(isMeasuring),
              style: TextStyle(
                color: _kNavy.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'Pretendard',
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Gauge
          DecibelGauge(
            db: displayDb,
            isMeasuring: isMeasuring,
          ),

          const SizedBox(height: 24),

          // Timer
          AnimatedOpacity(
            opacity: isMeasuring ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _kPaperWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kWarmBeige),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _kTerra,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '측정 중 ${_formatDuration(duration)}',
                    style: TextStyle(
                      color: _kNavy.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Tips
          if (!isMeasuring) _TipsCard(),

          const SizedBox(height: 20),

          // Start / Stop button
          _MeasureButton(isMeasuring: isMeasuring, onTap: onToggle),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tips Card
// ---------------------------------------------------------------------------

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kLightTeal.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kLightTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: _kDeepTeal),
              const SizedBox(width: 6),
              Text(
                '측정 팁',
                style: TextStyle(
                  color: _kDeepTeal,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TipItem('스마트폰을 테이블 위에 놓아주세요'),
          const SizedBox(height: 4),
          _TipItem('30초 이상 측정할수록 정확해요'),
          const SizedBox(height: 4),
          _TipItem('이동 중에는 측정하지 마세요'),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _kMutedTeal,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _kNavy.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Measure Button
// ---------------------------------------------------------------------------

class _MeasureButton extends StatelessWidget {
  final bool isMeasuring;
  final VoidCallback onTap;

  const _MeasureButton({required this.isMeasuring, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isMeasuring
              ? const LinearGradient(
                  colors: [Color(0xFF8B2500), _kTerra],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [_kDeepTeal, _kMutedTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMeasuring
                  ? Icons.stop_rounded
                  : Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              isMeasuring ? '측정 중지' : '측정 시작',
              style: const TextStyle(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Result View (shown after measurement completes)
// ---------------------------------------------------------------------------

class _ResultView extends StatelessWidget {
  final MeasurementResult result;
  final String? cafeId;
  final VoidCallback onReset;

  const _ResultView({
    required this.result,
    required this.cafeId,
    required this.onReset,
  });

  Color _levelColor(NoiseLevel level) {
    switch (level) {
      case NoiseLevel.quiet: return _kMutedTeal;
      case NoiseLevel.moderate: return const Color(0xFFB59B6E);
      case NoiseLevel.noisy: return _kTerra;
      case NoiseLevel.loud: return _kMauve;
    }
  }

  Color _levelBgColor(NoiseLevel level) {
    switch (level) {
      case NoiseLevel.quiet: return _kLightTeal;
      case NoiseLevel.moderate: return _kWarmBeige;
      case NoiseLevel.noisy: return const Color(0xFFFFDDD6);
      case NoiseLevel.loud: return const Color(0xFFEDD6E8);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}초';
    return '${d.inMinutes}분 ${d.inSeconds % 60}초';
  }

  @override
  Widget build(BuildContext context) {
    final level = noiseLevelFromDb(result.averageDb);
    final levelColor = _levelColor(level);
    final levelBgColor = _levelBgColor(level);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: levelBgColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: levelColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  '측정 완료!',
                  style: TextStyle(
                    color: _kNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  level.label,
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '평균 소음',
                  value: '${result.averageDb.toStringAsFixed(1)}dB',
                  icon: Icons.graphic_eq_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: '최고 소음',
                  value: '${result.peakDb.toStringAsFixed(1)}dB',
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '최저 소음',
                  value: '${result.minDb.toStringAsFixed(1)}dB',
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: '측정 시간',
                  value: _formatDuration(result.duration),
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: GestureDetector(
              onTap: () {
                // TODO: save to Firestore
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '측정 결과가 저장되었어요',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: _kDeepTeal,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                if (cafeId != null) {
                  context.pop();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kDeepTeal, _kMutedTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      '결과 저장하기',
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
          ),

          const SizedBox(height: 12),

          // Retry button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: GestureDetector(
              onTap: onReset,
              child: Container(
                decoration: BoxDecoration(
                  color: _kPaperWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kWarmBeige),
                ),
                child: Center(
                  child: Text(
                    '다시 측정하기',
                    style: TextStyle(
                      color: _kNavy.withOpacity(0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kOffWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kWarmBeige),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _kMutedTeal),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: _kNavy.withOpacity(0.45),
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: _kNavy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
