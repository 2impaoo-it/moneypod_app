import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/create_wallet/create_wallet_bloc.dart';
import 'package:moneypod/bloc/create_wallet/create_wallet_event.dart';
import 'package:moneypod/bloc/create_wallet/create_wallet_state.dart';
import 'package:moneypod/models/wallet.dart';
import '../../mocks/repositories.dart';

void main() {
  late MockWalletRepository mockWalletRepository;

  setUp(() {
    mockWalletRepository = MockWalletRepository();
  });

  group('CreateWalletBloc', () {
    test('initial state is correct', () {
      expect(
        CreateWalletBloc(walletRepository: mockWalletRepository).state,
        const CreateWalletState(),
      );
    });

    blocTest<CreateWalletBloc, CreateWalletState>(
      'emits updated name state when WalletNameChanged is added',
      build: () => CreateWalletBloc(walletRepository: mockWalletRepository),
      act: (bloc) => bloc.add(const WalletNameChanged('My Wallet')),
      expect: () => [const CreateWalletState(name: 'My Wallet')],
    );

    blocTest<CreateWalletBloc, CreateWalletState>(
      'emits updated balance state when WalletBalanceChanged is added',
      build: () => CreateWalletBloc(walletRepository: mockWalletRepository),
      act: (bloc) => bloc.add(const WalletBalanceChanged(100.0)),
      expect: () => [const CreateWalletState(balance: 100.0)],
    );

    blocTest<CreateWalletBloc, CreateWalletState>(
      'emits [loading, success] when CreateWalletSubmitted succeeds',
      build: () {
        when(
          () => mockWalletRepository.createWallet(
            name: any(named: 'name'),
            balance: any(named: 'balance'),
          ),
        ).thenAnswer(
          (_) async => Wallet(
            id: 'w1',
            name: 'My Wallet',
            balance: 100,
            currency: 'VND',
            userId: 'u1',
            createdAt: DateTime.now(),
          ),
        );
        return CreateWalletBloc(walletRepository: mockWalletRepository);
      },
      seed: () => const CreateWalletState(name: 'My Wallet', balance: 100),
      act: (bloc) => bloc.add(const CreateWalletSubmitted()),
      expect: () => [
        const CreateWalletState(
          name: 'My Wallet',
          balance: 100,
          status: CreateWalletStatus.loading,
        ),
        const CreateWalletState(
          name: 'My Wallet',
          balance: 100,
          status: CreateWalletStatus.success,
        ),
      ],
    );

    blocTest<CreateWalletBloc, CreateWalletState>(
      'emits [loading, failure] when CreateWalletSubmitted fails',
      build: () {
        when(
          () => mockWalletRepository.createWallet(
            name: any(named: 'name'),
            balance: any(named: 'balance'),
          ),
        ).thenThrow(Exception('Creation failed'));
        return CreateWalletBloc(walletRepository: mockWalletRepository);
      },
      seed: () => const CreateWalletState(name: 'My Wallet', balance: 100),
      act: (bloc) => bloc.add(const CreateWalletSubmitted()),
      expect: () => [
        const CreateWalletState(
          name: 'My Wallet',
          balance: 100,
          status: CreateWalletStatus.loading,
        ),
        const CreateWalletState(
          name: 'My Wallet',
          balance: 100,
          status: CreateWalletStatus.failure,
          errorMessage: 'Creation failed',
        ),
      ],
    );

    blocTest<CreateWalletBloc, CreateWalletState>(
      'resets state when ResetCreateWallet is added',
      build: () => CreateWalletBloc(walletRepository: mockWalletRepository),
      seed: () => const CreateWalletState(
        name: 'Dirty',
        status: CreateWalletStatus.failure,
      ),
      act: (bloc) => bloc.add(const ResetCreateWallet()),
      expect: () => [const CreateWalletState()],
    );
  });
}
