import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyHelper {
  // Format hiển thị: 1000000 -> 1.000.000
  static String format(double value) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0);
    return formatter.format(value).trim();
  }

  // Format hiển thị có đ: 1000000 -> 1.000.000 đ
  static String formatWithSymbol(double value) {
    return '${format(value)} đ';
  }

  // Chuyển chuỗi nhập liệu về double: "1.000.000" -> 1000000.0
  static double parse(String value) {
    // Xóa tất cả ký tự không phải số và dấu trừ (nếu có)
    String cleanValue = value.replaceAll(RegExp(r'[^0-9-]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }
}

// Formatter cho TextField: Tự động thêm dấu chấm phân cách hàng nghìn
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = '.';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Nếu rỗng thì trả về rỗng
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Chỉ cho phép nhập số
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Nếu chuỗi rỗng sau khi lọc (ví dụ user nhập chữ)
    if (newText.isEmpty) return oldValue;

    // Parse sang int để format
    int value = int.tryParse(newText) ?? 0;
    
    // Format lại: 1000 -> 1.000
    final formatter = NumberFormat('#,###', 'vi_VN');
    String newString = formatter.format(value);
    
    // Thay thế ký tự phân cách mặc định của locale (nếu cần) sang dấu chấm
    // vi_VN mặc định dùng dấu chấm cho ngàn, nên ok.

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
