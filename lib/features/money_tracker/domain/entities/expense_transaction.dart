import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseTransaction {
  final String id;
  final String jarId;
  final double amount;
  final DateTime date;
  final DateTime createdAt;

  ExpenseTransaction({
    required this.id,
    required this.jarId,
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  factory ExpenseTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseTransaction(
      id: doc.id,
      jarId: data['jarId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jarId': jarId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
