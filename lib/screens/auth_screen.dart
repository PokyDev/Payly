import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  static final _emailRx    = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
  static final _usernameRx = RegExp(r'^[a-zA-Z0-9._-]{3,20}$');

  final _auth      = AuthService();
  bool  _isLogin   = true;
  bool  _loading       = false;
  bool  _googleLoading = false;

  Timer? _usernameCheckTimer;
  bool   _usernameChecking  = false;
  bool?  _usernameAvailable;

  DateTime? _resetCooldownEnd;
  int       _cooldownSecondsLeft = 0;
  Timer?    _cooldownTimer;
  bool get  _resetCooldownActive => _cooldownSecondsLeft > 0;

  static const _kCooldownKey = 'password_reset_cooldown_end';

  final _nameTxt     = TextEditingController();
  final _emailCtrl   = TextEditingController(text: '');
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  late final FocusNode _nameFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _confirmFocus;

  bool _emailTouched   = false;
  bool _nameTouched    = false;
  bool _confirmTouched = false;

  String? _error;

  late final AnimationController _modeAnim;
  late final Animation<double> _nameSize;
  late final Animation<double> _nameFade;
  late final Animation<double> _forgotSize;
  late final Animation<double> _forgotFade;

  late final AnimationController _msgAnim;
  late final Animation<double> _msgSize;
  late final Animation<double> _msgFade;
  late final Animation<Offset> _msgSlide;
  Timer? _msgTimer;
  bool _msgIsWarning = false;

  late final AnimationController _strengthAnim;
  late final Animation<double> _strengthSize;
  late final Animation<double> _strengthFade;

  Offset? _swipeStart;

  bool get _emailValid => _emailRx.hasMatch(_emailCtrl.text.trim());
  bool get _nameValid  => _usernameRx.hasMatch(_nameTxt.text.trim());
  bool get _showUsernameAvailability =>
      !_isLogin && _nameValid && (_usernameChecking || _usernameAvailable != null);
  bool get _passwordsMatch =>
      _passCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty &&
      _passCtrl.text == _confirmCtrl.text;

  bool get _fieldsOk {
    if (!_emailValid || _passCtrl.text.isEmpty) return false;
    if (!_isLogin) {
      if (!_nameValid || _usernameAvailable != true) return false;
      if (!_passwordsMatch) return false;
    }
    return true;
  }

  bool get _showEmailError   => _emailTouched && !_emailValid;
  bool get _showNameError    => _nameTouched && !_nameValid && !_isLogin;
  bool get _showConfirmError =>
      _confirmTouched &&
      _confirmCtrl.text.isNotEmpty &&
      !_passwordsMatch;
  bool get _showPassError => _showConfirmError;

  int get _strengthLevel {
    final p = _passCtrl.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(p)) s++;
    if (s <= 1) return 1;
    if (s == 2) return 2;
    if (s <= 4) return 3;
    return 4;
  }

  @override
  void initState() {
    super.initState();

    _nameFocus    = FocusNode()..addListener(_onNameFocusChange);
    _emailFocus   = FocusNode()..addListener(_onEmailFocusChange);
    _confirmFocus = FocusNode()..addListener(_onConfirmFocusChange);

    _modeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 0.0,
    );
    _nameSize   = CurvedAnimation(parent: _modeAnim, curve: Curves.easeOutCubic);
    _nameFade   = CurvedAnimation(parent: _modeAnim, curve: Curves.easeOut);
    _forgotSize = CurvedAnimation(parent: ReverseAnimation(_modeAnim), curve: Curves.easeOutCubic);
    _forgotFade = CurvedAnimation(parent: ReverseAnimation(_modeAnim), curve: Curves.easeOut);

    _nameTxt.addListener(_onUsernameChange);
    _emailCtrl.addListener(_onFieldChange);
    _passCtrl.addListener(_onFieldChange);
    _confirmCtrl.addListener(_onFieldChange);

    _loadCooldown();

    _msgAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _msgSize  = CurvedAnimation(parent: _msgAnim, curve: Curves.easeOutCubic);
    _msgFade  = CurvedAnimation(parent: _msgAnim, curve: Curves.easeOut);
    _msgSlide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _msgAnim, curve: Curves.easeOutCubic));

    _strengthAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _strengthSize = CurvedAnimation(parent: _strengthAnim, curve: Curves.easeOutCubic);
    _strengthFade = CurvedAnimation(parent: _strengthAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    _usernameCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    _modeAnim.dispose();
    _msgAnim.dispose();
    _strengthAnim.dispose();
    _nameTxt.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final endMs = prefs.getInt(_kCooldownKey);
    if (endMs == null) return;
    final end = DateTime.fromMillisecondsSinceEpoch(endMs);
    final remaining = end.difference(DateTime.now()).inSeconds;
    if (remaining > 0) {
      if (mounted) setState(() { _resetCooldownEnd = end; _cooldownSecondsLeft = remaining; });
      _startCooldownTimer();
    } else {
      await prefs.remove(_kCooldownKey);
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _resetCooldownEnd!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        _cooldownTimer?.cancel();
        setState(() { _cooldownSecondsLeft = 0; _resetCooldownEnd = null; });
        SharedPreferences.getInstance().then((p) => p.remove(_kCooldownKey));
      } else {
        setState(() => _cooldownSecondsLeft = remaining);
      }
    });
  }

  void _onUsernameChange() {
    _scheduleUsernameCheck();
    setState(() {});
  }

  void _onFieldChange() {
    final shouldShowStrength = !_isLogin && _passwordsMatch;
    if (shouldShowStrength) {
      _strengthAnim.forward();
    } else {
      _strengthAnim.reverse();
    }
    setState(() {});
  }

  void _scheduleUsernameCheck() {
    if (_isLogin || !_nameValid) {
      _usernameCheckTimer?.cancel();
      if (_usernameAvailable != null || _usernameChecking) {
        setState(() { _usernameAvailable = null; _usernameChecking = false; });
      }
      return;
    }
    _usernameCheckTimer?.cancel();
    setState(() { _usernameChecking = true; _usernameAvailable = null; });
    _usernameCheckTimer = Timer(const Duration(milliseconds: 600), _checkUsernameAvailability);
  }

  Future<void> _checkUsernameAvailability() async {
    final username = _nameTxt.text.trim();
    if (!_usernameRx.hasMatch(username)) return;
    final available = await _auth.isUsernameAvailable(username);
    if (mounted) setState(() { _usernameChecking = false; _usernameAvailable = available; });
  }

  void _onEmailFocusChange() {
    if (!_emailFocus.hasFocus && _emailCtrl.text.isNotEmpty) {
      setState(() => _emailTouched = true);
    }
  }

  void _onNameFocusChange() {
    if (!_nameFocus.hasFocus && _nameTxt.text.isNotEmpty) {
      setState(() => _nameTouched = true);
    }
  }

  void _onConfirmFocusChange() {
    if (!_confirmFocus.hasFocus && _confirmCtrl.text.isNotEmpty) {
      setState(() => _confirmTouched = true);
    }
  }

  void _showMsg(String msg, {bool warning = false}) {
    _msgTimer?.cancel();
    setState(() { _error = msg; _msgIsWarning = warning; });
    _msgAnim.forward(from: 0.0);
    _msgTimer = Timer(const Duration(seconds: 5), _hideMsg);
  }

  void _hideMsg() {
    _msgTimer?.cancel();
    _msgAnim.reverse().then((_) {
      if (mounted) setState(() => _error = null);
    });
  }

  void _switchMode(bool toLogin) {
    _msgTimer?.cancel();
    _usernameCheckTimer?.cancel();
    _msgAnim.value = 0.0;
    _strengthAnim.value = 0.0;
    _confirmCtrl.clear();
    setState(() {
      _isLogin           = toLogin;
      _error             = null;
      _emailTouched      = false;
      _nameTouched       = false;
      _confirmTouched    = false;
      _usernameChecking  = false;
      _usernameAvailable = null;
    });
    if (toLogin) { _modeAnim.reverse(); } else { _modeAnim.forward(); }
  }

  void _trySubmit() {
    setState(() {
      _emailTouched = true;
      if (!_isLogin) {
        _nameTouched    = true;
        _confirmTouched = true;
      }
    });
    if (!_fieldsOk) {
      final passEmpty       = _passCtrl.text.isEmpty;
      final hasPassMismatch = !_isLogin && !passEmpty && !_passwordsMatch;
      final hasFormatErrors   = !_emailValid || (!_isLogin && !_nameValid);
      final usernameTaken     = !_isLogin && _usernameAvailable == false;
      final usernameChecking  = !_isLogin && _usernameChecking;
      _showMsg(
        passEmpty
            ? 'El ingreso de una contraseña es obligatorio (mínimo 6 caracteres).'
            : hasPassMismatch
                ? 'Las contraseñas no coinciden.'
                : usernameTaken
                    ? 'Ese nombre de usuario ya está en uso.'
                    : usernameChecking
                        ? 'Espera mientras se verifica el nombre de usuario.'
                        : hasFormatErrors
                            ? 'Revisa los campos marcados en rojo.'
                            : 'Tienes que llenar todos los campos requeridos.',
        warning: true,
      );
      return;
    }
    _submit();
  }

  Future<void> _submit() async {
    debugPrint('[AuthScreen] submit → mode: ${_isLogin ? "login" : "register"}, email: "${_emailCtrl.text.trim()}"');
    _msgTimer?.cancel();
    _msgAnim.value = 0.0;
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await _auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await _auth.register(
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _nameTxt.text.trim(),
        );
      }
      debugPrint('[AuthScreen] submit SUCCESS');
    } on Exception catch (e) {
      debugPrint('[AuthScreen] submit CAUGHT → $e');
      _showMsg(_friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (raw.contains('account-exists-with-different-credential')) {
      return 'Este correo ya tiene una cuenta con contraseña. Inicia sesión con correo y contraseña.';
    }
    if (raw.contains('username-taken'))        return 'Ese nombre de usuario ya está en uso.';
    if (raw.contains('email-already-in-use')) return 'Este correo ya está registrado.';
    if (raw.contains('weak-password'))        return 'La contraseña debe tener al menos 6 caracteres.';
    if (raw.contains('invalid-email'))        return 'Correo electrónico inválido.';
    return 'Ocurrió un error. Intenta de nuevo.';
  }

  Future<void> _signInWithGoogle() async {
    if (_googleLoading || _loading) return;
    setState(() => _googleLoading = true);
    try {
      await _auth.signInWithGoogle();
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('google-cancelled')) return;
      _showMsg(_friendlyError(msg));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_resetCooldownActive) {
      final m = _cooldownSecondsLeft ~/ 60;
      final s = _cooldownSecondsLeft % 60;
      _showMsg('Espera ${m > 0 ? "${m}m " : ""}${s.toString().padLeft(2, "0")}s antes de volver a intentarlo.');
      return;
    }
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showMsg('Ingresa tu correo para restablecer la contraseña.');
      return;
    }
    try {
      await _auth.sendPasswordReset(email);
      final end = DateTime.now().add(const Duration(minutes: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCooldownKey, end.millisecondsSinceEpoch);
      if (mounted) {
        setState(() { _resetCooldownEnd = end; _cooldownSecondsLeft = 60; });
        _startCooldownTimer();
        _showMsg('Correo de recuperación enviado. Revisa tu bandeja.', warning: true);
      }
    } catch (_) {
      _showMsg('No se pudo enviar el correo. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pc;

    InputDecoration inputDec(String hint, {bool hasError = false}) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: c.textTer),
      filled: true,
      fillColor: hasError ? c.danger.withValues(alpha: 0.06) : c.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: hasError ? c.danger : c.border,        width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: hasError ? c.danger : c.border,        width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: hasError ? c.danger : AppColors.yellow, width: 2.0)),
    );

    Widget fieldHint(String msg, bool show) => AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: show
          ? Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: c.danger),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      msg,
                      style: GoogleFonts.dmSans(fontSize: 12, color: c.danger),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );

    // Strength level metadata
    const strengthBarColors = [
      Color(0xFFEF5350), // Débil  – red
      Color(0xFFFF9800), // Regular – orange
      Color(0xFFF5C518), // Buena  – yellow
      Color(0xFF4CAF50), // Fuerte – green
    ];
    const strengthLabels = ['Débil', 'Regular', 'Buena', 'Fuerte'];
    final level = _strengthLevel;
    final strengthColor = level > 0 ? strengthBarColors[level - 1] : c.textTer;
    final strengthLabel = level > 0 ? strengthLabels[level - 1] : '';
    final strengthFill  = (level / 4.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: c.bg,
      body: Listener(
        onPointerDown: (e) => _swipeStart = e.position,
        onPointerUp: (e) {
          if (_swipeStart == null) return;
          final dx = e.position.dx - _swipeStart!.dx;
          final dy = (e.position.dy - _swipeStart!.dy).abs();
          _swipeStart = null;
          if (dx.abs() < 50 || dx.abs() < dy * 1.2) return;
          if (dx < 0 && _isLogin)  _switchMode(false);
          if (dx > 0 && !_isLogin) _switchMode(true);
        },
        onPointerCancel: (_) => _swipeStart = null,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hero
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 36, 32, 12),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.mode(AppColors.yellow, BlendMode.srcATop),
                                child: Image.asset('assets/Payly_ICON.png', width: 76, height: 76),
                              ),
                            ),
                            Image.asset('assets/Payly_ICON.png', width: 76, height: 76),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Payly', style: GoogleFonts.dmSans(fontSize: 30, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -1.2)),
                      const SizedBox(height: 4),
                      Text('Tu pago semanal, siempre claro 🐤', style: GoogleFonts.dmSans(fontSize: 13, color: c.textSec)),
                    ],
                  ),
                ),

                // Card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 32, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mode tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(14)),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  alignment: _isLogin ? Alignment.centerLeft : Alignment.centerRight,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.5,
                                    heightFactor: 1.0,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOut,
                                      decoration: BoxDecoration(
                                        color: AppColors.yellow,
                                        borderRadius: _isLogin
                                            ? const BorderRadius.only(topLeft: Radius.circular(11), bottomLeft: Radius.circular(11))
                                            : const BorderRadius.only(topRight: Radius.circular(11), bottomRight: Radius.circular(11)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                _Tab(label: 'Iniciar sesión', active: _isLogin,  onTap: () => _switchMode(true)),
                                _Tab(label: 'Registrarse',    active: !_isLogin, onTap: () => _switchMode(false)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name field (register only)
                          SizeTransition(
                            sizeFactor: _nameSize,
                            child: FadeTransition(
                              opacity: _nameFade,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 11),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _nameTxt,
                                      focusNode: _nameFocus,
                                      style: GoogleFonts.dmSans(color: c.text, fontSize: 15),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[a-zA-Z0-9._\-]'),
                                        ),
                                        LengthLimitingTextInputFormatter(20),
                                      ],
                                      decoration: inputDec('Nombre de usuario', hasError: _showNameError),
                                    ),
                                    fieldHint('Solo letras, números, puntos, guiones y _ (3–20 caracteres)', _showNameError),
                                    // Availability indicator
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      child: _showUsernameAvailability
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: 6, left: 4),
                                              child: Row(
                                                children: [
                                                  if (_usernameChecking)
                                                    SizedBox(
                                                      width: 12, height: 12,
                                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: c.textTer),
                                                    )
                                                  else if (_usernameAvailable == true)
                                                    Icon(Icons.check_circle_outline_rounded, size: 13, color: c.success)
                                                  else
                                                    Icon(Icons.cancel_outlined, size: 13, color: c.danger),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    _usernameChecking
                                                        ? 'Verificando...'
                                                        : _usernameAvailable == true
                                                            ? 'Disponible'
                                                            : 'Ya está en uso',
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 12,
                                                      color: _usernameChecking
                                                          ? c.textTer
                                                          : _usernameAvailable == true
                                                              ? c.success
                                                              : c.danger,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Email field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.dmSans(color: c.text, fontSize: 15),
                                decoration: inputDec('Correo electrónico', hasError: _showEmailError),
                              ),
                              fieldHint('Formato inválido (ej. usuario@gmail.com)', _showEmailError),
                            ],
                          ),
                          const SizedBox(height: 11),

                          // Password field – turns red when confirm doesn't match
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _passCtrl,
                                obscureText: true,
                                style: GoogleFonts.dmSans(color: c.text, fontSize: 15),
                                decoration: inputDec('Contraseña', hasError: _showPassError),
                              ),
                            ],
                          ),

                          // Confirm password field (register only)
                          SizeTransition(
                            sizeFactor: _nameSize,
                            child: FadeTransition(
                              opacity: _nameFade,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 11),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _confirmCtrl,
                                      focusNode: _confirmFocus,
                                      obscureText: true,
                                      style: GoogleFonts.dmSans(color: c.text, fontSize: 15),
                                      decoration: inputDec('Confirmar contraseña', hasError: _showConfirmError),
                                    ),
                                    fieldHint('Las contraseñas no coinciden', _showConfirmError),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Password strength bar (appears only when passwords match)
                          SizeTransition(
                            sizeFactor: _strengthSize,
                            child: FadeTransition(
                              opacity: _strengthFade,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Seguridad',
                                          style: GoogleFonts.dmSans(fontSize: 11, color: c.textTer),
                                        ),
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeOut,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: strengthColor,
                                          ),
                                          child: Text(strengthLabel),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: Container(
                                        height: 4,
                                        color: c.cardAlt,
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: strengthFill),
                                          duration: const Duration(milliseconds: 420),
                                          curve: Curves.easeOutCubic,
                                          builder: (context2, val, child2) => FractionallySizedBox(
                                            widthFactor: val,
                                            alignment: Alignment.centerLeft,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeOut,
                                              decoration: BoxDecoration(
                                                color: strengthColor,
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Forgot password (login only)
                          SizeTransition(
                            sizeFactor: _forgotSize,
                            child: FadeTransition(
                              opacity: _forgotFade,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Countdown — only visible while cooldown is active
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeOutCubic,
                                      child: _resetCooldownActive
                                          ? Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.timer_outlined, size: 13, color: c.textTer),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '${_cooldownSecondsLeft ~/ 60}:${(_cooldownSecondsLeft % 60).toString().padLeft(2, '0')}',
                                                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: c.textTer),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: _resetPassword,
                                      child: Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _resetCooldownActive
                                              ? Color.lerp(AppColors.yellow, Colors.black, 0.38)!
                                              : AppColors.yellow,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Error / warning message
                          SizeTransition(
                            sizeFactor: _msgSize,
                            child: FadeTransition(
                              opacity: _msgFade,
                              child: SlideTransition(
                                position: _msgSlide,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _msgIsWarning ? c.badgeAmber : c.danger.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(_error ?? '', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 13, color: _msgIsWarning ? c.badgeAmberText : c.danger)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Submit button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _trySubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _fieldsOk ? AppColors.yellow : c.cardAlt,
                                disabledBackgroundColor: AppColors.yellow,
                                foregroundColor: _fieldsOk ? AppColors.yellowText : c.textSec,
                                disabledForegroundColor: AppColors.yellowText,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellowText))
                                  : AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOut,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: _fieldsOk ? AppColors.yellowText : c.textSec,
                                      ),
                                      child: Text(_isLogin ? 'Entrar' : 'Crear cuenta'),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: Divider(color: c.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('o continúa con', style: GoogleFonts.dmSans(fontSize: 12, color: c.textTer)),
                              ),
                              Expanded(child: Divider(color: c.border)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          OutlinedButton(
                            onPressed: (_loading || _googleLoading) ? null : _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(color: c.borderMed),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              backgroundColor: c.bg,
                              disabledBackgroundColor: c.bg,
                            ),
                            child: _googleLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.yellow,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset('assets/svg/google-icon-logo.svg', width: 20, height: 20),
                                      const SizedBox(width: 10),
                                      Text('Google', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.pc;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.yellowText : c.textSec,
            ),
            child: Text(label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
