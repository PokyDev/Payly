import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum BadgeVariant { green, amber }

class PaylyBadge extends StatelessWidget {
  const PaylyBadge({super.key, required this.label, required this.variant});

  final String label;
  final BadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.pc;
    final bg = variant == BadgeVariant.green ? c.badgeGreen : c.badgeAmber;
    final fg = variant == BadgeVariant.green ? c.badgeGreenText : c.badgeAmberText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: bg),
      child: Text(
        label,
        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.2),
      ),
    );
  }
}
