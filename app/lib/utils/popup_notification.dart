import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../main.dart'; // For AppColors

class PopupNotification {
  static Future<void> showSuccess(BuildContext context, String message) async {
    await _showDialog(context, message, isError: false);
  }

  static Future<void> showError(BuildContext context, String message) async {
    await _showDialog(context, message, isError: true);
  }

  static Future<void> showWarning(BuildContext context, String message) async {
    await _showDialog(context, message, isError: true, isWarning: true);
  }

  static Future<void> _showDialog(
    BuildContext context,
    String message, {
    required bool isError,
    bool isWarning = false,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isWarning
                        ? AppColors.warning.withOpacity(0.1)
                        : (isError
                              ? AppColors.danger.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWarning
                        ? LucideIcons.alertTriangle
                        : (isError
                              ? LucideIcons.alertCircle
                              : LucideIcons.checkCircle2),
                    size: 48,
                    color: isWarning
                        ? AppColors.warning
                        : (isError ? AppColors.danger : AppColors.success),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isWarning ? "Cảnh báo" : (isError ? "Lỗi" : "Thành công"),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isWarning
                          ? AppColors.warning
                          : (isError ? AppColors.danger : AppColors.primary),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Đóng",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
