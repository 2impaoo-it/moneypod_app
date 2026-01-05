import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/create_wallet/create_wallet_bloc.dart';
import 'package:moneypod/bloc/create_wallet/create_wallet_event.dart';
import 'package:moneypod/bloc/create_wallet/create_wallet_state.dart';
import 'package:moneypod/repositories/wallet_repository.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockWalletRepository mockRepository;

  setUp(() {
    mockRepository = MockWalletRepository();
  });

  group('CreateWalletBloc', () {
    blocTest<CreateWalletBloc, CreateWalletState>(
      'emits state with new name when WalletNameChanged is added',
      build: () => CreateWalletBloc(walletRepository: mockRepository),
      act: (bloc) => bloc.add(const WalletNameChanged('New Wallet')),
      expect: () => [
        const CreateWalletState(
          name: 'New Wallet',
          status: CreateWalletStatus.initial,
        ),
      ],
    );

    blocTest<CreateWalletBloc, CreateWalletState>(
      'emits state with new balance when WalletBalanceChanged is added',
      build: () => CreateWalletBloc(walletRepository: mockRepository),
      act: (bloc) => bloc.add(const WalletBalanceChanged(1000)),
      expect: () => [
        const CreateWalletState(
          balance: 1000,
          status: CreateWalletStatus.initial,
        ),
      ],
    );

    blocTest<CreateWalletBloc, CreateWalletState>(
      'emits [loading, success] when CreateWalletSubmitted succeeds',
      build: () {
        when(
          () => mockRepository.createWallet(name: 'New Wallet', balance: 0),
        ).thenAnswer((_) async {});
        return CreateWalletBloc(walletRepository: mockRepository);
      },
      act: (bloc) {
        bloc.add(const WalletNameChanged('New Wallet'));
        bloc.add(const CreateWalletSubmitted());
      },
      skip: 1, // Skip the initial name change state
      expect: () => [
        const CreateWalletState(
          name: 'New Wallet',
          status: CreateWalletStatus.loading,
        ),
        const CreateWalletState(
          name: 'New Wallet',
          status: CreateWalletStatus.success,
        ),
      ],
    );

    blocTest<CreateWalletBloc, CreateWalletState>(
      'emits [loading, failure] when CreateWalletSubmitted fails',
      build: () {
        when(
          () => mockRepository.createWallet(name: 'New Wallet', balance: 0),
        ).thenThrow(Exception('Error'));
        return CreateWalletBloc(walletRepository: mockRepository);
      },
      act: (bloc) {
        bloc.add(const WalletNameChanged('New Wallet'));
        bloc.add(const CreateWalletSubmitted());
      },
      skip: 1,
      expect: () => [
        const CreateWalletState(
          name: 'New Wallet',
          status: CreateWalletStatus.loading,
        ),
        const CreateWalletState(
          name: 'New Wallet',
          status: CreateWalletStatus.failure,
          errorMessage: 'Error',
        ),
      ],
    );

    blocTest<CreateWalletBloc, CreateWalletState>(
      'emits initial state when ResetCreateWallet is added',
      build: () => CreateWalletBloc(walletRepository: mockRepository),
      seed: () => const CreateWalletState(name: 'Dirty', balance: 100),
      act: (bloc) => bloc.add(const ResetCreateWallet()),
      expect: () => [const CreateWalletState()],
    );
  });
}
