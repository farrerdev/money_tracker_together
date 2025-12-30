import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/tracker_repository_impl.dart';
import '../../domain/entities/jar.dart';
import '../../domain/repositories/tracker_repository.dart';

// 1. Core Services Providers
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);
final authProvider = Provider((ref) => FirebaseAuth.instance);

// 2. Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authProvider).authStateChanges();
});

// 3. Repository Provider (Dependency Injection)
final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(authProvider);
  return TrackerRepositoryImpl(firestore, auth);
});

// 4. Data Streams (Dữ liệu realtime)
final jarsStreamProvider = StreamProvider<List<Jar>>((ref) {
  final userAsync = ref.watch(authStateProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      final repository = ref.watch(trackerRepositoryProvider);
      return repository.watchJars();
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// 5. Controller: Add Expense Logic (AsyncNotifier)
class AddExpenseController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is data(null) aka idle
  }

  Future<bool> addExpense({
    required String jarId,
    required double amount,
    required DateTime date,
  }) async {
    state = const AsyncLoading(); // Set UI loading
    try {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.addExpense(jarId: jarId, amount: amount, date: date);
      
      state = const AsyncData(null); // Success
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack); // Error
      return false;
    }
  }
}

final addExpenseControllerProvider =
    AsyncNotifierProvider.autoDispose<AddExpenseController, void>(AddExpenseController.new);

// Controller for Creating Jars (Optional for Phase 1 but useful)
class CreateJarController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createJar(String name, double initialBalance) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.createJar(name, initialBalance);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final createJarControllerProvider = 
    AsyncNotifierProvider.autoDispose<CreateJarController, void>(CreateJarController.new);
