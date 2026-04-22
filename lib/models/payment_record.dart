import 'package:cloud_firestore/cloud_firestore.dart';

class DayEntry {
  final String entry;
  final String exit;

  const DayEntry({required this.entry, required this.exit});

  Map<String, dynamic> toMap() => {'entry': entry, 'exit': exit};

  factory DayEntry.fromMap(Map<String, dynamic> m) =>
      DayEntry(entry: m['entry'] as String, exit: m['exit'] as String);
}

class PaymentRecord {
  final String id;
  final DateTime date;
  final Map<int, DayEntry> days;
  final double totalHours;
  final int rate;
  final int basePay;
  final int tip;
  final bool hasTip;
  final int totalPay;

  const PaymentRecord({
    required this.id,
    required this.date,
    required this.days,
    required this.totalHours,
    required this.rate,
    required this.basePay,
    required this.tip,
    required this.hasTip,
    required this.totalPay,
  });

  PaymentRecord copyWith({
    String? id,
    DateTime? date,
    Map<int, DayEntry>? days,
    double? totalHours,
    int? rate,
    int? basePay,
    int? tip,
    bool? hasTip,
    int? totalPay,
  }) => PaymentRecord(
    id: id ?? this.id,
    date: date ?? this.date,
    days: days ?? this.days,
    totalHours: totalHours ?? this.totalHours,
    rate: rate ?? this.rate,
    basePay: basePay ?? this.basePay,
    tip: tip ?? this.tip,
    hasTip: hasTip ?? this.hasTip,
    totalPay: totalPay ?? this.totalPay,
  );

  Map<String, dynamic> toFirestore() => {
    'date': Timestamp.fromDate(date),
    'days': days.map((k, v) => MapEntry(k.toString(), v.toMap())),
    'totalHours': totalHours,
    'rate': rate,
    'basePay': basePay,
    'tip': tip,
    'hasTip': hasTip,
    'totalPay': totalPay,
  };

  factory PaymentRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawDays = (d['days'] as Map<String, dynamic>?) ?? {};
    final days = rawDays.map(
      (k, v) => MapEntry(int.parse(k), DayEntry.fromMap(v as Map<String, dynamic>)),
    );
    return PaymentRecord(
      id: doc.id,
      date: (d['date'] as Timestamp).toDate(),
      days: days,
      totalHours: (d['totalHours'] as num).toDouble(),
      rate: (d['rate'] as num).toInt(),
      basePay: (d['basePay'] as num).toInt(),
      tip: (d['tip'] as num?)?.toInt() ?? 0,
      hasTip: d['hasTip'] as bool? ?? false,
      totalPay: (d['totalPay'] as num).toInt(),
    );
  }
}

// ── Time helpers ──────────────────────────────────────────────────────────────

int timeToMinutes(String t) {
  if (t.isEmpty) return 0;
  final parts = t.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

double dayHours(String entry, String exit) {
  final diff = timeToMinutes(exit) - timeToMinutes(entry);
  return diff > 0 ? diff / 60.0 : 0.0;
}

String fmtHrs(double h) {
  final hh = h.floor();
  final mm = ((h - hh) * 60).round();
  return mm == 0 ? '${hh}h' : '${hh}h ${mm}m';
}

const List<String> kDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
const List<String> kDaysShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
