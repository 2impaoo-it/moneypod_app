import 'dart:io';
import 'dart:async'; // Added for Timer
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    as firebase_auth; // Added Firebase Auth
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:MoneyPod/models/profile.dart';
import 'package:MoneyPod/services/profile_service.dart';
import 'package:MoneyPod/services/auth_service.dart';
import 'package:MoneyPod/bloc/auth/auth_bloc.dart';
import 'package:MoneyPod/bloc/auth/auth_event.dart';
import 'package:MoneyPod/services/biometric_service.dart';
import '../../main.dart';
import '../../utils/popup_notification.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_event.dart';
import '../../bloc/savings/savings_bloc.dart';
import '../../bloc/savings/savings_event.dart';

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
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();

  // Phone Verification State
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  String? _verificationId;
  Timer? _timer;
  int _countdown = 0;
  bool _isCodeSent = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

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

    // Auto-sync for biometric storage (silent update)
    if (_profile != null &&
        _profile!.email != null &&
        _profile!.email!.isNotEmpty) {
      try {
        final email = _profile!.email!;
        final password = await _biometricService.getPassword(email);
        if (password != null) {
          await _biometricService.saveAccount(
            email: email,
            password: password,
            name: _profile!.fullName ?? email,
            avatarUrl: _profile!.avatarUrl,
          );
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // --- Phone Verification Logic ---

  void _startTimer() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('Vui lòng nhập số điện thoại');
      return;
    }

    // Format phone number: Replace leading 0 with +84 (Vietnam)
    String formattedPhone = phone;
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+84${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+84$formattedPhone';
    }

    setState(() => _loading = true);

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted:
            (firebase_auth.PhoneAuthCredential credential) async {
              // Auto-verification (Android mostly)
              await _firebaseAuth.signInWithCredential(credential);
              _onVerificationSuccess(phone);
            },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          setState(() => _loading = false);
          _showError(e.message ?? 'Lỗi xác thực số điện thoại');
          print('Phone Auth Error: ${e.code} - ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isCodeSent = true;
            _loading = false;
          });
          _startTimer();
          _showSuccess('Đã gửi mã OTP');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _loading = false);
      _showError('Lỗi gửi mã: $e');
    }
  }

  Future<void> _submitOTP() async {
    if (_verificationId == null) return;
    final otp = _otpController.text.trim();
    if (otp.length < 6) return;

    setState(() => _loading = true);
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _firebaseAuth.signInWithCredential(credential);
      _onVerificationSuccess(_phoneController.text.trim());
    } catch (e) {
      setState(() => _loading = false);
      _showError('Mã xác thực không đúng');
    }
  }

  Future<void> _onVerificationSuccess(String phone) async {
    // Call backend API
    try {
      await widget.profileService.updatePhoneNumber(widget.token, phone);

      if (mounted) Navigator.pop(context); // Close sheet
      await _loadProfile();
      _showSuccess('Liên kết số điện thoại thành công!');
    } catch (e) {
      setState(() => _loading = false);
      String msg = e.toString();
      if (msg.startsWith("Exception: ")) {
        msg = msg.substring(11); // Remove "Exception: " prefix
      }
      _showError(msg);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    PopupNotification.showError(context, msg);
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    PopupNotification.showSuccess(context, msg);
  }

  void _showPhoneInputSheet() {
    // Reset state
    _phoneController.clear();
    _otpController.clear();
    setState(() {
      _isCodeSent = false;
      _countdown = 0;
      _verificationId = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        // Use StatefulBuilder to update sheet UI
        builder: (context, setSheetState) {
          // Helper to sync local sheet state with parent state for timer/loading
          // Actually, since we use parent state variables (_loading, _isCodeSent),
          // we might just rely on parent setState if we pass callbacks or listen to changes?
          // Simpler: Just rely on parent setState and rebuild the widget tree,
          // but showModalBottomSheet usually blocks parent rebuilds from affecting it unless we use proper context.
          // Let's use the parent widget's variables but triggering setSheetState might be tricky.
          // Better approach for complex sheet: Use a separate Widget class.
          // OR: Just stick to parent calls and hope verifyPhone updates parent which triggers rebuild...
          // Wait, changing parent state won't rebuild the modal sheet unless we use StatefulBuilder/Bloc inside.

          // Let's define a simple listener logic or just re-open sheet? No.
          // I will implement the sheet UI content here that listens to the parent state variables
          // by passing them in or accessing via closure (which works if the parent rebuilds? No, modal is separate route).
          // Actually, accessing _isCodeSent via closure works, but we need to trigger setSheetState to update the modal UI.

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            height: MediaQuery.of(ctx).size.height * 0.8, // Make it tall
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Liên kết số điện thoại',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nhập số điện thoại để xác thực và bảo vệ tài khoản',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Phone Input
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !_isCodeSent,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: const Icon(LucideIcons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isCodeSent) ...[
                    const Text('Nhập mã OTP (6 số):'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: 'xxxxxx',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _countdown > 0
                              ? 'Gửi lại sau ${_countdown}s'
                              : 'Hết hạn mã',
                        ),
                        if (_countdown == 0)
                          TextButton(
                            onPressed: () {
                              // Close and re-open or just reset
                              // Ideally call verifyPhone again
                              // We need to bridge the setState gap.
                              // For now, let's just allow user to close and retry.
                              Navigator.pop(ctx);
                              _showPhoneInputSheet();
                            },
                            child: const Text('Gửi lại mã'),
                          ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : (_isCodeSent
                                ? _submitOTP
                                : () async {
                                    // Wrap verifyPhone to update sheet state
                                    // This is hacky. Better to move this sheet to a StatefulWidget.
                                    await _verifyPhone();
                                    setSheetState(() {});
                                    // Also we need the timer to update the sheet text...
                                    // StatefulBuilder won't auto-update on timer tick unless we call setSheetState in timer callback.
                                    // I will override the timer callback to call setSheetState.
                                    _timer?.cancel();
                                    setState(() => _countdown = 60);
                                    _timer = Timer.periodic(
                                      const Duration(seconds: 1),
                                      (timer) {
                                        if (_countdown == 0) {
                                          timer.cancel();
                                        } else {
                                          _countdown--;
                                        }
                                        setSheetState(() {});
                                      },
                                    );
                                  }),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_isCodeSent ? 'Xác thực' : 'Gửi mã OTP'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.logOut, color: AppColors.danger),
            SizedBox(width: 10),
            Text('Đăng xuất'),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Xóa token
      await _authService.logout();

      // Dispatch logout event to bloc
      if (mounted) {
        context.read<AuthBloc>().add(AuthLogoutRequested());

        // Reset Global Blocs
        context.read<SavingsBloc>().add(ResetSavings());
        context.read<DashboardBloc>().add(DashboardReset());

        // Navigate to login
        context.go('/login');
      }
    }
  }

  void _showEditProfileSheet() {
    final nameController = TextEditingController(
      text: _profile?.fullName ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Row(
                children: [
                  Icon(LucideIcons.edit, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    'Chỉnh sửa hồ sơ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name field
              const Text(
                'Họ và tên',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Nhập họ và tên',
                  prefixIcon: const Icon(LucideIcons.user, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppColors.textMuted.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _updateProfile(nameController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Lưu thay đổi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile(String newName) async {
    if (newName.trim().isEmpty) {
      PopupNotification.showError(context, 'Tên không được để trống');
      return;
    }

    setState(() => _loading = true);

    try {
      final updated = await widget.profileService.updateUserProfile(
        widget.token,
        {'full_name': newName.trim()},
        userId: _profile?.id,
      );

      if (updated != null) {
        // Reload full profile to get all fields including avatar
        await _loadProfile();

        // Sync new name to Biometric storage if exists
        try {
          final email = _profile?.email;
          if (email != null) {
            final password = await _biometricService.getPassword(email);
            if (password != null) {
              await _biometricService.saveAccount(
                email: email,
                password: password,
                name: newName.trim(),
                avatarUrl: _profile?.avatarUrl,
              );
            }
          }
        } catch (e) {
          print('Error syncing biometric name: $e');
        }

        if (mounted) {
          // Refresh Dashboard to sync user info
          context.read<DashboardBloc>().add(DashboardRefreshRequested());
          PopupNotification.showSuccess(context, 'Cập nhật thành công');
        }
      } else {
        setState(() => _loading = false);
        if (mounted) {
          PopupNotification.showError(context, 'Cập nhật thất bại');
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        PopupNotification.showError(context, 'Lỗi: $e');
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();

    // Show options
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn ảnh từ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.camera,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text('Máy ảnh'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.image, color: AppColors.purple),
                ),
                title: const Text('Thư viện ảnh'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _loading = true);

        final avatarUrl = await widget.profileService.uploadAvatar(
          widget.token,
          File(image.path),
          userId: _profile?.id,
        );

        if (avatarUrl != null) {
          await _loadProfile(); // Reload to get updated avatar

          // Sync new avatar to Biometric storage if exists
          try {
            final email = _profile?.email;
            if (email != null) {
              final password = await _biometricService.getPassword(email);
              if (password != null) {
                await _biometricService.saveAccount(
                  email: email,
                  password: password,
                  name: _profile?.fullName ?? email,
                  avatarUrl: avatarUrl,
                );
              }
            }
          } catch (e) {
            print('Error syncing biometric avatar: $e');
          }

          if (mounted) {
            PopupNotification.showSuccess(
              context,
              'Cập nhật ảnh đại diện thành công',
            );
          }
        } else {
          setState(() => _loading = false);
          if (mounted) {
            PopupNotification.showError(context, 'Không thể tải ảnh lên');
          }
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        PopupNotification.showError(context, 'Lỗi: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _buildErrorState()
          : _profile == null
          ? _buildEmptyState()
          : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Không có dữ liệu hồ sơ',
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildProfileContent() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
              onPressed: _loadProfile,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Avatar with edit button
                    Stack(
                      children: [
                        _buildAvatar(),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _pickAndUploadAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _profile!.fullName ?? 'Người dùng',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _profile!.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Info Card
                _buildInfoCard(),
                const SizedBox(height: 16),

                // Settings Section
                _buildSettingsSection(),
                const SizedBox(height: 16),

                // Logout Button
                _buildLogoutButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = _profile?.avatarUrl;
    final initials = (_profile?.fullName ?? '')
        .trim()
        .split(' ')
        .map((s) => s.isNotEmpty ? s[0] : '')
        .join()
        .toUpperCase();

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.white.withOpacity(0.2),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.white.withOpacity(0.2),
      child: Text(
        initials.isEmpty
            ? '?'
            : initials.substring(0, initials.length.clamp(0, 2)),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: LucideIcons.mail,
            label: 'Email',
            value: _profile!.email ?? 'Chưa có',
            iconColor: AppColors.primary,
          ),
          Divider(height: 1, color: AppColors.textMuted.withOpacity(0.1)),
          _buildInfoRow(
            icon: LucideIcons.user,
            label: 'Họ và tên',
            value: _profile!.fullName ?? 'Chưa cập nhật',
            iconColor: AppColors.purple,
            showEdit: true,
            onEdit: _showEditProfileSheet,
          ),

          Divider(height: 1, color: AppColors.textMuted.withOpacity(0.1)),
          _buildInfoRow(
            icon: LucideIcons.phone,
            label: 'Số điện thoại',
            value: _profile!.phone ?? 'Chưa liên kết',
            iconColor: AppColors.success,
            showEdit: true, // Always show edit/link button
            onEdit: _showPhoneInputSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool showEdit = false,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (showEdit)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(
                LucideIcons.edit,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: LucideIcons.bell,
            label: 'Thông báo',
            iconColor: AppColors.warning,
            onTap: () {
              PopupNotification.showSuccess(
                context,
                'Chức năng đang phát triển',
              );
            },
          ),
          Divider(height: 1, color: AppColors.textMuted.withOpacity(0.1)),
          _buildSettingsItem(
            icon: LucideIcons.lock,
            label: 'Đổi mật khẩu',
            iconColor: AppColors.primary,
            onTap: () => context.push('/profile/change-password'),
          ),
          Divider(height: 1, color: AppColors.textMuted.withOpacity(0.1)),
          _buildSettingsItem(
            icon: LucideIcons.helpCircle,
            label: 'Trợ giúp & Hỗ trợ',
            iconColor: AppColors.textSecondary,
            onTap: () {
              PopupNotification.showSuccess(
                context,
                'Chức năng đang phát triển',
              );
            },
          ),
          Divider(height: 1, color: AppColors.textMuted.withOpacity(0.1)),
          _buildSettingsItem(
            icon: LucideIcons.info,
            label: 'Về ứng dụng',
            iconColor: AppColors.textMuted,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'MoneyPod',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 MoneyPod Team',
              );
            },
          ),
          Divider(height: 1, color: AppColors.textMuted.withOpacity(0.1)),
          // Biometric Toggle Section
          _buildBiometricToggle(),
        ],
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _biometricService.getSavedAccounts(),
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? [];
        final currentAccount = accounts.firstWhere(
          (acc) => acc['email'] == _profile?.email,
          orElse: () => <String, dynamic>{},
        );
        // Check if account exists AND has biometric enabled
        final isEnabled =
            currentAccount.isNotEmpty &&
            (currentAccount['biometric_enabled'] ?? false) == true;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.fingerprint,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Đăng nhập bằng sinh trắc học',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: isEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (value) => _handleBiometricToggle(value),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleBiometricToggle(bool value) async {
    if (value) {
      // Bật: Cần nhập mật khẩu để lưu
      final authorized = await _showPasswordDialog();
      if (authorized != null) {
        // Verify password using AuthService
        // Note: Using AuthService to re-login verifies the password
        final result = await _authService.login(
          email: _profile?.email ?? '',
          password: authorized,
        );

        if (result['success'] == true) {
          // 1. Authenticate first to ensure user can use biometrics
          final authenticated = await _biometricService.authenticate();

          if (authenticated) {
            // 2. Save full account details
            // Proper fallback: check for null AND empty string
            String displayName = _profile?.email ?? 'User';
            if (_profile?.fullName != null && _profile!.fullName!.isNotEmpty) {
              displayName = _profile!.fullName!;
            }

            await _biometricService.saveAccount(
              email: _profile?.email ?? '',
              password: authorized,
              name: displayName,
              avatarUrl: _profile?.avatarUrl,
            );

            setState(() {}); // Rebuild to update toggle
            if (mounted) {
              PopupNotification.showSuccess(
                context,
                'Đã bật đăng nhập bằng sinh trắc học',
              );
            }
          } else {
            if (mounted) {
              PopupNotification.showError(
                context,
                'Xác thực sinh trắc học thất bại',
              );
            }
          }
        } else {
          if (mounted) {
            PopupNotification.showError(
              context,
              'Mật khẩu không đúng. Vui lòng thử lại.',
            );
          }
        }
      }
    } else {
      // Tắt - Yêu cầu xác thực mật khẩu trước khi tắt
      final authorized = await _showPasswordDialog();
      if (authorized != null) {
        final result = await _authService.login(
          email: _profile?.email ?? '',
          password: authorized,
        );

        if (result['success'] == true) {
          if (_profile?.email != null) {
            // Update account to disabled biometric but keep info
            // Proper fallback: check for null AND empty string
            String displayName = _profile?.email ?? 'User';
            if (_profile?.fullName != null && _profile!.fullName!.isNotEmpty) {
              displayName = _profile!.fullName!;
            }

            await _biometricService.saveAccount(
              email: _profile!.email!,
              name: displayName,
              avatarUrl: _profile?.avatarUrl,
              password: null, // No password needed for disabled state
              biometricEnabled: false,
            );
          }
          setState(() {});
          if (mounted) {
            PopupNotification.showSuccess(
              context,
              'Đã tắt đăng nhập bằng sinh trắc học',
            );
          }
        } else {
          if (mounted) {
            PopupNotification.showError(
              context,
              'Mật khẩu không đúng. Vui lòng thử lại.',
            );
          }
        }
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    bool isObscure = true;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Xác nhận mật khẩu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vui lòng nhập mật khẩu hiện tại để xác thực hành động này.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: passwordController,
                  obscureText: isObscure,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscure ? LucideIcons.eye : LucideIcons.eyeOff,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          isObscure = !isObscure;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, passwordController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(LucideIcons.logOut, size: 18),
        label: const Text('Đăng xuất'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
