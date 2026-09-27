import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cap_cchn_models.dart';
import '../../providers/cap_cchn_provider.dart';
import '../../services/nhan_vien_v2_service.dart';

class CapCchnFormDialog extends StatefulWidget {
  final CapCchnModel? initialData;
  final NhanVienV2Service nhanVienService;
  const CapCchnFormDialog({
    super.key,
    this.initialData,
    required this.nhanVienService,
  });

  @override
  State<CapCchnFormDialog> createState() => _CapCchnFormDialogState();
}

class _CapCchnFormDialogState extends State<CapCchnFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cccd = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _qualification = TextEditingController();
  final _school = TextEditingController();
  final _tuition = TextEditingController();
  final _note = TextEditingController();
  DateTime? _birth, _cccdDate, _start, _end;
  bool? _gender;
  int? _type;
  CapCchnCatalog _catalog = const CapCchnCatalog();
  bool _loading = true;
  String? _error;
  PlatformFile? _avatar, _tuitionFile, _contract, _decision, _confirmation;
  PlatformFile? _acceptanceNotice;
  bool _removeAvatar = false, _removeTuition = false, _removeContract = false;
  bool _removeDecision = false, _removeConfirmation = false;
  bool _removeAcceptanceNotice = false;
  bool _proposal = false, _resume = false, _hasCccd = false, _degree = false;
  bool _photo = false, _journal = false, _report = false;
  final List<_PeriodDraft> _periods = [];

  @override
  void initState() {
    super.initState();
    final x = widget.initialData;
    if (x != null) {
      _name.text = x.hoVaTen ?? '';
      _cccd.text = x.soCCCD ?? '';
      _phone.text = x.soDienThoai ?? '';
      _address.text = x.diaChiThuongTru ?? '';
      _qualification.text = x.trinhDoChuyenMon ?? '';
      _school.text = x.truongDonVi ?? '';
      _tuition.text = x.hocPhi?.toStringAsFixed(0) ?? '';
      _note.text = x.ghiChu ?? '';
      _birth = x.ngaySinh;
      _cccdDate = x.ngayCapCCCD;
      _start = x.ngayBatDauThucHanh;
      _end = x.ngayKetThucThucHanh;
      _gender = x.gioiTinh;
      _type = x.loaiNhanVien;
      _proposal = x.isDeNghiTH;
      _resume = x.isSoYeuLL;
      _hasCccd = x.isCCCD;
      _degree = x.isVanBangCM;
      _photo = x.isAnh34;
      _journal = x.isNhatKyTH;
      _report = x.isBaoCaoTH;
      _periods.addAll(x.nguoiHuongDans.map(_PeriodDraft.fromModel));
    }
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final data = await context.read<CapCchnProvider>().getCatalog();
      if (mounted) setState(() => _catalog = data);
    } catch (e) {
      if (mounted) setState(() => _error = _msg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _cccd,
      _phone,
      _address,
      _qualification,
      _school,
      _tuition,
      _note,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(
    DateTime? current,
    ValueChanged<DateTime> set, {
    DateTime? first,
    DateTime? last,
  }) async {
    final value = await showDatePicker(
      context: context,
      initialDate: current ?? first ?? DateTime.now(),
      firstDate: first ?? DateTime(1940),
      lastDate: last ?? DateTime(2100),
    );
    if (value != null) setState(() => set(value));
  }

  Future<PlatformFile?> _pickFile({bool image = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: image
          ? ['jpg', 'jpeg', 'png']
          : ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    return result?.files.single;
  }

  Future<void> _openPeriod({int? index}) async {
    if (_type == null) {
      setState(() => _error = 'Vui lòng chọn loại nhân viên trước.');
      return;
    }
    final provider = context.read<CapCchnProvider>();
    final value = await showDialog<_PeriodDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PeriodDialog(
        provider: provider,
        catalog: _catalog,
        employeeType: _type!,
        overallStart: _start,
        overallEnd: _end,
        capCchnId: widget.initialData?.idCapCCCHN,
        initial: index == null ? null : _periods[index],
      ),
    );
    if (value != null) {
      setState(
        () => index == null ? _periods.add(value) : _periods[index] = value,
      );
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_birth == null ||
        _cccdDate == null ||
        _start == null ||
        _end == null ||
        _type == null) {
      setState(
        () => _error = 'Vui lòng nhập đủ các trường ngày và loại nhân viên.',
      );
      return;
    }
    if (_end!.isBefore(_start!)) {
      setState(() => _error = 'Ngày kết thúc phải từ ngày bắt đầu trở đi.');
      return;
    }
    final feeText = _tuition.text.trim().replaceAll(',', '');
    final fee = feeText.isEmpty ? null : double.tryParse(feeText);
    if (feeText.isNotEmpty && fee == null) {
      setState(() => _error = 'Học phí không hợp lệ.');
      return;
    }
    final payload = <String, dynamic>{
      'hoVaTen': _name.text.trim(),
      'ngaySinh': _apiDate(_birth!),
      'gioiTinh': _gender,
      'soCCCD': _cccd.text.trim(),
      'ngayCapCCCD': _apiDate(_cccdDate!),
      'soDienThoai': _phone.text.trim(),
      'diaChiThuongTru': _address.text.trim(),
      'trinhDoChuyenMon': _qualification.text.trim(),
      'truongDonVi': _school.text.trim(),
      'ngayBatDauThucHanh': _apiDate(_start!),
      'ngayKetThucThucHanh': _apiDate(_end!),
      'hocPhi': fee,
      'ghiChu': _note.text.trim().isEmpty ? null : _note.text.trim(),
      'loaiNhanVien': _type,
      'isDeNghiTH': _proposal,
      'isSoYeuLL': _resume,
      'isCCCD': _hasCccd,
      'isVanBangCM': _degree,
      'isAnh34': _photo,
      'isNhatKyTH': _journal,
      'isBaoCaoTH': _report,
      'xoaFileHopDong': _removeContract,
      'xoaFileQuyetDinh': _removeDecision,
      'xoaFileXacNhanTH': _removeConfirmation,
      'xoaFileThongBaoTiepNhan': _removeAcceptanceNotice,
      'xoaAnhDaiDien': _removeAvatar,
      'xoaFileHocPhi': _removeTuition,
      'nguoiHuongDans': _periods.map((x) => x.toJson()).toList(),
    };
    final provider = context.read<CapCchnProvider>();
    final ok = await provider.save(
      id: widget.initialData?.idCapCCCHN,
      payload: payload,
      fileHopDong: _contract,
      fileQuyetDinh: _decision,
      fileXacNhanTH: _confirmation,
      fileThongBaoTiepNhan: _acceptanceNotice,
      anhDaiDien: _avatar,
      fileHocPhi: _tuitionFile,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = provider.errorMessage ?? 'Không thể lưu hồ sơ.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<CapCchnProvider>().isSaving;
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 850),
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (_error != null) _errorBox(_error!),
                            _section(
                              'Thông tin cá nhân',
                              Icons.person_outline,
                              _personal(),
                            ),
                            _section(
                              'Thời gian và học phí',
                              Icons.event_available_outlined,
                              _timeAndFee(),
                            ),
                            _section(
                              'Khoa/phòng và người hướng dẫn',
                              Icons.groups_outlined,
                              _periodList(),
                            ),
                            _section('File hồ sơ', Icons.attach_file, _files()),
                            _section(
                              'Thành phần hồ sơ',
                              Icons.fact_check_outlined,
                              _checks(),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE0E8EE))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: saving ? null : _save,
                    icon: saving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      widget.initialData == null
                          ? 'Thêm hồ sơ'
                          : 'Lưu thay đổi',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.all(18),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF087DBB), Color(0xFF18A5CB)]),
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    child: Row(
      children: [
        const Icon(Icons.badge_outlined, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialData == null
                    ? 'Thêm hồ sơ thực hành'
                    : 'Cập nhật hồ sơ thực hành',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Thông tin người thực hành độc lập với danh sách nhân sự',
                style: TextStyle(color: Color(0xFFDDF6FF), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _personal() => LayoutBuilder(
    builder: (_, c) {
      final w = c.maxWidth >= 760 ? (c.maxWidth - 14) / 2 : c.maxWidth;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          SizedBox(width: c.maxWidth, child: _avatarPicker()),
          _text(_name, 'Họ và tên *', w),
          _dateBox(
            'Ngày sinh *',
            _birth,
            () => _pickDate(_birth, (v) => _birth = v, last: DateTime.now()),
            w,
          ),
          _drop<bool?>(
            'Giới tính',
            _gender,
            const [
              DropdownMenuItem(value: null, child: Text('Chưa xác định')),
              DropdownMenuItem(value: true, child: Text('Nam')),
              DropdownMenuItem(value: false, child: Text('Nữ')),
            ],
            (v) => setState(() => _gender = v),
            w,
          ),
          _text(_cccd, 'Số CCCD *', w),
          _dateBox(
            'Ngày cấp CCCD *',
            _cccdDate,
            () => _pickDate(
              _cccdDate,
              (v) => _cccdDate = v,
              last: DateTime.now(),
            ),
            w,
          ),
          _text(_phone, 'Số điện thoại *', w),
          _drop<int?>(
            'Loại nhân viên *',
            _type,
            _catalog.loaiNhanViens
                .map(
                  (x) =>
                      DropdownMenuItem<int?>(value: x.id, child: Text(x.ten)),
                )
                .toList(),
            (v) => setState(() {
              _type = v;
              _periods.clear();
            }),
            w,
          ),
          _text(_qualification, 'Trình độ chuyên môn *', w),
          _text(_school, 'Trường/đơn vị *', w),
          _text(_address, 'Hộ khẩu thường trú *', c.maxWidth, lines: 2),
        ],
      );
    },
  );

  Widget _timeAndFee() => LayoutBuilder(
    builder: (_, c) {
      final w = c.maxWidth >= 760 ? (c.maxWidth - 14) / 2 : c.maxWidth;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          _dateBox(
            'Bắt đầu thực hành *',
            _start,
            () => _pickDate(_start, (v) => _start = v),
            w,
          ),
          _dateBox(
            'Kết thúc thực hành *',
            _end,
            () => _pickDate(_end, (v) => _end = v, first: _start),
            w,
          ),
          _text(_tuition, 'Học phí', w, required: false),
          SizedBox(
            width: w,
            child: _fileTile(
              'File học phí',
              widget.initialData?.fileHocPhi,
              _tuitionFile,
              _removeTuition,
              (f) => setState(() {
                _tuitionFile = f;
                _removeTuition = false;
              }),
              () => setState(() {
                _tuitionFile = null;
                _removeTuition = true;
              }),
            ),
          ),
          _text(_note, 'Ghi chú', c.maxWidth, required: false, lines: 3),
        ],
      );
    },
  );

  Widget _periodList() => Column(
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton.icon(
          onPressed: () => _openPeriod(),
          icon: const Icon(Icons.add),
          label: const Text('Thêm khoa/phòng'),
        ),
      ),
      if (_periods.isEmpty)
        const Padding(
          padding: EdgeInsets.all(22),
          child: Text('Chưa có khoa/phòng thực hành.'),
        )
      else
        ..._periods.asMap().entries.map(
          (e) => Card(
            elevation: 0,
            color: const Color(0xFFF4F8FB),
            margin: const EdgeInsets.only(top: 9),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.local_hospital_outlined),
              ),
              title: Text(
                e.value.departmentName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${_display(e.value.start)} – ${_display(e.value.end)}\n'
                'Hướng dẫn: ${e.value.mentor.hoVaTen} (${e.value.mentor.maSo})',
              ),
              isThreeLine: true,
              trailing: Wrap(
                children: [
                  IconButton(
                    onPressed: () => _openPeriod(index: e.key),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _periods.removeAt(e.key)),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget _files() => LayoutBuilder(
    builder: (_, c) {
      final w = c.maxWidth >= 760 ? (c.maxWidth - 14) / 2 : c.maxWidth;
      return Wrap(
        spacing: 14,
        runSpacing: 12,
        children: [
          SizedBox(
            width: w,
            child: _fileTile(
              'Hợp đồng',
              widget.initialData?.fileHopDong,
              _contract,
              _removeContract,
              (f) => setState(() {
                _contract = f;
                _removeContract = false;
              }),
              () => setState(() {
                _contract = null;
                _removeContract = true;
              }),
            ),
          ),
          SizedBox(
            width: w,
            child: _fileTile(
              'Quyết định',
              widget.initialData?.fileQuyetDinh,
              _decision,
              _removeDecision,
              (f) => setState(() {
                _decision = f;
                _removeDecision = false;
              }),
              () => setState(() {
                _decision = null;
                _removeDecision = true;
              }),
            ),
          ),
          SizedBox(
            width: w,
            child: _fileTile(
              'Xác nhận thực hành',
              widget.initialData?.fileXacNhanTH,
              _confirmation,
              _removeConfirmation,
              (f) => setState(() {
                _confirmation = f;
                _removeConfirmation = false;
              }),
              () => setState(() {
                _confirmation = null;
                _removeConfirmation = true;
              }),
            ),
          ),
          SizedBox(
            width: w,
            child: _fileTile(
              'Thông báo tiếp nhận',
              widget.initialData?.fileThongBaoTiepNhan,
              _acceptanceNotice,
              _removeAcceptanceNotice,
              (f) => setState(() {
                _acceptanceNotice = f;
                _removeAcceptanceNotice = false;
              }),
              () => setState(() {
                _acceptanceNotice = null;
                _removeAcceptanceNotice = true;
              }),
            ),
          ),
        ],
      );
    },
  );

  Widget _checks() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _chip('Đề nghị thực hành', _proposal, (v) => _proposal = v),
      _chip('Sơ yếu lý lịch', _resume, (v) => _resume = v),
      _chip('CCCD', _hasCccd, (v) => _hasCccd = v),
      _chip('Văn bằng chuyên môn', _degree, (v) => _degree = v),
      _chip('Ảnh 3x4', _photo, (v) => _photo = v),
      _chip('Nhật ký thực hành', _journal, (v) => _journal = v),
      _chip('Báo cáo thực hành', _report, (v) => _report = v),
    ],
  );

  Widget _avatarPicker() => Row(
    children: [
      CircleAvatar(
        radius: 34,
        backgroundColor: const Color(0xFFE1F3FA),
        backgroundImage: _avatar?.bytes == null
            ? null
            : MemoryImage(_avatar!.bytes!),
        child: _avatar?.bytes == null
            ? const Icon(Icons.person, size: 34)
            : null,
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _avatar?.name ??
                  (_removeAvatar
                      ? 'Đã đánh dấu xóa ảnh'
                      : widget.initialData?.anhDaiDien?.fileName ??
                            'Ảnh đại diện'),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final file = await _pickFile(image: true);
                    if (file != null) {
                      setState(() {
                        _avatar = file;
                        _removeAvatar = false;
                      });
                    }
                  },
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Chọn ảnh'),
                ),
                if (_avatar != null || widget.initialData?.anhDaiDien != null)
                  TextButton(
                    onPressed: () => setState(() {
                      _avatar = null;
                      _removeAvatar = true;
                    }),
                    child: const Text('Xóa ảnh'),
                  ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _fileTile(
    String title,
    CapCchnFileModel? current,
    PlatformFile? selected,
    bool removed,
    ValueChanged<PlatformFile> select,
    VoidCallback remove,
  ) {
    final name = selected?.name ?? (removed ? null : current?.fileName);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFD9E4EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Color(0xFF087DBB)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  name ?? 'Chưa có file',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final f = await _pickFile();
              if (f != null) select(f);
            },
            icon: const Icon(Icons.upload_file_outlined),
          ),
          if (name != null)
            IconButton(
              onPressed: remove,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFDDE7ED)),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF087DBB)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const Divider(height: 24),
        child,
      ],
    ),
  );

  Widget _text(
    TextEditingController c,
    String label,
    double width, {
    bool required = true,
    int lines = 1,
  }) => SizedBox(
    width: width,
    child: TextFormField(
      controller: c,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập $label' : null
          : null,
    ),
  );

  Widget _dateBox(
    String label,
    DateTime? date,
    VoidCallback tap,
    double width,
  ) => SizedBox(
    width: width,
    child: InkWell(
      onTap: tap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(date == null ? 'Chọn ngày' : _display(date)),
      ),
    ),
  );

  Widget _drop<T>(
    String label,
    T value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> changed,
    double width,
  ) => SizedBox(
    width: width,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: changed,
    ),
  );

  Widget _chip(String text, bool value, ValueChanged<bool> changed) =>
      FilterChip(
        label: Text(text),
        selected: value,
        onSelected: (v) => setState(() => changed(v)),
      );
  Widget _errorBox(String text) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEEEE),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
    ),
  );
  static String _apiDate(DateTime v) =>
      '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
  static String _display(DateTime v) => DateFormat('dd/MM/yyyy').format(v);
  static String _msg(Object e) =>
      e.toString().replaceFirst('Exception: ', '').trim();
}

