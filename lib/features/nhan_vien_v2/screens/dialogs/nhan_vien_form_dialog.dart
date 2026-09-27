import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/nhan_vien_v2_models.dart';
import '../../../../providers/nhan_vien_v2_provider.dart';
import '../../../../screens/nhan_vien/nhan_vien_web_design.dart';
import 'widgets/searchable_dropdown_form_field.dart';

class NhanVienFormDialog extends StatefulWidget {
  final NhanVienProfileV2Model? profile;

  const NhanVienFormDialog({super.key, this.profile});

  bool get isEdit => profile != null;

  @override
  State<NhanVienFormDialog> createState() => _NhanVienFormDialogState();
}

class _NhanVienFormDialogState extends State<NhanVienFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _maSoController;
  late final TextEditingController _hoTenController;
  late final TextEditingController _soDienThoaiController;
  late final TextEditingController _cccdController;
  late final TextEditingController _noiCapCccdController;
  late final TextEditingController _diaChiController;
  late final TextEditingController _noiOController;
  late final TextEditingController _queQuanController;
  late final TextEditingController _noiSinhController;
  late final TextEditingController _danTocController;
  late final TextEditingController _bhxhController;
  late final TextEditingController _taiKhoanController;
  late final TextEditingController _tenTaiKhoanController;
  late final TextEditingController _nganHangController;

  DateTime? _namSinh;
  DateTime? _ngayCapCccd;
  DateTime? _ngayKetThucCongTac;
  bool? _gioiTinh;
  int? _idTonGiao;
  int? _idTinhTrangHonNhan;
  int? _loaiNhanVien;
  bool _isNghiViec = false;

  int? _anhDaiDienId;
  Uint8List? _newImageBytes;
  String? _newImageName;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;

    _maSoController = TextEditingController(text: p?.maSo ?? '');
    _hoTenController = TextEditingController(text: p?.hoVaTen ?? '');
    _soDienThoaiController = TextEditingController(text: p?.soDienThoai ?? '');
    _cccdController = TextEditingController(text: p?.soCCCD ?? '');
    _noiCapCccdController = TextEditingController(text: p?.noiCapCCCD ?? '');
    _diaChiController = TextEditingController(text: p?.diaChiThuongTru ?? '');
    _noiOController = TextEditingController(text: p?.noiOHienTai ?? '');
    _queQuanController = TextEditingController(text: p?.queQuan ?? '');
    _noiSinhController = TextEditingController(text: p?.noiSinh ?? '');
    _danTocController = TextEditingController(text: p?.danToc ?? '');
    _bhxhController = TextEditingController(text: p?.soBHXH ?? '');
    _taiKhoanController = TextEditingController(text: p?.taiKhoanNH ?? '');
    _tenTaiKhoanController = TextEditingController(
      text: p?.tenTaiKhoanNH ?? '',
    );
    _nganHangController = TextEditingController(text: p?.tenNH ?? '');

    _namSinh = p?.namSinh;
    _ngayCapCccd = p?.ngayCapCCCD;
    _gioiTinh = p?.gioiTinh;
    _idTonGiao = p?.idTonGiao;
    _idTinhTrangHonNhan = p?.idTinhTrangHonNhan;
    _loaiNhanVien = p?.loaiNhanVien;
    _isNghiViec = p?.isNghiViec == true;

    if (_isNghiViec && p != null) {
      ViTriCongTacV2Model? viTriGanNhat;

      for (final viTri in p.lichSuViTriCongTac) {
        if (viTri.isKiemNhiem != true && viTri.idTinhTrang == 7) {
          viTriGanNhat = viTri;
          break;
        }
      }

      if (viTriGanNhat == null) {
        for (final viTri in p.lichSuViTriCongTac) {
          if (viTri.isKiemNhiem != true) {
            viTriGanNhat = viTri;
            break;
          }
        }
      }

      _ngayKetThucCongTac = viTriGanNhat?.ngayKetThuc;
    }

    // Giữ nguyên Id ảnh hiện tại khi người dùng chỉ sửa thông tin khác.
    _anhDaiDienId = p?.anhDaiDien;
  }

  @override
  void dispose() {
    _maSoController.dispose();
    _hoTenController.dispose();
    _soDienThoaiController.dispose();
    _cccdController.dispose();
    _noiCapCccdController.dispose();
    _diaChiController.dispose();
    _noiOController.dispose();
    _queQuanController.dispose();
    _noiSinhController.dispose();
    _danTocController.dispose();
    _bhxhController.dispose();
    _taiKhoanController.dispose();
    _tenTaiKhoanController.dispose();
    _nganHangController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NhanVienV2Provider>();
    final danhMuc = provider.danhMuc;
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: NhanVienWebColors.surface,
      surfaceTintColor: NhanVienWebColors.surface,
      shadowColor: NhanVienWebColors.primaryDark.withValues(alpha: .18),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1040,
          maxHeight: screenSize.height * .92,
        ),
        child: SizedBox(
          width: 1040,
          child: Column(
            children: [
              _buildHeader(
                theme,
                isBusy: provider.isSaving || _isUploadingImage,
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImageSelector(),
                        const SizedBox(height: 16),
                        _buildSection(
                          icon: Icons.person_outline_rounded,
                          title: 'Thông tin cơ bản',
                          subtitle: 'Thông tin nhận diện và liên hệ chính',
                          children: [
                            if (!widget.isEdit)
                              TextFormField(
                                controller: _maSoController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: _inputDecoration(
                                  label: 'Mã nhân viên *',
                                  icon: Icons.badge_outlined,
                                  hintText: 'Tối đa 5 ký tự',
                                ),
                                validator: (value) {
                                  final v = value?.trim();
                                  if (v == null || v.isEmpty) {
                                    return 'Nhập mã nhân viên';
                                  }
                                  if (v.length > 5) return 'Tối đa 5 ký tự';
                                  return null;
                                },
                              ),
                            TextFormField(
                              controller: _hoTenController,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration(
                                label: 'Họ và tên *',
                                icon: Icons.account_circle_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nhập họ và tên';
                                }
                                return null;
                              },
                            ),
                            _dateField(
                              label: 'Ngày sinh *',
                              value: _namSinh,
                              icon: Icons.cake_outlined,
                              requiredField: true,
                              onChanged: (value) =>
                                  setState(() => _namSinh = value),
                            ),
                            SearchableDropdownFormField<bool?>(
                              key: ValueKey<bool?>(_gioiTinh),
                              initialValue: _gioiTinh,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                label: widget.isEdit
                                    ? 'Giới tính'
                                    : 'Giới tính *',
                                icon: Icons.wc_outlined,
                              ),
                              items: [
                                if (widget.isEdit)
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Chưa chọn'),
                                  ),
                                const DropdownMenuItem(
                                  value: true,
                                  child: Text('Nam'),
                                ),
                                const DropdownMenuItem(
                                  value: false,
                                  child: Text('Nữ'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _gioiTinh = value),
                              validator: (value) =>
                                  !widget.isEdit && value == null
                                  ? 'Vui lòng chọn giới tính'
                                  : null,
                            ),
                            _textField(
                              _soDienThoaiController,
                              'Số điện thoại',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              requiredField: !widget.isEdit,
                            ),
                            SearchableDropdownFormField<int?>(
                              key: ValueKey<int?>(_loaiNhanVien),
                              initialValue: _loaiNhanVien,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                label: widget.isEdit
                                    ? 'Loại nhân viên'
                                    : 'Loại nhân viên *',
                                icon: Icons.work_outline_rounded,
                              ),
                              items: [
                                if (widget.isEdit)
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Chưa chọn'),
                                  ),
                                if (_loaiNhanVien != null &&
                                    (danhMuc == null ||
                                        !danhMuc.loaiNhanViens.any(
                                          (item) => item.id == _loaiNhanVien,
                                        )))
                                  DropdownMenuItem(
                                    value: _loaiNhanVien,
                                    child: Text(
                                      'ID $_loaiNhanVien - Không còn trong danh mục',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ...?danhMuc?.loaiNhanViens.map(
                                  (item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Text(
                                      item.ten ?? 'ID ${item.id}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _loaiNhanVien = value),
                              validator: (value) =>
                                  !widget.isEdit && value == null
                                  ? 'Vui lòng chọn loại nhân viên'
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          icon: Icons.assignment_ind_outlined,
                          title: 'Giấy tờ và thông tin cá nhân',
                          subtitle:
                              'CCCD, nơi sinh, quê quán và danh mục cá nhân',
                          children: [
                            _textField(
                              _cccdController,
                              'Số CCCD',
                              icon: Icons.credit_card_outlined,
                              keyboardType: TextInputType.number,
                              requiredField: !widget.isEdit,
                            ),
                            _dateField(
                              label: widget.isEdit
                                  ? 'Ngày cấp CCCD'
                                  : 'Ngày cấp CCCD *',
                              value: _ngayCapCccd,
                              icon: Icons.event_outlined,
                              requiredField: !widget.isEdit,
                              onChanged: (value) =>
                                  setState(() => _ngayCapCccd = value),
                            ),
                            _textField(
                              _noiCapCccdController,
                              'Nơi cấp CCCD',
                              icon: Icons.location_city_outlined,
                              requiredField: !widget.isEdit,
                            ),
                            _textField(
                              _danTocController,
                              'Dân tộc',
                              icon: Icons.groups_outlined,
                            ),
                            if (danhMuc != null)
                              SearchableDropdownFormField<int?>(
                                key: ValueKey<int?>(_idTonGiao),
                                initialValue: _idTonGiao,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  label: 'Tôn giáo',
                                  icon: Icons.auto_awesome_outlined,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Chưa chọn'),
                                  ),
                                  ...danhMuc.tonGiaos
                                      .where((e) => e.ksd != true)
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e.id,
                                          child: Text(
                                            e.ten ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _idTonGiao = value),
                              ),
                            if (danhMuc != null)
                              SearchableDropdownFormField<int?>(
                                key: ValueKey<int?>(_idTinhTrangHonNhan),
                                initialValue: _idTinhTrangHonNhan,
                                isExpanded: true,
                                decoration: _inputDecoration(
                                  label: 'Tình trạng hôn nhân',
                                  icon: Icons.favorite_border_rounded,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Chưa chọn'),
                                  ),
                                  ...danhMuc.tinhTrangHonNhans
                                      .where((e) => e.ksd != true)
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e.id,
                                          child: Text(
                                            e.ten ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                ],
                                onChanged: (value) {
                                  setState(() => _idTinhTrangHonNhan = value);
                                },
                              ),
                            _textField(
                              _noiSinhController,
                              'Nơi sinh',
                              icon: Icons.place_outlined,
                            ),
                            _textField(
                              _queQuanController,
                              'Quê quán',
                              icon: Icons.home_work_outlined,
                              requiredField: !widget.isEdit,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          icon: Icons.home_outlined,
                          title: 'Địa chỉ và an sinh',
                          subtitle: 'Nơi cư trú và thông tin bảo hiểm xã hội',
                          children: [
                            _textField(
                              _diaChiController,
                              'Địa chỉ thường trú',
                              icon: Icons.maps_home_work_outlined,
                              requiredField: !widget.isEdit,
                            ),
                            _textField(
                              _noiOController,
                              'Nơi ở hiện tại',
                              icon: Icons.my_location_outlined,
                            ),
                            _textField(
                              _bhxhController,
                              'Số BHXH',
                              icon: Icons.health_and_safety_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          icon: Icons.account_balance_outlined,
                          title: 'Thông tin ngân hàng',
                          subtitle: 'Tài khoản nhận lương của nhân viên',
                          children: [
                            _textField(
                              _taiKhoanController,
                              'Số tài khoản',
                              icon: Icons.numbers_outlined,
                              keyboardType: TextInputType.number,
                            ),
                            _textField(
                              _tenTaiKhoanController,
                              'Tên chủ tài khoản',
                              icon: Icons.person_pin_outlined,
                            ),
                            _textField(
                              _nganHangController,
                              'Ngân hàng',
                              icon: Icons.account_balance_rounded,
                            ),
                          ],
                        ),
                        if (widget.isEdit) ...[
                          const SizedBox(height: 16),
                          _buildEmploymentStatus(),
                        ],
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
                  ? Icons.manage_accounts_outlined
                  : Icons.person_add_alt_1_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEdit ? 'Cập nhật hồ sơ nhân viên' : 'Thêm nhân viên',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isEdit
                      ? 'Chỉnh sửa thông tin hành chính của ${widget.profile?.hoVaTen ?? widget.profile?.maSo ?? ''}'
                      : 'Nhập thông tin hành chính cho nhân viên mới',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        final columns = constraints.maxWidth >= 820
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
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

  Widget _buildImageSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Uint8List? bytes = _newImageBytes ?? widget.profile?.avatarBytes;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: .62),
            colorScheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final avatar = Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: .12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: compact ? 38 : 43,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage: bytes == null ? null : MemoryImage(bytes),
                child: bytes == null
                    ? Icon(
                        Icons.person_rounded,
                        size: compact ? 40 : 46,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            );
            final details = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  'Ảnh đại diện',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _newImageName ??
                      widget.profile?.anhFileName ??
                      'Chưa có ảnh đại diện',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: compact
                      ? WrapAlignment.center
                      : WrapAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(bytes == null ? 'Chọn ảnh' : 'Đổi ảnh'),
                    ),
                    if (_newImageBytes != null)
                      TextButton.icon(
                        onPressed: _isUploadingImage
                            ? null
                            : () {
                                setState(() {
                                  _newImageBytes = null;
                                  _newImageName = null;
                                });
                              },
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Hoàn tác'),
                      ),
                  ],
                ),
              ],
            );

            if (compact) {
              return Column(
                children: [avatar, const SizedBox(height: 12), details],
              );
            }

            return Row(
              children: [
                avatar,
                const SizedBox(width: 18),
                Expanded(child: details),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ảnh JPG, PNG • tối đa 5 MB',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmploymentStatus() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = _isNghiViec
        ? colorScheme.errorContainer.withValues(alpha: .46)
        : colorScheme.tertiaryContainer.withValues(alpha: .45);
    final foreground = _isNghiViec
        ? colorScheme.onErrorContainer
        : colorScheme.onTertiaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile.adaptive(
            value: _isNghiViec,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 5,
            ),
            secondary: Icon(
              _isNghiViec
                  ? Icons.work_off_outlined
                  : Icons.work_outline_rounded,
              color: foreground,
            ),
            title: Text(
              _isNghiViec
                  ? 'Nhân viên đã nghỉ việc'
                  : 'Nhân viên đang làm việc',
              style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              _isNghiViec
                  ? 'Chọn ngày kết thúc để cập nhật đợt vị trí công tác gần nhất.'
                  : 'Bật tùy chọn này khi nhân viên đã nghỉ việc.',
              style: TextStyle(color: foreground.withValues(alpha: .8)),
            ),
            onChanged: (value) => setState(() => _isNghiViec = value),
          ),
        ),
        if (_isNghiViec)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: .25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kết thúc vị trí công tác',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày kết thúc và tình trạng nghỉ việc (ID 7) sẽ được cập nhật vào đợt vị trí công tác gần nhất.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: .78),
                  ),
                ),
                const SizedBox(height: 12),
                _dateField(
                  label: 'Ngày kết thúc công tác *',
                  value: _ngayKetThucCongTac,
                  icon: Icons.event_busy_outlined,
                  requiredField: true,
                  onChanged: (value) =>
                      setState(() => _ngayKetThucCongTac = value),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(NhanVienV2Provider provider) {
    final theme = Theme.of(context);
    final isBusy = provider.isSaving || _isUploadingImage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Row(
        children: [
          if (isBusy) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _isUploadingImage ? 'Đang tải ảnh lên...' : 'Đang lưu hồ sơ...',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ] else
            const Spacer(),
          TextButton(
            onPressed: isBusy ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: isBusy ? null : _save,
            icon: const Icon(Icons.save_outlined, size: 19),
            label: Text(widget.isEdit ? 'Lưu thay đổi' : 'Thêm nhân viên'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
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

  Widget _textField(
    TextEditingController controller,
    String label, {
    required IconData icon,
    TextInputType? keyboardType,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(
        label: requiredField ? '$label *' : label,
        icon: icon,
      ),
      validator: (value) {
        if (requiredField && (value == null || value.trim().isEmpty)) {
          return 'Vui lòng nhập $label';
        }
        return null;
      },
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required ValueChanged<DateTime?> onChanged,
    bool requiredField = false,
  }) {
    return FormField<DateTime>(
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
            firstDate: DateTime(1940),
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
            icon: icon,
            suffixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
          ).copyWith(errorText: field.errorText),
          child: Text(
            field.value == null ? '' : _date(field.value!),
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

  Future<void> _pickImage() async {
    try {
      final fp.FilePickerResult? result = await fp.FilePicker.platform
          .pickFiles(
            type: fp.FileType.image,
            allowMultiple: false,
            withData: true,
          );

      if (result == null || result.files.isEmpty) return;

      final fp.PlatformFile file = result.files.single;
      final Uint8List? bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        _message('Không đọc được dữ liệu ảnh.');
        return;
      }

      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        _message('Ảnh không được vượt quá 5MB.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _newImageBytes = bytes;
        _newImageName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      _message('Không thể chọn ảnh: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_namSinh == null) {
      _message('Vui lòng chọn ngày sinh.');
      return;
    }

    if (widget.isEdit && _isNghiViec && _ngayKetThucCongTac == null) {
      _message('Vui lòng chọn ngày kết thúc công tác.');
      return;
    }

    final provider = context.read<NhanVienV2Provider>();

    if (_newImageBytes != null && _newImageName != null) {
      try {
        setState(() => _isUploadingImage = true);
        final uploaded = await provider.uploadFile(
          bytes: _newImageBytes!,
          fileName: _newImageName!,
        );
        _anhDaiDienId = uploaded.idFile;
      } catch (e) {
        if (mounted) _message('Upload ảnh thất bại: $e');
        return;
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }

    String? nullIfEmpty(String value) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }

    final data = <String, dynamic>{
      'hoVaTen': _hoTenController.text.trim(),
      'namSinh': _namSinh!.toIso8601String(),
      'gioiTinh': _gioiTinh,
      'anhDaiDien': _anhDaiDienId,
      'soCCCD': nullIfEmpty(_cccdController.text),
      'ngayCapCCCD': _ngayCapCccd?.toIso8601String(),
      'noiCapCCCD': nullIfEmpty(_noiCapCccdController.text),
      'diaChiThuongTru': nullIfEmpty(_diaChiController.text),
      'noiOHienTai': nullIfEmpty(_noiOController.text),
      'queQuan': nullIfEmpty(_queQuanController.text),
      'noiSinh': nullIfEmpty(_noiSinhController.text),
      'danToc': nullIfEmpty(_danTocController.text),
      'idTonGiao': _idTonGiao,
      'idTinhTrangHonNhan': _idTinhTrangHonNhan,
      'isNghiViec': widget.isEdit ? _isNghiViec : false,
      'ngayKetThucCongTac': widget.isEdit && _isNghiViec
          ? _ngayKetThucCongTac?.toIso8601String()
          : null,
      'soBHXH': nullIfEmpty(_bhxhController.text),
      'taiKhoanNH': nullIfEmpty(_taiKhoanController.text),
      'tenTaiKhoanNH': nullIfEmpty(_tenTaiKhoanController.text),
      'tenNH': nullIfEmpty(_nganHangController.text),
      'soDienThoai': nullIfEmpty(_soDienThoaiController.text),

      // Các field chưa có ô chỉnh vẫn phải giữ nguyên khi Update.
      'idTuyenDung': widget.profile?.idTuyenDung,
      'maBNMinhLo': widget.profile?.maBNMinhLo,
      'loaiNhanVien': _loaiNhanVien,
    };

    final bool ok;
    if (widget.isEdit) {
      ok = await provider.updateNhanVien(widget.profile!.maSo, data);
    } else {
      data['maSo'] = _maSoController.text.trim();
      ok = await provider.createNhanVien(data);
    }

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      _message(provider.errorMessage ?? 'Không thể lưu nhân viên.');
    }
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
