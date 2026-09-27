import 'package:flutter/material.dart';

class KhthWebView extends StatelessWidget {
  final String url;

  const KhthWebView({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Kế hoạch tổng hợp hiện chỉ hỗ trợ trên Web.',
      ),
    );
  }
}