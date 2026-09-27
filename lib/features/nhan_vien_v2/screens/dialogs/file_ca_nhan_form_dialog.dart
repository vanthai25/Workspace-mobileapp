import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;

import '../../../../models/nhan_vien_v2_models.dart';
import '../../../../providers/nhan_vien_v2_provider.dart';
import '../../utils/employee_file_open.dart';

class FileCaNhanFormDialog extends StatefulWidget {
  final String maSo;
  final bool canEdit; // Biến kiểm tra quyền Thêm/Sửa/Xóa

  const FileCaNhanFormDialog({
    super.key,
    required this.maSo,
    required this.canEdit,
  });

  @override
  State<FileCaNhanFormDialog> createState() => _FileCaNhanFormDialogState();
}

class _FileCaNhanFormDialogState extends State<FileCaNhanFormDialog> {
  static const Color _primary = Color(0xFF1274BC);
  static const Color _border = Color(0xFFE3EAF2);
  static const Color _mutedText = Color(0xFF66788A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NhanVienV2Provider>().loadTaiLieuKhac(widget.maSo);
    });
  }

  // =========================================================
  // XỬ LÝ UPLOAD FILE
  // =========================================================
  Future<void> _pickAndUploadFiles() async {
    final result = await fp.FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: fp.FileType.any,
    );

    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    final provider = context.read<NhanVienV2Provider>();

    final success = await provider.uploadTaiLieuKhac(
      maSo: widget.maSo,
      files: result.files,
      ngayTaiLieu: DateTime.now(),
    );

    if (!mounted) return;

    if (success) {
      _showMessage('Đã tải lên ${result.files.length} file thành công.');
    } else {
      _showMessage(
        provider.taiLieuKhacError ?? 'Lỗi khi tải file lên.',
        isError: true,
      );
    }
  }

  // =========================================================
  // XỬ LÝ XÓA FILE
  // =========================================================
  Future<void> _deleteFile(int idTaiLieu) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa tài liệu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<NhanVienV2Provider>();
    final success = await provider.deleteTaiLieuKhac(
      maSo: widget.maSo,
      idTaiLieu: idTaiLieu,
    );

    if (!mounted) return;
    if (success) {
      _showMessage('Đã xóa file thành công.');
    } else {
      _showMessage(
        provider.taiLieuKhacError ?? 'Lỗi khi xóa file.',
        isError: true,
      );
    }
  }

  // =========================================================
  // XEM FILE
  // =========================================================
  Future<void> _downloadFile(NhanVienTaiLieuKhacV2Model file) async {
    final provider = context.read<NhanVienV2Provider>();
    final idTaiLieu = file.idTaiLieuNhanVien;

    final bytes = await provider.downloadTaiLieuKhac(
      maSo: widget.maSo,
      idTaiLieu: idTaiLieu,
    );

    if (bytes == null || !mounted) {
      _showMessage(
        provider.taiLieuKhacError ?? 'Không thể tải file.',
        isError: true,
      );
      return;
    }

    await openEmployeeFile(
      bytes: bytes,
      fileName: file.fileName,
      fileType: file.fileType,
    );
  }

  // =========================================================
  // XỬ LÝ CẬP NHẬT THÔNG TIN FILE
  // =========================================================
  Future<void> _editFileInfo(NhanVienTaiLieuKhacV2Model file) async {
    final provider = context.read<NhanVienV2Provider>();
    final idTaiLieu = file.idTaiLieuNhanVien;

    final tenController = TextEditingController(text: file.tenTaiLieu);
    final ghiChuController = TextEditingController(text: file.ghiChu);

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật thông tin file'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(
                labelText: 'Tên tài liệu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ghiChuController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await provider.updateTaiLieuKhac(
                maSo: widget.maSo,
                idTaiLieu: idTaiLieu,
                tenTaiLieu: tenController.text,
                ghiChu: ghiChuController.text,
              );
              if (ctx.mounted) Navigator.pop(ctx, ok);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (success == true && mounted) {
      _showMessage('Cập nhật thông tin file thành công.');
    } else if (success == false &&
        mounted &&
        provider.taiLieuKhacError != null) {
      _showMessage(provider.taiLieuKhacError!, isError: true);
    }
  }

  // =========================================================
  // GIAO DIỆN
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.folder_shared_outlined,
                      color: _primary,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Quản lý File cá nhân',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172B3E),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Đóng',
                ),
              ],
            ),
            const Divider(height: 30, color: _border),

            // --- NÚT UPLOAD TÀI LIỆU (Chỉ hiện nếu có quyền canEdit) ---
            if (widget.canEdit) ...[
              Consumer<NhanVienV2Provider>(
                builder: (context, provider, child) {
                  return OutlinedButton.icon(
                    onPressed: provider.isUploadingTaiLieuKhac
                        ? null
                        : _pickAndUploadFiles,
                    icon: provider.isUploadingTaiLieuKhac
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      provider.isUploadingTaiLieuKhac
                          ? 'Đang tải lên...'
                          : 'Thêm file mới',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // --- DANH SÁCH FILE ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF9FAFB),
                ),
                child: Consumer<NhanVienV2Provider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingTaiLieuKhac) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.taiLieuKhacError != null &&
                        provider.taiLieuKhac.isEmpty) {
                      return Center(
                        child: Text(
                          provider.taiLieuKhacError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (provider.taiLieuKhac.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insert_drive_file_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Chưa có file cá nhân nào.',
                              style: TextStyle(color: _mutedText),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.taiLieuKhac.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final file = provider.taiLieuKhac[index];
                        final isDownloading = provider.isDownloadingTaiLieuKhac(
                          file.idTaiLieuNhanVien,
                        );

                        // Ưu tiên hiển thị tenTaiLieu, nếu trống thì dùng fileName gốc
                        final String displayName =
                            (file.tenTaiLieu != null &&
                                file.tenTaiLieu!.trim().isNotEmpty)
                            ? file.tenTaiLieu!
                            : file.fileName;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.insert_drive_file,
                                color: Colors.blueGrey,
                                size: 36,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ghi chú: ${file.ghiChu ?? 'Không có'}',
                                      style: const TextStyle(
                                        color: _mutedText,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  // Nút xem file luôn hiển thị
                                  IconButton(
                                    tooltip: 'Xem file',
                                    icon: isDownloading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.visibility_outlined,
                                            color: Colors.green,
                                          ),
                                    onPressed: isDownloading
                                        ? null
                                        : () => _downloadFile(file),
                                  ),
                                  // Nút Sửa & Xóa chỉ hiện khi có quyền
                                  if (widget.canEdit) ...[
                                    IconButton(
                                      tooltip: 'Chỉnh sửa',
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: _primary,
                                      ),
                                      onPressed: () => _editFileInfo(file),
                                    ),
                                    IconButton(
                                      tooltip: 'Xóa',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _deleteFile(file.idTaiLieuNhanVien),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
