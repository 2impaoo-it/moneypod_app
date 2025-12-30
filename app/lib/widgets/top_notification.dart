import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum NotificationType { success, error, warning, info }

class TopNotification extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;
  final AnimationController controller;

  const TopNotification({
    super.key,
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.controller,
  });

  // Static method to show notification
  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Create animation controller in the wrapper? No, needs State.
    // We need a StatefulWidget that holds the controller and manages the entry.

    overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationContainer(
        message: message,
        type: type,
        onDismiss: () async {
          // This callback is called when user taps X or auto-dismiss triggers.
          // We need to animate out then remove entry.
          // The container handles animation out.
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  @override
  State<TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<TopNotification> {
  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;
    IconData icon;

    switch (widget.type) {
      case NotificationType.success:
        bgColor = const Color(0xFFDCFCE7); // Green-100
        iconColor = const Color(0xFF16A34A); // Green-600
        icon = LucideIcons.checkCircle;
        break;
      case NotificationType.error:
        bgColor = const Color(0xFFFEE2E2); // Red-100
        iconColor = const Color(0xFFDC2626); // Red-600
        icon = LucideIcons.alertCircle;
        break;
      case NotificationType.warning:
        bgColor = const Color(0xFFFEF3C7); // Amber-100
        iconColor = const Color(0xFFD97706); // Amber-600
        icon = LucideIcons.alertTriangle;
        break;
      case NotificationType.info:
      default:
        bgColor = const Color(0xFFE0F2FE); // blue-100
        iconColor = const Color(0xFF0284C7); // blue-600
        icon = LucideIcons.info;
        break;
    }

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.fromBorderSide(BorderSide(color: bgColor, width: 1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Icon(LucideIcons.x, color: Colors.grey[400], size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopNotificationContainer extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const _TopNotificationContainer({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationContainer> createState() =>
      _TopNotificationContainerState();
}

class _TopNotificationContainerState extends State<_TopNotificationContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Auto dismiss
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: TopNotification(
            message: widget.message,
            type: widget.type,
            onDismiss: _dismiss,
            controller:
                _controller, // Pass controller if needed, currently not used inside widget but OK.
          ),
        ),
      ),
    );
  }
}
