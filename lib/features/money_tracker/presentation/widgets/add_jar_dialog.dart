import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_helper.dart';
import '../providers/tracker_providers.dart';

class AddJarDialog extends ConsumerStatefulWidget {
  const AddJarDialog({super.key});

  @override
  ConsumerState<AddJarDialog> createState() => _AddJarDialogState();
}

class _AddJarDialogState extends ConsumerState<AddJarDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createJarControllerProvider);

    return AlertDialog(
      title: const Text('Tạo hũ chi tiêu mới'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true, // Tự động focus vào đây
              decoration: const InputDecoration(
                labelText: 'Tên hũ',
                hintText: 'Ví dụ: Ăn uống, Tiết kiệm',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tên hũ không được để trống';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Vốn tháng này', 
                hintText: '0',
                suffixText: 'đ',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                ThousandsSeparatorInputFormatter(),
              ],
            ),
            
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  state.error.toString(),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                ) 
              : const Text('Tạo hũ'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final balance = CurrencyHelper.parse(_balanceController.text);

      // Lấy tháng/năm đang chọn từ provider
      final selectedMonth = ref.read(selectedMonthProvider);

      final success = await ref.read(createJarControllerProvider.notifier).createJar(
        name: name, 
        initialBudget: balance,
        month: selectedMonth.month,
        year: selectedMonth.year,
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }
}