class _PeriodDialog extends StatefulWidget {
  final CapCchnProvider provider;
  final CapCchnCatalog catalog;
  final int employeeType;
  final DateTime? overallStart, overallEnd;
  final int? capCchnId;
  final _PeriodDraft? initial;
  const _PeriodDialog({
    required this.provider,
    required this.catalog,
    required this.employeeType,
    required this.overallStart,
    required this.overallEnd,
    required this.capCchnId,
    this.initial,
  });

  @override
  State<_PeriodDialog> createState() => _PeriodDialogState();
}

class _PeriodDialogState extends State<_PeriodDialog> {
  int? _department;
  DateTime? _start, _end;
  CapCchnMentorOption? _mentor;
  List<CapCchnMentorOption> _options = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _department = widget.initial?.departmentId;
    _start = widget.initial?.start ?? widget.overallStart;
    _end = widget.initial?.end ?? widget.overallEnd;
    _mentor = widget.initial?.mentor;
    if (_department != null && _start != null && _end != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _date(bool start) async {
    final value = await showDatePicker(
      context: context,
      initialDate:
          (start ? _start : _end) ?? widget.overallStart ?? DateTime.now(),
      firstDate: widget.overallStart ?? DateTime(2000),
      lastDate: widget.overallEnd ?? DateTime(2100),
    );
    if (value != null) {
      setState(() {
        if (start) {
          _start = value;
        } else {
          _end = value;
        }
        _mentor = null;
      });
      await _load();
    }
  }

  Future<void> _load() async {
    if (_department == null ||
        _start == null ||
        _end == null ||
        _end!.isBefore(_start!)) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.provider.getMentorOptions(
        idKhoaPhong: _department!,
        loaiNhanVien: widget.employeeType,
        ngayBatDau: _start!,
        ngayKetThuc: _end!,
        excludeCapCchnId: widget.capCchnId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _options = rows;
        if (_mentor != null) {
          final matched = _options.where((x) => x.maSo == _mentor!.maSo);
          if (matched.isEmpty) {
            _options.insert(0, _mentor!);
          } else {
            _mentor = matched.first;
          }
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = _CapCchnFormDialogState._msg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseDepartment() async {
    final selected = await showDialog<CapCchnCatalogItem>(
      context: context,
      builder: (_) => _DepartmentSearchDialog(
        items: widget.catalog.khoaPhongs,
        selectedId: _department,
      ),
    );
    if (selected == null || selected.id == _department) return;
    setState(() {
      _department = selected.id;
      _mentor = null;
      _options = [];
    });
    await _load();
  }

  Future<void> _chooseMentor() async {
    if (_department == null || _start == null || _end == null) {
      setState(
        () => _error = 'Vui lòng chọn khoa/phòng và khoảng thời gian trước.',
      );
      return;
    }
    if (_loading) return;
    final selected = await showDialog<CapCchnMentorOption>(
      context: context,
      builder: (_) => _MentorSearchDialog(
        items: _options,
        selectedCode: _mentor?.maSo,
        requestedStart: _start!,
        requestedEnd: _end!,
        latestAllowedEnd: widget.overallEnd,
      ),
    );
    if (selected != null) {
      setState(() {
        _mentor = selected;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Phân công khoa/phòng'),
    content: SizedBox(
      width: 620,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _searchField(
            label: 'Khoa/phòng *',
            value: _department == null
                ? null
                : widget.catalog.khoaPhongs
                      .where((x) => x.id == _department)
                      .map((x) => x.ten)
                      .firstOrNull,
            hint: 'Tìm và chọn khoa/phòng',
            icon: Icons.apartment_outlined,
            onTap: _chooseDepartment,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dateField('Từ ngày', _start, () => _date(true))),
              const SizedBox(width: 10),
              Expanded(child: _dateField('Đến ngày', _end, () => _date(false))),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          _searchField(
            label: 'Người hướng dẫn *',
            value: _mentor == null
                ? null
                : '${_mentor!.hoVaTen} (${_mentor!.maSo}) • '
                      '${_mentor!.soNguoiDangHuongDan}/5',
            hint: _options.isEmpty
                ? 'Không có nhân sự phù hợp'
                : 'Tìm theo tên hoặc mã nhân viên',
            icon: Icons.person_search_outlined,
            onTap: _chooseMentor,
          ),
          if (_mentor != null) _mentorSummary(_mentor!),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (_department == null ||
              _start == null ||
              _end == null ||
              _mentor == null) {
            setState(
              () => _error =
                  'Vui lòng nhập đủ khoa/phòng, thời gian và người hướng dẫn.',
            );
            return;
          }
          if (_mentor!.daDuSoLuong) {
            setState(
              () => _error =
                  'Người hướng dẫn đã đủ 5 người trong thời gian này. '
                  'Vui lòng chọn người khác hoặc đổi thời gian.',
            );
            return;
          }
          final department = widget.catalog.khoaPhongs.firstWhere(
            (x) => x.id == _department,
          );
          Navigator.pop(
            context,
            _PeriodDraft(
              departmentId: department.id,
              departmentName: department.ten,
              start: _start!,
              end: _end!,
              mentor: _mentor!,
            ),
          );
        },
        child: const Text('Xác nhận'),
      ),
    ],
  );

  Widget _searchField({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(Icons.search_rounded),
      ),
      child: Text(
        value ?? hint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: value == null ? Colors.blueGrey : null,
          fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _mentorSummary(CapCchnMentorOption mentor) {
    final color = mentor.daDuSoLuong
        ? const Color(0xFFD33C32)
        : const Color(0xFF16845E);
    final suggestion = mentor.ngayBatDauGoiY == null
        ? null
        : '${_formatDate(mentor.ngayBatDauGoiY)} – '
              '${_formatDate(mentor.ngayKetThucGoiY)}';
    final suggestionAllowed =
        widget.overallEnd == null ||
        mentor.ngayKetThucGoiY == null ||
        !mentor.ngayKetThucGoiY!.isAfter(widget.overallEnd!);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        border: Border.all(color: color.withValues(alpha: .28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mentor.daDuSoLuong
                ? 'Đã đủ ${mentor.soNguoiDangHuongDan}/5 người'
                : 'Đang hướng dẫn ${mentor.soNguoiDangHuongDan}/5 người',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          if (mentor.nguoiDangHuongDan.isNotEmpty) ...[
            const SizedBox(height: 7),
            ...mentor.nguoiDangHuongDan.map(
              (x) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${x.hoVaTen}: ${_formatDate(x.ngayBatDau)} – '
                  '${_formatDate(x.ngayKetThuc)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
          if (suggestion != null) ...[
            const SizedBox(height: 5),
            Text(
              mentor.daDuSoLuong
                  ? suggestionAllowed
                        ? 'Gợi ý khoảng hợp lệ gần nhất: $suggestion'
                        : 'Không còn khoảng đủ dài trong thời gian thực hành chung.'
                  : 'Khoảng đang chọn hợp lệ: $suggestion',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime? value) =>
      value == null ? '—' : DateFormat('dd/MM/yyyy').format(value);

  Widget _dateField(String label, DateTime? value, VoidCallback tap) => InkWell(
    onTap: tap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      child: Text(
        value == null ? 'Chọn ngày' : DateFormat('dd/MM/yyyy').format(value),
      ),
    ),
  );
}

class _DepartmentSearchDialog extends StatefulWidget {
  final List<CapCchnCatalogItem> items;
  final int? selectedId;

  const _DepartmentSearchDialog({required this.items, this.selectedId});

  @override
  State<_DepartmentSearchDialog> createState() =>
      _DepartmentSearchDialogState();
}

class _DepartmentSearchDialogState extends State<_DepartmentSearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = _normalize(_query);
    final filtered = widget.items
        .where(
          (x) => normalized.isEmpty || _normalize(x.ten).contains(normalized),
        )
        .toList();
    return AlertDialog(
      title: const Text('Chọn khoa/phòng'),
      content: SizedBox(
        width: 520,
        height: MediaQuery.sizeOf(context).height * .62,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Nhập tên khoa/phòng...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Không tìm thấy khoa/phòng.'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final item = filtered[index];
                        final selected = item.id == widget.selectedId;
                        return ListTile(
                          selected: selected,
                          leading: const Icon(Icons.apartment_outlined),
                          title: Text(item.ten),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF16845E),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _MentorSearchDialog extends StatefulWidget {
  final List<CapCchnMentorOption> items;
  final String? selectedCode;
  final DateTime requestedStart;
  final DateTime requestedEnd;
  final DateTime? latestAllowedEnd;

  const _MentorSearchDialog({
    required this.items,
    required this.selectedCode,
    required this.requestedStart,
    required this.requestedEnd,
    this.latestAllowedEnd,
  });

  @override
  State<_MentorSearchDialog> createState() => _MentorSearchDialogState();
}

class _MentorSearchDialogState extends State<_MentorSearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = _normalize(_query);
    final filtered = widget.items.where((x) {
      if (normalized.isEmpty) return true;
      return _normalize(x.hoVaTen).contains(normalized) ||
          _normalize(x.maSo).contains(normalized);
    }).toList();
    return AlertDialog(
      title: const Text('Chọn người hướng dẫn'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      content: SizedBox(
        width: 720,
        height: MediaQuery.sizeOf(context).height * .70,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Tìm theo họ tên hoặc mã nhân viên...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 9),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Đang kiểm tra khoảng ${_date(widget.requestedStart)} – '
                '${_date(widget.requestedEnd)}.',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 9),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Không tìm thấy nhân sự phù hợp.'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) => _mentorTile(filtered[index]),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Widget _mentorTile(CapCchnMentorOption mentor) {
    final full = mentor.daDuSoLuong;
    final selected = mentor.maSo == widget.selectedCode;
    final color = full ? const Color(0xFFD33C32) : const Color(0xFF087DBB);
    final assignments = mentor.nguoiDangHuongDan;
    final suggestion = mentor.ngayBatDauGoiY == null
        ? null
        : '${_date(mentor.ngayBatDauGoiY)} – '
              '${_date(mentor.ngayKetThucGoiY)}';
    final suggestionAllowed =
        widget.latestAllowedEnd == null ||
        mentor.ngayKetThucGoiY == null ||
        !mentor.ngayKetThucGoiY!.isAfter(widget.latestAllowedEnd!);

    return Material(
      color: full
          ? const Color(0xFFFFF1F0)
          : selected
          ? const Color(0xFFEAF6FB)
          : const Color(0xFFF7FAFC),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: full
              ? const Color(0xFFF0AAA4)
              : selected
              ? const Color(0xFF74BDE0)
              : const Color(0xFFDCE6EC),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: full ? null : () => Navigator.pop(context, mentor),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: color.withValues(alpha: .12),
                    child: Icon(Icons.person_outline, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentor.hoVaTen,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Mã NV: ${mentor.maSo}',
                          style: const TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${mentor.soNguoiDangHuongDan}/5',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              if (assignments.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  'Đang hướng dẫn trong khoảng đã chọn:',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                ...assignments.map(
                  (x) => Text(
                    '• ${x.hoVaTen} (${_date(x.ngayBatDau)} – '
                    '${_date(x.ngayKetThuc)})',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
              ],
              if (suggestion != null) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      full ? Icons.event_available : Icons.check_circle,
                      size: 16,
                      color: full
                          ? const Color(0xFFE07920)
                          : const Color(0xFF16845E),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        full
                            ? suggestionAllowed
                                  ? 'Đã đủ người. Gợi ý lịch hợp lệ: $suggestion'
                                  : 'Đã đủ người và không còn khoảng đủ dài '
                                        'trong thời gian thực hành chung.'
                            : 'Có thể chọn trong khoảng hiện tại: $suggestion',
                        style: TextStyle(
                          color: full
                              ? const Color(0xFFB35613)
                              : const Color(0xFF16845E),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _date(DateTime? value) =>
      value == null ? '—' : DateFormat('dd/MM/yyyy').format(value);
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

class _PeriodDraft {
  final int departmentId;
  final String departmentName;
  final DateTime start, end;
  final CapCchnMentorOption mentor;
  const _PeriodDraft({
    required this.departmentId,
    required this.departmentName,
    required this.start,
    required this.end,
    required this.mentor,
  });

  factory _PeriodDraft.fromModel(CapCchnMentorModel x) => _PeriodDraft(
    departmentId: x.idKhoaPhong,
    departmentName: x.tenKhoaPhong ?? 'Khoa/phòng #${x.idKhoaPhong}',
    start: x.ngayBatDau ?? DateTime.now(),
    end: x.ngayKetThuc ?? DateTime.now(),
    mentor: CapCchnMentorOption(maSo: x.maSo, hoVaTen: x.hoVaTen ?? x.maSo),
  );
  Map<String, dynamic> toJson() => {
    'maSo': mentor.maSo,
    'idKhoaPhong': departmentId,
    'ngayBatDau': _CapCchnFormDialogState._apiDate(start),
    'ngayKetThuc': _CapCchnFormDialogState._apiDate(end),
  };
}
