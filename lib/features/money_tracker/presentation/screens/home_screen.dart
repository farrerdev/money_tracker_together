import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/jar.dart';
import '../../domain/entities/jar_budget.dart';
import '../providers/tracker_providers.dart';
import '../widgets/add_jar_dialog.dart';
import 'add_expense_screen.dart';
import 'transaction_history_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Tracker'),
        centerTitle: false,
        actions: [
           userAsync.when(
            data: (user) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                avatar: Icon(Icons.circle, size: 12, color: user != null ? Colors.green : Colors.grey),
                label: Text(user != null ? 'Online' : 'Offline'),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_,__) => const SizedBox.shrink(),
          )
        ],
      ),
      
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),              
          TransactionHistoryScreen(), 
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Ngân sách',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final jarsAsync = ref.read(jarsStreamProvider);
          jarsAsync.whenData((jars) {
             if (jars.isNotEmpty) {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
             } else {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Vui lòng tạo hũ chi tiêu trước!')),
               );
             }
          });
        },
        label: const Text('Thêm chi tiêu'),
        icon: const Icon(Icons.playlist_add),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jarsAsync = ref.watch(jarsStreamProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final transactionsInMonthAsync = ref.watch(transactionsInMonthProvider);
    final budgetsInMonthAsync = ref.watch(budgetsInMonthProvider);

    if (jarsAsync.isLoading || transactionsInMonthAsync.isLoading || budgetsInMonthAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final jars = jarsAsync.valueOrNull ?? [];
    if (jars.isEmpty) {
      return _buildEmptyState(context);
    }

    final transactions = transactionsInMonthAsync.valueOrNull ?? [];
    final budgets = budgetsInMonthAsync.valueOrNull ?? [];

    final budgetMap = {for (var b in budgets) b.jarId: b.amount};
    
    final expenseMap = <String, double>{};
    for (var t in transactions) {
      expenseMap[t.jarId] = (expenseMap[t.jarId] ?? 0) + t.amount;
    }

    double totalBudget = 0;
    double totalExpense = 0;
    
    for (var jar in jars) {
      totalBudget += budgetMap[jar.id] ?? 0;
      totalExpense += expenseMap[jar.id] ?? 0;
    }
    double totalRemaining = totalBudget - totalExpense;
    bool isNegative = totalRemaining < 0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final newMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                    ref.read(selectedMonthProvider.notifier).state = newMonth;
                  },
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) {
                      ref.read(selectedMonthProvider.notifier).state = DateTime(picked.year, picked.month);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          "Tháng ${selectedMonth.month}/${selectedMonth.year}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final newMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                    ref.read(selectedMonthProvider.notifier).state = newMonth;
                  },
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isNegative 
                    ? [Colors.red.shade700, Colors.red.shade500]
                    : [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: (isNegative ? Colors.red : Colors.blue).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng ngân sách', style: TextStyle(color: Colors.white70)),
                    Text(CurrencyHelper.format(totalBudget), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Đã chi', style: TextStyle(color: Colors.white70)),
                    Text(CurrencyHelper.format(totalExpense), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Còn lại', style: TextStyle(color: Colors.white70)),
                    Text(
                      CurrencyHelper.formatWithSymbol(totalRemaining),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)]
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ngân sách các hũ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton.icon(
                  onPressed: () => showDialog(context: context, builder: (_) => const AddJarDialog()),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Hũ mới'),
                )
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final jar = jars[index];
                final budget = budgetMap[jar.id] ?? 0.0;
                final expense = expenseMap[jar.id] ?? 0.0;
                final remaining = budget - expense;
                final percent = budget > 0 ? (expense / budget).clamp(0.0, 1.0) : 0.0;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionHistoryScreen(
                            jarId: jar.id, 
                            jarName: jar.name,
                            // MỚI: Truyền filter theo tháng (Optional, nhưng TransactionHistoryScreen sẽ dùng Provider tháng toàn cục nên không cần truyền explicit)
                          )
                        ),
                      );
                    },
                    onLongPress: () => _showJarOptions(context, ref, jar, selectedMonth, budget),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.green.shade50,
                                child: Icon(Icons.account_balance_wallet, color: Colors.green.shade700, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(jar.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              if (budget == 0)
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 12),
                                  label: const Text('Đặt vốn'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: () => _showSetBudgetDialog(context, ref, jar, selectedMonth, budget),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Còn lại', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text(
                                      CurrencyHelper.formatWithSymbol(remaining),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        color: remaining >= 0 ? Colors.green : Colors.red
                                      ),
                                    ),
                                  ],
                                )
                            ],
                          ),
                          if (budget > 0) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.grey.shade200,
                              color: remaining < 0 ? Colors.red : (percent > 0.8 ? Colors.orange : Colors.green),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${CurrencyHelper.format(expense)} / ${CurrencyHelper.format(budget)}', 
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('${(percent * 100).toStringAsFixed(0)}%', 
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: jars.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Chưa có hũ nào.'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => showDialog(context: context, builder: (_) => const AddJarDialog()),
            icon: const Icon(Icons.add),
            label: const Text('Tạo hũ ngay'),
          ),
        ],
      ),
    );
  }

  void _showJarOptions(BuildContext context, WidgetRef ref, Jar jar, DateTime month, double currentBudget) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(jar.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.orange),
              title: const Text('Đổi tên hũ'),
              onTap: () {
                Navigator.pop(ctx); 
                _showRenameJarDialog(context, ref, jar);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Đặt/Sửa ngân sách tháng này'),
              onTap: () {
                Navigator.pop(ctx); 
                _showSetBudgetDialog(context, ref, jar, month, currentBudget);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa hũ chi tiêu'),
              subtitle: const Text('Xóa vĩnh viễn hũ này khỏi hệ thống'),
              onTap: () {
                Navigator.pop(ctx); 
                _confirmDeleteJar(context, ref, jar.id, jar.name);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRenameJarDialog(BuildContext parentContext, WidgetRef ref, Jar jar) {
    final controller = TextEditingController(text: jar.name);
    
    showDialog(
      context: parentContext,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(updateJarControllerProvider);
          
          return AlertDialog(
            title: const Text('Đổi tên hũ'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tên mới',
                border: OutlineInputBorder(),
              ),
              enabled: !state.isLoading,
            ),
            actions: [
              TextButton(
                onPressed: state.isLoading ? null : () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: state.isLoading ? null : () async {
                  final newName = controller.text.trim();
                  if (newName.isEmpty) return;
                  
                  final success = await ref.read(updateJarControllerProvider.notifier)
                      .updateJar(jar.id, newName);
                  
                  if (success && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: state.isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Lưu'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext parentContext, WidgetRef ref, Jar jar, DateTime month, double currentBudget) {
    final initialText = currentBudget > 0 ? CurrencyHelper.format(currentBudget) : '';
    final controller = TextEditingController(text: initialText);
    
    showDialog(
      context: parentContext,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(setBudgetControllerProvider);
          
          return AlertDialog(
            title: Text('Vốn tháng ${month.month}/${month.year}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hũ: ${jar.name}'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Số tiền cấp vốn',
                    suffixText: 'đ',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !state.isLoading, 
                ),
                if (state.hasError)
                   Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(state.error.toString(), style: const TextStyle(color: Colors.red, fontSize: 12)),
                   )
              ],
            ),
            actions: [
              TextButton(
                onPressed: state.isLoading ? null : () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: state.isLoading ? null : () async {
                  final amount = CurrencyHelper.parse(controller.text);
                  
                  final success = await ref.read(setBudgetControllerProvider.notifier).setBudget(
                    jarId: jar.id, 
                    amount: amount, 
                    month: month.month, 
                    year: month.year
                  );
                  
                  if (success && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: state.isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Lưu'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _confirmDeleteJar(BuildContext parentContext, WidgetRef ref, String jarId, String jarName) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa hũ chi tiêu?'),
        content: Text('Bạn có chắc chắn muốn xóa hũ "$jarName"? Mọi dữ liệu chi tiêu liên quan đến hũ này cũng sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext); 
              
              final success = await ref.read(deleteJarControllerProvider.notifier).deleteJar(jarId);
              
              if (parentContext.mounted) {
                if (success) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('Đã xóa hũ $jarName')),
                  );
                } else {
                   ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(content: Text('Xóa thất bại! Vui lòng thử lại.')),
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
