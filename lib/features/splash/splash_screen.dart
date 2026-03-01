import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Noise Spot AppColors (replicated)
// ---------------------------------------------------------------------------

const _kMintGreen = Color(0xFF5BC8AC);
const _kMintLight = Color(0xFFA8E6CF);
const _kSkyLight = Color(0xFFB8E0F0);

// ---------------------------------------------------------------------------
// Splash Screen
// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final AnimationController _textCtrl;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _spinnerFade;

  @override
  void initState() {
    super.initState();

    // Wave: 2400 ms repeating (Noise Spot duration)
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Text + spinner fade-in
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    // Title: delay 400 ms, duration 600 ms
    _titleFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.18, 0.46, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.18, 0.46, curve: Curves.easeOutCubic),
    ));

    // Subtitle: delay 700 ms, duration 600 ms
    _subtitleFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.32, 0.59, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.32, 0.59, curve: Curves.easeOutCubic),
    ));

    // Spinner: delay 1800 ms, duration 400 ms
    _spinnerFade = CurvedAnimation(
      parent: _textCtrl,
      curve: const Interval(0.82, 1.00, curve: Curves.easeOut),
    );

    // Navigate after 2600 ms (Noise Spot timer)
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Noise Spot bgGradient: mintLight → skyLight, bottom-left → top-right
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [_kMintLight, _kSkyLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Wave animation (WaveToSpotPainter — exact Noise Spot copy)
              SizedBox(
                width: double.infinity,
                height: 108,
                child: AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _WaveToSpotPainter(progress: _waveCtrl.value),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App name with gradient shader (mint → sky)
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_kMintGreen, Color(0xFF78C5E8)],
                    ).createShader(bounds),
                    child: const Text(
                      '카페온도',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Slogan
              FadeTransition(
                opacity: _subtitleFade,
                child: SlideTransition(
                  position: _subtitleSlide,
                  child: const Text(
                    '카페 분위기, 온도로 느껴보세요',
                    style: TextStyle(
                      color: Color(0xFF2A7872),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Loading indicator (52 dp container, 24 dp spinner — Noise Spot)
              FadeTransition(
                opacity: _spinnerFade,
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_kMintGreen),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WaveToSpotPainter — exact copy from Noise Spot
// ---------------------------------------------------------------------------

class _WaveToSpotPainter extends CustomPainter {
  final double progress;
  const _WaveToSpotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    final waveStartX = w * 0.22;
    final spotX = w * 0.76;
    final spotY = midY + h * 0.02;

    // Build the complete path
    final path = Path()..moveTo(waveStartX, midY);

    final amp = h * 0.42;
    const segments = [
      [0.240, 0.00],
      [0.258, 0.18],
      [0.272, -0.32],
      [0.286, 0.52],
      [0.297, -1.00],
      [0.312, 0.88],
      [0.326, -0.82],
      [0.342, 0.62],
      [0.357, -0.45],
      [0.372, 0.28],
      [0.388, -0.15],
      [0.406, 0.06],
      [0.440, 0.00],
      [0.480, 0.00],
      [0.520, 0.00],
    ];
    for (final seg in segments) {
      path.lineTo(seg[0] * w, midY + seg[1] * amp);
    }

    // Smooth arc with upward curvature
    path.quadraticBezierTo(
      w * 0.63, midY - h * 0.52,
      spotX, spotY,
    );

    // PathMetric-based drawing animation
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLen = metric.length;
    final drawn = (totalLen * progress).clamp(0.0, totalLen);

    // Gradient stroke: mintGreen → white (Noise Spot style)
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        colors: [_kMintGreen, Colors.white],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(waveStartX, 0, spotX - waveStartX, h));

    canvas.drawPath(metric.extractPath(0, drawn), strokePaint);

    // Leading white dot
    if (progress > 0.01 && progress < 0.96) {
      final tangent = metric.getTangentForOffset(drawn);
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          3.5,
          Paint()..color = Colors.white,
        );
      }
    }

    // Spot circle blooms at the end
    if (progress > 0.90) {
      final t = ((progress - 0.90) / 0.10).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(spotX, spotY),
        12.0 * t,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white.withValues(alpha: t),
      );
    }
  }

  @override
  bool shouldRepaint(_WaveToSpotPainter old) => old.progress != progress;
}
