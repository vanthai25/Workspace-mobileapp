import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/xn_trasau_ket_qua.dart';
import '../models/xn_trasau_model.dart';
import '../services/xn_result_pdf_service.dart';
import '../services/xn_trasau_ket_qua_service.dart';
import '../utils/xn_pdf_save.dart';
import '../widgets/xn_gpb_376_report.dart';

class XNTraSauKetQuaScreen extends StatefulWidget {
  const XNTraSauKetQuaScreen({
    super.key,
    required this.item,
    this.gateway,
    this.pdfPreview = true,
  });
  final XNTraSau item;
  final XnResultGateway? gateway;
  final bool pdfPreview;

  @override
  State<XNTraSauKetQuaScreen> createState() => _XNTraSauKetQuaScreenState();
}

class _XNTraSauKetQuaScreenState extends State<XNTraSauKetQuaScreen> {
  late final XnResultGateway _api = widget.gateway ?? XnResultService();
  CancelToken? _configToken;
  CancelToken? _resultToken;
  XnResultConfig? _config;
  XnResultTemplate? _template;
  int? _form;
  XnRow? _result;
  XnRow? _signature;
  Uint8List? _pdfBytes;
  String? _error;
  String? _signatureError;
  String? _pdfError;
  bool _loadingConfig = true;
  bool _loadingResult = false;
  bool _loadingSignature = false;
  bool _buildingPdf = false;
  bool _savingPdf = false;
  int _revision = 0;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _configToken?.cancel();
    _resultToken?.cancel();
    super.dispose();
  }

  bool _current(int revision) => mounted && revision == _revision;

  Future<void> _loadConfiguration() async {
    final revision = ++_revision;
    _configToken?.cancel();
    _resultToken?.cancel();
    final token = _configToken = CancelToken();
    setState(() {
      _loadingConfig = true;
      _loadingResult = false;
      _loadingSignature = false;
      _config = null;
      _template = null;
      _form = null;
      _result = null;
      _signature = null;
      _pdfBytes = null;
      _error = null;
      _signatureError = null;
      _pdfError = null;
      _buildingPdf = false;
    });
    try {
      final config = XnResultConfig.fromJson(
        await _api.configuration(widget.item.id, token),
      );
      if (!_current(revision)) return;
      if (config.id != widget.item.id ||
          config.detailId == null ||
          (widget.item.mathanhtoanct != null &&
              config.detailId != widget.item.mathanhtoanct)) {
        throw const XnResultException(
          'Thông tin chỉ định không khớp. Vui lòng tải lại danh sách.',
        );
      }
      if (config.templates.map((e) => e.id).toSet().length !=
          config.templates.length) {
        throw const XnResultException(
          'Danh sách mẫu bị trùng. Vui lòng kiểm tra cấu hình HIS.',
        );
      }
      setState(() {
        _config = config;
        _loadingConfig = false;
        if (config.templates.length == 1) _template = config.templates.single;
        if (config.forms.length == 1) _form = config.forms.single;
      });
      await _loadResult();
    } catch (error) {
      if (!_current(revision) || token.isCancelled) return;
      setState(() {
        _error = _message(error);
        _loadingConfig = false;
      });
    }
  }

  bool get _needsForm =>
      _template?.kind == XnResultKind.pathology &&
      _config?.usesV2 == true &&
      (_config?.forms.isNotEmpty ?? false);

  Future<void> _loadResult() async {
    final revision = ++_revision;
    _resultToken?.cancel();
    final token = _resultToken = CancelToken();
    setState(() {
      _result = null;
      _signature = null;
      _pdfBytes = null;
      _error = null;
      _signatureError = null;
      _pdfError = null;
      _buildingPdf = false;
      _loadingResult = false;
      _loadingSignature = false;
    });
    final config = _config;
    final template = _template;
    if (config == null || template == null) return;
    final kind = template.kind;
    if (kind == null) {
      setState(() => _error = 'Loại dịch vụ này chưa được hỗ trợ xem kết quả.');
      return;
    }
    if (_needsForm && _form == null) return;
    final selectedForm = _needsForm ? _form : null;
    setState(() => _loadingResult = true);
    try {
      final data = await _api.result(
        widget.item.id,
        kind,
        template.id,
        selectedForm,
        token,
      );
      if (!_current(revision)) return;
      _checkIdentity(data, config);
      if (xnText(xnValue(data, 'idMauIn')) != template.id ||
          XnResultKind.parse(xnValue(data, 'loaiKetQua')) != kind ||
          (selectedForm != null &&
              xnInt(xnValue(data, 'idMauKqKhac')) != selectedForm)) {
        throw const XnResultException(
          'Kết quả không khớp mẫu hoặc form đang chọn.',
        );
      }
      final displayData = kind == XnResultKind.laboratory
          ? <String, dynamic>{
              ...data,
              'appThongTin': <String, dynamic>{
                'hoten': widget.item.hoten,
                'namsinh': widget.item.namsinh,
                'gioitinh': widget.item.gioitinh,
                'makcb': widget.item.makcb,
                'barcode': widget.item.barcode,
                'diachi': widget.item.diachi,
                'dienthoai': widget.item.dienthoai,
                'khoacd': widget.item.khoacd,
                'phongcd': widget.item.phongcd,
                'ngaycd': widget.item.ngaycd,
                'tennguoicd': widget.item.tennguoicd,
              },
            }
          : data;
      setState(() {
        _result = displayData;
        _loadingResult = false;
        _loadingSignature = true;
      });
      await _loadSignature(config, revision, token);
    } catch (error) {
      if (!_current(revision) || token.isCancelled) return;
      setState(() {
        _loadingResult = false;
        _error = _message(error);
      });
    }
  }

  Future<void> _loadSignature(
    XnResultConfig config,
    int revision,
    CancelToken token,
  ) async {
    setState(() {
      _signatureError = null;
      _loadingSignature = true;
    });
    try {
      final signature = await _api.signature(widget.item.id, token);
      if (!_current(revision)) return;
      _checkIdentity(signature, config);
      setState(() {
        _signature = signature;
        _loadingSignature = false;
      });
      await _buildPdf(revision);
    } catch (error) {
      if (!_current(revision) || token.isCancelled) return;
      setState(() {
        _signatureError = _message(error);
        _loadingSignature = false;
      });
      await _buildPdf(revision);
    }
  }

  Future<void> _buildPdf(int revision) async {
    if (!widget.pdfPreview) return;
    final result = _result;
    if (result == null || !_current(revision)) return;
    setState(() {
      _buildingPdf = true;
      _pdfError = null;
      _pdfBytes = null;
    });
    try {
      final bytes = await const XnResultPdfService().build(
        result: result,
        signature: _signature ?? const {},
      );
      if (!_current(revision)) return;
      setState(() {
        _pdfBytes = bytes;
        _buildingPdf = false;
      });
    } catch (error, stackTrace) {
      debugPrint('XnResultPdfService.build failed: $error');
      debugPrintStack(
        label: 'Stack trace while creating the result PDF',
        stackTrace: stackTrace,
      );
      if (!_current(revision)) return;
      setState(() {
        _buildingPdf = false;
        _pdfError = _pdfBuildMessage(error);
      });
    }
  }

  String _pdfBuildMessage(Object error) {
    final detail = error.toString().toLowerCase();
    if (detail.contains('unable to load asset') ||
        detail.contains('asset not found')) {
      return 'Bản cài đặt đang thiếu font hoặc logo để tạo PDF. '
          'Vui lòng cập nhật lại ứng dụng.';
    }
    return 'Không tạo được file PDF. Vui lòng thử lại.';
  }

  Future<void> _downloadPdf() async {
    final bytes = _pdfBytes;
    if (bytes == null || _savingPdf) return;
    setState(() => _savingPdf = true);
    try {
      final template = _template?.id ?? 'ket_qua';
      final form = _form == null ? '' : '_form_$_form';
      final makcb = widget.item.makcb ?? 'id_${widget.item.id}';
      await saveXnPdf(bytes, 'ket_qua_${makcb}_$template$form.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải được file PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPdf = false);
    }
  }

  void _checkIdentity(XnRow data, XnResultConfig config) {
    if (xnInt(xnValue(data, 'id')) != widget.item.id ||
        xnInt(xnValue(data, 'mathanhtoanct')) != config.detailId) {
      throw const XnResultException(
        'Dữ liệu trả về không khớp chỉ định đang xem.',
      );
    }
  }

  String _message(Object error) => error is XnResultException
      ? error.message
      : 'Không tải được dữ liệu. Vui lòng thử lại.';

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Kết quả cận lâm sàng'),
        backgroundColor: const Color(0xFF1274BC),
        foregroundColor: Colors.white,
        actions: [
          if (_pdfBytes != null)
            IconButton(
              onPressed: _savingPdf ? null : _downloadPdf,
              tooltip: 'Tải PDF',
              icon: _savingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
            ),
          IconButton(
            onPressed: _loadConfiguration,
            tooltip: 'Tải lại kết quả',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: widget.pdfPreview ? _pdfBody(config) : _legacyBody(config),
      ),
    );
  }

  Widget _legacyBody(XnResultConfig? config) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (config != null) _selectors(config),
              if (_error != null)
                _errorPanel(
                  _error!,
                  config == null ? _loadConfiguration : _loadResult,
                ),
              if (_loadingConfig || _loadingResult)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_result != null) ...[
                ..._report(_result!),
                if (!_uses376(_result!)) _signaturePanel(),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _pdfBody(XnResultConfig? config) {
    if (_loadingConfig || _loadingResult || _loadingSignature || _buildingPdf) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: _errorPanel(
            _error!,
            config == null ? _loadConfiguration : _loadResult,
          ),
        ),
      );
    }
    final mustChooseTemplate =
        config != null && config.templates.isNotEmpty && _template == null;
    final mustChooseForm = _needsForm && _form == null;
    if (config != null && (mustChooseTemplate || mustChooseForm)) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _selectors(config),
          ),
        ),
      );
    }
    if (_pdfError != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: _errorPanel(_pdfError!, () => _buildPdf(_revision)),
        ),
      );
    }
    final bytes = _pdfBytes;
    if (bytes != null) {
      return SfPdfViewer.memory(bytes);
    }
    return const Center(child: Text('Chưa có file kết quả để hiển thị.'));
  }

  Widget _selectors(XnResultConfig config) => _section('Mẫu kết quả', [
    if (config.templates.isEmpty)
      const Text('Dịch vụ chưa có mẫu kết quả được cấu hình trên HIS.')
    else ...[
      DropdownButtonFormField<String>(
        key: ValueKey('template-${_template?.id}'),
        initialValue: _template?.id,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Mẫu in',
          border: OutlineInputBorder(),
        ),
        hint: const Text('Chọn mẫu để xem kết quả'),
        items: config.templates
            .map(
              (e) => DropdownMenuItem(
                value: e.id,
                child: Text(
                  '${e.kind?.label ?? 'Chưa hỗ trợ'} · Mẫu ${e.id}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _template = config.templates.firstWhere((e) => e.id == value);
            _form = config.forms.length == 1 ? config.forms.single : null;
          });
          _loadResult();
        },
      ),
      if (_needsForm) ...[
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          key: ValueKey('form-${_template?.id}-$_form'),
          initialValue: _form,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Form kết quả GPB',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Chọn form của chỉ định'),
          items: config.forms
              .map((id) => DropdownMenuItem(value: id, child: Text('Form $id')))
              .toList(),
          onChanged: (value) {
            setState(() => _form = value);
            _loadResult();
          },
        ),
      ],
    ],
  ]);

  // Retained as a safe on-screen fallback while PDF templates are expanded.
  List<Widget> _report(XnRow data) {
    if (_uses376(data)) {
      return [
        XnGpb376Report(
          data: data,
          signature: _gpb376Signature(),
          images: [
            for (final image in xnRows(xnValue(data, 'hinhAnh')))
              XnResultImage(base64: xnText(xnValue(image, 'anhBase64'))),
          ],
        ),
      ];
    }
    final widgets = <Widget>[];
    final patients = xnRows(xnValue(data, 'benhNhan'));
    for (final patient in patients) {
      widgets.add(
        _section(
          'Thông tin trên phiếu',
          _details(patient, const {
            'hoten': 'Họ tên',
            'makcb': 'Mã KCB',
            'tuoi': 'Tuổi',
            'namsinh': 'Năm sinh',
            'tenphai': 'Giới tính',
            'gioitinh': 'Giới tính',
            'diachi': 'Địa chỉ',
            'dienthoai': 'Điện thoại',
            'sothebhyt': 'Thẻ BHYT',
          }),
        ),
      );
    }
    switch (_template!.kind!) {
      case XnResultKind.laboratory:
        widgets.addAll(_laboratory(data));
      case XnResultKind.pathology:
        widgets.addAll(_pathology(data));
      case XnResultKind.antibiogram:
        widgets.addAll(_antibiogram(data));
    }
    for (final row in xnRows(xnValue(data, 'chanDoan'))) {
      widgets.add(
        _section(
          'Chẩn đoán',
          _details(row, const {
            'benhchinh': 'Bệnh chính',
            'benhkemtheo': 'Bệnh kèm theo',
            'benhchung': 'Chẩn đoán',
            'trieuchung': 'Triệu chứng',
          }),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _laboratory(XnRow data) {
    final rows = xnRows(xnValue(data, 'dongKetQua'));
    final content = <Widget>[];
    var pending = <List<String>>[];
    var pendingStyles = <List<TextStyle?>>[];
    void flush() {
      if (pending.isEmpty) return;
      content.add(
        XnResultTable(
          headers: const [
            'Tên xét nghiệm',
            'Kết quả',
            'Đơn vị',
            'Khoảng tham chiếu',
            'HL',
            'Quy trình',
            'Máy XN',
          ],
          rows: pending,
          cellStyles: pendingStyles,
        ),
      );
      pending = [];
      pendingStyles = [];
    }

    for (final row in rows) {
      if (xnInt(xnValue(row, 'grouplevel')) != 0) {
        flush();
        final title = xnDisplayText(xnValue(row, 'grheadertext'));
        if (title.isNotEmpty) {
          content.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }
        continue;
      }
      final formattedResult = xnFormattedText(
        xnValue(row, 'ketluan'),
        fallbackText: xnValue(row, 'ketqua_goc'),
      );
      pending.add([
        xnDisplayText(xnValue(row, 'tenchiso_goc') ?? xnValue(row, 'tenchiso')),
        formattedResult.text,
        xnDisplayText(xnValue(row, 'tendonvitinh')),
        xnDisplayText(xnValue(row, 'giatribinhthuong')),
        xnDisplayText(xnValue(row, 'HL')),
        xnDisplayText(xnValue(row, 'quytrinhxn')),
        xnDisplayText(
          xnValue(row, 'tenmaylam') ?? xnValue(row, 'InstrumentID'),
        ),
      ]);
      pendingStyles.add([
        null,
        _hisResultTextStyle(formattedResult, xnValue(row, 'HL')),
        null,
        null,
        null,
        null,
        null,
      ]);
    }
    flush();
    if (content.isEmpty) content.add(const Text('Không có dòng kết quả.'));
    final notes = rows
        .map((r) => xnDisplayText(xnValue(r, 'ghichu')))
        .where((s) => s.isNotEmpty)
        .toSet();
    for (final note in notes) {
      content.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SelectableText(note),
        ),
      );
    }
    final details = rows
        .where((r) => xnInt(xnValue(r, 'grouplevel')) == 0)
        .toList();
    return [
      _section('Kết quả xét nghiệm', content),
      if (details.isNotEmpty)
        _section(
          'Thông tin thực hiện',
          _details(details.first, const {
            'barcode': 'Barcode',
            'tenloaimau': 'Loại mẫu',
            'bschidinh': 'Bác sĩ chỉ định',
            'bslam': 'Người thực hiện',
            'ngaycd': 'Ngày chỉ định',
            'ngaylam': 'Ngày thực hiện',
            'ngaykhopBC': 'Ngày nhận mẫu',
            'ngaytraKQ': 'Ngày trả kết quả',
          }),
        ),
    ];
  }

  List<Widget> _pathology(XnRow data) {
    final result = <Widget>[];
    final template = xnText(xnValue(data, 'idMauIn'));
    final form = xnInt(xnValue(data, 'idMauKqKhac'));
    final layout = xnGpbLayout(template, form);
    for (final row in xnRows(xnValue(data, 'chiDinh'))) {
      result.add(
        _section(
          'Chỉ định',
          _details(row, const {
            'tennv': 'Bác sĩ chỉ định',
            'tenkk': 'Khoa chỉ định',
            'tenphong': 'Phòng',
            'ngay': 'Ngày chỉ định',
            'sophieu': 'Số phiếu',
          }),
        ),
      );
    }
    for (final row in xnRows(xnValue(data, 'ketQua'))) {
      result.add(
        _section(
          layout.title,
          _details(row, {
            ...layout.resultLabels,
            'denghi': 'Đề nghị',
            'barcode': 'Mã bệnh phẩm',
            'Solam': 'Số lam',
            'tennv': 'Người thực hiện',
            'ngayth': 'Ngày thực hiện',
            'ngaylam': 'Ngày làm',
            'ngaytraKQ': 'Ngày trả kết quả',
            'maylam': 'Máy thực hiện',
          }),
        ),
      );
    }
    final fields = xnRows(xnValue(data, 'truongKetQuaKhac'));
    if (fields.isNotEmpty) {
      result.add(
        _section('Đánh giá chi tiết', [
          for (final field in fields)
            XnGpbField(field: field, templateId: template, formId: form),
        ]),
      );
    }
    for (final row in xnRows(xnValue(data, 'ketQuaKhacCu'))) {
      result.add(
        _section('Kết quả bổ sung', [
          for (final entry in row.entries)
            _detail(entry.key, xnDisplayText(entry.value)),
        ]),
      );
    }
    for (final row in xnRows(xnValue(data, 'nhanVien'))) {
      result.add(
        _section(
          'Nhân viên thực hiện',
          _details(row, const {
            'bslamchucdanh': 'Bác sĩ',
            'ktvlamchucdanh': 'Kỹ thuật viên',
            'bslam2': 'Bác sĩ phối hợp',
          }),
        ),
      );
    }
    final images = xnRows(xnValue(data, 'hinhAnh'));
    if (images.isNotEmpty) {
      result.add(
        _section('Hình ảnh kết quả', [
          for (final row in images)
            XnResultImage(base64: xnText(xnValue(row, 'anhBase64'))),
        ]),
      );
    }
    return result;
  }

  List<Widget> _antibiogram(XnRow data) {
    final organisms = xnRows(xnValue(data, 'viKhuanVaChiDinh'));
    final drugs = xnRows(xnValue(data, 'khangSinh'));
    return [
      for (final organism in organisms)
        _section(
          xnText(xnValue(organism, 'tenvikhuan')).isEmpty
              ? 'Kết quả vi sinh'
              : xnText(xnValue(organism, 'tenvikhuan')),
          [
            ..._details(organism, const {
              'ketluan': 'Kết luận',
              'ghichuvitheokhuan': 'Ghi chú',
              'barcode': 'Barcode',
              'sophieu': 'Số phiếu',
              'tenloaimau': 'Loại mẫu',
              'bschidinh': 'Bác sĩ chỉ định',
              'noigui': 'Nơi gửi',
              'phonggui': 'Phòng gửi',
              'ngaycd': 'Ngày chỉ định',
              'ngaylaymau': 'Ngày lấy mẫu',
              'ngaynhanbp': 'Ngày nhận bệnh phẩm',
              'ngaylam': 'Ngày thực hiện',
              'nguoilaymau': 'Người lấy mẫu',
              'nguoinhanmau': 'Người nhận mẫu',
              'ktvlam': 'Kỹ thuật viên',
            }),
            if (!drugs.any((r) => xnSameOrganism(r, organism)))
              const Text('Không có dòng kháng sinh được trả về.')
            else
              XnResultTable(
                headers: const [
                  'Kháng sinh',
                  'Nhóm',
                  'MIC',
                  'S/I/R',
                  'Đường kính',
                  'Tham chiếu',
                ],
                rows: drugs
                    .where((r) => xnSameOrganism(r, organism))
                    .map(
                      (r) => [
                        'tenkhangsinh',
                        'tennhomks',
                        'MIC',
                        'SIR',
                        'duongkinh',
                        'giatrithamchieu',
                      ].map((key) => xnDisplayText(xnValue(r, key))).toList(),
                    )
                    .toList(),
              ),
          ],
        ),
      if (organisms.isEmpty)
        _section('Kháng sinh đồ', [const Text('Chưa có dữ liệu vi khuẩn.')]),
    ];
  }

  bool _uses376(XnRow data) =>
      XnResultKind.parse(xnValue(data, 'loaiKetQua')) ==
          XnResultKind.pathology &&
      xnText(xnValue(data, 'idMauIn')) == '376' &&
      xnInt(xnValue(data, 'idMauKqKhac')) == 12;

  Widget _signaturePanel() => _section('Chữ ký', [_signatureContents()]);

  Widget _signatureContents() {
    if (_loadingSignature) {
      return const LinearProgressIndicator();
    }
    if (_signatureError != null) {
      return _errorPanel(
        _signatureError!,
        () => _loadSignature(_config!, _revision, _resultToken!),
      );
    }
    return XnSignatureView(data: _signature ?? {});
  }

  Widget _gpb376Signature() {
    if (_loadingSignature) return const LinearProgressIndicator();
    if (_signatureError != null) {
      return _errorPanel(
        _signatureError!,
        () => _loadSignature(_config!, _revision, _resultToken!),
      );
    }
    return XnSignatureView(data: _signature ?? {}, compact: true);
  }

  List<Widget> _details(XnRow row, Map<String, String> labels) => [
    for (final entry in labels.entries)
      if (xnText(xnValue(row, entry.key)).isNotEmpty)
        _detail(
          entry.value,
          entry.key.toLowerCase().startsWith('ngay')
              ? _date(xnValue(row, entry.key))
              : xnDisplayText(xnValue(row, entry.key)),
        ),
  ];

  Widget _detail(String label, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        const SizedBox(height: 3),
        SelectableText(text.isEmpty ? '—' : text),
      ],
    ),
  );

  Widget _section(String title, List<Widget> children) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 16),
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1274BC),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );

  Widget _errorPanel(String message, VoidCallback retry) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      ],
    ),
  );
}

