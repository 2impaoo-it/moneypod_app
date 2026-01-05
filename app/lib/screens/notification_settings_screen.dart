import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/notification/notification_bloc.dart';
import '../bloc/notification/notification_event.dart';
import '../bloc/notification/notification_state.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        final token = authState is AuthAuthenticated
            ? authState.user.token
            : null;
        return NotificationBloc(repository: NotificationRepository())
          ..add(NotificationLoadSettings(token ?? ''));
      },
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatefulWidget {
  const _NotificationSettingsView();

  @override
  State<_NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<_NotificationSettingsView> {
  NotificationSettings? _currentSettings;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final token = authState is AuthAuthenticated ? authState.user.token : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        actions: [
          TextButton(
            onPressed: _currentSettings != null && token != null
                ? () {
                    context.read<NotificationBloc>().add(
                      NotificationUpdateSettings(token, _currentSettings!),
                    );
                  }
                : null,
            child: const Text(
              'Lưu',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.pop(context);
          } else if (state is NotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is NotificationSettingsLoaded) {
            _currentSettings = state.settings;
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (token != null) {
                        context.read<NotificationBloc>().add(
                          NotificationLoadSettings(token),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (_currentSettings == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          return ListView(
            children: [
              // GROUP NOTIFICATIONS
              const _SectionHeader(icon: Icons.group, title: 'Thông báo nhóm'),
              _SettingTile(
                title: 'Chi tiêu nhóm mới',
                subtitle: 'Thông báo khi có giao dịch mới trong nhóm',
                value: _currentSettings!.groupExpense,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      groupExpense: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Thành viên được thêm',
                subtitle: 'Thông báo khi có thành viên mới',
                value: _currentSettings!.groupMemberAdded,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      groupMemberAdded: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Thành viên bị xóa',
                subtitle: 'Thông báo khi có thành viên rời nhóm',
                value: _currentSettings!.groupMemberRemoved,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      groupMemberRemoved: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Nhóm bị xóa',
                subtitle: 'Thông báo khi nhóm bị xóa',
                value: _currentSettings!.groupDeleted,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      groupDeleted: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Cập nhật chi tiêu',
                subtitle: 'Thông báo khi chi tiêu được chỉnh sửa',
                value: _currentSettings!.expenseUpdated,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      expenseUpdated: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Xóa chi tiêu',
                subtitle: 'Thông báo khi chi tiêu bị xóa',
                value: _currentSettings!.expenseDeleted,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      expenseDeleted: value,
                    );
                  });
                },
              ),

              // TRANSACTION NOTIFICATIONS
              const _SectionHeader(
                icon: Icons.account_balance_wallet,
                title: 'Thông báo giao dịch',
              ),
              _SettingTile(
                title: 'Giao dịch mới',
                subtitle: 'Thông báo khi có giao dịch mới',
                value: _currentSettings!.transactionCreated,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      transactionCreated: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Cảnh báo số dư thấp',
                subtitle: 'Thông báo khi số dư dưới 100,000đ',
                value: _currentSettings!.lowBalance,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      lowBalance: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Vượt ngân sách',
                subtitle: 'Thông báo khi chi tiêu vượt ngân sách',
                value: _currentSettings!.budgetExceeded,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      budgetExceeded: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Tóm tắt hàng ngày',
                subtitle: 'Nhận báo cáo tổng hợp hàng ngày',
                value: _currentSettings!.dailySummary,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      dailySummary: value,
                    );
                  });
                },
              ),

              // SAVINGS NOTIFICATIONS
              const _SectionHeader(
                icon: Icons.savings,
                title: 'Thông báo tiết kiệm',
              ),
              _SettingTile(
                title: 'Đạt mục tiêu tiết kiệm',
                subtitle: 'Thông báo khi hoàn thành mục tiêu',
                value: _currentSettings!.savingsGoalReached,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      savingsGoalReached: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Nhắc nhở tiết kiệm',
                subtitle: 'Nhắc nạp tiền định kỳ',
                value: _currentSettings!.savingsReminder,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      savingsReminder: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Tiến độ tiết kiệm',
                subtitle: 'Thông báo khi đạt 50%, 75%, 90%',
                value: _currentSettings!.savingsProgress,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      savingsProgress: value,
                    );
                  });
                },
              ),

              // SYSTEM NOTIFICATIONS
              const _SectionHeader(
                icon: Icons.settings,
                title: 'Thông báo hệ thống',
              ),
              _SettingTile(
                title: 'Thông báo hệ thống',
                subtitle: 'Thông báo quan trọng từ hệ thống',
                value: _currentSettings!.systemAnnouncement,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      systemAnnouncement: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Cảnh báo bảo mật',
                subtitle: 'Thông báo về hoạt động đáng ngờ',
                value: _currentSettings!.securityAlert,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      securityAlert: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Cập nhật ứng dụng',
                subtitle: 'Thông báo khi có phiên bản mới',
                value: _currentSettings!.appUpdate,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      appUpdate: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Bảo trì hệ thống',
                subtitle: 'Thông báo khi hệ thống bảo trì',
                value: _currentSettings!.maintenance,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      maintenance: value,
                    );
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[200],
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }
}
