import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../services/biometric_service.dart';
import '../../widgets/top_notification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  final _biometricService = BiometricService();
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _canCheckBiometrics = available && enabled;
      });
    }

    // Auto prompt if enabled
    if (available && enabled) {
      // Optional: Auto-trigger biometric prompt
      // _handleBiometricLogin();
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      final credentials = await _biometricService.getStoredCredentials();
      if (credentials != null) {
        // Auto fill and submit
        _emailController.text = credentials['email']!;
        _passwordController.text = credentials['password']!;

        if (mounted) {
          context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: credentials['email']!,
              password: credentials['password']!,
            ),
          );
        }
      } else {
        if (mounted) {
          TopNotification.show(
            context,
            'Không tìm thấy thông tin đăng nhập đã lưu',
            type: NotificationType.error,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          TopNotification.show(
            context,
            'Đăng nhập thành công!',
            type: NotificationType.success,
          );
          context.go('/');
        } else if (state is AuthError) {
          TopNotification.show(
            context,
            state.message,
            type: NotificationType.error,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo & Title
                    Icon(
                      LucideIcons.wallet,
                      size: 64,
                      color: const Color(0xFF14B8A6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MoneyPod',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập để quản lý tài chính',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'your.email@example.com',
                        prefixIcon: const Icon(LucideIcons.mail),
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
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      obscuringCharacter: '*',
                      enableSuggestions: false,
                      autocorrect: false,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: '********',
                        prefixIcon: const Icon(LucideIcons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
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
                    const SizedBox(height: 24),

                    // Login Button and Biometric
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return Row(
                          children: [
                            if (_canCheckBiometrics) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF14B8A6,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: isLoading
                                      ? null
                                      : _handleBiometricLogin,
                                  icon: const Icon(LucideIcons.fingerprint),
                                  color: const Color(0xFF14B8A6),
                                  iconSize: 28,
                                  style: IconButton.styleFrom(
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: SizedBox(
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
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
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'hoặc',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chưa có tài khoản? ',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register'),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
