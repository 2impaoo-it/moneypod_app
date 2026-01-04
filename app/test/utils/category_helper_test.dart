import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:moneypod/utils/category_helper.dart';

void main() {
  group('CategoryHelper', () {
    group('getIcon', () {
      test('returns utensils icon for "Ăn uống"', () {
        expect(CategoryHelper.getIcon('Ăn uống'), LucideIcons.utensils);
      });

      test('returns utensils icon for "food" (English)', () {
        expect(CategoryHelper.getIcon('food'), LucideIcons.utensils);
      });

      test('returns car icon for "Di chuyển"', () {
        expect(CategoryHelper.getIcon('Di chuyển'), LucideIcons.car);
      });

      test('returns shoppingBag icon for "Mua sắm"', () {
        expect(CategoryHelper.getIcon('Mua sắm'), LucideIcons.shoppingBag);
      });

      test('returns gamepad2 icon for "Giải trí"', () {
        expect(CategoryHelper.getIcon('Giải trí'), LucideIcons.gamepad2);
      });

      test('returns heart icon for "Sức khỏe"', () {
        expect(CategoryHelper.getIcon('Sức khỏe'), LucideIcons.heart);
      });

      test('returns fileText icon for "Hóa đơn"', () {
        expect(CategoryHelper.getIcon('Hóa đơn'), LucideIcons.fileText);
      });

      test('returns wallet icon for "Lương"', () {
        expect(CategoryHelper.getIcon('Lương'), LucideIcons.wallet);
      });

      test('returns award icon for "Thưởng"', () {
        expect(CategoryHelper.getIcon('Thưởng'), LucideIcons.award);
      });

      test('returns moreHorizontal for unknown category', () {
        expect(CategoryHelper.getIcon('Unknown'), LucideIcons.moreHorizontal);
      });

      test('is case insensitive', () {
        expect(CategoryHelper.getIcon('ĂN UỐNG'), LucideIcons.utensils);
        expect(CategoryHelper.getIcon('ăn uống'), LucideIcons.utensils);
        expect(CategoryHelper.getIcon('Ăn Uống'), LucideIcons.utensils);
      });
    });

    group('getColor', () {
      test('returns teal for "Ăn uống"', () {
        expect(CategoryHelper.getColor('Ăn uống'), const Color(0xFF0D9488));
      });

      test('returns blue for "Di chuyển"', () {
        expect(CategoryHelper.getColor('Di chuyển'), const Color(0xFF2563EB));
      });

      test('returns pink for "Mua sắm"', () {
        expect(CategoryHelper.getColor('Mua sắm'), const Color(0xFFDB2777));
      });

      test('returns purple for "Giải trí"', () {
        expect(CategoryHelper.getColor('Giải trí'), const Color(0xFF9333EA));
      });

      test('returns red for "Sức khỏe"', () {
        expect(CategoryHelper.getColor('Sức khỏe'), const Color(0xFFDC2626));
      });

      test('returns orange for "Hóa đơn"', () {
        expect(CategoryHelper.getColor('Hóa đơn'), const Color(0xFFEA580C));
      });

      test('returns green for "Lương"', () {
        expect(CategoryHelper.getColor('Lương'), const Color(0xFF16A34A));
      });

      test('returns gray for unknown category', () {
        expect(CategoryHelper.getColor('Unknown'), const Color(0xFF4B5563));
      });

      test('is case insensitive', () {
        expect(CategoryHelper.getColor('ăn uống'), const Color(0xFF0D9488));
      });
    });

    group('getBackgroundColor', () {
      test('returns light teal for "Ăn uống"', () {
        expect(
          CategoryHelper.getBackgroundColor('Ăn uống'),
          const Color(0xFFCCFBF1),
        );
      });

      test('returns light blue for "Di chuyển"', () {
        expect(
          CategoryHelper.getBackgroundColor('Di chuyển'),
          const Color(0xFFDBEAFE),
        );
      });

      test('returns light pink for "Mua sắm"', () {
        expect(
          CategoryHelper.getBackgroundColor('Mua sắm'),
          const Color(0xFFFCE7F3),
        );
      });

      test('returns light purple for "Giải trí"', () {
        expect(
          CategoryHelper.getBackgroundColor('Giải trí'),
          const Color(0xFFF3E8FF),
        );
      });

      test('returns light red for "Sức khỏe"', () {
        expect(
          CategoryHelper.getBackgroundColor('Sức khỏe'),
          const Color(0xFFFEE2E2),
        );
      });

      test('returns light orange for "Hóa đơn"', () {
        expect(
          CategoryHelper.getBackgroundColor('Hóa đơn'),
          const Color(0xFFFFEDD5),
        );
      });

      test('returns light green for "Lương"', () {
        expect(
          CategoryHelper.getBackgroundColor('Lương'),
          const Color(0xFFDCFCE7),
        );
      });

      test('returns light gray for unknown category', () {
        expect(
          CategoryHelper.getBackgroundColor('Unknown'),
          const Color(0xFFF3F4F6),
        );
      });
    });

    group('Category Lists', () {
      test('expenseCategories contains 11 items', () {
        expect(CategoryHelper.expenseCategories.length, 11);
      });

      test('expenseCategories contains expected categories', () {
        expect(
          CategoryHelper.expenseCategories,
          containsAll([
            'Ăn uống',
            'Di chuyển',
            'Mua sắm',
            'Giải trí',
            'Hóa đơn',
            'Sức khỏe',
          ]),
        );
      });

      test('incomeCategories contains 4 items', () {
        expect(CategoryHelper.incomeCategories.length, 4);
      });

      test('incomeCategories contains expected categories', () {
        expect(
          CategoryHelper.incomeCategories,
          containsAll(['Lương', 'Thưởng', 'Tiền lãi', 'Khác']),
        );
      });
    });
  });
}