String _date(dynamic value) {
  final date = DateTime.tryParse(xnText(value));
  return date == null
      ? xnText(value)
      : DateFormat('dd/MM/yyyy HH:mm').format(date);
}

TextStyle? _hisResultTextStyle(XnFormattedText value, dynamic hlValue) {
  final hl = xnDisplayText(hlValue).toUpperCase();
  Color? color;
  if (value.hasColor) {
    color = Color.fromARGB(255, value.red!, value.green!, value.blue!);
  } else if (hl.isNotEmpty) {
    color = hl.contains('L') || hl.contains('↓') ? Colors.blue : Colors.red;
  }
  if (color == null && !value.bold && !value.italic && !value.underline) {
    return null;
  }
  return TextStyle(
    color: color,
    fontWeight: value.bold || (!value.hasColor && hl.isNotEmpty)
        ? FontWeight.bold
        : null,
    fontStyle: value.italic ? FontStyle.italic : null,
    decoration: value.underline ? TextDecoration.underline : null,
  );
}

class XnResultTable extends StatelessWidget {
  const XnResultTable({
    super.key,
    required this.headers,
    required this.rows,
    this.cellStyles,
  });
  final List<String> headers;
  final List<List<String>> rows;
  final List<List<TextStyle?>>? cellStyles;

