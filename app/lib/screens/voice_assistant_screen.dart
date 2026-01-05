import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/voice_command.dart';
import '../services/voice_service.dart';
import '../services/voice_command_parser.dart';
import '../theme/app_colors.dart';

/// Bottom sheet UI cho Voice Assistant
class VoiceAssistantScreen extends StatefulWidget {
  final String? defaultWalletId;

  const VoiceAssistantScreen({super.key, this.defaultWalletId});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final VoiceService _voiceService = VoiceService();

  String _recognizedText = '';
  String _statusText = 'Đang khởi tạo...';
  bool _isInitialized = false;
  bool _isListening = false;
  VoiceCommand? _parsedCommand;

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    final initialized = await _voiceService.initialize();
    setState(() {
      _isInitialized = initialized;
      _statusText = initialized
          ? 'Nhấn để nói'
          : 'Không thể khởi tạo. Vui lòng cấp quyền microphone.';
    });

    if (initialized) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _recognizedText = '';
      _parsedCommand = null;
      _statusText = 'Đang nghe...';
      _isListening = true;
    });

    await _voiceService.startListening(
      onResult: (text, isFinal) {
        setState(() {
          _recognizedText = text;
        });

        if (isFinal && text.isNotEmpty) {
          _processCommand(text);
        }
      },
      onListeningStarted: () {
        setState(() => _isListening = true);
      },
      onListeningStopped: () {
        setState(() => _isListening = false);
      },
    );
  }

  void _processCommand(String text) {
    final command = VoiceCommandParser.parse(text);

    if (command != null && command.amount > 0) {
      setState(() {
        _parsedCommand = command;
        _statusText = 'Đã nhận diện';
      });

      // Show confirmation
      _showConfirmation(command);
    } else {
      setState(() {
        _statusText = 'Không hiểu lệnh. Hãy thử lại.';
      });

      // Speak feedback
      _voiceService.speak('Xin lỗi, tôi không hiểu. Hãy thử lại.');
    }
  }

  Future<void> _showConfirmation(VoiceCommand command) async {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: command.type == 'expense'
                    ? AppColors.danger.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                command.type == 'expense'
                    ? LucideIcons.arrowUpRight
                    : LucideIcons.arrowDownLeft,
                color: command.type == 'expense'
                    ? AppColors.danger
                    : AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Xác nhận',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(
              'Loại',
              command.type == 'expense' ? 'Chi tiêu' : 'Thu nhập',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Số tiền',
              currencyFormat.format(command.amount),
              valueColor: command.type == 'expense'
                  ? AppColors.danger
                  : AppColors.success,
            ),
            if (command.category != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Danh mục', command.category!),
            ],
            if (command.note != null && command.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Ghi chú', command.note!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Return command to caller
      Navigator.pop(context, command);
    } else if (mounted) {
      // Restart listening
      setState(() {
        _statusText = 'Nhấn để nói lại';
        _parsedCommand = null;
      });
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            _statusText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),

          // Microphone with glow animation
          GestureDetector(
            onTap: _isInitialized && !_isListening ? _startListening : null,
            child: AvatarGlow(
              animate: _isListening,
              glowColor: AppColors.primary,
              duration: const Duration(milliseconds: 1500),
              repeat: true,
              child: Material(
                elevation: 8,
                shape: const CircleBorder(),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: _isListening
                      ? AppColors.primary
                      : Colors.grey[300],
                  child: Icon(
                    _isListening ? LucideIcons.mic : LucideIcons.micOff,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Recognized text
          if (_recognizedText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _recognizedText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_parsedCommand != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _parsedCommand!.summary,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Examples
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.lightbulb,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ví dụ:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• "Chi 50 nghìn ăn sáng"\n'
                  '• "Thu nhập 5 triệu lương"\n'
                  '• "Mua 2 triệu 5 điện thoại"',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}
