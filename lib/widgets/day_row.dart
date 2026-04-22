import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_record.dart';
import '../theme/app_theme.dart';
import 'payly_toggle.dart';

class DayRow extends StatefulWidget {
  const DayRow({
    super.key,
    required this.label,
    required this.data,
    required this.onChanged,
    required this.defaultEntry,
    required this.defaultExit,
  });

  final String label;
  final DayEntry? data;
  final ValueChanged<DayEntry?> onChanged;
  final String defaultEntry;
  final String defaultExit;

  @override
  State<DayRow> createState() => _DayRowState();
}

class _DayRowState extends State<DayRow> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _size;
  late final Animation<double> _fade;

  // Kept to render content during collapse animation after data becomes null
  DayEntry? _lastData;

  bool get isOn => widget.data != null;
  double get hours => isOn ? dayHours(widget.data!.entry, widget.data!.exit) : 0;

  @override
  void initState() {
    super.initState();
    _lastData = widget.data;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: isOn ? 1.0 : 0.0,
    );
    _size = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void didUpdateWidget(DayRow old) {
    super.didUpdateWidget(old);
    if (widget.data != null) _lastData = widget.data;
    if (old.data == null && widget.data != null) {
      _ctrl.forward();
    } else if (old.data != null && widget.data == null) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.pc;
    final display = _lastData;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isOn ? c.card : Colors.transparent,
        border: Border.all(
          color: isOn ? AppColors.yellow : c.border,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Toggle row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                PaylyToggle(
                  value: isOn,
                  onChanged: (v) => widget.onChanged(
                    v ? DayEntry(entry: widget.defaultEntry, exit: widget.defaultExit) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isOn ? c.text : c.textSec,
                    ),
                  ),
                ),
                if (isOn && hours > 0)
                  Text(
                    fmtHrs(hours),
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.yellow),
                  )
                else if (!isOn)
                  Text(
                    'No laborado',
                    style: GoogleFonts.dmSans(fontSize: 12, color: c.textTer),
                  ),
              ],
            ),
          ),
          // Animated expandable time picker
          SizeTransition(
            sizeFactor: _size,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                decoration: BoxDecoration(
                  color: c.cardAlt,
                  border: Border(top: BorderSide(color: c.border)),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: display == null
                    ? const SizedBox.shrink()
                    : Row(
                        children: [
                          Expanded(
                            child: _TimePicker(
                              label: 'Entrada',
                              value: display.entry,
                              onChanged: (v) => widget.onChanged(DayEntry(entry: v, exit: display.exit)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Text('→', style: TextStyle(fontSize: 18, color: c.textTer, fontWeight: FontWeight.w300)),
                          ),
                          Expanded(
                            child: _TimePicker(
                              label: 'Salida',
                              value: display.exit,
                              onChanged: (v) => widget.onChanged(DayEntry(entry: display.entry, exit: v)),
                            ),
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

class _TimePicker extends StatelessWidget {
  const _TimePicker({required this.label, required this.value, required this.onChanged});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.pc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: c.textSec, letterSpacing: 0.8),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () async {
            final parts = value.split(':');
            final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
            final picked = await showTimePicker(context: context, initialTime: initial);
            if (picked != null) {
              onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border, width: 1.5),
            ),
            child: Text(
              value,
              style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: c.text),
            ),
          ),
        ),
      ],
    );
  }
}
