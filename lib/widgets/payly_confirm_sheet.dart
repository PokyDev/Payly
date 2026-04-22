import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PaylyConfirmSheet extends StatefulWidget {
  const PaylyConfirmSheet({
    super.key,
    required this.visible,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
    required this.onDismiss,
  });

  final bool visible;
  final String title;
  final String body;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  State<PaylyConfirmSheet> createState() => _PaylyConfirmSheetState();
}

class _PaylyConfirmSheetState extends State<PaylyConfirmSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  bool _localVisible = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    if (widget.visible) {
      _localVisible = true;
      _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PaylyConfirmSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      setState(() => _localVisible = true);
      _ctrl.forward();
    } else if (!widget.visible && oldWidget.visible) {
      _ctrl.reverse().then((_) {
        if (mounted) setState(() => _localVisible = false);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_localVisible) return const SizedBox.shrink();

    final c = context.pc;

    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: _ctrl,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SlideTransition(
            position: _slide,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 46),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.title,
                      style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.body,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(fontSize: 14, color: c.textSec, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onDismiss,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: c.cardAlt,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text('Cancelar', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onConfirm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: widget.confirmColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(widget.confirmLabel, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
