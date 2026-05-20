import 'package:flutter/material.dart';

class AppSnackBar {
  static void show(BuildContext context, {required String message, required Color backgroundColor, required IconData icon}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        elevation: 8,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFFD32F2F),
      icon: Icons.error_outline,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFF388E3C),
      icon: Icons.check_circle_outline,
    );
  }

  static void showInfo(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFF1976D2),
      icon: Icons.info_outline,
    );
  }
}
