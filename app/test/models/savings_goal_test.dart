import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/savings_goal.dart';

void main() {
  group('SavingsGoal Model Test', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 's1',
        'user_id': 'u1',
        'name': 'Trip',
        'target_amount': 1000000,
        'current_amount': 500000,
        'status': 'IN_PROGRESS',
        'is_overdue': false,
        'created_at': '2023-01-01T00:00:00Z',
      };

      final goal = SavingsGoal.fromJson(json);

      expect(goal.id, 's1');
      expect(goal.userId, 'u1');
      expect(goal.targetAmount, 1000000.0);
      expect(goal.currentAmount, 500000.0);
      expect(goal.createdAt.year, 2023);
    });

    test('progressPercentage calculates correctly', () {
      final goal = SavingsGoal(
        id: '1',
        userId: 'u1',
        name: 'Test',
        targetAmount: 1000,
        currentAmount: 250,
        status: 'IN_PROGRESS',
        isOverdue: false,
        createdAt: DateTime.now(),
      );

      expect(goal.progressPercentage, 25.0);
    });

    test('remainingAmount calculates correctly', () {
      final goal = SavingsGoal(
        id: '1',
        userId: 'u1',
        name: 'Test',
        targetAmount: 1000,
        currentAmount: 250,
        status: 'IN_PROGRESS',
        isOverdue: false,
        createdAt: DateTime.now(),
      );

      expect(goal.remainingAmount, 750.0);
    });

    test('toJson formats date for server correctly', () {
      final date = DateTime(2026, 6, 28);
      final goal = SavingsGoal(
        id: '1',
        userId: 'u1',
        name: 'Test',
        targetAmount: 100,
        currentAmount: 0,
        status: 'IN_PROGRESS',
        isOverdue: false,
        createdAt: DateTime.now(),
        deadline: date,
      );

      final json = goal.toJson();
      expect(json['deadline'], '2026-06-28T00:00:00.000Z');
    });
  });

  group('SavingsTransaction Model Test', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 't1',
        'goal_id': 'g1',
        'wallet_id': 'w1',
        'amount': 50000,
        'type': 'DEPOSIT',
        'created_at': '2023-10-27T10:00:00Z',
      };

      final tx = SavingsTransaction.fromJson(json);

      expect(tx.id, 't1');
      expect(tx.amount, 50000.0);
      expect(tx.type, 'DEPOSIT');
    });
  });
}
