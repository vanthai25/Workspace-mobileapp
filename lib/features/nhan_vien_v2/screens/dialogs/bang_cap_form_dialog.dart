import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/nhan_vien_v2_models.dart';
import '../../../../providers/nhan_vien_v2_provider.dart';
import '../../../../screens/nhan_vien/nhan_vien_web_design.dart';
import 'widgets/searchable_dropdown_form_field.dart';

class BangCapFormDialog extends StatefulWidget {
  final String maSo;
  final BangCapV2Model? item;

  const BangCapFormDialog({super.key, required this.maSo, this.item});

  bool get isEdit => item != null;

  @override
  State<BangCapFormDialog> createState() => _BangCapFormDialogState();
}

class _BangCapFormDialogState extends State<BangCapFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tenController;
  late final TextEditingController _donViController;
  late final TextEditingController _namController;

  int? _idTrinhDo;
  int? _idHinhThuc;
  int? _idXepLoai;
  int? _idFile;
  String? _fileName;
  fp.PlatformFile? _newFile;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _tenController = TextEditingController(text: item?.tenBangCap ?? '');
    _donViController = TextEditingController(text: item?.donViDaoTao ?? '');
    _namController = TextEditingController(text: item?.namTotNghiep ?? '');
    _idTrinhDo = item?.idTrinhDo;
    _idHinhThuc = item?.idHinhThucDaoTao;
    _idXepLoai = item?.idXepLoaiDaoTao;
    _idFile = item?.idFile;
    _fileName = item?.fileName;
  }

  @override
  void dispose() {
    _tenController.dispose();
    _donViController.dispose();
    _namController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NhanVienV2Provider>();
    final dm = provider.danhMuc!;
    final viewport = MediaQuery.sizeOf(context);
    final dialogHeight = viewport.height > 620 ? 620.0 : viewport.height - 32;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: NhanVienWebColors.surface,
      surfaceTintColor: NhanVienWebColors.surface,
      shadowColor: NhanVienWebColors.primaryDark.withValues(alpha: .18),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: 760,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(
              icon: Icons.school_outlined,
              title: widget.isEdit ? 'Sửa bằng cấp' : 'Thêm bằng cấp',
              subtitle: 'Cập nhật thông tin đào tạo và văn bằng của nhân viên',
              isSaving: provider.isSaving,
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Thông tin bằng cấp',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _tenController,
                              decoration: _inputDecoration(
                                'Tên bằng cấp *',
                                Icons.badge_outlined,
                                hintText: 'Ví dụ: Bác sĩ đa khoa',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tên bằng cấp';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _responsiveFields([
                              SearchableDropdownFormField<int?>(
                                initialValue: _idTrinhDo,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  'Trình độ',
                                  Icons.trending_up_outlined,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Chưa chọn'),
                                  ),
                                  if (_idTrinhDo != null &&
                                      !dm.trinhDos.any(
                                        (e) => e.id == _idTrinhDo,
                                      ))
                                    DropdownMenuItem(
                                      value: _idTrinhDo,
                                      child: Text(
                                        widget.item?.tenTrinhDo ??
                                            'Danh mục cũ (#$_idTrinhDo)',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ...dm.trinhDos
                                      .where(
                                        (e) =>
                                            e.ksd != true || e.id == _idTrinhDo,
                                      )
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e.id,
                                          child: Text(
                                            e.ksd == true
                                                ? '${e.ten ?? ''} (ngừng sử dụng)'
                                                : e.ten ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                ],
                                onChanged: (value) {
                                  setState(() => _idTrinhDo = value);
                                },
                              ),
                              SearchableDropdownFormField<int?>(
                                initialValue: _idHinhThuc,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  'Hình thức đào tạo',
                                  Icons.menu_book_outlined,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Chưa chọn'),
                                  ),
                                  if (_idHinhThuc != null &&
                                      !dm.hinhThucDaoTaos.any(
                                        (e) => e.id == _idHinhThuc,
                                      ))
                                    DropdownMenuItem(
                                      value: _idHinhThuc,
                                      child: Text(
                                        widget.item?.tenHinhThucDaoTao ??
                                            'Danh mục cũ (#$_idHinhThuc)',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ...dm.hinhThucDaoTaos
                                      .where(
                                        (e) =>
                                            e.ksd != true ||
                                            e.id == _idHinhThuc,
                                      )
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e.id,
                                          child: Text(
                                            e.ksd == true
                                                ? '${e.ten ?? ''} (ngừng sử dụng)'
                                                : e.ten ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                ],
                                onChanged: (value) {
                                  setState(() => _idHinhThuc = value);
                                },
                              ),
                              TextFormField(
                                controller: _donViController,
                                decoration: _inputDecoration(
                                  'Đơn vị đào tạo',
                                  Icons.account_balance_outlined,
                                ),
                              ),
                              TextFormField(
                                controller: _namController,
                                decoration: _inputDecoration(
                                  'Năm tốt nghiệp',
                                  Icons.event_outlined,
                                  hintText: 'Ví dụ: 2024',
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            SearchableDropdownFormField<int?>(
                              initialValue: _idXepLoai,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                'Xếp loại',
                                Icons.military_tech_outlined,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Chưa chọn'),
                                ),
                                if (_idXepLoai != null &&
                                    !dm.xepLoaiDaoTaos.any(
                                      (e) => e.id == _idXepLoai,
                                    ))
                                  DropdownMenuItem(
                                    value: _idXepLoai,
                                    child: Text(
                                      widget.item?.tenXepLoaiDaoTao ??
                                          'Danh mục cũ (#$_idXepLoai)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ...dm.xepLoaiDaoTaos
                                    .where(
                                      (e) =>
                                          e.ksd != true || e.id == _idXepLoai,
                                    )
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.id,
                                        child: Text(
                                          e.ksd == true
                                              ? '${e.ten ?? ''} (ngừng sử dụng)'
                                              : e.ten ?? '',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                              ],
                              onChanged: (value) {
                                setState(() => _idXepLoai = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSection(
                        icon: Icons.attach_file_outlined,
                        title: 'Tệp đính kèm',
                        child: _buildFileSelector(provider.isSaving),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            _buildFooter(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSaving,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2999D7), NhanVienWebColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: isSaving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _responsiveFields(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 560;
        final fieldWidth = useTwoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: fieldWidth, child: child))
              .toList(),
        );
      },
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hintText,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
    );
  }

  Widget _buildFileSelector(bool isSaving) {
    final colors = Theme.of(context).colorScheme;
    final selectedName = _newFile?.name ?? _fileName;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              selectedName == null
                  ? Icons.upload_file_outlined
                  : Icons.description_outlined,
              color: colors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedName ?? 'Chưa có tệp đính kèm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _newFile == null
                      ? 'Có thể giữ tệp hiện tại hoặc chọn tệp mới'
                      : 'Tệp mới sẽ được tải lên khi lưu',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: isSaving ? null : _pickFile,
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            label: const Text('Chọn tệp'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(NhanVienV2Provider provider) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      color: colors.surfaceContainerLowest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: provider.isSaving ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: provider.isSaving ? null : _save,
            icon: provider.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(provider.isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    setState(() => _newFile = result.files.single);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<NhanVienV2Provider>();
    int? fileId = _idFile;

    if (_newFile != null) {
      final bytes = _newFile!.bytes;

      if (bytes == null || bytes.isEmpty) {
        _message('Không đọc được dữ liệu file.');
        return;
      }

      try {
        final uploaded = await provider.uploadFile(
          bytes: bytes,
          fileName: _newFile!.name,
        );
        fileId = uploaded.idFile;
      } catch (e) {
        if (!mounted) return;
        _message('Upload file thất bại: $e');
        return;
      }
    }

    String? text(String value) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }

    final data = <String, dynamic>{
      'tenBangCap': _tenController.text.trim(),
      'idTrinhDo': _idTrinhDo,
      'donViDaoTao': text(_donViController.text),
      'idHinhThucDaoTao': _idHinhThuc,
      'namTotNghiep': text(_namController.text),
      'idXepLoaiDaoTao': _idXepLoai,
      'idFile': fileId,
    };

    final bool ok;

    if (widget.isEdit) {
      ok = await provider.updateBangCap(
        widget.maSo,
        widget.item!.idBangCap,
        data,
      );
    } else {
      ok = await provider.createBangCap(widget.maSo, data);
    }

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      _message(provider.errorMessage ?? 'Không thể lưu bằng cấp.');
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
