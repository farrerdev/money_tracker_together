import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseTransaction {
  final String id;
  final String jarId;
  final double amount;
  final String note; // Mới thêm: Nội dung chi tiêu
  final DateTime date;
  final DateTime createdAt;

  ExpenseTransaction({
    required this.id,
    required this.jarId,
    required this.amount,
    required this.note,
    required this.date,
    required this.createdAt,
  });

  factory ExpenseTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseTransaction(
      id: doc.id,
      jarId: data['jarId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      note: data['note'] ?? '', // Handle dữ liệu cũ không có note
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jarId': jarId,
      'amount': amount,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
