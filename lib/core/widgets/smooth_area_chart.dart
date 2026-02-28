import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// 시간별 소음 데이터 포인트
class NoiseDataPoint {
  /// x 축 값 (시간: 0–23)
  final double hour;

  /// y 축 값 (데시벨)
  final double value;

  const NoiseDataPoint({required this.hour, required this.value});

  FlSpot toFlSpot() => FlSpot(hour, value);
}

/// 부드러운 면적 차트 위젯 (fl_chart 기반)
///
/// - Bezier 곡선 (isCurved: true)
/// - 틸 컬러 그라디언트 fill
/// - 깔끔한 그리드, 현대적인 레이블
/// - 바 차트 없음, 부드러운 곡선만
///
/// 사용 예시:
/// ```dart
/// SmoothAreaChart(
///   dataPoints: [
///     NoiseDataPoint(hour: 9, value: 42),
///     NoiseDataPoint(hour: 12, value: 60),
///     NoiseDataPoint(hour: 18, value: 72),
///   ],
/// )
/// ```
class SmoothAreaChart extends StatelessWidget {
  final List<NoiseDataPoint> dataPoints;

  /// 차트 최솟값 (기본: 0)
  final double minY;

  /// 차트 최댓값 (기본: 100)
  final double maxY;

  /// y축 레이블 표시 여부
  final bool showYLabels;

  /// x축 레이블 표시 여부
  final bool showXLabels;

  /// 그리드 라인 표시 여부
  final bool showGrid;

  /// 터치 툴팁 활성화 여부
  final bool showTooltip;

  /// 차트 높이
  final double height;

  /// 선 두께
  final double lineWidth;

  const SmoothAreaChart({
    super.key,
    required this.dataPoints,
    this.minY = 0,
    this.maxY = 100,
    this.showYLabels = true,
    this.showXLabels = true,
    this.showGrid = true,
    this.showTooltip = true,
    this.height = 200,
    this.lineWidth = 2.5,
  });

  // ── Data ──────────────────────────────────────────────────────────────────

  List<FlSpot> get _spots =>
      dataPoints.map((p) => p.toFlSpot()).toList()
        ..sort((a, b) => a.x.compareTo(b.x));

  double get _minX =>
      dataPoints.isEmpty ? 0 : dataPoints.map((p) => p.hour).reduce((a, b) => a < b ? a : b);

  double get _maxX =>
      dataPoints.isEmpty ? 24 : dataPoints.map((p) => p.hour).reduce((a, b) => a > b ? a : b);

  // ── Gradient Fill ─────────────────────────────────────────────────────────

  LinearGradient get _areaGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.chartFillTop,
          AppColors.chartFillBottom,
        ],
        stops: [0.0, 1.0],
      );

  // ── Color by dB level ────────────────────────────────────────────────────

  Color _colorForValue(double value) {
    if (value < 40) return AppColors.noiseQuiet;
    if (value < 60) return AppColors.noiseModerate;
    if (value < 75) return AppColors.noiseNoisy;
    return AppColors.noiseLoud;
  }

  // ── X Axis Label ─────────────────────────────────────────────────────────

  String _xLabel(double value) {
    final hour = value.toInt();
    if (hour == 0 || hour == 24) return '0시';
    if (hour % 6 == 0) return '$hour시';
    return '';
  }

  // ── Y Axis Label ─────────────────────────────────────────────────────────

  String _yLabel(double value) {
    if (value == 0) return '0';
    return '${value.toInt()}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '측정 데이터가 없어요',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: LineChart(
        _buildChartData(),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      ),
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
      minX: _minX,
      maxX: _maxX,
      minY: minY,
      maxY: maxY,

      // ── Grid ───────────────────────────────────────────────────────────
      gridData: FlGridData(
        show: showGrid,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.divider,
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),

      // ── Axis Titles ────────────────────────────────────────────────────
      titlesData: FlTitlesData(
        show: true,
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: showXLabels,
            reservedSize: 28,
            interval: 6,
            getTitlesWidget: (value, meta) {
              final label = _xLabel(value);
              if (label.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: showYLabels,
            reservedSize: 36,
            interval: 20,
            getTitlesWidget: (value, meta) {
              if (value == minY || value == maxY) {
                return const SizedBox.shrink();
              }
              return Text(
                _yLabel(value),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ),

      // ── Border ────────────────────────────────────────────────────────
      borderData: FlBorderData(
        show: false,
      ),

      // ── Touch ─────────────────────────────────────────────────────────
      lineTouchData: LineTouchData(
        enabled: showTooltip,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.navy.withAlpha(220),
          tooltipRoundedRadius: AppDimensions.radiusSmall,
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final color = _colorForValue(spot.y);
              return LineTooltipItem(
                '${spot.x.toInt()}시\n',
                const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(
                    text: '${spot.y.toStringAsFixed(1)} dB',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: AppColors.mutedTeal.withAlpha(100),
                strokeWidth: 1.5,
                dashArray: [4, 4],
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 5,
                  color: AppColors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.mutedTeal,
                ),
              ),
            );
          }).toList();
        },
      ),

      // ── Line(s) ───────────────────────────────────────────────────────
      lineBarsData: [
        LineChartBarData(
          spots: _spots,
          isCurved: true,
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          color: AppColors.chartLine,
          barWidth: lineWidth,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: dataPoints.length <= 12,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 3.5,
              color: AppColors.white,
              strokeWidth: 2,
              strokeColor: AppColors.chartLine,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: _areaGradient,
          ),
          shadow: Shadow(
            color: AppColors.mutedTeal.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// 카페 상세 화면의 "시간대별 분위기" 차트 (레이블 포함 컨테이너 버전)
class AtmosphereChartCard extends StatelessWidget {
  final List<NoiseDataPoint> dataPoints;
  final String? title;

  const AtmosphereChartCard({
    super.key,
    required this.dataPoints,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingStandard),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppDimensions.paddingStandard),
          ],
          SmoothAreaChart(
            dataPoints: dataPoints,
            height: 180,
            showTooltip: true,
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          // dB 범례
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final items = [
      _LegendItem('조용함', AppColors.noiseQuiet),
      _LegendItem('보통', AppColors.noiseModerate),
      _LegendItem('시끄러움', AppColors.noiseNoisy),
      _LegendItem('매우 시끄러움', AppColors.noiseLoud),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
}
