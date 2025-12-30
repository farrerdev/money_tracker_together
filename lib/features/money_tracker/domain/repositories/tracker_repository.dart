import '../entities/jar.dart';

abstract class TrackerRepository {
  Stream<List<Jar>> watchJars();
  
  Future<void> createJar(String name, double initialBalance);
  
  Future<void> addExpense({
    required String jarId,
    required double amount,
    required DateTime date,
  });
}
