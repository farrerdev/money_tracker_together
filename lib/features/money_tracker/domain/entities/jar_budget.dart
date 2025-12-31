import 'package:cloud_firestore/cloud_firestore.dart';

class JarBudget {
  final String id; // format: jarId_month_year
  final String jarId;
  final double amount; // Số tiền cấp vốn (vd: 5tr)
  final int month;
  final int year;

  JarBudget({
    required this.id,
    required this.jarId,
    required this.amount,
    required this.month,
    required this.year,
  });

  factory JarBudget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JarBudget(
      id: doc.id,
      jarId: data['jarId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      month: data['month'] ?? 0,
      year: data['year'] ?? 0,
    );
  }
}
