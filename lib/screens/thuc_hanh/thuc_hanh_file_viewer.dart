import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import '../../models/thuc_hanh_models.dart';
import '../../services/thuc_hanh_service.dart';

Future<void> showThucHanhFile(
  BuildContext context,
  ThucHanhService service,
  String url,
  ThucHanhFileModel file,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await service.download(url);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920, maxHeight: 820),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
                color: const Color(0xFF075E91),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: Colors.white),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        file.fileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(child: _filePreview(bytes, file)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => FilePicker.platform.saveFile(
                        dialogTitle: 'Lưu file hồ sơ',
                        fileName: file.fileName,
                        bytes: bytes,
                      ),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Tải file'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Không mở được file: $error')),
    );
  }
}

Widget _filePreview(Uint8List bytes, ThucHanhFileModel file) {
  final type = (file.fileType ?? file.fileName.split('.').last).toLowerCase();
  if (const ['jpg', 'jpeg', 'png'].contains(type)) {
    return InteractiveViewer(
      child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
    );
  }
  if (type == 'pdf') {
    return PdfPreview(
      build: (_) async => bytes,
      allowPrinting: false,
      allowSharing: false,
      canChangeOrientation: false,
      canChangePageFormat: false,
    );
  }
  return const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Định dạng DOC/DOCX không xem trực tiếp được. Hãy tải file để mở bằng ứng dụng phù hợp.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
