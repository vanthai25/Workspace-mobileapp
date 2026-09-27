import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/nhan_vien_v2_models.dart';
import '../../../../providers/nhan_vien_v2_provider.dart';
import '../../../../screens/nhan_vien/nhan_vien_web_design.dart';
import 'widgets/searchable_dropdown_form_field.dart';

class HopDongFormDialog extends StatefulWidget {
  final String maSo;
  final HopDongLaoDongV2Model? item;

  const HopDongFormDialog({super.key, required this.maSo, this.item});

  bool get isEdit => item != null;

  @override
  State<HopDongFormDialog> createState() => _HopDongFormDialogState();
}

class _HopDongFormDialogState extends State<HopDongFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _soController;
  int? _idLoai;
  DateTime? _ngayKy;
  DateTime? _ngayKetThuc;
  int? _idFile;
  String? _fileName;
  fp.PlatformFile? _newFile;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _soController = TextEditingController(text: item?.soHopDong ?? '');
    _idLoai = item?.idLoaiHopDong;
    _ngayKy = item?.ngayKy;
    _ngayKetThuc = item?.ngayKetThuc;
    _idFile = item?.idFile;
    _fileName = item?.fileName;
  }

  @override
  void dispose() {
    _soController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NhanVienV2Provider>();
    final dm = provider.danhMuc!;
    final viewport = MediaQuery.sizeOf(context);
    final dialogHeight = viewport.height > 610 ? 610.0 : viewport.height - 32;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: NhanVienWebColors.surface,
      surfaceTintColor: NhanVienWebColors.surface,
      shadowColor: NhanVienWebColors.primaryDark.withValues(alpha: .18),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: 740,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(provider.isSaving),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSection(
                        icon: Icons.assignment_outlined,
                        title: 'Thông tin hợp đồng',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _soController,
                              decoration: _inputDecoration(
                                'Số hợp đồng *',
                                Icons.numbers_outlined,
                                hintText: 'Nhập số hợp đồng lao động',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập số hợp đồng';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            SearchableDropdownFormField<int?>(
                              initialValue: _idLoai,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                'Loại hợp đồng',
                                Icons.category_outlined,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Chưa chọn'),
                                ),
                                if (_idLoai != null &&
                                    !dm.loaiHopDongs.any(
                                      (e) => e.id == _idLoai,
                                    ))
                                  DropdownMenuItem(
                                    value: _idLoai,
                                    child: Text(
                                      widget.item?.tenLoaiHopDong ??
                                          'Danh mục cũ (#$_idLoai)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ...dm.loaiHopDongs
                                    .where(
                                      (e) => e.ksd != true || e.id == _idLoai,
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
                                setState(() => _idLoai = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSection(
                        icon: Icons.date_range_outlined,
                        title: 'Thời hạn hợp đồng',
                        child: _responsiveFields([
                          _dateField(
                            'Ngày ký',
                            _ngayKy,
                            (value) => setState(() => _ngayKy = value),
                            allowClear: true,
                          ),
                          _dateField(
                            'Ngày kết thúc',
                            _ngayKetThuc,
                            (value) => setState(() => _ngayKetThuc = value),
                            allowClear: true,
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      _buildSection(
                        icon: Icons.attach_file_outlined,
                        title: 'Tệp hợp đồng',
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

  Widget _buildHeader(bool isSaving) {
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
            child: Icon(Icons.handshake_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit
                      ? 'Sửa hợp đồng lao động'
                      : 'Thêm hợp đồng lao động',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thông tin loại hợp đồng, thời hạn và tệp văn bản',
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
        final useTwoColumns = constraints.maxWidth >= 520;
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
    Widget? suffixIcon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon,
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

  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> changed, {
    bool allowClear = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final result = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1990),
          lastDate: DateTime(2100),
        );

        if (result != null) changed(result);
      },
      child: InputDecorator(
        isEmpty: value == null,
        decoration: _inputDecoration(
          label,
          Icons.calendar_today_outlined,
          suffixIcon: allowClear && value != null
              ? IconButton(
                  tooltip: 'Xóa ngày',
                  onPressed: () => changed(null),
                  icon: const Icon(Icons.close, size: 18),
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: Text(value == null ? 'Chưa chọn' : _formatDate(value)),
      ),
    );
  }

  Widget _buildFileSelector(bool isSaving) {
    final colors = Theme.of(context).colorScheme;
    final selectedName = _newFile?.name ?? _fileName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final details = Row(
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _newFile == null
                        ? 'Giữ tệp hiện tại hoặc chọn tệp mới'
                        : 'Tệp mới sẽ được tải lên khi lưu',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final button = OutlinedButton.icon(
          onPressed: isSaving ? null : _pickFile,
          icon: const Icon(Icons.folder_open_outlined, size: 18),
          label: const Text('Chọn tệp'),
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [details, const SizedBox(height: 10), button],
                )
              : Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 12),
                    button,
                  ],
                ),
        );
      },
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

    if (result == null || result.files.isEmpty || !mounted) return;
    setState(() => _newFile = result.files.single);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ngayKy != null &&
        _ngayKetThuc != null &&
        _ngayKetThuc!.isBefore(_ngayKy!)) {
      _message('Ngày kết thúc không được nhỏ hơn ngày ký.');
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

    final data = <String, dynamic>{
      'soHopDong': _soController.text.trim(),
      'idLoaiHopDong': _idLoai,
      'ngayKy': _ngayKy?.toIso8601String(),
      'ngayKetThuc': _ngayKetThuc?.toIso8601String(),
      'idFile': fileId,
    };

    final bool ok;

    if (widget.isEdit) {
      ok = await provider.updateHopDong(
        widget.maSo,
        widget.item!.idHopDong,
        data,
      );
    } else {
      ok = await provider.createHopDong(widget.maSo, data);
    }

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      _message(provider.errorMessage ?? 'Không thể lưu hợp đồng.');
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
