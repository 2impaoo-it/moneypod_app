import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_event.dart';
import '../../services/biometric_service.dart';
import '../../utils/popup_notification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _canCheckBiometrics = false;
  List<Map<String, dynamic>> _savedAccounts = [];
  bool _showLoginForm = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadSavedAccounts();
  }

  Future<void> _checkBiometrics() async {
    final isAvailable = await BiometricService().isBiometricAvailable();
    if (mounted) {
      setState(() {
        _canCheckBiometrics = isAvailable;
      });
    }
  }

  Future<void> _loadSavedAccounts() async {
    final accounts = await BiometricService().getSavedAccounts();
    if (mounted) {
      setState(() {
        _savedAccounts = accounts;
        _showLoginForm = accounts.isEmpty;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _handleBiometricLogin(Map<String, dynamic> account) async {
    final service = BiometricService();
    final authenticated = await service.authenticate();

    if (authenticated && mounted) {
      final email = account['email'];
      final password = await service.getPassword(email);

      if (password != null) {
        context.read<AuthBloc>().add(
          AuthLoginRequested(email: email, password: password),
        );
      } else {
        PopupNotification.showError(
          context,
          'Thông tin đăng nhập đã hết hạn. Vui lòng đăng nhập lại bằng mật khẩu.',
        );
        setState(() {
          _showLoginForm = true;
          _emailController.text = email;
        });
      }
    }
  }

  // Xóa tài khoản đã lưu
  Future<void> _removeSavedAccount(String email) async {
    await BiometricService().removeAccount(email);
    await _loadSavedAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          // Lưu tài khoản khi login thành công
          final user = state.user;
          // Lấy password hiện tại hoặc từ biometric nếu auto login
          String passwordToSave = _passwordController.text;
          if (passwordToSave.isEmpty) {
            final savedPass = await BiometricService().getPassword(user.email);
            if (savedPass != null) passwordToSave = savedPass;
          }

          if (passwordToSave.isNotEmpty) {
            // Fallback logic for user name
            String displayName = user.email;
            if (user.fullName != null && user.fullName!.isNotEmpty) {
              displayName = user.fullName!;
            }

            await BiometricService().saveAccount(
              email: user.email,
              password: passwordToSave,
              name: displayName,
              avatarUrl: user.avatarUrl,
            );
          }

          // Refresh dashboard
          context.read<DashboardBloc>().add(DashboardRefreshRequested());
          await PopupNotification.showSuccess(context, 'Đăng nhập thành công!');
          if (context.mounted) context.go('/');
        } else if (state is AuthError) {
          PopupNotification.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _showLoginForm || _savedAccounts.isEmpty
                  ? _buildLoginForm()
                  : _buildSavedAccountsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAccountsList() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFF14B8A6),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.wallet, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Xin chào trở lại!',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 32),

        // List Accounts
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _savedAccounts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final account = _savedAccounts[index];
            final email = account['email'] ?? '';
            String name = account['name'] ?? 'User';

            // Nếu tên hiển thị giống email (do chưa có fullName),
            // hiển thị phần username của email cho đẹp
            if (name == email || name == 'User') {
              final parts = email.split('@');
              if (parts.isNotEmpty && parts[0].isNotEmpty) {
                name = parts[0];
                // Capitalize first letter
                if (name.isNotEmpty) {
                  name = name[0].toUpperCase() + name.substring(1);
                }
              }
            }

            final avatarUrl = account['avatar_url'];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF14B8A6).withOpacity(0.1),
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : email[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF14B8A6),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(email),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () => _handleBiometricLogin(account),
                onLongPress: () => _showDeleteAccountDialog(account),
              ),
            );
          },
        ),

        const SizedBox(height: 32),
        TextButton(
          onPressed: () {
            setState(() {
              _showLoginForm = true;
            });
          },
          child: const Text('Đăng nhập bằng tài khoản khác'),
        ),
      ],
    );
  }

  Future<void> _showDeleteAccountDialog(Map<String, dynamic> account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: Text(
          'Bạn có muốn xóa tài khoản ${account['email']} khỏi danh sách lưu không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeSavedAccount(account['email']);
    }
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF14B8A6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.wallet,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Chào mừng trở lại! 👋',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để quản lý chi tiêu của bạn',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Email Input
          Text(
            'Email',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Nhập email của bạn',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(
                LucideIcons.mail,
                color: Color(0xFF64748B),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Password Input
          Text(
            'Mật khẩu',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _isObscure,
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(
                LucideIcons.lock,
                color: Color(0xFF64748B),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Text(
                'Quên mật khẩu?',
                style: GoogleFonts.inter(
                  color: const Color(0xFF14B8A6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Login Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Đăng nhập',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Back to saved accounts (if any)
          if (_savedAccounts.isNotEmpty)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showLoginForm = false),
                child: const Text('Quay lại danh sách tài khoản'),
              ),
            ),

          // Register
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Chưa có tài khoản? ',
                style: GoogleFonts.inter(color: const Color(0xFF64748B)),
              ),
              TextButton(
                onPressed: () => context.push('/register'),
                child: Text(
                  'Đăng ký ngay',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF14B8A6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
