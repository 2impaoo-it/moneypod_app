import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:moneypod/utils/category_helper.dart';

void main() {
  group('CategoryHelper', () {
    group('getIcon', () {
      test('returns correct icons for Vietnamese categories', () {
        expect(CategoryHelper.getIcon('ăn uống'), LucideIcons.utensils);
        expect(CategoryHelper.getIcon('di chuyển'), LucideIcons.car);
        expect(CategoryHelper.getIcon('mua sắm'), LucideIcons.shoppingBag);
        expect(CategoryHelper.getIcon('giải trí'), LucideIcons.gamepad2);
        expect(CategoryHelper.getIcon('làm đẹp'), LucideIcons.sparkles);
        expect(CategoryHelper.getIcon('sức khỏe'), LucideIcons.heart);
        expect(CategoryHelper.getIcon('từ thiện'), LucideIcons.heartHandshake);
        expect(CategoryHelper.getIcon('hóa đơn'), LucideIcons.fileText);
        expect(CategoryHelper.getIcon('nhà cửa'), LucideIcons.home);
        expect(CategoryHelper.getIcon('người thân'), LucideIcons.users);
        expect(CategoryHelper.getIcon('lương'), LucideIcons.wallet);
        expect(CategoryHelper.getIcon('thưởng'), LucideIcons.award);
        expect(CategoryHelper.getIcon('tiền lãi'), LucideIcons.trendingUp);
        expect(
          CategoryHelper.getIcon('chợ, siêu thị'),
          LucideIcons.shoppingCart,
        );
      });

      test('returns correct icons for English categories', () {
        expect(CategoryHelper.getIcon('food'), LucideIcons.utensils);
        expect(CategoryHelper.getIcon('transport'), LucideIcons.car);
        expect(CategoryHelper.getIcon('shopping'), LucideIcons.shoppingBag);
        expect(CategoryHelper.getIcon('entertainment'), LucideIcons.gamepad2);
        expect(CategoryHelper.getIcon('health'), LucideIcons.heart);
        expect(CategoryHelper.getIcon('bill'), LucideIcons.fileText);
        expect(CategoryHelper.getIcon('salary'), LucideIcons.wallet);
      });

      test('handles case insensitivity', () {
        expect(CategoryHelper.getIcon('ĂN UỐNG'), LucideIcons.utensils);
        expect(CategoryHelper.getIcon('FOOD'), LucideIcons.utensils);
        expect(CategoryHelper.getIcon('Mua Sắm'), LucideIcons.shoppingBag);
      });

      test('returns default icon for unknown categories', () {
        expect(CategoryHelper.getIcon('unknown'), LucideIcons.moreHorizontal);
        expect(CategoryHelper.getIcon(''), LucideIcons.moreHorizontal);
        expect(
          CategoryHelper.getIcon('random category'),
          LucideIcons.moreHorizontal,
        );
      });
    });

    group('getColor', () {
      test('returns correct colors for categories', () {
        expect(CategoryHelper.getColor('ăn uống'), const Color(0xFF0D9488));
        expect(CategoryHelper.getColor('di chuyển'), const Color(0xFF2563EB));
        expect(CategoryHelper.getColor('mua sắm'), const Color(0xFFDB2777));
        expect(CategoryHelper.getColor('giải trí'), const Color(0xFF9333EA));
        expect(CategoryHelper.getColor('sức khỏe'), const Color(0xFFDC2626));
        expect(CategoryHelper.getColor('hóa đơn'), const Color(0xFFEA580C));
        expect(CategoryHelper.getColor('lương'), const Color(0xFF16A34A));
      });

      test('returns same color for Vietnamese and English equivalents', () {
        expect(
          CategoryHelper.getColor('ăn uống'),
          CategoryHelper.getColor('food'),
        );
        expect(
          CategoryHelper.getColor('di chuyển'),
          CategoryHelper.getColor('transport'),
        );
        expect(
          CategoryHelper.getColor('sức khỏe'),
          CategoryHelper.getColor('health'),
        );
      });

      test('returns default gray for unknown categories', () {
        expect(CategoryHelper.getColor('unknown'), const Color(0xFF4B5563));
      });

      test('groups shopping variants together', () {
        expect(
          CategoryHelper.getColor('mua sắm'),
          CategoryHelper.getColor('shopping'),
        );
        expect(
          CategoryHelper.getColor('chợ, siêu thị'),
          CategoryHelper.getColor('shopping'),
        );
      });
    });

    group('getBackgroundColor', () {
      test('returns correct background colors for categories', () {
        expect(
          CategoryHelper.getBackgroundColor('ăn uống'),
          const Color(0xFFCCFBF1),
        );
        expect(
          CategoryHelper.getBackgroundColor('di chuyển'),
          const Color(0xFFDBEAFE),
        );
        expect(
          CategoryHelper.getBackgroundColor('mua sắm'),
          const Color(0xFFFCE7F3),
        );
        expect(
          CategoryHelper.getBackgroundColor('giải trí'),
          const Color(0xFFF3E8FF),
        );
        expect(
          CategoryHelper.getBackgroundColor('sức khỏe'),
          const Color(0xFFFEE2E2),
        );
        expect(
          CategoryHelper.getBackgroundColor('hóa đơn'),
          const Color(0xFFFFEDD5),
        );
        expect(
          CategoryHelper.getBackgroundColor('lương'),
          const Color(0xFFDCFCE7),
        );
      });

      test('returns default light gray for unknown categories', () {
        expect(
          CategoryHelper.getBackgroundColor('unknown'),
          const Color(0xFFF3F4F6),
        );
      });
    });

    group('category lists', () {
      test('expenseCategories contains expected items', () {
        expect(CategoryHelper.expenseCategories, contains('Ăn uống'));
        expect(CategoryHelper.expenseCategories, contains('Di chuyển'));
        expect(CategoryHelper.expenseCategories, contains('Mua sắm'));
        expect(CategoryHelper.expenseCategories, contains('Hóa đơn'));
        expect(CategoryHelper.expenseCategories, hasLength(11));
      });

      test('incomeCategories contains expected items', () {
        expect(CategoryHelper.incomeCategories, contains('Lương'));
        expect(CategoryHelper.incomeCategories, contains('Thưởng'));
        expect(CategoryHelper.incomeCategories, contains('Tiền lãi'));
        expect(CategoryHelper.incomeCategories, contains('Khác'));
        expect(CategoryHelper.incomeCategories, hasLength(4));
      });

      test('expense and income categories do not overlap', () {
        final expenseSet = CategoryHelper.expenseCategories.toSet();
        final incomeSet = CategoryHelper.incomeCategories.toSet();
        expect(expenseSet.intersection(incomeSet), isEmpty);
      });
    });
  });
}
