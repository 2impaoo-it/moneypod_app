import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moneypod/bloc/bill_scan/bill_scan_bloc.dart';
import 'package:moneypod/bloc/bill_scan/bill_scan_state.dart';
import 'package:moneypod/screens/bill_scan_screen.dart';
import 'package:moneypod/repositories/bill_scan_repository.dart';

class MockBillScanRepository extends Mock implements BillScanRepository {}

void main() {
  group('BillScanScreen', () {
    late MockBillScanRepository mockRepository;

    setUp(() {
      mockRepository = MockBillScanRepository();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider(
          create: (_) => BillScanBloc(repository: mockRepository),
          child: const BillScanScreen(),
        ),
      );
    }

    testWidgets('renders BillScanScreen widget', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(BillScanScreen), findsOneWidget);
    });

    testWidgets('shows initial scan UI elements', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays Scaffold with correct background', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    test('BillScanBloc is created with repository', () {
      final bloc = BillScanBloc(repository: mockRepository);
      expect(bloc, isNotNull);
      expect(bloc.state, isA<BillScanState>());
    });

    test('BillScanInitial is initial state', () {
      final bloc = BillScanBloc(repository: mockRepository);
      expect(bloc.state, isA<BillScanInitial>());
    });
  });
}
