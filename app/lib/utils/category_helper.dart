import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CategoryHelper {
  static IconData getIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ăn uống':
      case 'food':
        return LucideIcons.utensils;
      case 'di chuyển':
      case 'transport':
        return LucideIcons.car;
      case 'mua sắm':
      case 'shopping':
        return LucideIcons.shoppingBag;
      case 'giải trí':
      case 'entertainment':
        return LucideIcons.gamepad2;
      case 'làm đẹp':
        return LucideIcons.sparkles;
      case 'sức khỏe':
      case 'health':
        return LucideIcons.heart;
      case 'từ thiện':
        return LucideIcons.heartHandshake;
      case 'hóa đơn':
      case 'bill':
        return LucideIcons.fileText;
      case 'nhà cửa':
        return LucideIcons.home;
      case 'người thân':
        return LucideIcons.users;
      case 'lương':
      case 'salary':
        return LucideIcons.wallet;
      case 'thưởng':
        return LucideIcons.award;
      case 'tiền lãi':
        return LucideIcons.trendingUp;
      case 'chợ, siêu thị':
        return LucideIcons.shoppingCart;
      case 'thu nợ':
        return LucideIcons.arrowDownCircle;
      case 'trả nợ':
        return LucideIcons.arrowUpCircle;
      default:
        return LucideIcons.moreHorizontal;
    }
  }

  static Color getColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ăn uống':
      case 'food':
        return const Color(0xFF0D9488); // Teal
      case 'di chuyển':
      case 'transport':
        return const Color(0xFF2563EB); // Blue
      case 'mua sắm':
      case 'shopping':
      case 'chợ, siêu thị':
        return const Color(0xFFDB2777); // Pink
      case 'giải trí':
      case 'entertainment':
        return const Color(0xFF9333EA); // Purple
      case 'làm đẹp':
        return Colors.pinkAccent;
      case 'sức khỏe':
      case 'health':
        return const Color(0xFFDC2626); // Red
      case 'từ thiện':
        return Colors.teal;
      case 'hóa đơn':
      case 'bill':
        return const Color(0xFFEA580C); // Orange
      case 'nhà cửa':
        return Colors.brown;
      case 'người thân':
        return Colors.deepOrange;
      case 'lương':
      case 'salary':
        return const Color(0xFF16A34A); // Green
      case 'thưởng':
        return Colors.lightGreen;
      case 'tiền lãi':
        return Colors.lime;
      case 'thu nợ':
        return const Color(0xFF059669); // Emerald - income from debt collection
      case 'trả nợ':
        return const Color(0xFFDC2626); // Red - expense for debt payment
      default:
        return const Color(0xFF4B5563); // Gray
    }
  }

  static Color getBackgroundColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ăn uống':
      case 'food':
        return const Color(0xFFCCFBF1);
      case 'di chuyển':
      case 'transport':
        return const Color(0xFFDBEAFE);
      case 'mua sắm':
      case 'shopping':
      case 'chợ, siêu thị':
        return const Color(0xFFFCE7F3);
      case 'giải trí':
      case 'entertainment':
        return const Color(0xFFF3E8FF);
      case 'sức khỏe':
      case 'health':
        return const Color(0xFFFEE2E2);
      case 'hóa đơn':
      case 'bill':
        return const Color(0xFFFFEDD5);
      case 'lương':
      case 'salary':
        return const Color(0xFFDCFCE7);
      case 'thu nợ':
        return const Color(0xFFD1FAE5); // Emerald light
      case 'trả nợ':
        return const Color(0xFFFEE2E2); // Red light
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  static const List<String> expenseCategories = [
    'Chợ, siêu thị',
    'Ăn uống',
    'Di chuyển',
    'Mua sắm',
    'Giải trí',
    'Làm đẹp',
    'Sức khỏe',
    'Từ thiện',
    'Hóa đơn',
    'Nhà cửa',
    'Người thân',
    'Trả nợ',
  ];

  static const List<String> incomeCategories = [
    'Lương',
    'Thưởng',
    'Tiền lãi',
    'Thu nợ',
    'Khác',
  ];
}
