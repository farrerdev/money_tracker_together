import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/tracker_repository_impl.dart';
import '../../domain/entities/jar.dart';
import '../../domain/entities/expense_transaction.dart';
import '../../domain/entities/jar_budget.dart';
import '../../domain/repositories/tracker_repository.dart';

// 1. Core Services Providers
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);
final authProvider = Provider((ref) => FirebaseAuth.instance);

// 2. Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authProvider).authStateChanges();
});

// 3. Repository Provider
final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(authProvider);
  return TrackerRepositoryImpl(firestore, auth);
});

// 4. Data Streams
final jarsStreamProvider = StreamProvider<List<Jar>>((ref) {
  final repository = ref.watch(trackerRepositoryProvider);
  return repository.watchJars();
});

final transactionsStreamProvider = StreamProvider<List<ExpenseTransaction>>((ref) {
  final repository = ref.watch(trackerRepositoryProvider);
  return repository.watchTransactions();
});

final jarTransactionsProvider = StreamProvider.family<List<ExpenseTransaction>, String>((ref, jarId) {
  final repository = ref.watch(trackerRepositoryProvider);
  return repository.watchTransactionsByJar(jarId);
});

final lastUsedJarIdProvider = StateProvider<String?>((ref) => null);

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final transactionsInMonthProvider = StreamProvider<List<ExpenseTransaction>>((ref) {
  final repository = ref.watch(trackerRepositoryProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  
  final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

  return repository.watchTransactionsInPeriod(start, end);
});

final jarTransactionsInMonthProvider = StreamProvider.family<List<ExpenseTransaction>, String>((ref, jarId) {
  final repository = ref.watch(trackerRepositoryProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  
  final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
  final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 0, 23, 59, 59);

  return repository.watchTransactionsByJarInPeriod(jarId, start, end);
});

final budgetsInMonthProvider = StreamProvider<List<JarBudget>>((ref) {
  final repository = ref.watch(trackerRepositoryProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  return repository.watchJarBudgets(selectedMonth.month, selectedMonth.year);
});

// 5. Controllers
class AddExpenseController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> addExpense({
    required String jarId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    state = const AsyncLoading(); 
    try {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.addExpense(
        jarId: jarId, 
        amount: amount, 
        date: date,
        note: note,
      );
      state = const AsyncData(null); 
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final addExpenseControllerProvider =
    AsyncNotifierProvider.autoDispose<AddExpenseController, void>(AddExpenseController.new);

class CreateJarController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createJar({
    required String name, 
    required double initialBudget,
    required int month,
    required int year,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.createJar(
        name: name, 
        initialBudget: initialBudget,
        month: month,
        year: year,
      );
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

class UpdateJarController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateJar(String jarId, String name) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.updateJar(jarId, name);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final updateJarControllerProvider = 
    AsyncNotifierProvider.autoDispose<UpdateJarController, void>(UpdateJarController.new);

class DeleteJarController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> deleteJar(String jarId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.deleteJar(jarId);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final deleteJarControllerProvider = 
    AsyncNotifierProvider.autoDispose<DeleteJarController, void>(DeleteJarController.new);

class DeleteTransactionController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> deleteTransaction(String transactionId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.deleteTransaction(transactionId);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final deleteTransactionControllerProvider = 
    AsyncNotifierProvider.autoDispose<DeleteTransactionController, void>(DeleteTransactionController.new);

class SetBudgetController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> setBudget({
    required String jarId,
    required double amount,
    required int month,
    required int year,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.setJarBudget(
        jarId: jarId, 
        amount: amount, 
        month: month, 
        year: year
      );
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final setBudgetControllerProvider = 
    AsyncNotifierProvider.autoDispose<SetBudgetController, void>(SetBudgetController.new);

class UpdateExpenseController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateExpense({
    required String transactionId,
    required String newJarId,
    required double newAmount,
    required DateTime newDate,
    String? newNote,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.updateExpense(
        transactionId: transactionId,
        newJarId: newJarId,
        newAmount: newAmount,
        newDate: newDate,
        newNote: newNote,
      );
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final updateExpenseControllerProvider = 
    AsyncNotifierProvider.autoDispose<UpdateExpenseController, void>(UpdateExpenseController.new);

// MỚI: Controller để Copy Budget từ tháng trước
class CopyBudgetController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> copyBudget(int currentMonth, int currentYear) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(trackerRepositoryProvider);
      await repository.copyBudgetFromPreviousMonth(
        currentMonth: currentMonth, 
        currentYear: currentYear
      );
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final copyBudgetControllerProvider = 
    AsyncNotifierProvider.autoDispose<CopyBudgetController, void>(CopyBudgetController.new);
