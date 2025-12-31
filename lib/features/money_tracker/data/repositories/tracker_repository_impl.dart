import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/jar.dart';
import '../../domain/entities/expense_transaction.dart';
import '../../domain/entities/jar_budget.dart';
import '../../domain/repositories/tracker_repository.dart';

class TrackerRepositoryImpl implements TrackerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth; 

  TrackerRepositoryImpl(this._firestore, this._auth);

  String get _userId => "shared_family_wallet";
  DocumentReference get _userDoc => _firestore.collection('users').doc(_userId);

  @override
  Stream<List<Jar>> watchJars() {
    try {
      return _userDoc.collection('jars')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Jar.fromFirestore(doc)).toList());
    } catch (e) {
      return const Stream.empty();
    }
  }

  @override
  Stream<List<ExpenseTransaction>> watchTransactions() {
    try {
      return _userDoc.collection('transactions')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => ExpenseTransaction.fromFirestore(doc)).toList());
    } catch (e) {
      return const Stream.empty();
    }
  }

  @override
  Stream<List<ExpenseTransaction>> watchTransactionsByJar(String jarId) {
    try {
      return _userDoc.collection('transactions')
          .where('jarId', isEqualTo: jarId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => ExpenseTransaction.fromFirestore(doc)).toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          });
    } catch (e) {
      return const Stream.empty();
    }
  }

  @override
  Stream<List<ExpenseTransaction>> watchTransactionsInPeriod(DateTime start, DateTime end) {
    try {
      return _userDoc.collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs.map((doc) => ExpenseTransaction.fromFirestore(doc)).toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          });
    } catch (e) {
      return const Stream.empty();
    }
  }

  @override
  Stream<List<ExpenseTransaction>> watchTransactionsByJarInPeriod(String jarId, DateTime start, DateTime end) {
    try {
      return _userDoc.collection('transactions')
          .where('jarId', isEqualTo: jarId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) => ExpenseTransaction.fromFirestore(doc))
                .where((t) => t.date.isAfter(start.subtract(const Duration(microseconds: 1))) && t.date.isBefore(end))
                .toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          });
    } catch (e) {
      return const Stream.empty();
    }
  }

  @override
  Stream<List<JarBudget>> watchJarBudgets(int month, int year) {
    try {
      return _userDoc.collection('budgets')
          .where('year', isEqualTo: year)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => JarBudget.fromFirestore(doc))
                .where((budget) => budget.month == month)
                .toList();
          });
    } catch (e) {
      return const Stream.empty();
    }
  }

  @override
  Future<void> setJarBudget({
    required String jarId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final budgetId = '${jarId}_${month}_$year';
    final budgetRef = _userDoc.collection('budgets').doc(budgetId);

    await budgetRef.set({
      'jarId': jarId,
      'amount': amount,
      'month': month,
      'year': year,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> createJar(String name, double initialBalance) async {
    await _userDoc.collection('jars').add({
      'name': name,
      'balance': initialBalance, 
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateJar(String jarId, String name) async {
    await _userDoc.collection('jars').doc(jarId).update({
      'name': name,
    });
  }

  @override
  Future<void> deleteJar(String jarId) async {
    final transactionsQuery = await _userDoc.collection('transactions')
        .where('jarId', isEqualTo: jarId)
        .get();
        
    final budgetsQuery = await _userDoc.collection('budgets')
        .where('jarId', isEqualTo: jarId)
        .get();

    final batch = _firestore.batch();

    for (var doc in transactionsQuery.docs) {
      batch.delete(doc.reference);
    }

    for (var doc in budgetsQuery.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_userDoc.collection('jars').doc(jarId));

    await batch.commit();
  }

  @override
  Future<void> addExpense({
    required String jarId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final jarRef = _userDoc.collection('jars').doc(jarId);
    final transactionRef = _userDoc.collection('transactions').doc();

    await _firestore.runTransaction((transaction) async {
      final jarSnapshot = await transaction.get(jarRef);

      if (!jarSnapshot.exists) {
        throw Exception("Hũ chi tiêu không tồn tại!");
      }

      final currentBalance = (jarSnapshot.data() as Map<String, dynamic>)['balance'] ?? 0.0;
      final newBalance = currentBalance - amount;

      transaction.set(transactionRef, {
        'jarId': jarId,
        'amount': amount,
        'note': note ?? '',
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(jarRef, {'balance': newBalance});
    });
  }

  // --- LOGIC MỚI: CẬP NHẬT CHI TIÊU ---
  @override
  Future<void> updateExpense({
    required String transactionId,
    required String newJarId,
    required double newAmount,
    required DateTime newDate,
    String? newNote,
  }) async {
    final transactionRef = _userDoc.collection('transactions').doc(transactionId);

    await _firestore.runTransaction((transaction) async {
      // 1. Lấy thông tin giao dịch cũ
      final oldTransactionSnapshot = await transaction.get(transactionRef);
      if (!oldTransactionSnapshot.exists) {
        throw Exception("Giao dịch không tồn tại để cập nhật!");
      }

      final oldData = oldTransactionSnapshot.data() as Map<String, dynamic>;
      final oldJarId = oldData['jarId'] as String;
      final oldAmount = (oldData['amount'] ?? 0).toDouble();

      // 2. Hoàn tiền cho hũ cũ
      final oldJarRef = _userDoc.collection('jars').doc(oldJarId);
      transaction.update(oldJarRef, {'balance': FieldValue.increment(oldAmount)});

      // 3. Trừ tiền ở hũ mới
      final newJarRef = _userDoc.collection('jars').doc(newJarId);
      transaction.update(newJarRef, {'balance': FieldValue.increment(-newAmount)});

      // 4. Cập nhật lại thông tin giao dịch
      transaction.update(transactionRef, {
        'jarId': newJarId,
        'amount': newAmount,
        'note': newNote ?? '',
        'date': Timestamp.fromDate(newDate),
      });
    });
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final transactionRef = _userDoc.collection('transactions').doc(transactionId);

    await _firestore.runTransaction((transaction) async {
      final transactionSnapshot = await transaction.get(transactionRef);
      if (!transactionSnapshot.exists) {
        throw Exception("Giao dịch không tồn tại!");
      }

      final data = transactionSnapshot.data() as Map<String, dynamic>;
      final jarId = data['jarId'] as String;
      final amount = (data['amount'] ?? 0).toDouble();

      final jarRef = _userDoc.collection('jars').doc(jarId);
      final jarSnapshot = await transaction.get(jarRef);

      if (jarSnapshot.exists) {
        transaction.update(jarRef, {'balance': FieldValue.increment(amount)});
      }

      transaction.delete(transactionRef);
    });
  }
}
