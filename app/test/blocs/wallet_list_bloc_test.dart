import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_bloc.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_event.dart';
import 'package:moneypod/bloc/wallet_list/wallet_list_state.dart';
import 'package:moneypod/repositories/wallet_repository.dart';
import 'package:moneypod/models/wallet.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockWalletRepository mockRepository;

  setUp(() {
    mockRepository = MockWalletRepository();
  });

  group('WalletListBloc', () {
    final mockWallet = Wallet(
      id: 'w1',
      name: 'Cash',
      balance: 1000,
      currency: 'VND',
      userId: 'u1',
      createdAt: DateTime.now(),
    );

    blocTest<WalletListBloc, WalletListState>(
      'emits [loading, success] when LoadWalletList is added',
      build: () {
        when(
          () => mockRepository.getWallets(),
        ).thenAnswer((_) async => [mockWallet]);
        return WalletListBloc(walletRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const LoadWalletList()),
      expect: () => [
        const WalletListState(status: WalletStatus.loading),
        WalletListState(status: WalletStatus.success, wallets: [mockWallet]),
      ],
    );
  });
}
