import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    group('Slate palette', () {
      test('slate colors are defined', () {
        expect(AppColors.slate50, isA<Color>());
        expect(AppColors.slate100, isA<Color>());
        expect(AppColors.slate200, isA<Color>());
        expect(AppColors.slate300, isA<Color>());
        expect(AppColors.slate400, isA<Color>());
        expect(AppColors.slate500, isA<Color>());
        expect(AppColors.slate600, isA<Color>());
        expect(AppColors.slate700, isA<Color>());
        expect(AppColors.slate900, isA<Color>());
      });
    });

    group('Teal palette', () {
      test('teal colors are defined', () {
        expect(AppColors.teal50, isA<Color>());
        expect(AppColors.teal100, isA<Color>());
        expect(AppColors.teal400, isA<Color>());
        expect(AppColors.teal500, isA<Color>());
        expect(AppColors.teal600, isA<Color>());
        expect(AppColors.teal700, isA<Color>());
      });
    });

    group('Green palette', () {
      test('green colors are defined', () {
        expect(AppColors.green50, isA<Color>());
        expect(AppColors.green100, isA<Color>());
        expect(AppColors.green300, isA<Color>());
        expect(AppColors.green500, isA<Color>());
        expect(AppColors.green600, isA<Color>());
        expect(AppColors.green700, isA<Color>());
      });
    });

    group('Semantic colors', () {
      test('primary equals teal500', () {
        expect(AppColors.primary, equals(AppColors.teal500));
      });

      test('primaryDark equals teal700', () {
        expect(AppColors.primaryDark, equals(AppColors.teal700));
      });

      test('background equals slate50', () {
        expect(AppColors.background, equals(AppColors.slate50));
      });

      test('surface is white', () {
        expect(AppColors.surface, equals(Colors.white));
      });

      test('success equals green500', () {
        expect(AppColors.success, equals(AppColors.green500));
      });

      test('warning equals amber500', () {
        expect(AppColors.warning, equals(AppColors.amber500));
      });

      test('danger equals red500', () {
        expect(AppColors.danger, equals(AppColors.red500));
      });

      test('info equals teal400', () {
        expect(AppColors.info, equals(AppColors.teal400));
      });
    });

    group('Text colors', () {
      test('textPrimary equals slate900', () {
        expect(AppColors.textPrimary, equals(AppColors.slate900));
      });

      test('textSecondary equals slate500', () {
        expect(AppColors.textSecondary, equals(AppColors.slate500));
      });

      test('textMuted equals slate400', () {
        expect(AppColors.textMuted, equals(AppColors.slate400));
      });
    });
  });
}
