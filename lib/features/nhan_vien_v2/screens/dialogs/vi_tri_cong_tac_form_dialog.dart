import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/nhan_vien_v2_models.dart';
import '../../../../providers/nhan_vien_v2_provider.dart';
import '../../../../screens/nhan_vien/nhan_vien_web_design.dart';
import 'widgets/searchable_dropdown_form_field.dart';

class ViTriCongTacFormDialog extends StatefulWidget {
  final String maSo;
  final ViTriCongTacV2Model? item;

  const ViTriCongTacFormDialog({super.key, required this.maSo, this.item});

  bool get isEdit => item != null;

  @override
  State<ViTriCongTacFormDialog> createState() => _ViTriCongTacFormDialogState();
}

class _ViTriCongTacFormDialogState extends State<ViTriCongTacFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _idKhoaPhong;
  int? _idToDoi;
  int? _idChucDanh;
  int? _idChucVu;
  int? _idTinhTrang;
  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;
  bool _isKiemNhiem = false;
  int? _fileId;
  String? _fileName;
  fp.PlatformFile? _newFile;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _idKhoaPhong = item?.idKhoaPhong;
    _idToDoi = item?.idToDoi;
    _idChucDanh = item?.idChucDanh;
    _idChucVu = item?.idChucVu;
    _idTinhTrang = item?.idTinhTrang;
    _ngayBatDau = item?.ngayBatDau;
    _ngayKetThuc = item?.ngayKetThuc;
    _isKiemNhiem = item?.isKiemNhiem == true;
    _fileId = item?.fileId;
    _fileName = item?.fileName;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NhanVienV2Provider>();
    final dm = provider.danhMuc;
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);

    if (dm == null) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: NhanVienWebColors.surface,
        surfaceTintColor: NhanVienWebColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: const SizedBox(
          width: 520,
          height: 240,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text('Đang tải danh mục...'),
              ],
            ),
          ),
        ),
      );
    }

    List<NhanVienDanhMucItemV2Model> availableOptions(
      Iterable<NhanVienDanhMucItemV2Model> source,
      int? selectedId, {
      String? legacyName,
      bool Function(NhanVienDanhMucItemV2Model item)? where,
    }) {
      final options = source
          .where((item) => where == null || where(item))
          .where((item) => item.ksd != true || item.id == selectedId)
          .toList();

      if (selectedId != null && !options.any((item) => item.id == selectedId)) {
        options.insert(
          0,
          NhanVienDanhMucItemV2Model(
            id: selectedId,
            ten: legacyName ?? 'Danh mục cũ (#$selectedId)',
            ksd: true,
          ),
        );
      }

      return options;
    }

    final khoaPhongs = availableOptions(
      dm.khoaPhongs,
      _idKhoaPhong,
      legacyName: widget.item?.tenKhoaPhong,
    );
    final toDois = availableOptions(
      dm.toDois,
      _idToDoi,
      legacyName: widget.item?.tenToDoi,
      where: (item) => _idKhoaPhong == null || item.idKhoaPhong == _idKhoaPhong,
    );
    final chucDanhs = availableOptions(
      dm.chucDanhs,
      _idChucDanh,
      legacyName: widget.item?.tenChucDanh,
    );
    final chucVus = availableOptions(
      dm.chucVus,
      _idChucVu,
      legacyName: widget.item?.tenChucVu,
    );
    final tinhTrangs = availableOptions(
      dm.tinhTrangs,
      _idTinhTrang,
      legacyName: widget.item?.tenTinhTrang,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: NhanVienWebColors.surface,
      surfaceTintColor: NhanVienWebColors.surface,
      shadowColor: NhanVienWebColors.primaryDark.withValues(alpha: .18),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: screenSize.height * .9,
        ),
        child: SizedBox(
          width: 780,
          child: Column(
            children: [
              _buildHeader(theme, isBusy: provider.isSaving),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!widget.isEdit) ...[
                          _buildAutoCloseNotice(),
                          const SizedBox(height: 16),
                        ],
                        _buildSection(
                          icon: Icons.apartment_outlined,
                          title: 'Đơn vị công tác',
                          subtitle: 'Chọn khoa/phòng và tổ/đội trực thuộc',
                          children: [
                            SearchableDropdownFormField<int?>(
                              key: ValueKey<int?>(_idKhoaPhong),
                              initialValue: _idKhoaPhong,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                label: 'Khoa / Phòng *',
                                icon: Icons.business_outlined,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Chưa chọn'),
                                ),
                                ...khoaPhongs.map(
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
                                setState(() {
                                  _idKhoaPhong = value;
                                  final isToDoiValid = dm.toDois.any(
                                    (item) =>
                                        item.id == _idToDoi &&
                                        item.ksd != true &&
                                        (value == null ||
                                            item.idKhoaPhong == value),
                                  );
                                  if (!isToDoiValid) {
                                    _idToDoi = null;
                                  }
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Vui lòng chọn khoa/phòng'
                                  : null,
                            ),
                            SearchableDropdownFormField<int?>(
                              key: ValueKey<int?>(_idToDoi),
                              initialValue: _idToDoi,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                label: 'Tổ / Đội',
                                icon: Icons.groups_2_outlined,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Chưa chọn'),
                                ),
                                ...toDois.map(
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
                              onChanged: (value) =>
                                  setState(() => _idToDoi = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          icon: Icons.badge_outlined,
                          title: 'Vai trò công việc',
                          subtitle: 'Chức danh, chức vụ và tình trạng công tác',
                          children: [
                            SearchableDropdownFormField<int?>(
                              key: ValueKey<int?>(_idChucDanh),
                              initialValue: _idChucDanh,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                label: 'Chức danh *',
                                icon: Icons.workspace_premium_outlined,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Chưa chọn'),
                                ),
                                ...chucDanhs.map(
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
                                setState(() => _idChucDanh = value);
                              },
                              validator: (value) => value == null
                                  ? 'Vui lòng chọn chức danh'
                                  : null,
                            ),
                            SearchableDropdownFormField<int?>(
                              key: ValueKey<int?>(_idChucVu),
                              initialValue: _idChucVu,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                label: 'Chức vụ *',
                                icon: Icons.supervisor_account_outlined,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Chưa chọn'),
                                ),
                                ...chucVus.map(
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
                              onChanged: (value) =>
                                  setState(() => _idChucVu = value),
                              validator: (value) => value == null
                                  ? 'Vui lòng chọn chức vụ'
                                  : null,
                            ),
                            SearchableDropdownFormField<int?>(
                              key: ValueKey<int?>(_idTinhTrang),
                              initialValue: _idTinhTrang,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                label: 'Tình trạng công tác *',
                                icon: Icons.fact_check_outlined,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Chưa chọn'),
                                ),
                                ...tinhTrangs.map(
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
                                setState(() => _idTinhTrang = value);
                              },
                              validator: (value) => value == null
                                  ? 'Vui lòng chọn tình trạng công tác'
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          icon: Icons.date_range_outlined,
                          title: 'Thời gian công tác',
                          subtitle:
                              'Để trống ngày kết thúc nếu vị trí vẫn còn hiệu lực',
                          children: [
                            _dateField(
                              label: 'Ngày bắt đầu *',
                              value: _ngayBatDau,
                              requiredField: true,
                              onChanged: (value) {
                                setState(() => _ngayBatDau = value);
                              },
                            ),
                            _dateField(
                              label: 'Ngày kết thúc',
                              value: _ngayKetThuc,
                              allowClear: true,
                              onChanged: (value) {
                                setState(() => _ngayKetThuc = value);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFileSection(provider.isSaving),
                        const SizedBox(height: 16),
                        _buildConcurrentPositionTile(),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              _buildFooter(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, {required bool isBusy}) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2999D7), NhanVienWebColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.isEdit
                  ? Icons.edit_location_alt_outlined
                  : Icons.add_business,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit
                      ? 'Cập nhật vị trí công tác'
                      : 'Thêm vị trí công tác',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nhân viên ${widget.maSo}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: isBusy ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoCloseNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FD),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFB9DFF3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: NhanVienWebColors.primary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nếu đang có một đợt công tác chưa có ngày kết thúc, hệ thống sẽ tự kết thúc đợt đó trước ngày bắt đầu mới một ngày. Vị trí chính và kiêm nhiệm được xử lý riêng.',
              style: TextStyle(
                color: Color(0xFF31566D),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _responsiveGrid(children),
          ],
        ),
      ),
    );
  }

  Widget _responsiveGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 540 ? 2 : 1;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }

  Widget _buildConcurrentPositionTile() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _isKiemNhiem
            ? colorScheme.tertiaryContainer.withValues(alpha: .55)
            : colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile.adaptive(
        value: _isKiemNhiem,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        secondary: Icon(
          Icons.layers_outlined,
          color: _isKiemNhiem
              ? colorScheme.onTertiaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        title: const Text(
          'Vị trí kiêm nhiệm',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Bật nếu đây là nhiệm vụ kiêm nhiệm bên cạnh vị trí chính.',
        ),
        onChanged: (value) => setState(() => _isKiemNhiem = value),
      ),
    );
  }

  Widget _buildFileSection(bool isSaving) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedName = _newFile?.name ?? _fileName;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.attach_file_rounded,
                    size: 19,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File đính kèm',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        selectedName ?? 'Chưa có file đính kèm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _pickFile,
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  label: Text(selectedName == null ? 'Chọn file' : 'Đổi file'),
                ),
              ],
            ),
            if (_newFile != null) ...[
              const SizedBox(height: 10),
              Text(
                'File mới sẽ được tải lên khi lưu vị trí công tác.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await fp.FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty || !mounted) return;

    final file = result.files.single;
    if (file.size > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File đính kèm không được vượt quá 10 MB.'),
        ),
      );
      return;
    }

    setState(() => _newFile = file);
  }

  Widget _buildFooter(NhanVienV2Provider provider) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Row(
        children: [
          if (provider.isSaving) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Đang lưu vị trí công tác...',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ] else
            const Spacer(),
          TextButton(
            onPressed: provider.isSaving ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: provider.isSaving ? null : _save,
            icon: const Icon(Icons.save_outlined, size: 19),
            label: Text(widget.isEdit ? 'Lưu thay đổi' : 'Thêm vị trí'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
    bool allowClear = false,
    bool requiredField = false,
  }) {
    return FormField<DateTime>(
      key: ValueKey('$label-${value?.millisecondsSinceEpoch ?? 'null'}'),
      initialValue: value,
      validator: (selected) => requiredField && selected == null
          ? 'Vui lòng chọn ${label.replaceAll(' *', '')}'
          : null,
      builder: (field) => InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () async {
          final result = await showDatePicker(
            context: field.context,
            initialDate: field.value ?? DateTime.now(),
            firstDate: DateTime(1990),
            lastDate: DateTime(2100),
          );

          if (result != null) {
            field.didChange(result);
            onChanged(result);
          }
        },
        child: InputDecorator(
          decoration: _inputDecoration(
            label: label,
            icon: Icons.calendar_month_outlined,
            suffixIcon: allowClear && field.value != null
                ? IconButton(
                    tooltip: 'Xóa ngày kết thúc',
                    onPressed: () {
                      field.didChange(null);
                      onChanged(null);
                    },
                    icon: const Icon(Icons.close_rounded, size: 19),
                  )
                : const Icon(Icons.arrow_drop_down_rounded),
          ).copyWith(errorText: field.errorText),
          child: Text(
            field.value == null ? 'Chưa chọn' : _date(field.value!),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: field.value == null
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ngayBatDau = _ngayBatDau;
    if (ngayBatDau == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu.')),
      );
      return;
    }

    if (_ngayKetThuc != null && _ngayKetThuc!.isBefore(ngayBatDau)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc không được nhỏ hơn ngày bắt đầu.'),
        ),
      );
      return;
    }

    final provider = context.read<NhanVienV2Provider>();
    var fileId = _fileId;

    if (_newFile != null) {
      final bytes = _newFile!.bytes;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không đọc được dữ liệu file đính kèm.'),
          ),
        );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload file thất bại: $e')));
        return;
      }
    }

    final data = <String, dynamic>{
      'idChucDanh': _idChucDanh,
      'idChucVu': _idChucVu,
      'idKhoaPhong': _idKhoaPhong,
      'idToDoi': _idToDoi,
      'ngayBatDau': ngayBatDau.toIso8601String(),
      'ngayKetThuc': _ngayKetThuc?.toIso8601String(),
      'fileId': fileId,
      'isKiemNhiem': _isKiemNhiem,
      'idTinhTrang': _idTinhTrang,
    };

    final bool ok;

    if (widget.isEdit) {
      ok = await provider.updateViTriCongTac(
        widget.maSo,
        widget.item!.idViTriCongTac,
        data,
      );
    } else {
      ok = await provider.createViTriCongTac(widget.maSo, data);
    }

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Không thể lưu vị trí công tác.',
          ),
        ),
      );
    }
  }
}
