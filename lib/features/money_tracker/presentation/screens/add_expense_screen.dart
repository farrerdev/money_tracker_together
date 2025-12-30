import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/jar.dart';
import '../providers/tracker_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedJarId;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe state để hiện loading hoặc báo lỗi
    final state = ref.watch(addExpenseControllerProvider);
    final jarsAsync = ref.watch(jarsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm chi tiêu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Chọn ngày
              ListTile(
                title: Text("Ngày: ${_selectedDate.toLocal().toString().split(' ')[0]}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              
              // 2. Nhập số tiền
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tiền'),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Vui lòng nhập số tiền hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Chọn Hũ (Load từ Riverpod)
              jarsAsync.when(
                data: (jars) {
                  if (jars.isEmpty) {
                    return const Text('Chưa có hũ nào. Hãy tạo hũ trước!');
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedJarId,
                    decoration: const InputDecoration(labelText: 'Chọn hũ chi tiêu'),
                    items: jars.map((jar) {
                      return DropdownMenuItem(
                        value: jar.id,
                        child: Text('${jar.name} (${jar.balance.toStringAsFixed(0)})'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedJarId = value),
                    validator: (val) => val == null ? 'Phải chọn hũ' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Lỗi tải hũ: $e'),
              ),

              const Spacer(),

              // 4. Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isLoading ? null : _submit,
                  child: state.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Lưu chi tiêu'),
                ),
              ),
              
              // Hiển thị lỗi nếu có
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    state.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(addExpenseControllerProvider.notifier).addExpense(
        jarId: _selectedJarId!,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
      );

      if (success && mounted) {
        Navigator.pop(context); // Đóng màn hình khi thành công
      }
    }
  }
}
