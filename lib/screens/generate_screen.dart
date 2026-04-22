import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_record.dart';
import '../services/payments_service.dart';
import '../theme/app_theme.dart';
import '../widgets/day_row.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({
    super.key,
    required this.uid,
    required this.rate,
    required this.defaultEntry,
    required this.defaultExit,
  });

  final String uid;
  final int rate;
  final String defaultEntry;
  final String defaultExit;

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final _svc = PaymentsService();
  final Map<int, DayEntry> _days = {};
  final _tipCtrl = TextEditingController();
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    _tipCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('draft_days_${widget.uid}');
    final tip = prefs.getString('draft_tip_${widget.uid}') ?? '';
    if (json != null) {
      final raw = jsonDecode(json) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _days.addAll(raw.map((k, v) => MapEntry(int.parse(k), DayEntry.fromMap(v as Map<String, dynamic>))));
          _tipCtrl.text = tip;
        });
      }
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_days.map((k, v) => MapEntry(k.toString(), v.toMap())));
    await prefs.setString('draft_days_${widget.uid}', json);
    await prefs.setString('draft_tip_${widget.uid}', _tipCtrl.text);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_days_${widget.uid}');
    await prefs.remove('draft_tip_${widget.uid}');
  }

  double get _totalHours => _days.values.fold(0, (s, d) => s + dayHours(d.entry, d.exit));
  int get _basePay => (_totalHours * widget.rate).round();
  int get _tipVal => int.tryParse(_tipCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  int get _totalPay => _basePay + _tipVal;
  int get _workedCount => _days.length;

  String _fmtCOP(int n) => NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(n);

  Future<void> _save() async {
    if (_workedCount == 0 || _saving) return;
    setState(() => _saving = true);
    final p = PaymentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      days: Map.from(_days),
      totalHours: _totalHours,
      rate: widget.rate,
      basePay: _basePay,
      tip: _tipVal,
      hasTip: _tipVal > 0,
      totalPay: _totalPay,
    );
    await _svc.addPayment(widget.uid, p);
    if (!mounted) return;
    setState(() { _saving = false; _saved = true; _days.clear(); _tipCtrl.clear(); });
    _clearDraft();
    Future.delayed(const Duration(milliseconds: 2800), () { if (mounted) setState(() => _saved = false); });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pc;
    final active = _workedCount > 0;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Generar Pago', style: GoogleFonts.dmSans(fontSize: 27, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -0.9, height: 1.1)),
                          const SizedBox(height: 3),
                          Text('Registra tus horas de esta semana', style: GoogleFonts.dmSans(fontSize: 13, color: c.textSec)),
                        ],
                      ),
                    ),
                    Image.asset('assets/Payly_ICON.png', width: 38, height: 38, opacity: const AlwaysStoppedAnimation(0.85)),
                  ],
                ),
              ),

              // Live summary pill
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: active ? AppColors.yellow : c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: active ? null : Border.all(color: c.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                                child: Text(
                                  active ? '$_workedCount día${_workedCount > 1 ? 's' : ''} · ${fmtHrs(_totalHours)}' : 'Sin días registrados',
                                  key: ValueKey(active),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4,
                                    color: active ? AppColors.yellowText.withValues(alpha: 0.55) : c.textSec,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                active ? _fmtCOP(_totalPay) : '—',
                                style: GoogleFonts.dmSans(
                                  fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.2,
                                  color: active ? AppColors.yellowText : c.textTer,
                                ),
                              ),
                              if (active)
                                Text(
                                  'Base: ${_fmtCOP(_basePay)}${_tipVal > 0 ? ' + propina: ${_fmtCOP(_tipVal)}' : ''}',
                                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.yellowText.withValues(alpha: 0.5)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeInOut,
                        child: active
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  '${_fmtCOP(widget.rate)}/h',
                                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.yellowText.withValues(alpha: 0.5)),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              // Days
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DÍAS LABORADOS', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSec, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    ...List.generate(7, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: DayRow(
                        label: kDaysShort[i],
                        data: _days[i],
                        onChanged: (v) {
                            setState(() { v == null ? _days.remove(i) : _days[i] = v; });
                            _saveDraft();
                          },
                        defaultEntry: widget.defaultEntry,
                        defaultExit: widget.defaultExit,
                      ),
                    )),
                  ],
                ),
              ),

              // Propina
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: 'PAGOS ADICIONALES ', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSec, letterSpacing: 1)),
                        TextSpan(text: '(opcional)', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400, color: c.textSec)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    _ExtraField(emoji: '🍽️', label: 'Propina del restaurante', controller: _tipCtrl, c: c, onChanged: (_) { setState(() {}); _saveDraft(); }),
                  ],
                ),
              ),

              // Save button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: active && !_saving ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: active ? AppColors.yellow : c.cardAlt,
                      foregroundColor: active ? AppColors.yellowText : c.textTer,
                      disabledBackgroundColor: c.cardAlt,
                      disabledForegroundColor: c.textTer,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellowText))
                        : Text(
                            _saved ? '✓ Guardado exitosamente' : 'Guardar registro de pago',
                            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w800),
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

class _ExtraField extends StatelessWidget {
  const _ExtraField({required this.emoji, required this.label, required this.controller, required this.c, required this.onChanged});

  final String emoji;
  final String label;
  final TextEditingController controller;
  final PaylyColors c;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: c.textSec)),
                const SizedBox(height: 3),
                TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: c.text),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: c.textTer),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          Text('COP', style: GoogleFonts.dmSans(fontSize: 12, color: c.textSec, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
