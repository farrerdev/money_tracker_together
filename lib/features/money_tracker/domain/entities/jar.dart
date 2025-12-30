import 'package:cloud_firestore/cloud_firestore.dart';

class Jar {
  final String id;
  final String name;
  final double balance;
  final DateTime createdAt;

  Jar({
    required this.id,
    required this.name,
    required this.balance,
    required this.createdAt,
  });

  factory Jar.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Jar(
      id: doc.id,
      name: data['name'] ?? '',
      balance: (data['balance'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
