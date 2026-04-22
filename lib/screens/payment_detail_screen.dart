import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment_record.dart';
import '../services/payments_service.dart';
import '../theme/app_theme.dart';
import '../widgets/payly_badge.dart';

class PaymentDetailScreen extends StatefulWidget {
  const PaymentDetailScreen({
    super.key,
    required this.payment,
    required this.uid,
    required this.onUpdated,
    required this.onDeleted,
  });

  final PaymentRecord payment;
  final String uid;
  final ValueChanged<PaymentRecord> onUpdated;
  final VoidCallback onDeleted;

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final _svc = PaymentsService();
  late final _tipCtrl = TextEditingController(text: widget.payment.tip > 0 ? widget.payment.tip.toString() : '');
  bool _saved = false;
  bool _confirmDel = false;

  @override
  void dispose() {
    _tipCtrl.dispose();
    super.dispose();
  }

  int get _tipVal => int.tryParse(_tipCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  int get _newTotal => widget.payment.basePay + _tipVal;

  String _fmtCOP(int n) => NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(n);

  String _weekLabel() {
    final d = widget.payment.date;
    final dow = d.weekday; // 1=Mon
    final mon = d.subtract(Duration(days: dow - 1));
    final sun = mon.add(const Duration(days: 6));
    String f(DateTime dt) => DateFormat('d MMM', 'es_CO').format(dt);
    return '${f(mon)} – ${f(sun)}';
  }

  String _daysAgo() {
    final diff = DateTime.now().difference(widget.payment.date).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return 'Hace $diff días';
  }

  Future<void> _update() async {
    final updated = widget.payment.copyWith(tip: _tipVal, hasTip: _tipVal > 0, totalPay: _newTotal);
    await _svc.updatePayment(widget.uid, updated);
    widget.onUpdated(updated);
    if (!mounted) return;
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _saved = false); });
  }

  Future<void> _delete() async {
    await _svc.deletePayment(widget.uid, widget.payment.id);
    widget.onDeleted();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pc;
    final p = widget.payment;

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
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        _IconBtn(icon: Icons.chevron_left_rounded, onTap: () => Navigator.pop(context), c: c),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Detalle del pago', style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -0.5)),
                              Text('${_weekLabel()} · ${_daysAgo()}', style: GoogleFonts.dmSans(fontSize: 12, color: c.textSec)),
                            ],
                          ),
                        ),
                        _IconBtn(
                          icon: Icons.delete_outline_rounded,
                          onTap: () => setState(() => _confirmDel = true),
                          c: c,
                          color: c.danger,
                        ),
                      ],
                    ),
                  ),

                  // Total hero
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(22)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total recibido', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.yellowText.withValues(alpha: 0.5), letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(_fmtCOP(p.totalPay), style: GoogleFonts.dmSans(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.yellowText, letterSpacing: -1.2, height: 1.15)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _HeroPill('${fmtHrs(p.totalHours)} trabajadas'),
                              _HeroPill('${p.days.length} días'),
                              PaylyBadge(label: p.hasTip ? '✓ Propina recibida' : 'Sin propina', variant: p.hasTip ? BadgeVariant.green : BadgeVariant.amber),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Days breakdown
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DÍAS LABORADOS', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSec, letterSpacing: 1)),
                        const SizedBox(height: 10),
                        _Card(c: c, children: [
                          ...p.days.entries.toList().asMap().entries.map((e) {
                            final idx = e.key;
                            final dayIdx = e.value.key;
                            final d = e.value.value;
                            final h = dayHours(d.entry, d.exit);
                            final isLast = idx == p.days.length - 1;
                            return _DayRow(dayName: kDays[dayIdx], entry: d.entry, exit_: d.exit, hours: h, pay: (h * p.rate).round(), isLast: isLast, c: c);
                          }),
                        ]),
                      ],
                    ),
                  ),

                  // Payment summary
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RESUMEN DE PAGO', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSec, letterSpacing: 1)),
                        const SizedBox(height: 10),
                        _Card(c: c, children: [
                          _SummaryRow(label: 'Horas (${fmtHrs(p.totalHours)} × ${_fmtCOP(p.rate)}/h)', value: _fmtCOP(p.basePay), highlight: false, c: c),
                          _SummaryRow(label: 'Propina restaurante', value: _fmtCOP(p.tip), highlight: p.tip > 0, c: c),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(color: c.yellowLight, border: Border(top: BorderSide(color: c.border))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                                Text(_fmtCOP(p.totalPay), style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.yellow)),
                              ],
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  // Edit tip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EDITAR PROPINA', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: c.textSec, letterSpacing: 1)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
                          child: Row(
                            children: [
                              const Text('🍽️', style: TextStyle(fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Propina del restaurante', style: GoogleFonts.dmSans(fontSize: 11, color: c.textSec)),
                                    const SizedBox(height: 3),
                                    TextField(
                                      controller: _tipCtrl,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: c.text),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        hintStyle: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: c.textTer),
                                        isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text('COP', style: GoogleFonts.dmSans(fontSize: 12, color: c.textSec, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        if (_tipVal != p.tip) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            decoration: BoxDecoration(color: c.yellowLight, borderRadius: BorderRadius.circular(12)),
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(text: 'Nuevo total: ', style: GoogleFonts.dmSans(fontSize: 13, color: c.text)),
                                TextSpan(text: _fmtCOP(_newTotal), style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w800, color: c.text)),
                              ]),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _update,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.yellowText, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            child: Text(_saved ? '✓ Actualizado' : 'Guardar cambios', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Delete confirmation bottom sheet
          if (_confirmDel)
            GestureDetector(
              onTap: () => setState(() => _confirmDel = false),
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
          if (_confirmDel)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 44),
                  decoration: BoxDecoration(color: c.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(26))),
                  child: Column(
                    children: [
                      Text('¿Eliminar registro?', style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w800, color: c.text)),
                      const SizedBox(height: 8),
                      Text('Esta acción no se puede deshacer.', style: GoogleFonts.dmSans(fontSize: 14, color: c.textSec)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _confirmDel = false),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: c.cardAlt, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: Text('Cancelar', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _delete,
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: c.danger, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: Text('Eliminar', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, required this.c, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final PaylyColors c;
  final Color? color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
      child: Icon(icon, color: color ?? c.text, size: 20),
    ),
  );
}

class _HeroPill extends StatelessWidget {
  const _HeroPill(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
    child: Text(label, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.yellowText)),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.c, required this.children});
  final PaylyColors c;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
    clipBehavior: Clip.hardEdge,
    child: Column(children: children),
  );
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.dayName, required this.entry, required this.exit_, required this.hours, required this.pay, required this.isLast, required this.c});
  final String dayName, entry, exit_;
  final double hours;
  final int pay;
  final bool isLast;
  final PaylyColors c;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: c.border))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dayName, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
          Text('$entry → $exit_', style: GoogleFonts.dmSans(fontSize: 12, color: c.textSec)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmtHrs(hours), style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.yellow)),
          Text(NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(pay), style: GoogleFonts.dmSans(fontSize: 11, color: c.textSec)),
        ]),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, required this.highlight, required this.c});
  final String label, value;
  final bool highlight;
  final PaylyColors c;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: c.textSec)),
        Text(value, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: highlight ? AppColors.yellow : c.text)),
      ],
    ),
  );
}
