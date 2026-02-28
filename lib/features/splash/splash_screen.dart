import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// App color constants (mirrors app_colors.dart)
const Color _kDeepTeal = Color(0xFF115058);
const Color _kMutedTeal = Color(0xFF20808D);
const Color _kLightTeal = Color(0xFFD6F5FA);
const Color _kOffWhite = Color(0xFFFCFAF6);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _subtitleFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    // Navigate to home after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kOffWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo mark + App name
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  // Icon mark
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _kDeepTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        '°',
                        style: TextStyle(
                          color: _kLightTeal,
                          fontSize: 44,
                          fontWeight: FontWeight.w300,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App name
                  Text(
                    '카페온도',
                    style: TextStyle(
                      color: _kDeepTeal,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      fontFamily: GoogleFonts.notoSansKr().fontFamily,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            AnimatedBuilder(
              animation: _subtitleFadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _subtitleFadeAnimation.value,
                  child: child,
                );
              },
              child: Text(
                '당신의 완벽한 카페를 찾아보세요',
                style: TextStyle(
                  color: _kMutedTeal,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                  fontFamily: GoogleFonts.notoSansKr().fontFamily,
                ),
              ),
            ),

            const SizedBox(height: 80),

            // Loading indicator
            AnimatedBuilder(
              animation: _subtitleFadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _subtitleFadeAnimation.value * 0.5,
                  child: child,
                );
              },
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(_kMutedTeal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
