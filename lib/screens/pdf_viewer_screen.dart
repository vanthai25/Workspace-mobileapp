import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class PdfViewerScreen extends StatelessWidget {
  final int fileId; // Dùng ID của file thay vì mathanhtoanct
  final String fileName;

  const PdfViewerScreen({
    super.key,
    required this.fileId,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    // Trỏ tới API download-pdf theo id
    final String pdfUrl = '${AppConstants.baseUrl}/XNTraSau/download-pdf?id=$fileId';
    final token = context.read<AuthProvider>().token;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1274BC),
        foregroundColor: Colors.white,
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }
}