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
    // Lắng nghe trạng thái của CreateJarController để hiện loading
    final state = ref.watch(createJarControllerProvider);

    return AlertDialog(
      title: const Text('Tạo hũ chi tiêu mới'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input Tên hũ
            TextFormField(
              controller: _nameController,
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
            
            // Input Số dư ban đầu
            TextFormField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Số dư ban đầu',
                hintText: '0',
                suffixText: 'đ',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                ThousandsSeparatorInputFormatter(), // Tự động thêm dấu chấm
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return null; // Cho phép rỗng (mặc định 0)
                // Parse thử xem có hợp lệ không
                // Vì input có dấu chấm, cần parse bằng CurrencyHelper
                return null; 
              },
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
      
      // Parse số tiền từ chuỗi có định dạng (1.000.000 -> 1000000.0)
      final balance = CurrencyHelper.parse(_balanceController.text);

      final success = await ref.read(createJarControllerProvider.notifier)
          .createJar(name, balance);

      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }
}
