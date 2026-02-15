import 'package:flutter/material.dart';
import 'package:connect/globals/navigator_key.dart';

class UiUtils {
  static void showSuccessSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green,
    );
  }

  static void showErrorSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.redAccent,
    );
  }

  static void showInfoSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.blueAccent,
    );
  }

  static void showWarningSnackBar(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.orangeAccent,
    );
  }

  static void _showSnackBar({
    required String message,
    required Color backgroundColor,
  }) {
    final context = navigatorKey.currentState?.context;
    if (context != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          showCloseIcon: true,
          closeIconColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
