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
                title: 'Lời mời tham gia nhóm',
                subtitle: 'Nhận thông báo khi được mời vào nhóm',
                value: _currentSettings!.groupInvite,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      groupInvite: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Thành viên mới tham gia',
                subtitle: 'Thông báo khi có người tham gia nhóm',
                value: _currentSettings!.groupJoin,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      groupJoin: value,
                    );
                  });
                },
              ),
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
                title: 'Thanh toán công nợ',
                subtitle: 'Thông báo khi có người thanh toán nợ',
                value: _currentSettings!.groupSettle,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      groupSettle: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Cập nhật chi tiêu',
                subtitle: 'Thông báo khi chi tiêu được chỉnh sửa',
                value: _currentSettings!.groupExpenseUpdate,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      groupExpenseUpdate: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Xóa chi tiêu',
                subtitle: 'Thông báo khi chi tiêu bị xóa',
                value: _currentSettings!.groupExpenseDelete,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      groupExpenseDelete: value,
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
                title: 'Cột mốc tiết kiệm',
                subtitle: 'Thông báo khi đạt 25%, 50%, 75%',
                value: _currentSettings!.savingsMilestone,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      savingsMilestone: value,
                    );
                  });
                },
              ),
              _SettingTile(
                title: 'Nhắc nhở tiết kiệm',
                subtitle: 'Nhắc nạp tiền mỗi 7 ngày',
                value: _currentSettings!.savingsReminder,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      savingsReminder: value,
                    );
                  });
                },
              ),

              // WALLET NOTIFICATIONS
              const _SectionHeader(
                icon: Icons.account_balance_wallet,
                title: 'Thông báo ví',
              ),
              _SettingTile(
                title: 'Cảnh báo số dư thấp',
                subtitle: 'Thông báo khi số dư dưới 100,000đ',
                value: _currentSettings!.lowBalanceAlert,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      lowBalanceAlert: value,
                    );
                  });
                },
              ),

              // SYSTEM NOTIFICATIONS
              const _SectionHeader(
                icon: Icons.security,
                title: 'Thông báo hệ thống',
              ),
              _SettingTile(
                title: 'Đăng nhập thiết bị mới',
                subtitle: 'Cảnh báo khi có đăng nhập từ thiết bị lạ',
                value: _currentSettings!.newDeviceLogin,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      newDeviceLogin: value,
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
              _SettingTile(
                title: 'Nhắc nhở công nợ',
                subtitle: 'Nhắc thanh toán nợ mỗi ngày',
                value: _currentSettings!.debtReminder,
                onChanged: (value) {
                  setState(() {
                    _currentSettings = _currentSettings!.copyWith(
                      debtReminder: value,
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
