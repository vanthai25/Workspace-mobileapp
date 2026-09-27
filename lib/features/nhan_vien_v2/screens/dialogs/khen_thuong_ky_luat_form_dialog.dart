import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/khen_thuong_ky_luat_models.dart';
import '../../../../providers/nhan_vien_v2_provider.dart';

class KhenThuongKyLuatFormDialog extends StatefulWidget {
  final String maSo;
  final bool isKhenThuong;
  final KhenThuongNhanVienModel? khenThuong;
  final KyLuatNhanVienModel? kyLuat;

  const KhenThuongKyLuatFormDialog.khenThuong({
    super.key,
    required this.maSo,
    this.khenThuong,
  }) : isKhenThuong = true,
       kyLuat = null;

  const KhenThuongKyLuatFormDialog.kyLuat({
    super.key,
    required this.maSo,
    this.kyLuat,
  }) : isKhenThuong = false,
       khenThuong = null;

  bool get isEdit => khenThuong != null || kyLuat != null;

  @override
  State<KhenThuongKyLuatFormDialog> createState() =>
      _KhenThuongKyLuatFormDialogState();
}

class _KhenThuongKyLuatFormDialogState
    extends State<KhenThuongKyLuatFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lyDo;
  late final TextEditingController _hinhThuc;
  late final TextEditingController _canCuDiaDiem;
  late final TextEditingController _moTa;
  late final TextEditingController _soQuyetDinh;
  late final TextEditingController _nguoiKy;
  late final TextEditingController _soTien;
  late final TextEditingController _soDiem;
  late final TextEditingController _soThangThamNien;
  late final TextEditingController _ghiChu;
  DateTime? _ngayChinh;
  DateTime? _ngayXayRa;
  DateTime? _ngayBatDauKeoDaiThamNien;
  bool _keoDaiThamNien = false;
  bool _xoaFile = false;
  PlatformFile? _file;

  @override
  void initState() {
    super.initState();
    final reward = widget.khenThuong;
    final discipline = widget.kyLuat;
    _lyDo = TextEditingController(
      text: reward?.lyDoKhen ?? discipline?.lyDoKyLuat ?? '',
    );
    _hinhThuc = TextEditingController(
      text: reward?.hinhThucKhen ?? discipline?.hinhThucKyLuat ?? '',
    );
    _canCuDiaDiem = TextEditingController(
      text: reward?.canCuKhen ?? discipline?.diaDiemXayRa ?? '',
    );
    _moTa = TextEditingController(text: discipline?.moTaSuViec ?? '');
    _soQuyetDinh = TextEditingController(
      text: reward?.soQuyetDinhKhen ?? discipline?.soQuyetDinhKyLuat ?? '',
    );
    _nguoiKy = TextEditingController(
      text: reward?.nguoiKhen ?? discipline?.nguoiKy ?? '',
    );
    _soTien = TextEditingController(
      text: _numberText(reward?.soTienKhen ?? discipline?.soTienKyLuat),
    );
    _soDiem = TextEditingController(
      text: '${reward?.soDiemKhen ?? discipline?.soDiemKyLuat ?? ''}',
    );
    _soThangThamNien = TextEditingController(
      text: '${discipline?.soThangKeoDaiThamNien ?? ''}',
    );
    _ghiChu = TextEditingController(
      text: reward?.ghiChu ?? discipline?.ghiChu ?? '',
    );
    _ngayChinh = reward?.ngayKhen ?? discipline?.ngayKy;
    _ngayXayRa = discipline?.ngayXayRa;
    _ngayBatDauKeoDaiThamNien = discipline?.ngayBatDauKeoDaiThamNien;
    _keoDaiThamNien = discipline?.keoDaiThamNien ?? false;
  }

  String _numberText(double? value) => value == null
      ? ''
      : value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  @override
  void dispose() {
    for (final controller in [
      _lyDo,
      _hinhThuc,
      _canCuDiaDiem,
      _moTa,
      _soQuyetDinh,
      _nguoiKy,
      _soTien,
      _soDiem,
      _soThangThamNien,
      _ghiChu,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NhanVienV2Provider>();
    final title = widget.isKhenThuong ? 'khen thưởng' : 'kỷ luật';
    final existingFile = widget.khenThuong?.file ?? widget.kyLuat?.file;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              color: const Color(0xFF0879BE),
              child: Row(
                children: [
                  Icon(
                    widget.isKhenThuong
                        ? Icons.emoji_events_outlined
                        : Icons.gavel_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.isEdit ? 'Sửa' : 'Thêm'} $title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: provider.isSaving
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _field(
                        _lyDo,
                        'Lý do ${widget.isKhenThuong ? 'khen thưởng' : 'kỷ luật'} *',
                        required: true,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        _hinhThuc,
                        'Hình thức *',
                        required: true,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _row([
                        _field(
                          _canCuDiaDiem,
                          widget.isKhenThuong
                              ? 'Căn cứ khen'
                              : 'Địa điểm xảy ra',
                        ),
                        _dateField(
                          widget.isKhenThuong ? 'Ngày khen *' : 'Ngày ký *',
                          _ngayChinh,
                          (date) => setState(() => _ngayChinh = date),
                        ),
                      ]),
                      if (!widget.isKhenThuong) ...[
                        const SizedBox(height: 12),
                        _row([
                          _dateField(
                            'Ngày xảy ra',
                            _ngayXayRa,
                            (date) => setState(() => _ngayXayRa = date),
                          ),
                          _field(_moTa, 'Mô tả sự việc', maxLines: 2),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      _row([
                        _field(_soQuyetDinh, 'Số quyết định'),
                        _field(
                          _nguoiKy,
                          widget.isKhenThuong ? 'Người khen/ký' : 'Người ký',
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _row([
                        _field(
                          _soTien,
                          widget.isKhenThuong
                              ? 'Số tiền khen'
                              : 'Số tiền kỷ luật',
                          number: true,
                        ),
                        _field(
                          _soDiem,
                          widget.isKhenThuong
                              ? 'Số điểm khen'
                              : 'Số điểm kỷ luật',
                          number: true,
                          integer: true,
                        ),
                      ]),
                      if (!widget.isKhenThuong) ...[
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Kéo dài thời gian nâng bậc/thâm niên',
                          ),
                          value: _keoDaiThamNien,
                          onChanged: (value) =>
                              setState(() => _keoDaiThamNien = value),
                        ),
                        if (_keoDaiThamNien) ...[
                          _row([
                            _field(
                              _soThangThamNien,
                              'Số tháng kéo dài * (12 tháng = 1 năm)',
                              required: true,
                              number: true,
                              integer: true,
                            ),
                            _dateField(
                              'Ngày bắt đầu áp dụng',
                              _ngayBatDauKeoDaiThamNien,
                              (date) => setState(
                                () => _ngayBatDauKeoDaiThamNien = date,
                              ),
                            ),
                          ]),
                          const Padding(
                            padding: EdgeInsets.only(top: 7, bottom: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Nếu không chọn ngày bắt đầu, hệ thống dùng ngày ký quyết định.',
                                style: TextStyle(
                                  color: Color(0xFF66788A),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                      _field(_ghiChu, 'Ghi chú', maxLines: 2),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCE7F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.attach_file, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _file?.name ??
                                        existingFile?.fileName ??
                                        'Chưa chọn file (PDF, Word, JPG, PNG; tối đa 10 MB)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: _pickFile,
                                  child: const Text('Chọn file'),
                                ),
                              ],
                            ),
                            if (existingFile != null && _file == null)
                              CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Xóa file đính kèm hiện tại'),
                                value: _xoaFile,
                                onChanged: (value) =>
                                    setState(() => _xoaFile = value ?? false),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: provider.isSaving
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: provider.isSaving ? null : _save,
                    icon: provider.isSaving
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(provider.isSaving ? 'Đang lưu...' : 'Lưu'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns = constraints.maxWidth >= 560;
      final width = twoColumns
          ? (constraints.maxWidth - 12) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    bool integer = false,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: number
        ? TextInputType.numberWithOptions(decimal: !integer)
        : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return 'Vui lòng nhập thông tin này';
      if (number && text.isNotEmpty) {
        final parsed = integer
            ? int.tryParse(text)
            : double.tryParse(text.replaceAll(',', '.'));
        if (parsed == null || parsed < 0) return 'Giá trị không hợp lệ';
        if (integer && parsed == 0) return 'Số tháng phải lớn hơn 0';
      }
      return null;
    },
  );

  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onChanged,
  ) => InkWell(
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        firstDate: DateTime(1950),
        lastDate: DateTime(2100),
        initialDate: value ?? DateTime.now(),
      );
      if (date != null) onChanged(date);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Text(value == null ? 'Chọn ngày' : _dateText(value)),
    ),
  );

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && mounted) {
      final file = result.files.single;
      if (file.size > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File không được vượt quá 10 MB.')),
        );
        return;
      }
      setState(() {
        _file = file;
        _xoaFile = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ngayChinh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isKhenThuong
                ? 'Vui lòng chọn ngày khen.'
                : 'Vui lòng chọn ngày ký.',
          ),
        ),
      );
      return;
    }
    final provider = context.read<NhanVienV2Provider>();
    final money = double.tryParse(_soTien.text.trim().replaceAll(',', '.'));
    final points = int.tryParse(_soDiem.text.trim());
    final common = <String, dynamic>{
      'xoaFile': _xoaFile,
      'ghiChu': _nullIfEmpty(_ghiChu.text),
    };
    final success = widget.isKhenThuong
        ? await provider.saveKhenThuong(
            maSo: widget.maSo,
            maKhenThuong: widget.khenThuong?.maKhenThuong,
            file: _file,
            data: {
              ...common,
              'lyDoKhen': _lyDo.text.trim(),
              'canCuKhen': _nullIfEmpty(_canCuDiaDiem.text),
              'hinhThucKhen': _hinhThuc.text.trim(),
              'soTienKhen': money,
              'soDiemKhen': points,
              'ngayKhen': _apiDate(_ngayChinh!),
              'soQuyetDinhKhen': _nullIfEmpty(_soQuyetDinh.text),
              'nguoiKhen': _nullIfEmpty(_nguoiKy.text),
            },
          )
        : await provider.saveKyLuat(
            maSo: widget.maSo,
            maKyLuat: widget.kyLuat?.maKyLuat,
            file: _file,
            data: {
              ...common,
              'lyDoKyLuat': _lyDo.text.trim(),
              'diaDiemXayRa': _nullIfEmpty(_canCuDiaDiem.text),
              'moTaSuViec': _nullIfEmpty(_moTa.text),
              'hinhThucKyLuat': _hinhThuc.text.trim(),
              'ngayXayRa': _ngayXayRa == null ? null : _apiDate(_ngayXayRa!),
              'ngayKy': _apiDate(_ngayChinh!),
              'nguoiKy': _nullIfEmpty(_nguoiKy.text),
              'soTienKyLuat': money,
              'soDiemKyLuat': points,
              'soQuyetDinhKyLuat': _nullIfEmpty(_soQuyetDinh.text),
              'keoDaiThamNien': _keoDaiThamNien,
              'soThangKeoDaiThamNien': _keoDaiThamNien
                  ? int.tryParse(_soThangThamNien.text.trim())
                  : null,
              'ngayBatDauKeoDaiThamNien':
                  !_keoDaiThamNien || _ngayBatDauKeoDaiThamNien == null
                  ? null
                  : _apiDate(_ngayBatDauKeoDaiThamNien!),
            },
          );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không thể lưu dữ liệu.'),
        ),
      );
    }
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();
  String _apiDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _dateText(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
