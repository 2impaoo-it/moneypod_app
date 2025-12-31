import 'package:MoneyPod/main.dart';
import 'package:MoneyPod/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key, required this.profile});
  final Profile profile;
  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl;
    final initials = (profile.fullName ?? '')
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .join()
        .toUpperCase();

    return GestureDetector(
      onTap: () {
        print('Avatar tapped - navigating to /profile');
        try {
          context.go('/profile');
        } catch (e) {
          print('Navigation error: $e');
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Xin chào,",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                profile.fullName ?? 'Người dùng',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              context.push('/notifications');
            },
            icon: const Icon(LucideIcons.bell, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
