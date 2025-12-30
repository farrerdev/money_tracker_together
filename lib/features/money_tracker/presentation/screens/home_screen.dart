import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/jar.dart';
import '../providers/tracker_providers.dart';
import 'add_expense_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jarsAsync = ref.watch(jarsStreamProvider);
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Tracker'),
        actions: [
          // Show user status or logout button if needed
           userAsync.when(
            data: (user) => Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(user != null ? 'Online' : 'Offline', 
                  style: TextStyle(color: user != null ? Colors.green : Colors.grey)),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_,__) => const SizedBox.shrink(),
          )
        ],
      ),
      body: jarsAsync.when(
        data: (jars) {
          if (jars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có hũ chi tiêu nào.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddJarDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo hũ mới'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: jars.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final jar = jars[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.account_balance_wallet, color: Colors.green),
                  ),
                  title: Text(jar.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Tạo ngày: ${jar.createdAt.toLocal().toString().split(' ')[0]}'),
                  trailing: Text(
                    '${jar.balance.toStringAsFixed(0)} đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Lỗi: $e')),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_jar',
            onPressed: () => _showAddJarDialog(context, ref),
            label: const Text('Hũ'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.green.shade200,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'add_expense',
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
            },
            label: const Text('Chi tiêu'),
            icon: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  void _showAddJarDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo hũ mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên hũ (vd: Ăn uống)'),
            ),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(labelText: 'Số dư ban đầu'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text;
              final balance = double.tryParse(balanceController.text) ?? 0.0;
              
              if (name.isNotEmpty) {
                // Gọi Controller tạo jar
                await ref.read(createJarControllerProvider.notifier).createJar(name, balance);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }
}
