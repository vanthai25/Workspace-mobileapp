import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../models/nhan_vien_tuyen_dung_v2_models.dart';
import '../../../../models/nhan_vien_v2_models.dart';
import '../../../../services/nhan_vien_tuyen_dung_service.dart';
import 'widgets/searchable_dropdown_form_field.dart';

class TuyenDungPreviewDialog extends StatefulWidget {
  final int idTuyenDung;

  final NhanVienTuyenDungService service;

  final NhanVienDanhMucV2Model danhMuc;

  const TuyenDungPreviewDialog({
    super.key,
    required this.idTuyenDung,
    required this.service,
    required this.danhMuc,
  });

  @override
  State<TuyenDungPreviewDialog> createState() => _TuyenDungPreviewDialogState();
}

class _TuyenDungPreviewDialogState extends State<TuyenDungPreviewDialog> {
  static const Color _primary = Color(0xFF1274BC);

  static const Color _border = Color(0xFFE3EAF2);

  static const Color _muted = Color(0xFF66788A);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  NhanVienTuyenDungPreviewV2Model? _preview;

  bool _loading = true;
  bool _saving = false;

  String? _errorMessage;
  bool _isImageFileName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }

    final lower = value.toLowerCase();

    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  String _fileNameFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return '';
    }

    try {
      final uri = Uri.parse(url.trim());

      if (uri.pathSegments.isEmpty) {
        return 'File từ tuyển dụng';
      }

      return Uri.decodeComponent(uri.pathSegments.last);
    } catch (_) {
      return 'File từ tuyển dụng';
    }
  }

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.service.getPreview(widget.idTuyenDung);

      // ========================================================
      // ẢNH ĐẠI DIỆN
      // ========================================================

      if (result.nhanVien.anhDaiDienUrl != null &&
          result.nhanVien.anhDaiDienUrl!.trim().isNotEmpty) {
        result.nhanVien.sourceAvatarBytes = await widget.service
            .getAnhDaiDienPreview(result.idTuyenDung);
      }

      // ========================================================
      // BẰNG CẤP
      // ========================================================

      for (final item in result.bangCaps) {
        if (item.fileUrl == null || item.fileUrl!.trim().isEmpty) {
          continue;
        }

        if (!_isImageFileName(_fileNameFromUrl(item.fileUrl))) {
          continue;
        }

        item.sourcePreviewBytes = await widget.service.getBangCapFilePreview(
          idTuyenDung: result.idTuyenDung,
          idBangCapTuyenDung: item.idBangCapTuyenDung,
        );
      }

      // ========================================================
      // CHỨNG CHỈ
      // ========================================================

      for (final item in result.chungChis) {
        if (item.fileUrl == null || item.fileUrl!.trim().isEmpty) {
          continue;
        }

        if (!_isImageFileName(_fileNameFromUrl(item.fileUrl))) {
          continue;
        }

        item.sourcePreviewBytes = await widget.service.getChungChiFilePreview(
          idTuyenDung: result.idTuyenDung,
          idChungChiTuyenDung: item.idChungChiTuyenDung,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _preview = result;
        _errorMessage = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Future<PlatformFile?> _pickFile({bool imageOnly = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: imageOnly
          ? ['jpg', 'jpeg', 'png', 'webp']
          : ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;

    if (file.bytes == null || file.bytes!.isEmpty) {
      _showMessage('Không đọc được nội dung file.', error: true);

      return null;
    }

    return file;
  }

  Future<void> _showFullImage({
    required Uint8List bytes,
    required String title,
  }) async {
    if (bytes.isEmpty || !mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF111111),
          insetPadding: const EdgeInsets.all(12),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: SizedBox(
            width: MediaQuery.sizeOf(dialogContext).width * .96,
            height: MediaQuery.sizeOf(dialogContext).height * .94,
            child: Column(
              children: [
                // ===============================================
                // HEADER
                // ===============================================
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0xFF1C1C1C),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined, color: Colors.white70),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const Text(
                        'Cuộn / kéo để xem chi tiết',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),

                      const SizedBox(width: 12),

                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // ===============================================
                // FULL IMAGE
                // ===============================================
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    child: InteractiveViewer(
                      minScale: 0.25,
                      maxScale: 8,
                      boundaryMargin: const EdgeInsets.all(300),
                      child: Center(
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // ==========================================================
  // SAVE
  // ==========================================================

  Future<void> _save() async {
    final preview = _preview;

    if (preview == null || _saving) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final missingFields = _missingRequiredEmployeeFields(preview.nhanVien);
    if (missingFields.isNotEmpty) {
      _showMessage(
        'Vui lòng nhập đầy đủ: ${missingFields.join(', ')}.',
        error: true,
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final maSo = await widget.service.importNhanVien(preview);

      if (!mounted) {
        return;
      }

      Navigator.pop(context, maSo);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(22),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SizedBox(
        width: size.width >= 1400 ? 1180 : size.width * .92,
        height: size.height * .9,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _preview == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Không tải được hồ sơ.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _errorMessage = null;
                });

                _load();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final preview = _preview!;

    return Column(
      children: [
        _header(preview),

        const Divider(height: 1),

        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (preview.canhBao.isNotEmpty) _warnings(preview),

                  _section(
                    title: 'Thông tin nhân viên',
                    icon: Icons.person_outline,
                    child: _employeeForm(preview),
                  ),

                  _section(
                    title: 'Bằng cấp (${preview.bangCaps.length})',
                    icon: Icons.school_outlined,
                    child: _bangCaps(preview),
                  ),

                  _section(
                    title: 'Chứng chỉ (${preview.chungChis.length})',
                    icon: Icons.workspace_premium_outlined,
                    child: _chungChis(preview),
                  ),

                  if (preview.cchn != null)
                    _section(
                      title: 'Chứng chỉ hành nghề',
                      icon: Icons.medical_information_outlined,
                      child: _cchn(preview),
                    ),
                ],
              ),
            ),
          ),
        ),

        const Divider(height: 1),

        _footer(),
      ],
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _header(NhanVienTuyenDungPreviewV2Model preview) {
    final nv = preview.nhanVien;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      color: Colors.white,
      child: Row(
        children: [
          _avatar(
            nv.anhDaiDienUrl,
            nv.hoVaTen,
            bytes: nv.replacementAvatarBytes,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nv.hoVaTen ?? 'Hồ sơ tuyển dụng',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172B3E),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Tuyển dụng #${preview.idTuyenDung}'
                  '${preview.tenDotTuyenDung != null ? ' • ${preview.tenDotTuyenDung}' : ''}',
                  style: const TextStyle(color: _muted, fontSize: 11.5),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Mã dự kiến: ${preview.maSoDuKien}',
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            onPressed: _saving
                ? null
                : () {
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPLOYEE
  // ==========================================================

  Widget _employeeForm(NhanVienTuyenDungPreviewV2Model preview) {
    final nv = preview.nhanVien;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 700;

        final width = twoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _textField(
                label: 'Mã nhân viên',
                initialValue: nv.maSo,
                requiredField: true,
                maxLength: 5,
                onChanged: (value) {
                  nv.maSo = value.trim();
                },
              ),
            ),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Họ và tên',
                initialValue: nv.hoVaTen,
                requiredField: true,
                maxLength: 250,
                onChanged: (value) {
                  nv.hoVaTen = value;
                },
              ),
            ),

            SizedBox(
              width: width,
              child: _dateField(
                label: 'Ngày sinh',
                value: nv.namSinh,
                requiredField: true,
                onChanged: (value) {
                  setState(() {
                    nv.namSinh = value;
                  });
                },
              ),
            ),

            SizedBox(
              width: width,
              child: SearchableDropdownFormField<bool?>(
                initialValue: nv.gioiTinh,
                decoration: _decoration('Giới tính *'),
                items: const [
                  DropdownMenuItem<bool?>(value: true, child: Text('Nam')),
                  DropdownMenuItem<bool?>(value: false, child: Text('Nữ')),
                ],
                onChanged: (value) {
                  nv.gioiTinh = value;
                },
                validator: (value) =>
                    value == null ? 'Vui lòng chọn Giới tính' : null,
              ),
            ),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Số CCCD',
                initialValue: nv.soCCCD,
                requiredField: true,
                maxLength: 15,
                onChanged: (v) => nv.soCCCD = v,
              ),
            ),

            SizedBox(
              width: width,
              child: _dateField(
                label: 'Ngày cấp CCCD',
                value: nv.ngayCapCCCD,
                requiredField: true,
                onChanged: (value) {
                  setState(() {
                    nv.ngayCapCCCD = value;
                  });
                },
              ),
            ),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Nơi cấp CCCD',
                initialValue: nv.noiCapCCCD,
                requiredField: true,
                maxLength: 250,
                onChanged: (v) => nv.noiCapCCCD = v,
              ),
            ),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Số điện thoại',
                initialValue: nv.soDienThoai,
                requiredField: true,
                maxLength: 20,
                onChanged: (v) => nv.soDienThoai = v,
              ),
            ),

            SizedBox(
              width: width,
              child: _dropdownDanhMuc(
                label: 'Tôn giáo',
                value: nv.idTonGiao,
                items: widget.danhMuc.tonGiaos,
                onChanged: (value) {
                  nv.idTonGiao = value;
                },
              ),
            ),

            SizedBox(
              width: width,
              child: _dropdownDanhMuc(
                label: 'Tình trạng hôn nhân',
                value: nv.idTinhTrangHonNhan,
                items: widget.danhMuc.tinhTrangHonNhans,
                onChanged: (value) {
                  nv.idTinhTrangHonNhan = value;
                },
              ),
            ),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Dân tộc',
                initialValue: nv.danToc,
                maxLength: 20,
                onChanged: (v) => nv.danToc = v,
              ),
            ),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Nơi sinh',
                initialValue: nv.noiSinh,
                maxLength: 250,
                onChanged: (v) => nv.noiSinh = v,
              ),
            ),

            SizedBox(
              width: constraints.maxWidth,
              child: _textField(
                label: 'Quê quán',
                initialValue: nv.queQuan,
                requiredField: true,
                maxLength: 250,
                onChanged: (v) => nv.queQuan = v,
              ),
            ),

            SizedBox(
              width: constraints.maxWidth,
              child: _textField(
                label: 'Địa chỉ thường trú',
                initialValue: nv.diaChiThuongTru,
                requiredField: true,
                maxLength: 250,
                onChanged: (v) => nv.diaChiThuongTru = v,
              ),
            ),

            SizedBox(
              width: constraints.maxWidth,
              child: _textField(
                label: 'Nơi ở hiện tại',
                initialValue: nv.noiOHienTai,
                maxLength: 250,
                onChanged: (v) => nv.noiOHienTai = v,
              ),
            ),

            SizedBox(width: constraints.maxWidth, child: _avatarEditor(nv)),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Số BHXH',
                initialValue: nv.soBHXH,
                maxLength: 20,
                onChanged: (v) => nv.soBHXH = v,
              ),
            ),

            SizedBox(
              width: width,
              child: _dropdownDanhMuc(
                label: 'Loại nhân viên',
                value: nv.loaiNhanVien,
                items: widget.danhMuc.loaiNhanViens,
                requiredField: true,
                onChanged: (value) => nv.loaiNhanVien = value,
              ),
            ),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Số tài khoản',
                initialValue: nv.taiKhoanNH,
                maxLength: 50,
                onChanged: (v) => nv.taiKhoanNH = v,
              ),
            ),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Tên tài khoản',
                initialValue: nv.tenTaiKhoanNH,
                maxLength: 50,
                onChanged: (v) => nv.tenTaiKhoanNH = v,
              ),
            ),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Ngân hàng',
                initialValue: nv.tenNH,
                maxLength: 100,
                onChanged: (v) => nv.tenNH = v,
              ),
            ),

            SizedBox(
              width: width,
              child: _textField(
                label: 'Mã BN Minh Lộ',
                initialValue: nv.maBNMinhLo,
                maxLength: 10,
                onChanged: (v) => nv.maBNMinhLo = v,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _avatarEditor(NhanVienTuyenDungNhanVienDraftV2Model nv) {
    final replacementBytes = nv.replacementAvatarBytes;

    final sourceUrl = nv.anhDaiDienUrl;
    final sourceBytes = nv.sourceAvatarBytes;
    final Uint8List? currentBytes = replacementBytes ?? sourceBytes;
    Widget preview;

    if (replacementBytes != null && replacementBytes.isNotEmpty) {
      preview = Image.memory(replacementBytes, fit: BoxFit.cover);
    } else if (sourceBytes != null && sourceBytes.isNotEmpty) {
      preview = Image.memory(sourceBytes, fit: BoxFit.cover);
    } else {
      preview = const Center(
        child: Icon(Icons.person_outline, size: 48, color: _muted),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: currentBytes == null
                ? null
                : () {
                    _showFullImage(
                      bytes: currentBytes,
                      title:
                          nv.replacementAvatarFileName ??
                          'Ảnh đại diện ${nv.hoVaTen ?? ''}',
                    );
                  },
            child: Container(
              width: 170,
              height: 200,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  preview,

                  if (currentBytes != null)
                    Positioned(
                      right: 7,
                      bottom: 7,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ảnh đại diện',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 6),

                Text(
                  nv.replacementAvatarFileName ??
                      (sourceUrl != null
                          ? 'Ảnh từ hồ sơ tuyển dụng'
                          : 'Chưa có ảnh'),
                  style: const TextStyle(color: _muted, fontSize: 11.5),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // =======================================================
                    // XEM ẢNH LỚN
                    // =======================================================
                    if (currentBytes != null && currentBytes.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () {
                          _showFullImage(
                            bytes: currentBytes,
                            title:
                                nv.replacementAvatarFileName ??
                                'Ảnh đại diện ${nv.hoVaTen ?? ''}',
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.fullscreen_rounded, size: 18),
                        label: const Text('Fullscreen'),
                      ),

                    // =======================================================
                    // CHỌN ẢNH KHÁC
                    // =======================================================
                    OutlinedButton.icon(
                      onPressed: () async {
                        final file = await _pickFile(imageOnly: true);

                        if (file == null || !mounted) {
                          return;
                        }

                        setState(() {
                          nv.replacementAvatarBytes = file.bytes;

                          nv.replacementAvatarFileName = file.name;
                        });
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Chọn ảnh khác'),
                    ),

                    // =======================================================
                    // BỎ ẢNH
                    // =======================================================
                    if (sourceUrl != null || replacementBytes != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            nv.anhDaiDienUrl = null;

                            nv.sourceAvatarBytes = null;

                            nv.replacementAvatarBytes = null;

                            nv.replacementAvatarFileName = null;
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Bỏ ảnh'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceFileEditor({
    required String title,
    required String? sourceUrl,
    required Uint8List? sourcePreviewBytes,
    required Uint8List? replacementBytes,
    required String? replacementFileName,
    required Future<void> Function() onPick,
    required VoidCallback onRemove,
  }) {
    final sourceFileName = _fileNameFromUrl(sourceUrl);

    final currentName =
        replacementFileName ??
        (sourceFileName.isNotEmpty ? sourceFileName : null);

    // File hiện tại user đang nhìn thấy:
    // ưu tiên file mới nếu đã chọn lại.
    final Uint8List? currentBytes = replacementBytes ?? sourcePreviewBytes;

    final bool isImage =
        currentBytes != null &&
        currentBytes.isNotEmpty &&
        _isImageFileName(currentName);

    final bool hasFile =
        replacementBytes != null ||
        sourcePreviewBytes != null ||
        (sourceUrl != null && sourceUrl.trim().isNotEmpty);

    return Container(
      width: 620,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),

              if (replacementBytes != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F5EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'File mới',
                    style: TextStyle(
                      color: Color(0xFF19734B),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ===============================================
          // KHÔNG CÓ FILE
          // ===============================================
          if (!hasFile)
            Container(
              height: 100,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 32,
                    color: _muted,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Không có file',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),

          // ===============================================
          // PREVIEW ẢNH
          // ===============================================
          if (isImage)
            InkWell(
              onTap: () {
                _showFullImage(
                  bytes: currentBytes,
                  title: currentName ?? title,
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 320,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      currentBytes,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),

                    // Overlay nhỏ báo có thể click
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .68),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Bấm để xem lớn',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ===============================================
          // FILE NAME
          // ===============================================
          if (hasFile)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Icon(
                    isImage ? Icons.image_outlined : Icons.description_outlined,
                    color: _primary,
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      currentName ?? 'File từ hồ sơ tuyển dụng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF304A5F),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // ===============================================
          // ACTION
          // ===============================================
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isImage)
                FilledButton.icon(
                  onPressed: () {
                    _showFullImage(
                      bytes: currentBytes,
                      title: currentName ?? title,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.fullscreen_rounded, size: 18),
                  label: const Text('Fullscreen'),
                ),

              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(hasFile ? 'Thay file' : 'Chọn file'),
              ),

              if (hasFile)
                TextButton.icon(
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC43C35),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Bỏ file'),
                ),
            ],
          ),
        ],
      ),
    );
  }
  // ==========================================================
  // BANG CAP
  // ==========================================================

  Widget _bangCaps(NhanVienTuyenDungPreviewV2Model preview) {
    if (preview.bangCaps.isEmpty) {
      return _empty('Không có bằng cấp.');
    }

    return Column(
      children: List.generate(preview.bangCaps.length, (index) {
        final item = preview.bangCaps[index];

        return KeyedSubtree(
          key: ValueKey('bangcap_${item.idBangCapTuyenDung}'),
          child: _editableCard(
            title: item.tenBangCap ?? 'Bằng cấp',
            onDelete: () {
              setState(() {
                preview.bangCaps.removeAt(index);
              });
            },
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 310,
                  child: _textField(
                    label: 'Tên bằng cấp',
                    initialValue: item.tenBangCap,
                    requiredField: true,
                    maxLength: 250,
                    onChanged: (v) => item.tenBangCap = v,
                  ),
                ),

                SizedBox(
                  width: 250,
                  child: _dropdownDanhMuc(
                    label: 'Trình độ',
                    value: item.idTrinhDo,
                    items: widget.danhMuc.trinhDos,
                    onChanged: (v) => item.idTrinhDo = v,
                  ),
                ),

                SizedBox(
                  width: 310,
                  child: _textField(
                    label: 'Đơn vị đào tạo',
                    initialValue: item.donViDaoTao,
                    maxLength: 50,
                    onChanged: (v) => item.donViDaoTao = v,
                  ),
                ),

                SizedBox(
                  width: 250,
                  child: _dropdownDanhMuc(
                    label: 'Hình thức đào tạo',
                    value: item.idHinhThucDaoTao,
                    items: widget.danhMuc.hinhThucDaoTaos,
                    onChanged: (v) => item.idHinhThucDaoTao = v,
                  ),
                ),

                SizedBox(
                  width: 200,
                  child: _textField(
                    label: 'Năm tốt nghiệp',
                    initialValue: item.namTotNghiep,
                    maxLength: 10,
                    onChanged: (v) => item.namTotNghiep = v,
                  ),
                ),

                SizedBox(
                  width: 250,
                  child: _dropdownDanhMuc(
                    label: 'Xếp loại',
                    value: item.idXepLoaiDaoTao,
                    items: widget.danhMuc.xepLoaiDaoTaos,
                    onChanged: (v) => item.idXepLoaiDaoTao = v,
                  ),
                ),

                _sourceFileEditor(
                  title: 'File bằng cấp',
                  sourceUrl: item.fileUrl,
                  sourcePreviewBytes: item.sourcePreviewBytes,
                  replacementBytes: item.replacementFileBytes,
                  replacementFileName: item.replacementFileName,
                  onPick: () async {
                    final file = await _pickFile();

                    if (file == null || !mounted) {
                      return;
                    }

                    setState(() {
                      item.replacementFileBytes = file.bytes;

                      item.replacementFileName = file.name;
                    });
                  },
                  onRemove: () {
                    setState(() {
                      item.fileUrl = null;
                      item.sourcePreviewBytes = null;
                      item.replacementFileBytes = null;

                      item.replacementFileName = null;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ==========================================================
  // CHUNG CHI
  // ==========================================================

  Widget _chungChis(NhanVienTuyenDungPreviewV2Model preview) {
    if (preview.chungChis.isEmpty) {
      return _empty('Không có chứng chỉ.');
    }

    return Column(
      children: List.generate(preview.chungChis.length, (index) {
        final item = preview.chungChis[index];

        return KeyedSubtree(
          key: ValueKey('chungchi_${item.idChungChiTuyenDung}'),
          child: _editableCard(
            title: item.tenChungChi ?? 'Chứng chỉ',
            onDelete: () {
              setState(() {
                preview.chungChis.removeAt(index);
              });
            },
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 320,
                  child: _textField(
                    label: 'Tên chứng chỉ',
                    initialValue: item.tenChungChi,
                    maxLength: 300,
                    onChanged: (v) => item.tenChungChi = v,
                  ),
                ),

                SizedBox(
                  width: 230,
                  child: _textField(
                    label: 'Số chứng chỉ',
                    initialValue: item.soChungChi,
                    maxLength: 50,
                    onChanged: (v) => item.soChungChi = v,
                  ),
                ),

                SizedBox(
                  width: 300,
                  child: _textField(
                    label: 'Đơn vị đào tạo',
                    initialValue: item.donViDaoTao,
                    maxLength: 200,
                    onChanged: (v) => item.donViDaoTao = v,
                  ),
                ),

                SizedBox(
                  width: 260,
                  child: _dropdownDanhMuc(
                    label: 'Hình thức đào tạo',
                    value: item.idHinhThucDaoTao,
                    items: widget.danhMuc.hinhThucDaoTaos,
                    onChanged: (v) => item.idHinhThucDaoTao = v,
                  ),
                ),

                SizedBox(
                  width: 200,
                  child: _textField(
                    label: 'Số tiết',
                    initialValue: item.soTiet?.toString(),
                    number: true,
                    onChanged: (v) => item.soTiet = double.tryParse(
                      v.replaceAll(',', '.').trim(),
                    ),
                  ),
                ),

                SizedBox(
                  width: 220,
                  child: _dateField(
                    label: 'Ngày bắt đầu',
                    value: item.ngayBatDau,
                    onChanged: (v) {
                      setState(() {
                        item.ngayBatDau = v;
                      });
                    },
                  ),
                ),

                SizedBox(
                  width: 220,
                  child: _dateField(
                    label: 'Ngày kết thúc',
                    value: item.ngayKetThuc,
                    onChanged: (v) {
                      setState(() {
                        item.ngayKetThuc = v;
                      });
                    },
                  ),
                ),

                SizedBox(
                  width: 220,
                  child: _dateField(
                    label: 'Ngày cấp',
                    value: item.ngayCap,
                    onChanged: (v) {
                      setState(() {
                        item.ngayCap = v;
                      });
                    },
                  ),
                ),

                SizedBox(
                  width: 220,
                  child: _dateField(
                    label: 'Ngày hết hạn',
                    value: item.ngayHetHan,
                    onChanged: (v) {
                      setState(() {
                        item.ngayHetHan = v;
                      });
                    },
                  ),
                ),

                SizedBox(
                  width: 170,
                  child: _textField(
                    label: 'Chu kỳ',
                    initialValue: item.chuKy?.toString(),
                    number: true,
                    onChanged: (v) => item.chuKy = int.tryParse(v.trim()),
                  ),
                ),

                SizedBox(
                  width: 180,
                  child: CheckboxListTile(
                    value: item.cme ?? false,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('CME'),
                    onChanged: (v) {
                      setState(() {
                        item.cme = v;
                      });
                    },
                  ),
                ),

                _sourceFileEditor(
                  title: 'File chứng chỉ',
                  sourceUrl: item.fileUrl,
                  sourcePreviewBytes: item.sourcePreviewBytes,
                  replacementBytes: item.replacementFileBytes,
                  replacementFileName: item.replacementFileName,
                  onPick: () async {
                    final file = await _pickFile();

                    if (file == null || !mounted) {
                      return;
                    }

                    setState(() {
                      item.replacementFileBytes = file.bytes;

                      item.replacementFileName = file.name;
                    });
                  },
                  onRemove: () {
                    setState(() {
                      item.fileUrl = null;
                      item.sourcePreviewBytes = null;
                      item.replacementFileBytes = null;

                      item.replacementFileName = null;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ==========================================================
  // CCHN
  // ==========================================================

  Widget _cchn(NhanVienTuyenDungPreviewV2Model preview) {
    final item = preview.cchn!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                preview.cchn = null;
              });
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa CCHN khỏi dữ liệu import'),
          ),
        ),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 260,
              child: _textField(
                label: 'Số CCHN/GPHN',
                initialValue: item.soCchn,
                maxLength: 20,
                onChanged: (v) => item.soCchn = v,
              ),
            ),

            SizedBox(
              width: 320,
              child: _textField(
                label: 'Nơi cấp',
                initialValue: item.noiCap,
                maxLength: 50,
                onChanged: (v) => item.noiCap = v,
              ),
            ),

            SizedBox(
              width: 220,
              child: _dateField(
                label: 'Ngày cấp GPHN',
                value: item.ngayCapGphn,
                onChanged: (v) {
                  setState(() {
                    item.ngayCapGphn = v;
                  });
                },
              ),
            ),

            SizedBox(
              width: 220,
              child: _dateField(
                label: 'Ngày bắt đầu hiệu lực',
                value: item.ngayBatDau,
                onChanged: (v) {
                  setState(() {
                    item.ngayBatDau = v;
                  });
                },
              ),
            ),

            SizedBox(
              width: 220,
              child: _dateField(
                label: 'Ngày kết thúc',
                value: item.ngayKetThuc,
                onChanged: (v) {
                  setState(() {
                    item.ngayKetThuc = v;
                  });
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: _textField(
                label: 'Văn bằng chuyên môn',
                initialValue: item.vanBangChuyenMon,
                maxLines: 3,
                onChanged: (v) => item.vanBangChuyenMon = v,
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: _textField(
                label: 'Phạm vi hoạt động',
                initialValue: item.phamViHoatDong,
                maxLines: 4,
                onChanged: (v) => item.phamViHoatDong = v,
              ),
            ),

            SizedBox(
              width: 240,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: item.isPhamViBoSung ?? false,
                title: const Text('Phạm vi bổ sung'),
                onChanged: (v) {
                  setState(() {
                    item.isPhamViBoSung = v;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // COMMON UI
  // ==========================================================

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: _primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _editableCard({
    required String title,
    required Widget child,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

              IconButton(
                tooltip: 'Xóa',
                onPressed: onDelete,
                color: const Color(0xFFC43C35),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),

          const SizedBox(height: 8),

          child,
        ],
      ),
    );
  }

  Widget _warnings(NhanVienTuyenDungPreviewV2Model preview) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD59A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cảnh báo dữ liệu',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF8A5600),
            ),
          ),

          const SizedBox(height: 6),

          ...preview.canhBao.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('• $e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    String? initialValue,
    required ValueChanged<String> onChanged,
    bool requiredField = false,
    int? maxLength,
    int maxLines = 1,
    bool number = false,
    bool integer = false,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      keyboardType: integer
          ? TextInputType.number
          : number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: _decoration(requiredField ? '$label *' : label),
      onChanged: onChanged,
      validator: (value) {
        final text = value?.trim() ?? '';

        if (requiredField && text.isEmpty) {
          return 'Vui lòng nhập $label';
        }

        if (maxLength != null && text.length > maxLength) {
          return 'Tối đa $maxLength ký tự';
        }

        if (integer && text.isNotEmpty && int.tryParse(text) == null) {
          return '$label phải là số nguyên';
        }

        return null;
      },
    );
  }

  Widget _dropdownDanhMuc({
    required String label,
    required int? value,
    required List<NhanVienDanhMucItemV2Model> items,
    required ValueChanged<int?> onChanged,
    bool requiredField = false,
  }) {
    final bool valueExists = value == null || items.any((e) => e.id == value);

    return SearchableDropdownFormField<int?>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(requiredField ? '$label *' : label),
      items: [
        if (!requiredField)
          const DropdownMenuItem<int?>(value: null, child: Text('Không chọn')),

        if (!valueExists)
          DropdownMenuItem<int?>(
            value: value,
            child: Text(
              'ID $value - Không còn trong danh mục',
              overflow: TextOverflow.ellipsis,
            ),
          ),

        ...items.map(
          (e) => DropdownMenuItem<int?>(
            value: e.id,
            child: Text(e.ten ?? 'ID ${e.id}', overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
      validator: (selected) =>
          requiredField && selected == null ? 'Vui lòng chọn $label' : null,
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    bool requiredField = false,
  }) {
    return FormField<DateTime>(
      initialValue: value,
      validator: (selected) =>
          requiredField && selected == null ? 'Vui lòng chọn $label' : null,
      builder: (field) => InkWell(
        onTap: () async {
          final selected = await showDatePicker(
            context: context,
            initialDate: field.value ?? DateTime.now(),
            firstDate: DateTime(1940),
            lastDate: DateTime(2100),
          );

          if (selected != null) {
            field.didChange(selected);
            onChanged(selected);
          }
        },
        child: InputDecorator(
          decoration: _decoration(
            requiredField ? '$label *' : label,
          ).copyWith(errorText: field.errorText),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  field.value == null ? 'Chưa chọn' : _formatDate(field.value!),
                  style: TextStyle(
                    color: field.value == null ? _muted : Colors.black87,
                  ),
                ),
              ),

              if (field.value != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Xóa ngày',
                  onPressed: () {
                    field.didChange(null);
                    onChanged(null);
                  },
                  icon: const Icon(Icons.close, size: 17),
                ),

              const Icon(Icons.calendar_month_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _missingRequiredEmployeeFields(
    NhanVienTuyenDungNhanVienDraftV2Model employee,
  ) {
    bool isBlank(String? value) => value == null || value.trim().isEmpty;

    return <(String, bool)>[
      ('Mã nhân viên', isBlank(employee.maSo)),
      ('Họ và tên', isBlank(employee.hoVaTen)),
      ('Ngày sinh', employee.namSinh == null),
      ('Giới tính', employee.gioiTinh == null),
      ('Số CCCD', isBlank(employee.soCCCD)),
      ('Ngày cấp CCCD', employee.ngayCapCCCD == null),
      ('Nơi cấp CCCD', isBlank(employee.noiCapCCCD)),
      ('Số điện thoại', isBlank(employee.soDienThoai)),
      ('Quê quán', isBlank(employee.queQuan)),
      ('Địa chỉ thường trú', isBlank(employee.diaChiThuongTru)),
      ('Loại nhân viên', employee.loaiNhanVien == null),
    ].where((entry) => entry.$2).map((entry) => entry.$1).toList();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Center(
        child: Text(text, style: const TextStyle(color: _muted)),
      ),
    );
  }

  Widget _avatar(String? url, String? name, {Uint8List? bytes}) {
    final String? normalizedUrl = url?.trim();

    final Uri? uri = normalizedUrl == null || normalizedUrl.isEmpty
        ? null
        : Uri.tryParse(normalizedUrl);

    final bool validUrl =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    ImageProvider? imageProvider;

    if (bytes != null && bytes.isNotEmpty) {
      imageProvider = MemoryImage(bytes);
    } else if (validUrl) {
      imageProvider = NetworkImage(normalizedUrl!);
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFFDCEFF9),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              _initials(name),
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: const Color(0xFFFAFCFE),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Kiểm tra kỹ thông tin trước khi tạo nhân viên.',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),

          TextButton(
            onPressed: _saving
                ? null
                : () {
                    Navigator.pop(context);
                  },
            child: const Text('Hủy'),
          ),

          const SizedBox(width: 8),

          FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: _primary),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_add_alt_1),
            label: Text(_saving ? 'Đang tạo...' : 'Tạo nhân viên'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: error ? Colors.red : null),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '?';
    }

    final list = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (list.length == 1) {
      return list.first[0].toUpperCase();
    }

    return '${list.first[0]}${list.last[0]}'.toUpperCase();
  }
}
