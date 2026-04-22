import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/payly_confirm_sheet.dart';
import '../widgets/payly_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.user,
    required this.rate,
    required this.onRateChanged,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.defaultEntry,
    required this.onDefaultEntryChanged,
    required this.defaultExit,
    required this.onDefaultExitChanged,
    required this.onLogout,
  });

  final User user;
  final int rate;
  final ValueChanged<int> onRateChanged;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final String defaultEntry;
  final ValueChanged<String> onDefaultEntryChanged;
  final String defaultExit;
  final ValueChanged<String> onDefaultExitChanged;
  final VoidCallback onLogout;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  late final _rateCtrl = TextEditingController(text: widget.rate.toString());
  String _currency = 'COP';
  String _weekStart = 'lunes';
  bool _reminders = false;
  bool _showLogout = false;
  String? _username;

  bool get _isGoogleUser => widget.user.providerData.any((p) => p.providerId == 'google.com');

  @override
  void initState() {
    super.initState();
    if (!_isGoogleUser) _loadUsername();
  }

  Future<void> _loadUsername() async {
    final name = await _auth.getUsernameForUid(widget.user.uid);
    if (mounted) setState(() => _username = name);
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  void _commitRate() {
    final n = int.tryParse(_rateCtrl.text.replaceAll(RegExp(r'[^\d]'), ''));
    if (n != null && n > 0) widget.onRateChanged(n);
  }

  Future<void> _pickTime(bool isEntry) async {
    final current = isEntry ? widget.defaultEntry : widget.defaultExit;
    final parts = current.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final str = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    isEntry ? widget.onDefaultEntryChanged(str) : widget.onDefaultExitChanged(str);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pc;
    final displayName = _isGoogleUser
        ? (widget.user.displayName ?? 'Usuario')
        : (_username ?? widget.user.displayName ?? 'Usuario');
    final email = widget.user.email ?? '';

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ajustes', style: GoogleFonts.dmSans(fontSize: 27, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -0.9, height: 1.1)),
                        const SizedBox(height: 3),
                        Text('Hola, $displayName 👋', style: GoogleFonts.dmSans(fontSize: 13, color: c.textSec)),
                      ],
                    ),
                  ),

                  // Profile pill
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                            child: const Center(child: Text('🐤', style: TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.yellowText)),
                                Text(email, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.yellowText.withValues(alpha: 0.55))),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.yellowText, size: 18),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Pago section
                  _Section(title: 'Pago', c: c, children: [
                    _Row(icon: Icons.attach_money_rounded, label: 'Valor por hora', desc: 'Tarifa base de liquidación', c: c,
                      trailing: Row(children: [
                        SizedBox(
                          width: 88,
                          child: TextField(
                            controller: _rateCtrl,
                            onEditingComplete: _commitRate,
                            onTapOutside: (_) => _commitRate(),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.yellow),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                              filled: true, fillColor: c.input,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.yellow)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('COP/h', style: GoogleFonts.dmSans(fontSize: 11, color: c.textSec, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    _Row(icon: Icons.monetization_on_outlined, label: 'Moneda', desc: 'Formato de visualización', c: c, isLast: true,
                      trailing: _DropBtn(
                        value: _currency,
                        items: const ['COP', 'USD'],
                        onChanged: (v) => setState(() => _currency = v),
                        c: c,
                      ),
                    ),
                  ]),

                  // Horario section
                  _Section(title: 'Horario', c: c, children: [
                    _Row(icon: Icons.calendar_today_outlined, label: 'Inicio de semana', desc: 'Primer día visible al registrar', c: c,
                      trailing: _DropBtn(
                        value: _weekStart,
                        items: const ['lunes', 'domingo'],
                        labels: const ['Lunes', 'Domingo'],
                        onChanged: (v) => setState(() => _weekStart = v),
                        c: c,
                      ),
                    ),
                    _Row(icon: Icons.access_time_rounded, label: 'Hora de entrada', desc: 'Valor al activar un día', c: c,
                      trailing: _TimeBtn(value: widget.defaultEntry, onTap: () => _pickTime(true), c: c),
                    ),
                    _Row(icon: Icons.access_time_filled_rounded, label: 'Hora de salida', desc: 'Valor al activar un día', c: c, isLast: true,
                      trailing: _TimeBtn(value: widget.defaultExit, onTap: () => _pickTime(false), c: c),
                    ),
                  ]),

                  // Apariencia section
                  _Section(title: 'Apariencia', c: c, children: [
                    _Row(icon: widget.darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, label: 'Modo oscuro', desc: 'Cambiar tema de la aplicación', c: c,
                      trailing: PaylyToggle(value: widget.darkMode, onChanged: widget.onDarkModeChanged),
                    ),
                    _Row(icon: Icons.notifications_outlined, label: 'Recordatorios', desc: 'Notificación el viernes a las 6pm', c: c, isLast: true,
                      trailing: PaylyToggle(value: _reminders, onChanged: (v) => setState(() => _reminders = v)),
                    ),
                  ]),

                  // Datos section
                  _Section(title: 'Datos', c: c, children: [
                    _Row(icon: Icons.file_download_outlined, label: 'Exportar historial', desc: 'Descargar en CSV o PDF', c: c, isLast: true,
                      trailing: Row(children: [
                        _ExportBtn(label: 'CSV', c: c),
                        const SizedBox(width: 6),
                        _ExportBtn(label: 'PDF', c: c),
                      ]),
                    ),
                  ]),

                  // Logout
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showLogout = true),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: BorderSide(color: c.danger),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: c.danger,
                      ),
                      icon: Icon(Icons.logout_rounded, size: 17, color: c.danger),
                      label: Text('Cerrar sesión', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: c.danger)),
                    ),
                  ),

                  // Footer
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Column(children: [
                        Image.asset('assets/Payly_ICON.png', width: 32, height: 32, opacity: const AlwaysStoppedAnimation(0.2)),
                        const SizedBox(height: 6),
                        Text('Payly v1.1.0 · alpha', style: GoogleFonts.dmSans(fontSize: 11, color: c.textTer)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned.fill(
            child: PaylyConfirmSheet(
              visible: _showLogout,
              title: '¿Cerrar sesión?',
              body: 'Tu historial está guardado en la nube\ny seguirá disponible.',
              confirmLabel: 'Salir',
              confirmColor: c.danger,
              onConfirm: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('draft_days_${widget.user.uid}');
                await prefs.remove('draft_tip_${widget.user.uid}');
                await _auth.signOut();
                widget.onLogout();
              },
              onDismiss: () => setState(() => _showLogout = false),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.c, required this.children});
  final String title;
  final PaylyColors c;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSec, letterSpacing: 1)),
        const SizedBox(height: 9),
        Container(
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
          clipBehavior: Clip.hardEdge,
          child: Column(children: children),
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.desc, required this.c, required this.trailing, this.isLast = false});
  final IconData icon;
  final String label, desc;
  final PaylyColors c;
  final Widget trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: c.border))),
    child: Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: c.cardAlt, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: AppColors.yellow),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
              Text(desc, style: GoogleFonts.dmSans(fontSize: 11, color: c.textSec)),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _DropBtn extends StatelessWidget {
  const _DropBtn({required this.value, required this.items, this.labels, required this.onChanged, required this.c});
  final String value;
  final List<String> items;
  final List<String>? labels;
  final ValueChanged<String> onChanged;
  final PaylyColors c;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: c.input, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isDense: true,
        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: c.text),
        dropdownColor: c.card,
        items: items.asMap().entries.map((e) => DropdownMenuItem(value: e.value, child: Text(labels?[e.key] ?? e.value))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    ),
  );
}

class _TimeBtn extends StatelessWidget {
  const _TimeBtn({required this.value, required this.onTap, required this.c});
  final String value;
  final VoidCallback onTap;
  final PaylyColors c;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: c.input, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
      child: Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
    ),
  );
}

class _ExportBtn extends StatelessWidget {
  const _ExportBtn({required this.label, required this.c});
  final String label;
  final PaylyColors c;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {},
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.yellowLight, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.yellow)),
    ),
  );
}
