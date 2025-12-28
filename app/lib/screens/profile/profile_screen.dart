//import 'package:MoneyPod/screens/profile/profile_update_screen.dart';
import 'package:flutter/material.dart';
import 'package:MoneyPod/models/profile.dart';
import 'package:MoneyPod/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final ProfileService profileService;
  final String token;

  const ProfileScreen({
    super.key,
    required this.profileService,
    required this.token,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String? _error;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await widget.profileService.getUserProfile(widget.token);
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không tải được thông tin: $e';
        _loading = false;
      });
    }
  }

  Widget _buildAvatar() {
    final avatarUrl = _profile == null
        ? null
        : (_profile!.avatarUrl ?? _profile!.avatarUrl);

    final initials = (_profile == null
        ? ''
        : ((_profile!.fullName ?? _profile!.fullName ?? '')
                  .trim()
                  .split(' ')
                  .map((s) => s.isNotEmpty ? s[0] : '')
                  .join())
              .toUpperCase());

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(radius: 44, backgroundImage: NetworkImage(avatarUrl));
    }

    return CircleAvatar(
      radius: 44,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        value ?? 'Không có',
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : _profile == null
          ? const Center(child: Text('Không có dữ liệu hồ sơ'))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildAvatar(),
                  const SizedBox(height: 12),
                  Text(
                    _profile!.fullName ?? _profile!.fullName ?? 'Người dùng',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile!.email ?? 'Không có email',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.email, 'Email', _profile!.email),
                        _buildInfoRow(
                          Icons.person,
                          'Họ và tên',
                          _profile!.fullName ?? _profile!.fullName,
                        ),
                        // If your Profile model has a balance field, uncomment:
                        // _buildInfoRow(Icons.account_balance_wallet, 'Số dư', _profile!.balance?.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Chỉnh sửa'),
                            onPressed: () {
                              // Navigator.of(context)
                              //     .push(
                              //       MaterialPageRoute(
                              //         builder: (context) => ProfileUpdateScreen(
                              //           profileService: widget.profileService,
                              //           token: widget.token,
                              //           initialProfile: _profile!,
                              //         ),
                              //       ),
                              //     )
                              //     .then((_) => _loadProfile());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Đăng xuất'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            // Implement logout flow in caller or via AuthService
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
