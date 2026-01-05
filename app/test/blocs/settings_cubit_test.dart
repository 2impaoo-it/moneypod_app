import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:moneypod/bloc/settings/settings_cubit.dart';

void main() {
  group('SettingsCubit', () {
    test('initial state is true', () {
      expect(SettingsCubit().state, true);
    });

    blocTest<SettingsCubit, bool>(
      'emits [false] when toggleBalanceVisibility is called',
      build: () => SettingsCubit(),
      act: (cubit) => cubit.toggleBalanceVisibility(),
      expect: () => [false],
    );

    blocTest<SettingsCubit, bool>(
      'emits [false, true] when toggleBalanceVisibility is called twice',
      build: () => SettingsCubit(),
      act: (cubit) {
        cubit.toggleBalanceVisibility();
        cubit.toggleBalanceVisibility();
      },
      expect: () => [false, true],
    );
  });
}
