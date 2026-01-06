import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../domain/entities/expense_transaction.dart';
import '../../domain/entities/jar.dart';
import '../providers/tracker_providers.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseTransaction? transaction;

  const AddExpenseScreen({super.key, this.transaction});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final _amountFocusNode = FocusNode();

  String? _selectedJarId;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      // Chế độ Sửa: điền thông tin cũ
      final t = widget.transaction!;
      _amountController.text = CurrencyHelper.format(t.amount);
      _noteController.text = t.note;
      _selectedJarId = t.jarId;
      _selectedDate = t.date;
    } else {
      // Chế độ Thêm mới: chỉ cần request focus
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addState = ref.watch(addExpenseControllerProvider);
    final updateState = ref.watch(updateExpenseControllerProvider);
    final isLoading = addState.isLoading || updateState.isLoading;
    final hasError = addState.hasError || updateState.hasError;
    final error = addState.hasError ? addState.error : updateState.error;

    final jarsAsync = ref.watch(jarsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa chi tiêu' : 'Thêm chi tiêu'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text('Số tiền chi tiêu', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                            suffixText: 'đ',
                            suffixStyle: TextStyle(fontSize: 20, color: Colors.grey),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Nhập số tiền';
                            final amount = CurrencyHelper.parse(value);
                            if (amount <= 0) return 'Số tiền không hợp lệ';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Chi tiết giao dịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Chọn Hũ
                jarsAsync.when(
                  data: (jars) {
                    // MỚI: Logic tự động chọn hũ
                    if (!_isEditing && _selectedJarId == null && jars.isNotEmpty) {
                      String? jarToSelect;
                      final lastUsedJarId = ref.read(lastUsedJarIdProvider);

                      // 1. Ưu tiên hũ dùng gần nhất
                      if (lastUsedJarId != null && jars.any((j) => j.id == lastUsedJarId)) {
                        jarToSelect = lastUsedJarId;
                      } else {
                        // 2. Nếu không có, tìm hũ 'Ăn uống'
                        try {
                          jarToSelect = jars.firstWhere((j) => j.name.toLowerCase().contains('ăn uống')).id;
                        } catch (e) {
                          // 3. Nếu không có, chọn hũ đầu tiên
                          jarToSelect = jars.first.id;
                        }
                      }

                      // Cập nhật state an toàn sau khi build xong
                      Future.microtask(() {
                        if (mounted && _selectedJarId == null) {
                          setState(() {
                            _selectedJarId = jarToSelect;
                          });
                        }
                      });
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedJarId,
                      decoration: InputDecoration(
                        labelText: 'Chọn hũ chi tiêu',
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: jars.map((jar) {
                        return DropdownMenuItem(
                          value: jar.id,
                          child: Text(jar.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedJarId = value;
                        });
                      },
                      validator: (val) => val == null ? 'Vui lòng chọn hũ' : null,
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Lỗi tải danh sách hũ: $e'),
                ),

                const SizedBox(height: 16),

                // Nhập Nội dung
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Nội dung chi tiêu',
                    hintText: 'Ví dụ: Ăn trưa, Đổ xăng...',
                    prefixIcon: const Icon(Icons.edit_note),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),

                const SizedBox(height: 16),

                // Chọn Ngày
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Ngày chi tiêu',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Nút Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditing ? 'LƯU THAY ĐỔI' : 'LƯU CHI TIÊU',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        'Lỗi: $error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      final amount = CurrencyHelper.parse(_amountController.text);
      final note = _noteController.text.trim();

      bool success = false;

      if (_isEditing) {
        success = await ref.read(updateExpenseControllerProvider.notifier).updateExpense(
          transactionId: widget.transaction!.id,
          newJarId: _selectedJarId!,
          newAmount: amount,
          newDate: _selectedDate,
          newNote: note,
        );
      } else {
        ref.read(lastUsedJarIdProvider.notifier).state = _selectedJarId;
        success = await ref.read(addExpenseControllerProvider.notifier).addExpense(
          jarId: _selectedJarId!,
          amount: amount,
          date: _selectedDate,
          note: note,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Đã cập nhật chi tiêu!' : 'Đã thêm chi tiêu thành công!')),
        );
        Navigator.pop(context);
      }
    }
  }
}
