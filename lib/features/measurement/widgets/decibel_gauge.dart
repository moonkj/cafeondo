import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/cafe_providers.dart';
import '../../../providers/measurement_providers.dart';

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

/// Animated circular gauge that visualises a dB level from 30–90dB.
class DecibelGauge extends StatefulWidget {
  /// Current decibel value to display (30–90 range).
  final double db;

  /// Whether measurement is actively running (enables pulse animation).
  final bool isMeasuring;

  const DecibelGauge({
    super.key,
    required this.db,
    this.isMeasuring = false,
  });

  @override
  State<DecibelGauge> createState() => _DecibelGaugeState();
}

class _DecibelGaugeState extends State<DecibelGauge>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  double _previousDb = 30.0;

  static const double _minDb = 30.0;
  static const double _maxDb = 90.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _progressAnimation = Tween<double>(
      begin: _normalise(_previousDb),
      end: _normalise(widget.db),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    _progressController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(DecibelGauge old) {
    super.didUpdateWidget(old);
    if (old.db != widget.db) {
      final from = _normalise(_previousDb);
      final to = _normalise(widget.db);
      _progressAnimation = Tween<double>(begin: from, end: to).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeInOut,
        ),
      );
      _progressController
        ..reset()
        ..forward();
      _previousDb = widget.db;
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double _normalise(double db) =>
      ((db - _minDb) / (_maxDb - _minDb)).clamp(0.0, 1.0);

  Color _gaugeColor(double db) {
    if (db <= 50) return _kMutedTeal;
    if (db <= 65) return const Color(0xFFB59B6E); // warm amber
    if (db <= 75) return _kTerra;
    return _kMauve;
  }

  String _levelLabel(double db) {
    if (db <= 50) return '조용함';
    if (db <= 65) return '보통';
    if (db <= 75) return '시끄러움';
    return '매우 시끄러움';
  }

  @override
  Widget build(BuildContext context) {
    final color = _gaugeColor(widget.db);

    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _pulseAnimation]),
      builder: (context, child) {
        final progress = _progressAnimation.value;
        final scale = widget.isMeasuring ? _pulseAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _GaugePainter(
                progress: progress,
                color: color,
                isMeasuring: widget.isMeasuring,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // dB value
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: widget.db),
                      duration: const Duration(milliseconds: 250),
                      builder: (_, value, __) => Text(
                        value.round().toString(),
                        style: TextStyle(
                          color: color,
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                    Text(
                      'dB',
                      style: TextStyle(
                        color: _kNavy.withOpacity(0.4),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Level label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _levelLabel(widget.db),
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Gauge Painter
// ---------------------------------------------------------------------------

class _GaugePainter extends CustomPainter {
  final double progress; // 0.0–1.0
  final Color color;
  final bool isMeasuring;

  const _GaugePainter({
    required this.progress,
    required this.color,
    required this.isMeasuring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Track (background arc)
    final trackPaint = Paint()
      ..color = _kWarmBeige
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        progressPaint,
      );
    }

    // Pulsing outer ring when measuring
    if (isMeasuring) {
      final ringPaint = Paint()
        ..color = color.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawCircle(center, radius + 20, ringPaint);
    }

    // Tick marks
    _drawTicks(canvas, center, radius);
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    const totalTicks = 30;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    for (int i = 0; i <= totalTicks; i++) {
      final angle = startAngle + (sweepAngle / totalTicks) * i;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 10.0 : 5.0;
      final outerR = radius - 22;
      final innerR = outerR - tickLength;

      final outerPoint = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );

      canvas.drawLine(
        outerPoint,
        innerPoint,
        Paint()
          ..color = _kNavy.withOpacity(isMajor ? 0.2 : 0.1)
          ..strokeWidth = isMajor ? 1.5 : 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.color != color;
}
