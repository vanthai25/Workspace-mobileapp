import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/dao_tao_v2_models.dart';
import '../../../../../../providers/dao_tao_v2_provider.dart';
import 'dao_tao_design.dart';
import 'lop_khoa_phong_selector.dart';

class LopDaoTaoFormDialog extends StatefulWidget {
  final LopDaoTaoV2Model? item;

  final bool isRole47;

  const LopDaoTaoFormDialog({super.key, this.item, required this.isRole47});
  bool get isEdit => item != null;

  @override
  State<LopDaoTaoFormDialog> createState() => _LopDaoTaoFormDialogState();
}

class _LopDaoTaoFormDialogState extends State<LopDaoTaoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  bool get _isExpiredNameOnly =>
      widget.isRole47 &&
      widget.item?.isHetHanDangKy == true &&
      widget.item?.canEdit == true;

  late final TextEditingController _tenLopController;
  late final TextEditingController _soTietController;
  late final TextEditingController _kinhPhiController;
  late final TextEditingController _chuKyController;
  late final TextEditingController _ghiChuController;
  late final TextEditingController _donViController;
  late final TextEditingController _tenChungChiController;
  late final TextEditingController _baoCaoVienController;

  late final TextEditingController _donViGiangDayController;

  late final TextEditingController _linkZoomController;

  late final TextEditingController _linkChatController;

  late final TextEditingController _zoomIdController;

  late final TextEditingController _zoomPasscodeController;
  late final TextEditingController _kpController;

  late final TextEditingController _thoiGianDetailsController;

  late final TextEditingController _diaDiemController;

  late final TextEditingController _tpThamDuController;
  bool _isOnline = false;
  int _phamViDaoTao = 1;
  final Set<int> _idKhoaPhongs = {};
  bool _khoaPhongsInitialized = false;
  int? _idHinhThucDaoTao;
  int? _idNguonKinhPhi;
  int? _idLoaiHinhDaoTao;

  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;

  DateTime? _batDauDangKy;
  DateTime? _ketThucDangKy;

  TimeOfDay? _gioBatDauVanTayVao;
  TimeOfDay? _gioKetThucVanTayVao;
  TimeOfDay? _gioBatDauVanTayRa;
  TimeOfDay? _gioKetThucVanTayRa;

  static const int _maxFileCount = 10;

  static const int _maxFileSize = 20 * 1024 * 1024;

  static const int _maxTotalFileSize = 100 * 1024 * 1024;

  static const List<String> _allowedExtensions = [
    'pdf',

    'doc',
    'docx',

    'xls',
    'xlsx',

    'ppt',
    'pptx',

    'txt',
    'csv',

    'jpg',
    'jpeg',
    'png',
    'webp',

    'zip',
    'rar',
    '7z',
  ];

  List<LopDaoTaoFileV2Model> _existingFiles = [];

  final List<fp.PlatformFile> _newFiles = [];

  final Set<int> _fileIdsToDelete = {};

  bool _isLoadingFiles = false;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    if (item != null) {
      _phamViDaoTao = item.phamViDaoTao;
    } else {
      _phamViDaoTao = widget.isRole47 ? 1 : 2;
    }
    _tenLopController = TextEditingController(text: item?.tenLopDaoTao ?? '');

    _soTietController = TextEditingController(
      text: item?.soTiet?.toString() ?? '',
    );

    _kinhPhiController = TextEditingController(
      text: item?.kinhPhi?.toStringAsFixed(0) ?? '',
    );

    _chuKyController = TextEditingController(
      text: item?.chuKy?.toString() ?? '',
    );

    _ghiChuController = TextEditingController(text: item?.ghiChu ?? '');

    _donViController = TextEditingController(text: item?.donViDaoTao ?? '');

    _tenChungChiController = TextEditingController(
      text: item?.tenChungChi ?? '',
    );

    _idHinhThucDaoTao = item?.idHinhThucDaoTao;

    _idNguonKinhPhi = item?.idNguonKinhPhi;

    _idLoaiHinhDaoTao = item?.idLoaiHinhDaoTao;

    _ngayBatDau = item?.ngayBatDau;

    _ngayKetThuc = item?.ngayKetThuc;

    _batDauDangKy = item?.batDauDangKy;

    _ketThucDangKy = item?.ketThucDangKy;

    _gioBatDauVanTayVao = _parseTime(item?.gioBatDauVanTayVao);

    _gioKetThucVanTayVao = _parseTime(item?.gioKetThucVanTayVao);

    _gioBatDauVanTayRa = _parseTime(item?.gioBatDauVanTayRa);

    _gioKetThucVanTayRa = _parseTime(item?.gioKetThucVanTayRa);
    _baoCaoVienController = TextEditingController(text: item?.baoCaoVien ?? '');

    _donViGiangDayController = TextEditingController(
      text: item?.donViGiangDay ?? '',
    );

    _isOnline = item?.isOnline ?? false;

    _linkZoomController = TextEditingController();

    _linkChatController = TextEditingController();

    _zoomIdController = TextEditingController();

    _zoomPasscodeController = TextEditingController();
    _kpController = TextEditingController(text: item?.kp ?? '');

    _thoiGianDetailsController = TextEditingController(
      text: item?.thoiGianDetails ?? '',
    );

    _diaDiemController = TextEditingController(text: item?.diaDiem ?? '');

    _tpThamDuController = TextEditingController(text: item?.tpThamDu ?? '');
    if (widget.isEdit && !_isExpiredNameOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingFiles();
      });
    }
  }

  @override
  void dispose() {
    _tenLopController.dispose();
    _soTietController.dispose();
    _kinhPhiController.dispose();
    _chuKyController.dispose();
    _ghiChuController.dispose();
    _donViController.dispose();
    _tenChungChiController.dispose();
    _baoCaoVienController.dispose();
    _donViGiangDayController.dispose();
    _linkZoomController.dispose();
    _linkChatController.dispose();
    _zoomIdController.dispose();
    _zoomPasscodeController.dispose();
    _kpController.dispose();

    _thoiGianDetailsController.dispose();

    _diaDiemController.dispose();

    _tpThamDuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DaoTaoV2Provider>();

    if (_isExpiredNameOnly) {
      return _buildExpiredNameDialog(provider);
    }

    final danhMuc = provider.danhMuc;

    if (danhMuc == null) {
      return Theme(
        data: daoTaoTheme(context),
        child: const AlertDialog(
          content: SizedBox(
            width: 500,
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    final idKhoaPhongGoc = widget.item?.phamViDaoTao == 2
        ? widget.item?.idKhoaPhong
        : danhMuc.idKhoaPhongHienTai;
    if (!_khoaPhongsInitialized) {
      _idKhoaPhongs.addAll(widget.item?.idKhoaPhongs ?? []);
      if (idKhoaPhongGoc != null) _idKhoaPhongs.add(idKhoaPhongGoc);
      _khoaPhongsInitialized = true;
    }
    final lockedKhoaPhongIds = <int>{
      ?idKhoaPhongGoc,
      if ((widget.item?.soNguoiDangKy ?? 0) > 0)
        ...?widget.item?.idKhoaPhongs,
    };

    final hinhThucItems = _buildDanhMucItems(
      danhMuc.hinhThucDaoTaos,
      selectedId: _idHinhThucDaoTao,
      oldName: widget.item?.tenHinhThucDaoTao,
    );

    final loaiHinhItems = _buildDanhMucItems(
      danhMuc.loaiHinhDaoTaos,
      selectedId: _idLoaiHinhDaoTao,
      oldName: widget.item?.tenLoaiHinhDaoTao,
    );

    final nguonKinhPhiItems = _buildDanhMucItems(
      danhMuc.nguonKinhPhis,
      selectedId: _idNguonKinhPhi,
      oldName: widget.item?.tenNguonKinhPhi,
    );

    return Theme(
      data: daoTaoTheme(context),
      child: AlertDialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
        contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2999D7), DaoTaoColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                widget.isEdit ? Icons.edit_note_rounded : Icons.school_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEdit ? 'Cập nhật lớp đào tạo' : 'Tạo lớp đào tạo',
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.isEdit
                        ? 'Điều chỉnh thông tin và lịch tổ chức lớp học'
                        : 'Khai báo đầy đủ thông tin để mở đăng ký lớp học',
                    style: const TextStyle(
                      color: DaoTaoColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Đóng',
              onPressed: provider.isSaving
                  ? null
                  : () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: SizedBox(
          width: 900,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =============================================
                  // TÊN LỚP
                  // =============================================
                  TextFormField(
                    controller: _tenLopController,
                    decoration: const InputDecoration(
                      labelText: 'Tên lớp đào tạo *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên lớp đào tạo.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  if (widget.isRole47) ...[
                    _sectionHeading(
                      Icons.apartment_rounded,
                      'Phạm vi lớp đào tạo',
                      'Quy định đối tượng có thể nhìn thấy và đăng ký lớp',
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,

                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),

                        border: Border.all(color: DaoTaoColors.border),

                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: CheckboxListTile(
                        value: _phamViDaoTao == 1,

                        controlAffinity: ListTileControlAffinity.leading,

                        title: const Text(
                          'Áp dụng toàn viện',

                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),

                        subtitle: Text(
                          _phamViDaoTao == 1
                              ? 'Tất cả nhân viên trong viện có thể nhìn thấy và đăng ký lớp này.'
                              : 'Chỉ nhân viên thuộc các khoa/phòng được chọn có thể nhìn thấy và đăng ký.',

                          style: const TextStyle(
                            color: DaoTaoColors.muted,

                            fontSize: 12,
                          ),
                        ),

                        onChanged: provider.isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _phamViDaoTao = value == true ? 1 : 2;
                                });
                              },
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],

                  if (_phamViDaoTao == 2) ...[
                    LopKhoaPhongSelector(
                      items: danhMuc.khoaPhongs,
                      selectedIds: _idKhoaPhongs,
                      lockedIds: lockedKhoaPhongIds,
                      enabled: !provider.isSaving,
                      onChanged: (ids) => setState(() {
                        _idKhoaPhongs
                          ..clear()
                          ..addAll(ids);
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // =============================================
                  // DANH MỤC
                  // =============================================
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _safeValue(
                            hinhThucItems,
                            _idHinhThucDaoTao,
                          ),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Hình thức đào tạo',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Chưa chọn'),
                            ),
                            ...hinhThucItems.map(
                              (e) => DropdownMenuItem<int?>(
                                value: e.id,
                                child: Text(
                                  e.ten,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _idHinhThucDaoTao = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: _safeValue(
                            loaiHinhItems,
                            _idLoaiHinhDaoTao,
                          ),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Loại hình đào tạo',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Chưa chọn'),
                            ),
                            ...loaiHinhItems.map(
                              (e) => DropdownMenuItem<int?>(
                                value: e.id,
                                child: Text(
                                  e.ten,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _idLoaiHinhDaoTao = value;
                            });
                          },
                        ),
                      ),

                      if (widget.isEdit) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _safeValue(
                              nguonKinhPhiItems,
                              _idNguonKinhPhi,
                            ),
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Nguồn kinh phí',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Chưa chọn'),
                              ),
                              ...nguonKinhPhiItems.map(
                                (e) => DropdownMenuItem<int?>(
                                  value: e.id,
                                  child: Text(
                                    e.ten,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _idNguonKinhPhi = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =============================================
                  // SỐ TIẾT - KINH PHÍ - CHU KỲ
                  // =============================================
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _soTietController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Giờ tín chỉ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),

                      if (widget.isEdit) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _kinhPhiController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Kinh phí',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _chuKyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Chu kỳ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =============================================
                  // NGÀY HỌC
                  // =============================================
                  _sectionHeading(
                    Icons.date_range_rounded,
                    'Thời gian đào tạo',
                    'Ngày bắt đầu và kết thúc chương trình',
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _dateTile(
                          label: 'Ngày bắt đầu',
                          value: _ngayBatDau,
                          onTap: () async {
                            final value = await _pickDate(_ngayBatDau);

                            if (value != null) {
                              setState(() {
                                _ngayBatDau = value;
                              });
                            }
                          },
                          onClear: () {
                            setState(() {
                              _ngayBatDau = null;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _dateTile(
                          label: 'Ngày kết thúc',
                          value: _ngayKetThuc,
                          onTap: () async {
                            final value = await _pickDate(_ngayKetThuc);

                            if (value != null) {
                              setState(() {
                                _ngayKetThuc = value;
                              });
                            }
                          },
                          onClear: () {
                            setState(() {
                              _ngayKetThuc = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =============================================
                  // ĐĂNG KÝ
                  // =============================================
                  _sectionHeading(
                    Icons.how_to_reg_rounded,
                    'Thời gian đăng ký',
                    'Khoảng thời gian nhân viên được phép đăng ký',
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _dateTimeTile(
                          label: 'Bắt đầu đăng ký',
                          value: _batDauDangKy,
                          onTap: () async {
                            final value = await _pickDateTime(_batDauDangKy);

                            if (value != null) {
                              setState(() {
                                _batDauDangKy = value;
                              });
                            }
                          },
                          onClear: () {
                            setState(() {
                              _batDauDangKy = null;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _dateTimeTile(
                          label: 'Kết thúc đăng ký',
                          value: _ketThucDangKy,
                          onTap: () async {
                            final value = await _pickDateTime(_ketThucDangKy);

                            if (value != null) {
                              setState(() {
                                _ketThucDangKy = value;
                              });
                            }
                          },
                          onClear: () {
                            setState(() {
                              _ketThucDangKy = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =============================================
                  // ĐƠN VỊ + CHỨNG CHỈ
                  // =============================================
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _donViController,
                          decoration: const InputDecoration(
                            labelText: 'Đơn vị đào tạo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: TextFormField(
                          controller: _tenChungChiController,
                          decoration: const InputDecoration(
                            labelText: 'Tên chứng chỉ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _sectionHeading(
                    Icons.record_voice_over_rounded,
                    'Thông tin giảng dạy',
                    'Báo cáo viên và đơn vị giảng dạy',
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _baoCaoVienController,

                          decoration: const InputDecoration(
                            labelText: 'Báo cáo viên',

                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: TextFormField(
                          controller: _donViGiangDayController,

                          decoration: const InputDecoration(
                            labelText: 'Đơn vị giảng dạy',

                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _sectionHeading(
                    Icons.print_rounded,
                    'Thông tin phiếu điểm danh',
                    'Thông tin hiển thị trên bản in danh sách điểm danh',
                  ),

                  const SizedBox(height: 8),

                  // ==========================================================
                  // KHOA/PHÒNG + ĐỊA ĐIỂM
                  // ==========================================================
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _kpController,

                          maxLength: 255,

                          decoration: const InputDecoration(
                            labelText: 'Khoa / Phòng',

                            hintText: 'Ví dụ: Khoa Nội',

                            border: OutlineInputBorder(),

                            counterText: '',
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: TextFormField(
                          controller: _diaDiemController,

                          maxLength: 255,

                          decoration: const InputDecoration(
                            labelText: 'Địa điểm',

                            hintText: 'Ví dụ: Hội trường T',

                            border: OutlineInputBorder(),

                            counterText: '',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ==========================================================
                  // THỜI GIAN CHI TIẾT
                  // ==========================================================
                  TextFormField(
                    controller: _thoiGianDetailsController,

                    maxLength: 500,

                    decoration: const InputDecoration(
                      labelText: 'Thời gian chi tiết',

                      hintText: 'Ví dụ: 11h30 - 12h30',

                      border: OutlineInputBorder(),

                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==========================================================
                  // THÀNH PHẦN THAM DỰ
                  // ==========================================================
                  TextFormField(
                    controller: _tpThamDuController,

                    maxLength: 500,

                    maxLines: 2,

                    decoration: const InputDecoration(
                      labelText: 'Thành phần tham dự',

                      hintText: 'Ví dụ: Bác sĩ, Điều dưỡng, KTV, HS trưởng',

                      border: OutlineInputBorder(),

                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 16),
                  _sectionHeading(
                    Icons.video_camera_front_rounded,
                    'Học online',
                    'Cấu hình Zoom và kênh trao đổi',
                  ),

                  const SizedBox(height: 8),

                  SwitchListTile(
                    value: _isOnline,

                    contentPadding: EdgeInsets.zero,

                    title: const Text(
                      'Cho phép tham gia online',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),

                    subtitle: const Text(
                      'Khi bật, người đăng ký có thể chọn trực tiếp hoặc online.',
                    ),

                    onChanged: (value) {
                      setState(() {
                        _isOnline = value;
                      });
                    },
                  ),

                  if (_isOnline) ...[
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _linkZoomController,

                            decoration: const InputDecoration(
                              labelText: 'Link Zoom',

                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: TextFormField(
                            controller: _linkChatController,

                            decoration: const InputDecoration(
                              labelText: 'Link Chat',

                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _zoomIdController,

                            decoration: const InputDecoration(
                              labelText: 'Zoom ID',

                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: TextFormField(
                            controller: _zoomPasscodeController,

                            decoration: const InputDecoration(
                              labelText: 'Zoom Passcode',

                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // =============================================
                  // VÂN TAY
                  // =============================================
                  _sectionHeading(
                    Icons.fingerprint_rounded,
                    'Khung giờ vân tay',
                    'Thiết lập thời gian ghi nhận vào và ra lớp',
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _timeTile(
                          label: 'Bắt đầu vào',
                          value: _gioBatDauVanTayVao,
                          onChanged: (value) {
                            setState(() {
                              _gioBatDauVanTayVao = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _timeTile(
                          label: 'Kết thúc vào',
                          value: _gioKetThucVanTayVao,
                          onChanged: (value) {
                            setState(() {
                              _gioKetThucVanTayVao = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _timeTile(
                          label: 'Bắt đầu ra',
                          value: _gioBatDauVanTayRa,
                          onChanged: (value) {
                            setState(() {
                              _gioBatDauVanTayRa = value;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: _timeTile(
                          label: 'Kết thúc ra',
                          value: _gioKetThucVanTayRa,
                          onChanged: (value) {
                            setState(() {
                              _gioKetThucVanTayRa = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =============================================
                  // GHI CHÚ
                  // =============================================
                  TextFormField(
                    controller: _ghiChuController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =============================================
                  // TÀI LIỆU LỚP HỌC
                  // =============================================
                  _sectionHeading(
                    Icons.attach_file_rounded,
                    'Tài liệu lớp học',
                    'Tối đa 10 file, 20 MB/file, '
                        'tổng tối đa 100 MB',
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),

                      border: Border.all(color: DaoTaoColors.border),

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        if (_isLoadingFiles)
                          const Padding(
                            padding: EdgeInsets.all(16),

                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          // =====================================
                          // FILE CŨ
                          // =====================================
                          ..._existingFiles
                              .where(
                                (file) =>
                                    !_fileIdsToDelete.contains(file.idFile),
                              )
                              .map((file) => _existingFileTile(file)),

                          // =====================================
                          // FILE MỚI
                          // =====================================
                          ..._newFiles.asMap().entries.map(
                            (entry) => _newFileTile(entry.key, entry.value),
                          ),

                          if (_currentFileCount == 0)
                            Container(
                              width: double.infinity,

                              padding: const EdgeInsets.symmetric(vertical: 16),

                              alignment: Alignment.center,

                              child: const Text(
                                'Chưa có tài liệu đính kèm.',
                                style: TextStyle(color: DaoTaoColors.muted),
                              ),
                            ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$_currentFileCount / '
                                  '$_maxFileCount file'
                                  ' • '
                                  '${_formatFileSize(_currentTotalSize)}'
                                  ' / 100 MB',

                                  style: const TextStyle(
                                    color: DaoTaoColors.muted,

                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              OutlinedButton.icon(
                                onPressed: _currentFileCount >= _maxFileCount
                                    ? null
                                    : _pickFiles,

                                icon: const Icon(Icons.upload_file_rounded),

                                label: const Text('Chọn tài liệu'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: provider.isSaving ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: provider.isSaving ? null : _save,
            icon: provider.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(widget.isEdit ? 'Lưu thay đổi' : 'Thêm lớp'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredNameDialog(DaoTaoV2Provider provider) {
    return Theme(
      data: daoTaoTheme(context),
      child: AlertDialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
        contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DD),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFFD67B1F),
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sửa tên lớp đã hết hạn'),
                  SizedBox(height: 3),
                  Text(
                    'Quyền 47 chỉ được thay đổi tên lớp và tên chứng chỉ',
                    style: TextStyle(
                      color: DaoTaoColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Đóng',
              onPressed: provider.isSaving
                  ? null
                  : () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1D7B1)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_clock_outlined, color: Color(0xFFC36D18)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lớp đã hết hạn đăng ký. Các thông tin thời gian, phạm vi, tài liệu và học viên được khóa.',
                          style: TextStyle(
                            color: Color(0xFF85501C),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tenLopController,
                  autofocus: true,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Tên lớp đào tạo *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên lớp đào tạo.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tenChungChiController,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Tên chứng chỉ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: provider.isSaving ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: provider.isSaving ? null : _saveExpiredNames,
            icon: provider.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Lưu hai tên'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveExpiredNames() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<DaoTaoV2Provider>();
    final ok = await provider.updateLop(
      widget.item!.idLopDaoTao,
      <String, dynamic>{
        'tenLopDaoTao': _tenLopController.text.trim(),
        'tenChungChi': _nullText(_tenChungChiController.text),
      },
      files: const <fp.PlatformFile>[],
      fileIdsToDelete: const <int>[],
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _message(provider.errorMessage ?? 'Không thể cập nhật tên lớp.');
    }
  }

  int get _currentFileCount {
    final existingCount = _existingFiles
        .where((file) => !_fileIdsToDelete.contains(file.idFile))
        .length;

    return existingCount + _newFiles.length;
  }

  int get _currentTotalSize {
    final existingSize = _existingFiles
        .where((file) => !_fileIdsToDelete.contains(file.idFile))
        .fold<int>(0, (sum, file) => sum + file.fileSize);

    final newSize = _newFiles.fold<int>(0, (sum, file) => sum + file.size);

    return existingSize + newSize;
  }

  Widget _existingFileTile(LopDaoTaoFileV2Model file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: DaoTaoColors.border),
      ),

      child: Row(
        children: [
          Icon(_fileIcon(file.fileName), color: DaoTaoColors.primary),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  file.fileName,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 2),

                Text(
                  '${_fileExtension(file.fileName)}'
                  ' • '
                  '${_formatFileSize(file.fileSize)}',

                  style: const TextStyle(
                    color: DaoTaoColors.muted,

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Xóa tài liệu',

            onPressed: () {
              setState(() {
                _fileIdsToDelete.add(file.idFile);
              });
            },

            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _newFileTile(int index, fp.PlatformFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: const Color(0xFFB9DDF2)),
      ),

      child: Row(
        children: [
          Icon(_fileIcon(file.name), color: DaoTaoColors.primary),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  file.name,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

                Text(
                  '${_formatFileSize(file.size)} • File mới',

                  style: const TextStyle(
                    fontSize: 11,

                    color: DaoTaoColors.primary,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Bỏ file',

            onPressed: () {
              setState(() {
                _newFiles.removeAt(index);
              });
            },

            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String fileName) {
    final ext = _fileExtension(fileName).toLowerCase();

    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;

      case 'doc':
      case 'docx':
        return Icons.description_rounded;

      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;

      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;

      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;

      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return Icons.image_rounded;

      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _fileExtension(String fileName) {
    final index = fileName.lastIndexOf('.');

    if (index < 0 || index == fileName.length - 1) {
      return 'FILE';
    }

    return fileName.substring(index + 1).toUpperCase();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _loadExistingFiles() async {
    if (!widget.isEdit) {
      return;
    }

    setState(() {
      _isLoadingFiles = true;
    });

    final provider = context.read<DaoTaoV2Provider>();

    final files = await provider.loadTaiLieu(
      widget.item!.idLopDaoTao,
      force: true,
    );

    DaoTaoThongTinOnlineV2Model? onlineInfo;

    if (widget.item!.isOnline) {
      onlineInfo = await provider.loadThongTinOnline(
        widget.item!.idLopDaoTao,
        force: true,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _existingFiles = List<LopDaoTaoFileV2Model>.from(files);

      if (onlineInfo != null) {
        _linkZoomController.text = onlineInfo.linkZoom ?? '';

        _linkChatController.text = onlineInfo.linkChat ?? '';

        _zoomIdController.text = onlineInfo.zoomID ?? '';

        _zoomPasscodeController.text = onlineInfo.zoomPasscode ?? '';
      }

      _isLoadingFiles = false;
    });
  }

  Future<void> _pickFiles() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        allowMultiple: true,

        withData: true,

        type: fp.FileType.custom,

        allowedExtensions: _allowedExtensions,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      // ===============================================
      // FILE HIỆN CÓ VẪN GIỮ
      // ===============================================

      final existingKept = _existingFiles
          .where((file) => !_fileIdsToDelete.contains(file.idFile))
          .toList();

      // ===============================================
      // SỐ FILE SAU KHI THÊM
      // ===============================================

      final finalCount =
          existingKept.length + _newFiles.length + result.files.length;

      if (finalCount > _maxFileCount) {
        _message(
          'Một lớp chỉ được có tối đa '
          '$_maxFileCount tài liệu.',
        );

        return;
      }

      // ===============================================
      // KIỂM TRA FILE MỚI
      // ===============================================

      for (final file in result.files) {
        if (file.size <= 0) {
          _message('File "${file.name}" không có dữ liệu.');

          return;
        }

        if (file.size > _maxFileSize) {
          _message('File "${file.name}" vượt quá 20 MB.');

          return;
        }

        if (file.bytes == null || file.bytes!.isEmpty) {
          _message('Không đọc được file "${file.name}".');

          return;
        }
      }

      // ===============================================
      // TỔNG DUNG LƯỢNG
      //
      // Bao gồm file giữ lại + file mới đã chọn +
      // file vừa chọn.
      // ===============================================

      final currentExistingSize = existingKept.fold<int>(
        0,
        (sum, file) => sum + file.fileSize,
      );

      final currentNewSize = _newFiles.fold<int>(
        0,
        (sum, file) => sum + file.size,
      );

      final selectedSize = result.files.fold<int>(
        0,
        (sum, file) => sum + file.size,
      );

      final totalSize = currentExistingSize + currentNewSize + selectedSize;

      if (totalSize > _maxTotalFileSize) {
        _message(
          'Tổng dung lượng tài liệu '
          'không được vượt quá 100 MB.',
        );

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _newFiles.addAll(result.files);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _message('Không thể chọn file: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_phamViDaoTao == 2 && _idKhoaPhongs.isEmpty) {
      _message('Vui lòng chọn ít nhất một khoa/phòng được đăng ký.');
      return;
    }

    if (_ngayBatDau != null &&
        _ngayKetThuc != null &&
        _ngayKetThuc!.isBefore(
          DateTime(_ngayBatDau!.year, _ngayBatDau!.month, _ngayBatDau!.day),
        )) {
      _message('Ngày kết thúc không được nhỏ hơn ngày bắt đầu.');

      return;
    }

    if (_batDauDangKy != null &&
        _ketThucDangKy != null &&
        _ketThucDangKy!.isBefore(_batDauDangKy!)) {
      _message(
        'Thời gian kết thúc đăng ký không được nhỏ hơn '
        'thời gian bắt đầu đăng ký.',
      );

      return;
    }

    final provider = context.read<DaoTaoV2Provider>();

    final data = <String, dynamic>{
      'tenLopDaoTao': _tenLopController.text.trim(),

      'soTiet': _parseDouble(_soTietController.text),

      'ngayBatDau': _ngayBatDau?.toIso8601String(),

      'ngayKetThuc': _ngayKetThuc?.toIso8601String(),

      'idHinhThucDaoTao': _idHinhThucDaoTao,

      'idNguonKinhPhi': _idNguonKinhPhi,

      'kinhPhi': _parseDouble(_kinhPhiController.text),

      'idLoaiHinhDaoTao': _idLoaiHinhDaoTao,

      'chuKy': int.tryParse(_chuKyController.text.trim()),

      'idFile': null,

      'batDauDangKy': _batDauDangKy?.toIso8601String(),

      'ketThucDangKy': _ketThucDangKy?.toIso8601String(),

      'ghiChu': _nullText(_ghiChuController.text),

      'donViDaoTao': _nullText(_donViController.text),

      'tenChungChi': _nullText(_tenChungChiController.text),
      'kp': _nullText(_kpController.text),

      'thoiGianDetails': _nullText(_thoiGianDetailsController.text),

      'diaDiem': _nullText(_diaDiemController.text),

      'tpThamDu': _nullText(_tpThamDuController.text),
      'baoCaoVien': _nullText(_baoCaoVienController.text),

      'donViGiangDay': _nullText(_donViGiangDayController.text),

      'isOnline': _isOnline,

      'linkZoom': _isOnline ? _nullText(_linkZoomController.text) : null,

      'linkChat': _isOnline ? _nullText(_linkChatController.text) : null,

      'zoomID': _isOnline ? _nullText(_zoomIdController.text) : null,

      'zoomPasscode': _isOnline
          ? _nullText(_zoomPasscodeController.text)
          : null,

      'gioBatDauVanTayVao': _timeToApi(_gioBatDauVanTayVao),

      'gioKetThucVanTayVao': _timeToApi(_gioKetThucVanTayVao),

      'gioBatDauVanTayRa': _timeToApi(_gioBatDauVanTayRa),

      'gioKetThucVanTayRa': _timeToApi(_gioKetThucVanTayRa),
    };

    if (widget.isRole47) {
      data['phamViDaoTao'] = _phamViDaoTao;
    }
    data['idKhoaPhongs'] = _phamViDaoTao == 2
        ? (_idKhoaPhongs.toList()..sort())
        : <int>[];

    final bool ok;

    if (widget.isEdit) {
      ok = await provider.updateLop(
        widget.item!.idLopDaoTao,

        data,

        files: List<fp.PlatformFile>.from(_newFiles),

        fileIdsToDelete: _fileIdsToDelete.toList(),
      );
    } else {
      ok = await provider.createLop(
        data,

        files: List<fp.PlatformFile>.from(_newFiles),
      );
    }

    if (!mounted) {
      return;
    }

    if (ok) {
      Navigator.pop(context, true);
    } else {
      _message(provider.errorMessage ?? 'Không thể lưu lớp đào tạo.');
    }
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<DateTime?> _pickDateTime(DateTime? current) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay.fromDateTime(current)
          : TimeOfDay.now(),
    );

    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ==========================================================
  // UI HELPERS
  // ==========================================================

  Widget _sectionHeading(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5FC),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: DaoTaoColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: DaoTaoColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: DaoTaoColors.muted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(value == null ? 'Chưa chọn' : _formatDate(value)),
          ),
          if (value != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onTap,
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeTile({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(value == null ? 'Chưa chọn' : _formatDateTime(value)),
          ),
          if (value != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onTap,
            icon: const Icon(Icons.event),
          ),
        ],
      ),
    );
  }

  Widget _timeTile({
    required String label,
    required TimeOfDay? value,
    required ValueChanged<TimeOfDay?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(child: Text(value == null ? '--:--' : _formatTime(value))),
          if (value != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close, size: 18),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: value ?? TimeOfDay.now(),
              );

              if (picked != null) {
                onChanged(picked);
              }
            },
            icon: const Icon(Icons.schedule),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DANH MỤC HELPER
  // Giữ được ID cũ nếu danh mục đã KSD
  // ==========================================================

  List<DaoTaoDanhMucItemV2Model> _buildDanhMucItems(
    List<DaoTaoDanhMucItemV2Model> source, {
    required int? selectedId,
    String? oldName,
  }) {
    final result = List<DaoTaoDanhMucItemV2Model>.from(source);

    if (selectedId != null && !result.any((e) => e.id == selectedId)) {
      result.add(
        DaoTaoDanhMucItemV2Model(
          id: selectedId,
          ten:
              '${oldName?.trim().isNotEmpty == true ? oldName : 'ID $selectedId'} (đã ngừng sử dụng)',
        ),
      );
    }

    return result;
  }

  int? _safeValue(List<DaoTaoDanhMucItemV2Model> items, int? value) {
    if (value == null) {
      return null;
    }

    return items.any((e) => e.id == value) ? value : null;
  }

  // ==========================================================
  // FORMAT
  // ==========================================================

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _formatDateTime(DateTime value) {
    return '${_formatDate(value)} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parts = value.split(':');

    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);

    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String? _timeToApi(TimeOfDay? value) {
    if (value == null) {
      return null;
    }

    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:00';
  }

  double? _parseDouble(String value) {
    final text = value.trim().replaceAll(',', '.');

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }

  String? _nullText(String value) {
    final text = value.trim();

    return text.isEmpty ? null : text;
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
