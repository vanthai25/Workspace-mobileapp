import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/nhan_vien_v2_models.dart';
import '../../../../providers/nhan_vien_v2_provider.dart';
import '../../../../screens/nhan_vien/nhan_vien_web_design.dart';

class CchnFormDialog extends StatefulWidget {
  final String maSo;
  final CchnV2Model? item;

  const CchnFormDialog({super.key, required this.maSo, this.item});

  bool get isEdit => item != null;

  @override
  State<CchnFormDialog> createState() => _CchnFormDialogState();
}

class _CchnFormDialogState extends State<CchnFormDialog> {
  late final TextEditingController _soController;
  late final TextEditingController _noiCapController;
  late final TextEditingController _vanBangController;
  late final TextEditingController _phamViController;

  DateTime? _batDau;
  DateTime? _ketThuc;
  bool _isBoSung = false;
  int? _idFile;
  String? _fileName;
  fp.PlatformFile? _newFile;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _soController = TextEditingController(text: item?.soCchn ?? '');
    _noiCapController = TextEditingController(text: item?.noiCap ?? '');
    _vanBangController = TextEditingController(
      text: item?.vanBangChuyenMon ?? '',
    );
    _phamViController = TextEditingController(text: item?.phamViHoatDong ?? '');
    _batDau = item?.ngayBatDau;
    _ketThuc = item?.ngayKetThuc;
    _isBoSung = item?.isPhamViBoSung == true;
    _idFile = item?.idFile;
    _fileName = item?.fileName;
  }

  @override
  void dispose() {
    _soController.dispose();
    _noiCapController.dispose();
    _vanBangController.dispose();
    _phamViController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NhanVienV2Provider>();
    final viewport = MediaQuery.sizeOf(context);
    final dialogHeight = viewport.height > 730 ? 730.0 : viewport.height - 32;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: NhanVienWebColors.surface,
      surfaceTintColor: NhanVienWebColors.surface,
      shadowColor: NhanVienWebColors.primaryDark.withValues(alpha: .18),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: 780,
        height: dialogHeight,
        child: Column(
          children: [
            _buildHeader(provider.isSaving),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSection(
                      icon: Icons.medical_information_outlined,
                      title: 'Thông tin chứng chỉ hành nghề',
                      child: _responsiveFields([
                        TextFormField(
                          controller: _soController,
                          decoration: _inputDecoration(
                            'Số CCHN',
                            Icons.numbers_outlined,
                          ),
                        ),
                        TextFormField(
                          controller: _noiCapController,
                          decoration: _inputDecoration(
                            'Nơi cấp',
                            Icons.account_balance_outlined,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      icon: Icons.description_outlined,
                      title: 'Phạm vi chuyên môn',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _vanBangController,
                            minLines: 2,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              'Văn bằng chuyên môn',
                              Icons.school_outlined,
                              hintText: 'Nhập văn bằng chuyên môn được cấp',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phamViController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: _inputDecoration(
                              'Phạm vi hoạt động',
                              Icons.fact_check_outlined,
                              hintText: 'Mô tả phạm vi hoạt động chuyên môn',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildSupplementSwitch(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      icon: Icons.event_available_outlined,
                      title: 'Thời hạn hiệu lực',
                      child: _responsiveFields([
                        _dateField(
                          'Ngày bắt đầu',
                          _batDau,
                          (value) => setState(() => _batDau = value),
                        ),
                        _dateField(
                          'Ngày kết thúc',
                          _ketThuc,
                          (value) => setState(() => _ketThuc = value),
                          allowClear: true,
                        ),
                      ]),
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
            child: Icon(Icons.health_and_safety_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit ? 'Sửa CCHN' : 'Thêm CCHN',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chứng chỉ hành nghề và phạm vi hoạt động chuyên môn',
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
    bool alignLabelWithHint = false,
    Widget? suffixIcon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
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

  Widget _buildSupplementSwitch() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: _isBoSung
            ? colors.primary.withAlpha(16)
            : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isBoSung
              ? colors.primary.withAlpha(80)
              : colors.outlineVariant,
        ),
      ),
      child: SwitchListTile.adaptive(
        value: _isBoSung,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        secondary: Icon(
          Icons.add_task_outlined,
          color: _isBoSung ? colors.primary : colors.onSurfaceVariant,
        ),
        title: const Text('Phạm vi bổ sung'),
        subtitle: const Text('Đánh dấu nếu đây là phạm vi được cấp bổ sung'),
        onChanged: (value) => setState(() => _isBoSung = value),
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
    try {
      final fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty || !mounted) return;
      setState(() => _newFile = result.files.single);
    } catch (e) {
      if (!mounted) return;
      _message('Không thể chọn file: $e');
    }
  }

  Future<void> _save() async {
    if (_batDau != null && _ketThuc != null && _ketThuc!.isBefore(_batDau!)) {
      _message('Ngày kết thúc không được nhỏ hơn ngày bắt đầu.');
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
      'soCchn': text(_soController.text),
      'noiCap': text(_noiCapController.text),
      'vanBangChuyenMon': text(_vanBangController.text),
      'phamViHoatDong': text(_phamViController.text),
      'ngayBatDau': _batDau?.toIso8601String(),
      'ngayKetThuc': _ketThuc?.toIso8601String(),
      'idFile': fileId,
      'isPhamViBoSung': _isBoSung,
    };

    final bool ok;

    if (widget.isEdit) {
      ok = await provider.updateCchn(widget.maSo, widget.item!.idCchn, data);
    } else {
      ok = await provider.createCchn(widget.maSo, data);
    }

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      _message(provider.errorMessage ?? 'Không thể lưu CCHN.');
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
