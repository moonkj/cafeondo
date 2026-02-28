import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../providers/cafe_providers.dart';

// Color constants
const Color _kNavy = Color(0xFF091717);
const Color _kDeepTeal = Color(0xFF115058);
const Color _kMutedTeal = Color(0xFF20808D);
const Color _kLightTeal = Color(0xFFD6F5FA);
const Color _kWarmBeige = Color(0xFFE5E3D4);
const Color _kPaperWhite = Color(0xFFF3F3EE);

class AtmosphereChart extends StatefulWidget {
  final List<HourlyNoise> hourlyData;

  const AtmosphereChart({super.key, required this.hourlyData});

  @override
  State<AtmosphereChart> createState() => _AtmosphereChartState();
}

class _AtmosphereChartState extends State<AtmosphereChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _drawAnimation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _drawAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<FlSpot> get _spots {
    return widget.hourlyData
        .map((h) => FlSpot((h.hour - 8).toDouble(), h.db))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drawAnimation,
      builder: (context, _) {
        return SizedBox(
          height: 200,
          child: LineChart(
            _buildChartData(),
            duration: const Duration(milliseconds: 250),
          ),
        );
      },
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
      minX: 0,
      maxX: 14,
      minY: 28,
      maxY: 82,
      clipData: FlClipData.all(),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => _kDeepTeal,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          getTooltipItems: (spots) {
            return spots.map((spot) {
              final hour = spot.x.toInt() + 8;
              final label = hour < 12
                  ? '오전 ${hour}시'
                  : hour == 12
                      ? '오후 12시'
                      : '오후 ${hour - 12}시';
              return LineTooltipItem(
                '$label\n${spot.y.round()}dB',
                TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.notoSansKr().fontFamily,
                ),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (_) => FlLine(
          color: _kWarmBeige.withOpacity(0.8),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: 10,
            getTitlesWidget: (value, meta) {
              if (value < 30 || value > 80) return const SizedBox.shrink();
              return Text(
                '${value.toInt()}',
                style: TextStyle(
                  color: _kNavy.withOpacity(0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  fontFamily: GoogleFonts.notoSansKr().fontFamily,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 2,
            getTitlesWidget: (value, meta) {
              final hour = value.toInt() + 8;
              if (value < 0 || value > 14) return const SizedBox.shrink();
              if (value % 2 != 0) return const SizedBox.shrink();
              final label = hour < 12
                  ? '${hour}시'
                  : hour == 12
                      ? '12시'
                      : '${hour - 12}시';
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    color: _kNavy.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    fontFamily: GoogleFonts.notoSansKr().fontFamily,
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: _spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: _kMutedTeal,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: _kDeepTeal,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
            checkToShowDot: (spot, barData) {
              // Only show dots at even hours
              return spot.x % 2 == 0;
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _kLightTeal.withOpacity(0.6),
                _kLightTeal.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
