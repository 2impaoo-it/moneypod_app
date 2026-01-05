import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_bloc.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_event.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_state.dart';
import 'package:moneypod/repositories/wallet_repository.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockWalletRepository mockRepository;

  setUp(() {
    mockRepository = MockWalletRepository();
  });

  group('WalletListBloc Edge Cases', () {
    blocTest<WalletListBloc, WalletListState>(
      'emits failure status when load fails',
      build: () {
        when(
          () => mockRepository.getWallets(),
        ).thenThrow(Exception('Failed to load'));
        return WalletListBloc(walletRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const LoadWalletList()),
      expect: () => [
        const WalletListState(status: WalletStatus.loading),
        isA<WalletListState>()
            .having((s) => s.status, 'status', WalletStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('Failed to load'),
            ),
      ],
    );

    blocTest<WalletListBloc, WalletListState>(
      'emits failure status when delete fails',
      build: () {
        when(
          () => mockRepository.deleteWallet(any()),
        ).thenThrow(Exception('Failed to delete'));
        return WalletListBloc(walletRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const DeleteWalletRequested('w1')),
      expect: () => [
        const WalletListState(status: WalletStatus.loading),
        isA<WalletListState>()
            .having((s) => s.status, 'status', WalletStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('Failed to delete'),
            ),
      ],
    );

    blocTest<WalletListBloc, WalletListState>(
      'emits failure status when update fails',
      build: () {
        when(
          () => mockRepository.updateWallet(
            id: any(named: 'id'),
            name: any(named: 'name'),
            currency: any(named: 'currency'),
          ),
        ).thenThrow(Exception('Failed to update'));
        return WalletListBloc(walletRepository: mockRepository);
      },
      act: (bloc) =>
          bloc.add(const UpdateWalletRequested(id: 'w1', name: 'New Name')),
      expect: () => [
        const WalletListState(status: WalletStatus.loading),
        isA<WalletListState>()
            .having((s) => s.status, 'status', WalletStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('Failed to update'),
            ),
      ],
    );
  });
}
