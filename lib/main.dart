import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/payly_splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('es_CO');
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const PaylyApp());
}

enum _AppPhase { init, auth, loginSplash, home, logoutSplash }

class PaylyApp extends StatefulWidget {
  const PaylyApp({super.key});

  @override
  State<PaylyApp> createState() => _PaylyAppState();
}

class _PaylyAppState extends State<PaylyApp> {
  bool _darkMode = false;
  _AppPhase _phase = _AppPhase.init;
  User? _user;
  StreamSubscription<User?>? _authSub;
  bool _firstEvent = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChange);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChange(User? user) async {
    if (!mounted) return;

    if (_firstEvent) {
      _firstEvent = false;
      // Initial load: skip splash, go straight to the right screen
      setState(() {
        _user = user;
        _phase = user != null ? _AppPhase.home : _AppPhase.auth;
      });
      return;
    }

    final wasAuthenticated = _user != null;
    final isAuthenticated  = user != null;

    if (!wasAuthenticated && isAuthenticated) {
      // Logged in → show login splash, then enter home
      setState(() => _phase = _AppPhase.loginSplash);
      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted) setState(() { _user = user; _phase = _AppPhase.home; });
    } else if (wasAuthenticated && !isAuthenticated) {
      // Logged out → show logout splash, then return to auth
      setState(() => _phase = _AppPhase.logoutSplash);
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) setState(() { _user = null; _phase = _AppPhase.auth; });
    } else {
      setState(() {
        _user = user;
        _phase = user != null ? _AppPhase.home : _AppPhase.auth;
      });
    }
  }

  Future<void> _loadTheme() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _darkMode = p.getBool('darkMode') ?? false);
  }

  Future<void> _setDarkMode(bool v) async {
    setState(() => _darkMode = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool('darkMode', v);
  }

  @override
  Widget build(BuildContext context) {
    final Widget screen = switch (_phase) {
      _AppPhase.init =>
        const _InitSplash(),
      _AppPhase.auth =>
        const AuthScreen(),
      _AppPhase.loginSplash =>
        const PaylyTransitionSplash(
          message: 'Cargando tu espacio...',
          tagline: '¡Tu semana laboral\nsiempre al día! 🐤',
        ),
      _AppPhase.home =>
        HomeScreen(
          user: _user!,
          darkMode: _darkMode,
          onThemeChanged: _setDarkMode,
        ),
      _AppPhase.logoutSplash =>
        const PaylyTransitionSplash(
          message: 'Cerrando sesión...',
          tagline: 'Hasta pronto.\nTu historial está seguro. 🔐',
        ),
    };

    return MaterialApp(
      title: 'Payly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.055),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey(_phase), child: screen),
      ),
    );
  }
}

// Pantalla de carga inicial (mientras Firebase verifica el estado de auth)
class _InitSplash extends StatelessWidget {
  const _InitSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141210),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/Payly_ICON.png', width: 80, height: 80),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: AppColors.yellow, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
