import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/expense_transaction.dart';
import '../providers/tracker_providers.dart';
import 'add_expense_screen.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  final String? jarId;
  final String? jarName;

  const TransactionHistoryScreen({super.key, this.jarId, this.jarName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);

    final transactionsAsync = jarId != null
        ? ref.watch(jarTransactionsInMonthProvider(jarId!))
        : ref.watch(transactionsInMonthProvider);

    final jarsAsync = ref.watch(jarsStreamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: Text(jarId != null ? 'Hũ: $jarName' : 'Lịch sử chi tiêu'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            "Tháng ${selectedMonth.month}/${selectedMonth.year}",
            style: TextStyle(color: Colors.white70),
          ),
        ),
        elevation: 0,
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Không có giao dịch nào trong tháng này',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final jarsMap =
              jarsAsync.valueOrNull?.fold<Map<String, String>>(
                {},
                (map, jar) => map..[jar.id] = jar.name,
              ) ??
              {};

          return ListView.separated(
            itemCount: transactions.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final displayJarName =
                  jarName ?? jarsMap[transaction.jarId] ?? 'Hũ đã xóa';

              return InkWell(
                onLongPress: () =>
                    _showTransactionOptions(context, ref, transaction),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.red,
                    ),
                  ),
                  title: Row(
                    children: [
                      if (jarId == null)
                        Text(
                          displayJarName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                      if (transaction.note.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: jarId == null ? 8.0 : 0,
                            ),
                            child: Text(
                              transaction.note,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                      else if (jarId != null)
                        Expanded(
                          child: const Text(
                            "Chi tiêu không có ghi chú",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '-${CurrencyHelper.formatWithSymbol(transaction.amount)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  void _showTransactionOptions(
    BuildContext context,
    WidgetRef ref,
    ExpenseTransaction transaction,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                transaction.note.isNotEmpty ? transaction.note : "Chi tiêu",
              ),
              subtitle: Text(
                '-${CurrencyHelper.formatWithSymbol(transaction.amount)}',
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Chỉnh sửa chi tiêu'),
              onTap: () {
                Navigator.pop(ctx); // Đóng menu
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(transaction: transaction),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa chi tiêu'),
              subtitle: const Text('Hoàn tiền lại vào hũ'),
              onTap: () {
                Navigator.pop(ctx); // Đóng menu
                _confirmDeleteTransaction(context, ref, transaction.id);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTransaction(
    BuildContext context,
    WidgetRef ref,
    String transactionId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa giao dịch này?\n'
          'Số tiền sẽ được hoàn lại vào hũ tương ứng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext); // Đóng dialog

              final success = await ref
                  .read(deleteTransactionControllerProvider.notifier)
                  .deleteTransaction(transactionId);

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa giao dịch & hoàn tiền'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Xóa thất bại! Vui lòng thử lại.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
