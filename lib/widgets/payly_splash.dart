import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Splash de transición reutilizable para login y logout.
///
/// Muestra el ícono con resplandor animado, un mensaje de estado,
/// un indicador de puntos secuenciales y un tagline creativo.
/// Se adapta al tema claro/oscuro a través de [PaylyColors].
class PaylyTransitionSplash extends StatefulWidget {
  const PaylyTransitionSplash({
    super.key,
    required this.message,
    required this.tagline,
  });

  final String message;
  final String tagline;

  @override
  State<PaylyTransitionSplash> createState() => _PaylyTransitionSplashState();
}

class _PaylyTransitionSplashState extends State<PaylyTransitionSplash>
    with TickerProviderStateMixin {
  // Entrance: icon + text
  late final AnimationController _enterCtrl;
  // Breathing glow on the icon
  late final AnimationController _glowCtrl;
  // Sequential dots loader
  late final AnimationController _dotsCtrl;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _glowSigma;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    // Icon: scale from 65% with a slight overshoot (easeOutBack)
    _iconScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOut),
      ),
    );

    // Glow breathing: sigma 16 → 28
    _glowSigma = Tween<double>(begin: 16.0, end: 28.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Message + dots slide up after icon
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.40),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.28, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.28, 0.78, curve: Curves.easeOut),
      ),
    );

    // Tagline slides up last, staggered
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.55),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.50, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.50, 0.95, curve: Curves.easeOut),
      ),
    );

    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _glowCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pc;

    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with breathing glow
              ScaleTransition(
                scale: _iconScale,
                child: FadeTransition(
                  opacity: _iconFade,
                  child: AnimatedBuilder(
                    animation: _glowSigma,
                    builder: (_, _) => SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: _glowSigma.value,
                              sigmaY: _glowSigma.value,
                            ),
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                AppColors.yellow,
                                BlendMode.srcATop,
                              ),
                              child: Image.asset(
                                'assets/Payly_ICON.png',
                                width: 92,
                                height: 92,
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/Payly_ICON.png',
                            width: 92,
                            height: 92,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 38),

              // Loading message + dots
              SlideTransition(
                position: _contentSlide,
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    children: [
                      Text(
                        widget.message,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DotsLoader(controller: _dotsCtrl),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 38),

              // Creative tagline
              SlideTransition(
                position: _taglineSlide,
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    widget.tagline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: c.textSec,
                      height: 1.6,
                    ),
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

/// Tres puntos amarillos con animación secuencial (efecto chaser).
class _DotsLoader extends StatelessWidget {
  const _DotsLoader({required this.controller});
  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot offset by 1/4 of the cycle (left-to-right chaser)
            final phase = ((controller.value - i * 0.25) % 1.0 + 1.0) % 1.0;
            // Map phase to a 0→1→0 wave
            final wave = phase < 0.5 ? phase * 2.0 : (1.0 - phase) * 2.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.5),
              child: Opacity(
                opacity: 0.22 + 0.78 * wave,
                child: Transform.scale(
                  scale: 0.50 + 0.50 * wave,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
