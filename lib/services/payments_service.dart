import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_record.dart';

class PaymentsService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('payments');

  Stream<List<PaymentRecord>> watchPayments(String uid) => _col(uid)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PaymentRecord.fromFirestore).toList());

  Future<void> addPayment(String uid, PaymentRecord p) =>
      _col(uid).doc(p.id).set(p.toFirestore());

  Future<void> updatePayment(String uid, PaymentRecord p) =>
      _col(uid).doc(p.id).update(p.toFirestore());

  Future<void> deletePayment(String uid, String paymentId) =>
      _col(uid).doc(paymentId).delete();
}
