import 'package:flutter/material.dart';

class AppHelpers {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSnackBar(String message, {bool isError = false}) {
    // Dọn dẹp sạch sẽ chữ "Exception: " mặc định của Dart
    String cleanMessage = message.replaceAll('Exception: ', '').trim();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cleanMessage,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? const Color(0xFFFF4B4B) : const Color(0xFF4CAF50),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(20),
      elevation: 10,
      duration: const Duration(seconds: 3),
    );

    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}