import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'generate_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user, required this.onThemeChanged, required this.darkMode});
  final User user;
  final ValueChanged<bool> onThemeChanged;
  final bool darkMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _rate = 7950;
  String _defaultEntry = '08:00';
  String _defaultExit = '17:00';
  late final PageController _pageController;
  late final HistoryScreen _historyScreen;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _historyScreen = HistoryScreen(uid: widget.user.uid);
    _loadPrefs();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _rate = p.getInt('hourlyRate') ?? 7950;
      _defaultEntry = p.getString('defaultEntry') ?? '08:00';
      _defaultExit = p.getString('defaultExit') ?? '17:00';
    });
  }

  Future<void> _setRate(int v) async {
    setState(() => _rate = v);
    final p = await SharedPreferences.getInstance();
    await p.setInt('hourlyRate', v);
  }

  Future<void> _setEntry(String v) async {
    setState(() => _defaultEntry = v);
    final p = await SharedPreferences.getInstance();
    await p.setString('defaultEntry', v);
  }

  Future<void> _setExit(String v) async {
    setState(() => _defaultExit = v);
    final p = await SharedPreferences.getInstance();
    await p.setString('defaultExit', v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pc;
    final uid = widget.user.uid;

    final screens = [
      GenerateScreen(uid: uid, rate: _rate, defaultEntry: _defaultEntry, defaultExit: _defaultExit),
      _historyScreen,
      SettingsScreen(
        user: widget.user,
        rate: _rate,
        onRateChanged: _setRate,
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onThemeChanged,
        defaultEntry: _defaultEntry,
        onDefaultEntryChanged: _setEntry,
        defaultExit: _defaultExit,
        onDefaultExitChanged: _setExit,
        onLogout: () {},
      ),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: PageView(
        controller: _pageController,
        children: screens.map((s) => _KeepAlive(child: s)).toList(),
      ),
      bottomNavigationBar: _TabBar(
        pageController: _pageController,
        onTap: (i) => _pageController.animateToPage(
          i,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOut,
        ),
        c: c,
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.pageController, required this.onTap, required this.c});
  final PageController pageController;
  final ValueChanged<int> onTap;
  final PaylyColors c;

  static const _tabs = [
    (icon: Icons.add_rounded, label: 'Generar'),
    (icon: Icons.list_rounded, label: 'Historial'),
    (icon: Icons.settings_outlined, label: 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.tabBg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: AnimatedBuilder(
            animation: pageController,
            builder: (context, _) {
              final page = pageController.hasClients
                  ? (pageController.page ?? 0.0)
                  : 0.0;
              return Row(
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final t = (1.0 - (page - i).abs()).clamp(0.0, 1.0);
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50, height: 32,
                            decoration: BoxDecoration(
                              color: Color.lerp(Colors.transparent, AppColors.yellow, t),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              tab.icon,
                              size: 20,
                              color: Color.lerp(c.textSec, AppColors.yellowText, t),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              letterSpacing: 0.1,
                              fontWeight: FontWeight.lerp(FontWeight.w500, FontWeight.w800, t),
                              color: Color.lerp(c.textSec, c.text, t),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
