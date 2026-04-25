import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Splash inicial de la app. Reproduce Payly_splash.json una sola vez,
/// espera [_postDelay] ms y luego llama [onComplete] para que el padre
/// transite a la siguiente pantalla con un fade-out suave.
class PaylyInitSplash extends StatefulWidget {
  const PaylyInitSplash({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<PaylyInitSplash> createState() => _PaylyInitSplashState();
}

class _PaylyInitSplashState extends State<PaylyInitSplash>
    with SingleTickerProviderStateMixin {
  static const _postDelay   = Duration(milliseconds: 2000);
  static const _fadeDuration = Duration(milliseconds: 700);

  late final AnimationController _ctrl;
  bool _notified = false;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onLoaded(LottieComposition composition) async {
    _ctrl.duration = composition.duration;
    await _ctrl.forward();
    if (!mounted || _notified) return;
    await Future.delayed(_postDelay);
    if (!mounted || _notified) return;
    // Inicia el fade-out; onComplete se llama cuando termina
    setState(() => _opacity = 0.0);
    await Future.delayed(_fadeDuration);
    if (!mounted || _notified) return;
    _notified = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: _fadeDuration,
      curve: Curves.easeOut,
      child: Scaffold(
        backgroundColor: const Color(0xFF141210),
        body: Center(
          child: Lottie.asset(
            'assets/animations/Payly_splash.json',
            controller: _ctrl,
            onLoaded: _onLoaded,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
