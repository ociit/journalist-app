import 'package:flutter/material.dart';
import 'dart:async';

enum NotificationType { success, error, info, warning }

class TopNotification {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Jika sudah ada notifikasi, hapus dulu
    if (_overlayEntry != null) {
      _removeNotification();
    }

    IconData iconData;
    Color backgroundColor;
    Color textColor = Colors.white; // Default text color

    final ThemeData theme = Theme.of(context);

    switch (type) {
      case NotificationType.success:
        iconData = Icons.check_circle_outline;
        backgroundColor = Colors.green.shade600;
        break;
      case NotificationType.error:
        iconData = Icons.error_outline;
        backgroundColor = theme.colorScheme.error; // Menggunakan warna error dari tema
        textColor = theme.colorScheme.onError;
        break;
      case NotificationType.warning:
        iconData = Icons.warning_amber_outlined;
        backgroundColor = Colors.orange.shade700;
        break;
      case NotificationType.info:
      default:
        iconData = Icons.info_outline;
        backgroundColor = Colors.blue.shade600;
        break;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        message: message,
        iconData: iconData,
        backgroundColor: backgroundColor,
        textColor: textColor,
        onDismiss: _removeNotification,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Hapus notifikasi setelah durasi tertentu
    _timer?.cancel(); // Batalkan timer sebelumnya jika ada
    _timer = Timer(duration, () {
      _removeNotification();
    });
  }

  static void _removeNotification() {
    _timer?.cancel();
    _timer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final IconData iconData;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.iconData,
    required this.backgroundColor,
    required this.textColor,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5), // Mulai dari atas layar
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan MediaQuery untuk mendapatkan tinggi status bar
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Positioned(
      top: statusBarHeight + 16.0, // Posisi di bawah status bar dengan sedikit margin
      left: 16.0,
      right: 16.0,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent, // Material transparan agar shadow terlihat
          child: SafeArea( // Hanya SafeArea untuk bagian atas (jika diperlukan)
            top: false, // Kita sudah atur posisi dengan statusBarHeight
            bottom: false,
            child: GestureDetector(
              onTap: widget.onDismiss, // Tutup notifikasi jika di-tap
              onVerticalDragUpdate: (details) { // Tutup notifikasi jika di-swipe ke atas
                if (details.primaryDelta != null && details.primaryDelta! < -5) { // Swipe ke atas
                  widget.onDismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(widget.iconData, color: widget.textColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(color: widget.textColor, fontSize: 15, fontWeight: FontWeight.w500),
                        softWrap: true,
                      ),
                    ),
                    //tombol untuk close notif
                    InkWell(
                      onTap: widget.onDismiss,
                      child: Icon(Icons.close, color: widget.textColor, size: 20),
                    )
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