  TextStyle? _cellStyle(int row, int column) {
    final styles = cellStyles;
    if (styles == null ||
        row >= styles.length ||
        column >= styles[row].length) {
      return null;
    }
    return styles[row][column];
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 720) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      rows[rowIndex].first.isEmpty ? '—' : rows[rowIndex].first,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ).merge(_cellStyle(rowIndex, 0)),
                    ),
                    for (var i = 1; i < headers.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SelectableText.rich(
                          TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(text: '${headers[i]}: '),
                              TextSpan(
                                text: rows[rowIndex][i].isEmpty
                                    ? '—'
                                    : rows[rowIndex][i],
                                style: _cellStyle(rowIndex, i),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      }
      return Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        columnWidths: const {0: FlexColumnWidth(2.3)},
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEAF3FA)),
            children: [
              for (final header in headers)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    header,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
            TableRow(
              children: [
                for (
                  var columnIndex = 0;
                  columnIndex < rows[rowIndex].length;
                  columnIndex++
                )
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SelectableText(
                      rows[rowIndex][columnIndex].isEmpty
                          ? '—'
                          : rows[rowIndex][columnIndex],
                      style: _cellStyle(rowIndex, columnIndex),
                    ),
                  ),
              ],
            ),
        ],
      );
    },
  );
}

