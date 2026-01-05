import 'package:flutter_test/flutter_test.dart';
import 'package:moneypod/models/savings_goal.dart';

void main() {
  group('SavingsGoal Model', () {
    final now = DateTime.now();
    final deadline = DateTime(2026, 12, 31);

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': '123',
          'user_id': 'user1',
          'name': 'Vacation Fund',
          'target_amount': 10000000.0,
          'current_amount': 5000000.0,
          'color': '#FF5733',
          'icon': '🌴',
          'status': 'IN_PROGRESS',
          'deadline': deadline.toIso8601String(),
          'is_overdue': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final goal = SavingsGoal.fromJson(json);

        expect(goal.id, '123');
        expect(goal.userId, 'user1');
        expect(goal.name, 'Vacation Fund');
        expect(goal.targetAmount, 10000000.0);
        expect(goal.currentAmount, 5000000.0);
        expect(goal.color, '#FF5733');
        expect(goal.icon, '🌴');
        expect(goal.status, 'IN_PROGRESS');
        expect(goal.isOverdue, false);
      });

      test('handles uppercase keys (Go backend format)', () {
        final json = {
          'ID': 456,
          'UserID': 'user789',
          'name': 'Goal',
          'target_amount': 1000,
          'current_amount': 500,
          'status': 'IN_PROGRESS',
          'is_overdue': false,
          'CreatedAt': now.toIso8601String(),
        };

        final goal = SavingsGoal.fromJson(json);

        expect(goal.id, '456');
        expect(goal.userId, 'user789');
      });

      test('parses amounts from different types', () {
        // int
        expect(
          SavingsGoal.fromJson({
            'id': '1',
            'user_id': 'u',
            'name': 'G',
            'status': 'IN_PROGRESS',
            'is_overdue': false,
            'target_amount': 1000,
            'current_amount': 500,
            'created_at': now.toIso8601String(),
          }).targetAmount,
          1000.0,
        );

        // String
        expect(
          SavingsGoal.fromJson({
            'id': '1',
            'user_id': 'u',
            'name': 'G',
            'status': 'IN_PROGRESS',
            'is_overdue': false,
            'target_amount': '2000.50',
            'current_amount': '1000.25',
            'created_at': now.toIso8601String(),
          }).targetAmount,
          2000.50,
        );
      });

      test('handles missing optional fields', () {
        final json = {
          'id': '1',
          'user_id': 'u1',
          'name': 'Goal',
          'target_amount': 1000,
          'current_amount': 500,
          'status': 'IN_PROGRESS',
          'is_overdue': false,
          'created_at': now.toIso8601String(),
        };

        final goal = SavingsGoal.fromJson(json);

        expect(goal.color, isNull);
        expect(goal.icon, isNull);
        expect(goal.deadline, isNull);
        expect(goal.updatedAt, isNull);
      });

      test('parses deadline with timezone', () {
        final json = {
          'id': '1',
          'user_id': 'u',
          'name': 'G',
          'status': 'IN_PROGRESS',
          'is_overdue': false,
          'target_amount': 1000,
          'current_amount': 0,
          'created_at': now.toIso8601String(),
          'deadline': '2026-07-15T00:00:00.000+07:00',
        };

        final goal = SavingsGoal.fromJson(json);
        expect(goal.deadline?.year, 2026);
        expect(goal.deadline?.month, 7);
        expect(goal.deadline?.day, 15);
      });

      test('strips time component from dates (date only)', () {
        final json = {
          'id': '1',
          'user_id': 'u',
          'name': 'G',
          'status': 'IN_PROGRESS',
          'is_overdue': false,
          'target_amount': 1000,
          'current_amount': 0,
          'created_at': '2026-01-05T14:30:45.123Z',
          'deadline': '2026-12-31T23:59:59Z',
        };

        final goal = SavingsGoal.fromJson(json);

        // Time should be stripped
        expect(goal.createdAt.hour, 0);
        expect(goal.createdAt.minute, 0);
        expect(goal.deadline?.hour, 0);
      });
    });

    group('toJson', () {
      test('serializes fields for server', () {
        final goal = SavingsGoal(
          id: '123',
          userId: 'user1',
          name: 'New Car',
          targetAmount: 50000000,
          currentAmount: 10000000,
          color: '#00FF00',
          icon: '🚗',
          status: 'IN_PROGRESS',
          deadline: DateTime(2027, 6, 1),
          isOverdue: false,
          createdAt: now,
        );

        final json = goal.toJson();

        // toJson only includes fields for server create/update
        expect(json['name'], 'New Car');
        expect(json['target_amount'], 50000000);
        expect(json['color'], '#00FF00');
        expect(json['icon'], '🚗');
        expect(json['deadline'], isNotNull);

        // These fields are NOT included in toJson (server manages them)
        expect(json.containsKey('id'), false);
        expect(json.containsKey('user_id'), false);
        expect(json.containsKey('current_amount'), false);
      });
    });

    group('copyWith', () {
      test('copies all fields when provided', () {
        final original = SavingsGoal(
          id: '1',
          userId: 'u1',
          name: 'Old',
          targetAmount: 1000,
          currentAmount: 500,
          status: 'IN_PROGRESS',
          isOverdue: false,
          createdAt: now,
        );

        final copied = original.copyWith(
          name: 'New',
          targetAmount: 2000,
          currentAmount: 1000,
          status: 'COMPLETED',
        );

        expect(copied.id, '1'); // unchanged
        expect(copied.name, 'New');
        expect(copied.targetAmount, 2000);
        expect(copied.currentAmount, 1000);
        expect(copied.status, 'COMPLETED');
      });
    });

    group('computed properties', () {
      test('progressPercentage calculates correctly', () {
        final goal = SavingsGoal(
          id: '1',
          userId: 'u',
          name: 'G',
          status: 'IN_PROGRESS',
          isOverdue: false,
          createdAt: now,
          targetAmount: 10000000,
          currentAmount: 5000000,
        );

        expect(goal.progressPercentage, 50.0);
      });

      test('progressPercentage handles zero target', () {
        final goal = SavingsGoal(
          id: '1',
          userId: 'u',
          name: 'G',
          status: 'IN_PROGRESS',
          isOverdue: false,
          createdAt: now,
          targetAmount: 0,
          currentAmount: 1000,
        );

        expect(goal.progressPercentage, 0);
      });

      test('progressPercentage clamps to 100 max', () {
        final goal = SavingsGoal(
          id: '1',
          userId: 'u',
          name: 'G',
          status: 'IN_PROGRESS',
          isOverdue: false,
          createdAt: now,
          targetAmount: 1000,
          currentAmount: 2000, // exceeded
        );

        expect(goal.progressPercentage, 100);
      });

      test('remainingAmount calculates correctly', () {
        final goal = SavingsGoal(
          id: '1',
          userId: 'u',
          name: 'G',
          status: 'IN_PROGRESS',
          isOverdue: false,
          createdAt: now,
          targetAmount: 10000000,
          currentAmount: 4000000,
        );

        expect(goal.remainingAmount, 6000000);
      });

      test('remainingAmount clamps to 0 minimum', () {
        final goal = SavingsGoal(
          id: '1',
          userId: 'u',
          name: 'G',
          status: 'IN_PROGRESS',
          isOverdue: false,
          createdAt: now,
          targetAmount: 1000,
          currentAmount: 2000, // exceeded
        );

        expect(goal.remainingAmount, 0);
      });
    });
  });

  group('SavingsTransaction Model', () {
    final now = DateTime.now();

    group('fromJson', () {
      test('parses complete JSON correctly', () {
        final json = {
          'id': '123',
          'goal_id': 'goal1',
          'wallet_id': 'wallet1',
          'amount': 500000.0,
          'type': 'DEPOSIT',
          'note': 'Monthly contribution',
          'created_at': now.toIso8601String(),
        };

        final tx = SavingsTransaction.fromJson(json);

        expect(tx.id, '123');
        expect(tx.goalId, 'goal1');
        expect(tx.walletId, 'wallet1');
        expect(tx.amount, 500000.0);
        expect(tx.type, 'DEPOSIT');
        expect(tx.note, 'Monthly contribution');
      });

      test('handles uppercase ID key', () {
        final json = {
          'ID': 456,
          'goal_id': 'g1',
          'wallet_id': 'w1',
          'amount': 100,
          'type': 'WITHDRAW',
          'created_at': now.toIso8601String(),
        };

        final tx = SavingsTransaction.fromJson(json);
        expect(tx.id, '456');
      });

      test('parses amount from different types', () {
        // int
        expect(
          SavingsTransaction.fromJson({
            'id': '1',
            'goal_id': 'g',
            'wallet_id': 'w',
            'type': 'DEPOSIT',
            'amount': 1000,
            'created_at': now.toIso8601String(),
          }).amount,
          1000.0,
        );

        // String
        expect(
          SavingsTransaction.fromJson({
            'id': '1',
            'goal_id': 'g',
            'wallet_id': 'w',
            'type': 'DEPOSIT',
            'amount': '2000.50',
            'created_at': now.toIso8601String(),
          }).amount,
          2000.50,
        );
      });

      test('defaults type to DEPOSIT', () {
        final json = {
          'id': '1',
          'goal_id': 'g1',
          'wallet_id': 'w1',
          'amount': 100,
          'created_at': now.toIso8601String(),
        };

        final tx = SavingsTransaction.fromJson(json);
        expect(tx.type, 'DEPOSIT');
      });

      test('handles missing created_at', () {
        final json = {
          'id': '1',
          'goal_id': 'g1',
          'wallet_id': 'w1',
          'amount': 100,
          'type': 'DEPOSIT',
        };

        final tx = SavingsTransaction.fromJson(json);
        expect(tx.createdAt.year, DateTime.now().year);
      });
    });
  });
}
