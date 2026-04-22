import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/payment_record.dart';
import '../services/payments_service.dart';
import '../theme/app_theme.dart';
import '../widgets/payly_badge.dart';
import 'payment_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.uid});
  final String uid;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Stream<List<PaymentRecord>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = PaymentsService().watchPayments(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pc;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: StreamBuilder<List<PaymentRecord>>(
          stream: _stream,
          builder: (context, snap) {
            if (snap.hasError) {
              return _ErrorState(c: c, error: snap.error.toString());
            }
            final payments = snap.data ?? [];
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Historial', style: GoogleFonts.dmSans(fontSize: 27, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -0.9, height: 1.1)),
                              const SizedBox(height: 3),
                              Text('${payments.length} registro${payments.length != 1 ? 's' : ''} guardados', style: GoogleFonts.dmSans(fontSize: 13, color: c.textSec)),
                            ],
                          ),
                        ),
                        Image.asset('assets/Payly_ICON.png', width: 38, height: 38, opacity: const AlwaysStoppedAnimation(0.7)),
                      ],
                    ),
                  ),
                ),
                if (snap.connectionState == ConnectionState.waiting && payments.isEmpty)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.yellow)))
                else if (payments.isEmpty)
                  SliverFillRemaining(child: _EmptyState(c: c))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList.separated(
                      itemCount: payments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _PaymentCard(payment: payments[i], uid: widget.uid, c: c),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, required this.uid, required this.c});
  final PaymentRecord payment;
  final String uid;
  final PaylyColors c;

  String _weekLabel() {
    final d = payment.date;
    final mon = d.subtract(Duration(days: d.weekday - 1));
    final sun = mon.add(const Duration(days: 6));
    String f(DateTime dt) => DateFormat('d MMM', 'es_CO').format(dt);
    return '${f(mon)} – ${f(sun)}';
  }

  String _fmtCOP(int n) => NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(n);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PaymentDetailScreen(
          payment: payment, uid: uid,
          onUpdated: (_) {},
          onDeleted: () {},
        ),
      )),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_weekLabel(), style: GoogleFonts.dmSans(fontSize: 11, color: c.textSec, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Text(_fmtCOP(payment.totalPay), style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -0.8, height: 1)),
                    ],
                  ),
                ),
                PaylyBadge(label: payment.hasTip ? 'Propina recibida' : 'Sin propina', variant: payment.hasTip ? BadgeVariant.green : BadgeVariant.amber),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: c.border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Stat(label: 'Días', value: payment.days.length.toString(), c: c),
                _Stat(label: 'Horas', value: fmtHrs(payment.totalHours), c: c),
                _Stat(label: 'Base', value: _fmtCOP(payment.basePay), c: c, accent: true),
                Icon(Icons.chevron_right_rounded, color: c.textTer, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.c, this.accent = false});
  final String label, value;
  final PaylyColors c;
  final bool accent;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: c.textTer, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: accent ? AppColors.yellow : c.text)),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.c});
  final PaylyColors c;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset('assets/Payly_AppIcon.png', width: 70, height: 70, fit: BoxFit.cover),
          ),
          const SizedBox(height: 14),
          Text('Sin registros aún', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: c.textSec)),
          const SizedBox(height: 6),
          Text('Genera tu primer pago semanal en la pestaña Generar', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 13, color: c.textTer, height: 1.5)),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.c, required this.error});
  final PaylyColors c;
  final String error;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: c.textTer),
          const SizedBox(height: 14),
          Text('Error al cargar', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: c.textSec)),
          const SizedBox(height: 6),
          Text('No se pudo conectar con Firebase. Verifica tu conexión.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 13, color: c.textTer, height: 1.5)),
        ],
      ),
    ),
  );
}