class XnGpbField extends StatelessWidget {
  const XnGpbField({
    super.key,
    required this.field,
    required this.templateId,
    this.formId,
  });
  final XnRow field;
  final String templateId;
  final int? formId;

  @override
  Widget build(BuildContext context) {
    final name = xnText(xnValue(field, 'name'));
    final label = xnGpbLayout(
      templateId,
      formId,
    ).fieldLabels[name.toLowerCase()];
    // Only API-typed booleans are checkbox values; unknown is not unchecked.
    final typed = xnValue(field, 'giaTriBoolean');
    final bool? checked = typed is bool ? typed : null;
    final raw = xnDisplayText(xnValue(field, 'value'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (checked != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                checked
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
                semanticLabel: checked ? 'Được tích' : 'Không được tích',
                color: checked ? const Color(0xFF1274BC) : Colors.grey,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(label ?? name),
                if (label == null)
                  const Text(
                    'Tên trường HIS — chưa có nhãn đối chiếu',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                if (checked == null)
                  Text(raw.isEmpty ? 'Chưa có dữ liệu' : raw),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class XnSignatureView extends StatelessWidget {
  const XnSignatureView({super.key, required this.data, this.compact = false});
  final XnRow data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final signed = xnBool(xnValue(data, 'daKyHIS'));
    final hsm = xnBool(xnValue(data, 'dangKyHsmHopLe'));
    final badge =
        signed == true &&
        hsm == true &&
        xnBool(xnValue(data, 'hienThiTichXanh')) == true;
    if (signed != true) {
      return Text(
        signed == false
            ? 'Chưa ký trên HIS.'
            : 'Chưa xác định được trạng thái chữ ký.',
      );
    }
    final image = xnText(xnValue(data, 'anhBase64'));
    final name = xnText(xnValue(data, 'tenthuonggoi')).isNotEmpty
        ? xnText(xnValue(data, 'tenthuonggoi'))
        : xnText(xnValue(data, 'tenNguoiKy'));
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 106,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (image.isNotEmpty)
                  Center(
                    child: SizedBox(
                      width: 270,
                      child: XnResultImage(base64: image, height: 92),
                    ),
                  )
                else
                  const Center(child: Text('Chưa có ảnh chữ ký.')),
                if (badge)
                  const Positioned(
                    left: 24,
                    top: 18,
                    child: Icon(
                      Icons.verified,
                      color: Colors.green,
                      semanticLabel: 'Chữ ký số hợp lệ',
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'Ngày ký: ${_date(xnValue(data, 'ngayKy'))}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 3),
          SelectableText(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đã ký trên HIS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (image.isNotEmpty)
          XnResultImage(base64: image, height: 130)
        else
          const Text('Chưa có ảnh chữ ký.'),
        SelectableText(name),
        Text('Ngày ký: ${_date(xnValue(data, 'ngayKy'))}'),
        const SizedBox(height: 8),
        if (badge)
          const Row(
            children: [
              Icon(
                Icons.verified,
                color: Colors.green,
                semanticLabel: 'Đăng ký HSM hợp lệ',
              ),
              SizedBox(width: 8),
              Expanded(child: Text('Đăng ký HSM hợp lệ')),
            ],
          )
        else
          Text(
            hsm == null
                ? 'Chưa xác định trạng thái đăng ký HSM.'
                : hsm
                ? 'Chưa xác nhận tích xanh.'
                : 'Không có đăng ký HSM hợp lệ.',
          ),
        if (xnText(xnValue(data, 'canhBaoHsm')).isNotEmpty)
          Text(
            xnText(xnValue(data, 'canhBaoHsm')),
            style: const TextStyle(color: Colors.orange),
          ),
      ],
    );
  }
}

class XnResultImage extends StatelessWidget {
  const XnResultImage({super.key, required this.base64, this.height = 300});
  final String base64;
  final double height;

  @override
  Widget build(BuildContext context) {
    Uint8List bytes;
    try {
      bytes = base64Decode(base64);
    } on FormatException {
      return const Text('Dữ liệu ảnh không hợp lệ.');
    }
    if (bytes.isEmpty) return const Text('Chưa có ảnh.');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Image.memory(
        bytes,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Text('Không hiển thị được ảnh trên thiết bị này.'),
      ),
    );
  }
}
