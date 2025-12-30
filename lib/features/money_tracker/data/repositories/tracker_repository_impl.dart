import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/jar.dart';
import '../../domain/repositories/tracker_repository.dart';

class TrackerRepositoryImpl implements TrackerRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TrackerRepositoryImpl(this._firestore, this._auth);

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  // Helper to access the specific user document
  DocumentReference get _userDoc => _firestore.collection('users').doc(_userId);

  @override
  Stream<List<Jar>> watchJars() {
    try {
       // Check if user is logged in before listening
      if (_auth.currentUser == null) return const Stream.empty();

      return _userDoc.collection('jars')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => Jar.fromFirestore(doc)).toList());
    } catch (e) {
      // Return empty list on error for now, or handle appropriately
      return const Stream.empty();
    }
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
  Future<void> addExpense({
    required String jarId,
    required double amount,
    required DateTime date,
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

      // Create transaction record
      transaction.set(transactionRef, {
        'jarId': jarId,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update jar balance
      transaction.update(jarRef, {'balance': newBalance});
    });
  }
}
