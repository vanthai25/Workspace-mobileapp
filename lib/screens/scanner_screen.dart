import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // 🟢 Khởi tạo controller đơn giản hơn cho bản 5.x
  final MobileScannerController controller = MobileScannerController(
    autoStart: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? rawValue = barcodes.first.rawValue;
                if (rawValue != null) {
                  controller.stop();
                  Navigator.pop(context, rawValue);
                }
              }
            },
          ),
          
          // Khung quét
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
              child: Center(
                child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white), 
                  onPressed: () => Navigator.pop(context)
                ),
                const Text("Quét mã QR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white), // Dùng icon tĩnh cho đơn giản
                  onPressed: () => controller.toggleTorch(), // Gọi thẳng hàm toggle
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}