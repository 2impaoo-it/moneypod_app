import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';

/// Splash screen - Màn hình khởi động kiểm tra server
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _statusMessage = 'Đang kết nối với server...';
  bool _hasError = false;
  String _errorType = ''; // 'maintenance', 'no_internet', 'unknown'

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Kiểm tra server
    _checkServerAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Kiểm tra server và điều hướng
  Future<void> _checkServerAndNavigate() async {
    // Chờ animation chạy một chút
    await Future.delayed(const Duration(milliseconds: 500));

    // Kiểm tra server
    final healthCheck = await ApiService.checkServerHealth();
    final isHealthy = healthCheck['isHealthy'] as bool;
    final errorType = healthCheck['errorType'] as String?;
    final message = healthCheck['message'] as String?;

    if (!mounted) return;

    if (isHealthy) {
      // Server OK → Navigate đến Login
      setState(() {
        _statusMessage = 'Kết nối thành công!';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      // Server không hoạt động → Hiển thị lỗi theo loại
      setState(() {
        _hasError = true;
        _errorType = errorType ?? 'unknown';
        _statusMessage = message ?? 'Không thể kết nối đến server';
      });
    }
  }

  /// Thử lại kết nối
  void _retry() {
    setState(() {
      _hasError = false;
      _errorType = '';
      _statusMessage = 'Đang kết nối với server...';
    });
    _checkServerAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.wallet,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // App Name
                const Text(
                  'MoneyPod',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quản lý tài chính thông minh',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // Loading hoặc Error
                if (!_hasError) ...[
                  // Loading Indicator
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  // Error Message
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _errorType == 'maintenance'
                          ? AppColors.warning.withOpacity(0.1)
                          : AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _errorType == 'maintenance'
                            ? AppColors.warning.withOpacity(0.3)
                            : AppColors.danger.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _errorType == 'maintenance'
                              ? LucideIcons.wrench
                              : LucideIcons.wifiOff,
                          size: 48,
                          color: _errorType == 'maintenance'
                              ? AppColors.warning
                              : AppColors.danger,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _errorType == 'maintenance'
                                ? AppColors.warning
                                : AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorType == 'maintenance'
                              ? 'Server đang trong quá trình bảo trì.\nVui lòng thử lại sau ít phút.'
                              : 'Vui lòng kiểm tra:\n• Kết nối mạng\n• Server\n',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(LucideIcons.refreshCw, size: 20),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _errorType == 'maintenance'
                                  ? AppColors.warning
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
