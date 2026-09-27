import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/nhan_vien_v2_models.dart';
import '../../../../providers/nhan_vien_v2_provider.dart';
import '../../../../screens/nhan_vien/nhan_vien_web_design.dart';
import 'widgets/searchable_dropdown_form_field.dart';

class ChungChiFormDialog extends StatefulWidget {
  final String maSo;
  final bool cme;
  final ChungChiNhanVienV2Model? item;

  const ChungChiFormDialog({
    super.key,
    required this.maSo,
    required this.cme,
    this.item,
  });

  bool get isEdit => item != null;

  @override
  State<ChungChiFormDialog> createState() => _ChungChiFormDialogState();
}

class _ChungChiFormDialogState extends State<ChungChiFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tenController;
  late final TextEditingController _soController;
  late final TextEditingController _donViController;
  late final TextEditingController _soTietController;
  late final TextEditingController _chuKyController;

  int? _idHinhThucDaoTao;
  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;
  DateTime? _ngayCap;
  DateTime? _ngayHetHan;
  int? _idFile;
  String? _fileName;
  fp.PlatformFile? _newFile;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _tenController = TextEditingController(text: item?.tenChungChi ?? '');
    _soController = TextEditingController(text: item?.soChungChi ?? '');
    _donViController = TextEditingController(text: item?.donViDaoTao ?? '');
    _soTietController = TextEditingController(
      text: item?.soTiet?.toString() ?? '',
    );
    _chuKyController = TextEditingController(
      text: item?.chuKy?.toString() ?? '',
    );
    _idHinhThucDaoTao = item?.idHinhThucDaoTao;
    _ngayBatDau = item?.ngayBatDau;
    _ngayKetThuc = item?.ngayKetThuc;
    _ngayCap = item?.ngayCap;
    _ngayHetHan = item?.ngayHetHan;
    _idFile = item?.idFile;
    _fileName = item?.fileName;
  }

  @override
  void dispose() {
    _tenController.dispose();
    _soController.dispose();
    _donViController.dispose();
    _soTietController.dispose();
    _chuKyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NhanVienV2Provider>();
    final dm = provider.danhMuc;
    final viewport = MediaQuery.sizeOf(context);
    final dialogHeight = viewport.height > 760 ? 760.0 : viewport.height - 32;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: NhanVienWebColors.surface,
      surfaceTintColor: NhanVienWebColors.surface,
      shadowColor: NhanVienWebColors.primaryDark.withValues(alpha: .18),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: SizedBox(
        width: 820,
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
                        icon: Icons.workspace_premium_outlined,
                        title: 'Thông tin chứng chỉ',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _tenController,
                              decoration: _inputDecoration(
                                'Tên chứng chỉ',
                                Icons.badge_outlined,
                                hintText: widget.cme
                                    ? 'Nhập tên khóa học hoặc chứng chỉ CME'
                                    : 'Nhập tên chứng chỉ',
                              ),
                            ),
                            const SizedBox(height: 12),
                            _responsiveFields([
                              TextFormField(
                                controller: _soController,
                                decoration: _inputDecoration(
                                  'Số chứng chỉ',
                                  Icons.numbers_outlined,
                                ),
                              ),
                              TextFormField(
                                controller: _donViController,
                                decoration: _inputDecoration(
                                  'Đơn vị đào tạo',
                                  Icons.account_balance_outlined,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSection(
                        icon: Icons.menu_book_outlined,
                        title: 'Thông tin đào tạo',
                        child: Column(
                          children: [
                            if (dm != null)
                              SearchableDropdownFormField<int?>(
                                initialValue: _idHinhThucDaoTao,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  'Hình thức đào tạo',
                                  Icons.school_outlined,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Chưa chọn'),
                                  ),
                                  if (_idHinhThucDaoTao != null &&
                                      !dm.hinhThucDaoTaos.any(
                                        (e) => e.id == _idHinhThucDaoTao,
                                      ))
                                    DropdownMenuItem(
                                      value: _idHinhThucDaoTao,
                                      child: Text(
                                        widget.item?.tenHinhThucDaoTao ??
                                            'Danh mục cũ (#$_idHinhThucDaoTao)',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ...dm.hinhThucDaoTaos
                                      .where(
                                        (e) =>
                                            e.ksd != true ||
                                            e.id == _idHinhThucDaoTao,
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
                                  setState(() => _idHinhThucDaoTao = value);
                                },
                              ),
                            if (dm != null) const SizedBox(height: 12),
                            _responsiveFields([
                              TextFormField(
                                controller: _soTietController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(
                                  'Giờ tín chỉ',
                                  Icons.schedule_outlined,
                                  hintText: 'Ví dụ: 24',
                                ),
                              ),
                              TextFormField(
                                controller: _chuKyController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  'Chu kỳ',
                                  Icons.autorenew_outlined,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSection(
                        icon: Icons.event_available_outlined,
                        title: 'Thời gian và hiệu lực',
                        child: Column(
                          children: [
                            _responsiveFields([
                              _dateField(
                                'Ngày bắt đầu',
                                _ngayBatDau,
                                (value) => setState(() => _ngayBatDau = value),
                              ),
                              _dateField(
                                'Ngày kết thúc',
                                _ngayKetThuc,
                                (value) => setState(() => _ngayKetThuc = value),
                                allowClear: true,
                              ),
                              _dateField(
                                'Ngày cấp',
                                _ngayCap,
                                (value) => setState(() => _ngayCap = value),
                                allowClear: true,
                              ),
                              _dateField(
                                'Ngày hết hạn',
                                _ngayHetHan,
                                (value) => setState(() => _ngayHetHan = value),
                                allowClear: true,
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSection(
                        icon: Icons.attach_file_outlined,
                        title: 'Tệp chứng minh',
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
    final certificateLabel = widget.cme ? 'Chứng chỉ CME' : 'Chứng chỉ khác';
    final actionLabel = widget.isEdit ? 'Sửa' : 'Thêm';

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
            child: Icon(
              widget.cme
                  ? Icons.monitor_heart_outlined
                  : Icons.workspace_premium_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$actionLabel $certificateLabel',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.cme) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.tertiaryContainer,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'CME',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.onTertiaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Thông tin đào tạo, thời hạn và tệp chứng minh',
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
        child: Text(value == null ? '' : _formatDate(value)),
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
    if (_ngayBatDau != null &&
        _ngayKetThuc != null &&
        _ngayKetThuc!.isBefore(_ngayBatDau!)) {
      _message('Ngày kết thúc không được nhỏ hơn ngày bắt đầu.');
      return;
    }

    if (_ngayCap != null &&
        _ngayHetHan != null &&
        _ngayHetHan!.isBefore(_ngayCap!)) {
      _message('Ngày hết hạn không được nhỏ hơn ngày cấp.');
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

    String? nullText(String value) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }

    final data = <String, dynamic>{
      'tenChungChi': nullText(_tenController.text),
      'cme': widget.cme,
      'donViDaoTao': nullText(_donViController.text),
      'idHinhThucDaoTao': _idHinhThucDaoTao,
      'ngayBatDau': _ngayBatDau?.toIso8601String(),
      'ngayKetThuc': _ngayKetThuc?.toIso8601String(),
      'soTiet': double.tryParse(
        _soTietController.text.trim().replaceAll(',', '.'),
      ),
      'ngayCap': _ngayCap?.toIso8601String(),
      'idFile': fileId,
      'idLopDaoTao': widget.item?.idLopDaoTao,
      'ngayHetHan': _ngayHetHan?.toIso8601String(),
      'soChungChi': nullText(_soController.text),
      'chuKy': int.tryParse(_chuKyController.text.trim()),
    };

    final bool ok;

    if (widget.isEdit) {
      ok = await provider.updateChungChi(
        widget.maSo,
        widget.item!.idChungChi,
        data,
      );
    } else {
      ok = await provider.createChungChi(widget.maSo, data);
    }

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      _message(provider.errorMessage ?? 'Không thể lưu chứng chỉ.');
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
