import '../entities/jar.dart';
import '../entities/expense_transaction.dart';
import '../entities/jar_budget.dart';

abstract class TrackerRepository {
  Stream<List<Jar>> watchJars();
  
  Stream<List<ExpenseTransaction>> watchTransactions();
  Stream<List<ExpenseTransaction>> watchTransactionsByJar(String jarId);
  Stream<List<ExpenseTransaction>> watchTransactionsInPeriod(DateTime start, DateTime end);
  Stream<List<ExpenseTransaction>> watchTransactionsByJarInPeriod(String jarId, DateTime start, DateTime end);
  
  Stream<List<JarBudget>> watchJarBudgets(int month, int year);
  
  Future<void> setJarBudget({
    required String jarId,
    required double amount,
    required int month,
    required int year,
  });

  // SỬA: Thay đổi hàm tạo hũ để nhận ngân sách tháng đầu tiên
  Future<void> createJar({
    required String name,
    required double initialBudget,
    required int month,
    required int year,
  });
  
  Future<void> updateJar(String jarId, String name);
  
  Future<void> deleteJar(String jarId);
  
  Future<void> addExpense({
    required String jarId,
    required double amount,
    required DateTime date,
    String? note,
  });

  Future<void> updateExpense({
    required String transactionId,
    required String newJarId,
    required double newAmount,
    required DateTime newDate,
    String? newNote,
  });

  Future<void> deleteTransaction(String transactionId);
}
