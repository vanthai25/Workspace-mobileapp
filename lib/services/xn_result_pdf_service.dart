import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/xn_gpb_376_template.dart';
import '../models/xn_trasau_ket_qua.dart';

/// One PDF entry point for every result type. New print layouts are registered
/// in [_specializedBuilders]; the viewer and download flow do not change.
class XnResultPdfService {
  const XnResultPdfService();

  Future<Uint8List> build({
    required XnRow result,
    XnRow signature = const {},
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load(
        'assets/font-times-new-roman/times-new-roman-regular-unicode.ttf',
      ),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load(
        'assets/font-times-new-roman/times-new-roman-bold-unicode.ttf',
      ),
    );
    final italic = pw.Font.ttf(
      await rootBundle.load(
        'assets/font-times-new-roman/times_new_roman_italic.ttf',
      ),
    );
    final boldItalic = pw.Font.ttf(
      await rootBundle.load(
        'assets/font-times-new-roman/times_new_roman_bold_italic.ttf',
      ),
    );
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/images/LOGO.png')).buffer.asUint8List(),
    );
    final document = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
      fontFallback: [regular],
    );
    final context = _PdfContext(result, signature, logo);
    final key = _key(result);
    final builder = _specializedBuilders[key] ?? _generic;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(30, 26, 30, 28),
        theme: theme,
        build: (_) => builder(context),
        footer: (page) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${page.pageNumber}/${page.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
      ),
    );
    return document.save();
  }

  static String _key(XnRow data) =>
      '${xnText(xnValue(data, 'loaiKetQua'))}:'
      '${xnText(xnValue(data, 'idMauIn'))}:'
      '${xnInt(xnValue(data, 'idMauKqKhac')) ?? ''}';

  static final Map<String, List<pw.Widget> Function(_PdfContext)>
  _specializedBuilders = {
    'GPB:376:12': _gpb376,
    'GPB:381:': _gpb381,
    'GPB:383:': _gpb383,
    'XET_NGHIEM:301:': _laboratory301,
    'XET_NGHIEM:388:': _hbv388,
    'XET_NGHIEM:391:': _hsv391,
    'XET_NGHIEM:474:': _pcrPathogen474,
    'XET_NGHIEM:477:': _hpv477,
    'XET_NGHIEM:609:': _hematology609,
    'KHANG_SINH_DO:351:': _microbiology351,
    'KHANG_SINH_DO:743:': _microbiology743,
    'KHANG_SINH_DO:764:': _fungalCulture764,
  };

  static List<pw.Widget> _gpb376(_PdfContext c) {
    final fields = xnRows(xnValue(c.result, 'truongKetQuaKhac'));
    final rows = xnRows(xnValue(c.result, 'ketQua'));
    final result = rows.isEmpty ? <String, dynamic>{} : rows.first;
    final content = <pw.Widget>[
      _header(c, result),
      pw.SizedBox(height: 10),
      _title('PHIẾU KẾT QUẢ GIẢI PHẪU BỆNH'),
      pw.SizedBox(height: 9),
      ..._clinicalInfo(c),
      pw.SizedBox(height: 5),
      pw.Center(
        child: pw.Text(
          'KẾT QUẢ TẾ BÀO HỌC CỔ TỬ CUNG THEO HỆ THỐNG BETHESDA 2014',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Đánh giá tiêu bản:',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 12),
          ..._group(
            fields,
            'assessment',
          ).map((item) => pw.Expanded(child: item)),
        ],
      ),
      pw.SizedBox(height: 2),
      ..._group(fields, 'negative'),
      pw.SizedBox(height: 2),
      _parentWithColumns(fields, 'non_neoplastic'),
      pw.SizedBox(height: 2),
      _parentWithColumns(fields, 'infection'),
      pw.SizedBox(height: 2),
      ..._group(fields, 'endometrial'),
      pw.SizedBox(height: 1),
      ..._group(fields, 'epithelial'),
      pw.SizedBox(height: 1),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: pw.Column(children: _group(fields, 'squamous'))),
          pw.SizedBox(width: 12),
          pw.Expanded(child: pw.Column(children: _group(fields, 'glandular'))),
        ],
      ),
      pw.SizedBox(height: 2),
      ..._group(fields, 'other'),
      pw.SizedBox(height: 5),
      _line('KẾT LUẬN', xnDisplayText(xnValue(result, 'ketluan')), bold: true),
    ];
    final note = xnDisplayText(xnValue(result, 'denghi'));
    if (note.isNotEmpty) content.add(_line('KIẾN NGHỊ', note, bold: true));
    content.addAll([pw.SizedBox(height: 8), _signature(c, result)]);
    return content;
  }

  static List<pw.Widget> _gpb381(_PdfContext c) {
    final rows = xnRows(xnValue(c.result, 'ketQua'));
    final result = rows.isEmpty ? <String, dynamic>{} : rows.first;
    final staffRows = xnRows(xnValue(c.result, 'nhanVien'));
    final staff = staffRows.isEmpty ? <String, dynamic>{} : staffRows.first;
    final serviceRows = xnRows(xnValue(c.result, 'dichVu'));
    final service = serviceRows.isEmpty
        ? <String, dynamic>{}
        : serviceRows.first;
    final order = c.order;
    final samplePosition = _text(service, 'ghichudv');
    final content = <pw.Widget>[
      _header381(c, result),
      pw.SizedBox(height: 4),
      _title('PHIẾU XÉT NGHIỆM GIẢI PHẪU BỆNH'),
      pw.SizedBox(height: 8),
      ..._clinicalInfo381(c),
      _two(
        _line('Vị trí lấy mẫu', samplePosition),
        _line('Ngày lấy mẫu', _date(xnValue(order, 'ngay'))),
      ),
      pw.SizedBox(height: 7),
      _title('KẾT QUẢ MÔ BỆNH HỌC'),
      pw.SizedBox(height: 8),
      _two(
        _line('Người pha bệnh phẩm', _text(staff, 'bslam2')),
        _line('Ngày pha', _dateOnly(xnValue(result, 'ngayth'))),
      ),
      _two(
        _line('Người làm tiêu bản', _text(staff, 'ktvlam')),
        _line('Số Block', _text(result, 'Solam')),
      ),
      _line('Phương pháp nhuộm', 'Hematoxylin Eosin'),
      pw.SizedBox(height: 5),
      _resultParagraph('Nhận xét đại thể', xnValue(result, 'docketqua')),
      _resultParagraph('Nhận xét vi thể', xnValue(result, 'mota')),
      _resultParagraph(
        'Chẩn đoán mô bệnh học',
        xnValue(result, 'ketluan'),
        valueBold: true,
      ),
      _resultParagraph('Bàn luận', xnValue(result, 'denghi')),
      ..._resultImages(c.result),
      pw.SizedBox(height: 18),
      _signature(c, result, dateKey: 'ngaytraKQ'),
      pw.SizedBox(height: 50),
      pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 9),
          children: [
            pw.TextSpan(
              text: 'Ghi chú: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(
              text: 'Xin vui lòng giữ phiếu này và mang theo khi tái khám!',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
            ),
          ],
        ),
      ),
    ];
    return content;
  }

  static List<pw.Widget> _gpb383(_PdfContext c) {
    final rows = xnRows(xnValue(c.result, 'ketQua'));
    final result = rows.isEmpty ? <String, dynamic>{} : rows.first;
    final serviceRows = xnRows(xnValue(c.result, 'dichVu'));
    final service = serviceRows.isEmpty
        ? <String, dynamic>{}
        : serviceRows.first;
    final samplePosition = _text(service, 'ghichudv');
    return [
      _header381(c, result),
      pw.SizedBox(height: 4),
      _title('PHIẾU XÉT NGHIỆM GIẢI PHẪU BỆNH'),
      pw.SizedBox(height: 8),
      ..._clinicalInfo383(c, result),
      _two(
        _samplePosition(samplePosition),
        _line('Ngày lấy mẫu', _dateOnly(xnValue(result, 'ngayth'))),
      ),
      pw.SizedBox(height: 7),
      _title('KẾT QUẢ TẾ BÀO HỌC'),
      pw.SizedBox(height: 8),
      _line('Số lam', _text(result, 'Solam')),
      _line('Phương pháp nhuộm', 'Giemsa'),
      pw.SizedBox(height: 5),
      _resultParagraph('Nhận xét vi thể', xnValue(result, 'mota')),
      _resultParagraph(
        'Chẩn đoán tế bào học',
        xnValue(result, 'ketluan'),
        valueBold: true,
      ),
      _resultParagraph('BÀN LUẬN', xnValue(result, 'denghi')),
      ..._resultImages(c.result),
      pw.SizedBox(height: 18),
      _signature(c, result, dateKey: 'ngaytraKQ'),
      pw.SizedBox(height: 90),
      pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 9),
          children: [
            pw.TextSpan(
              text: 'Ghi chú: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(
              text: 'Xin vui lòng giữ phiếu này và mang theo khi tái khám!',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
            ),
          ],
        ),
      ),
    ];
  }

  static List<pw.Widget> _hematology609(_PdfContext c) {
    final rows = xnRows(xnValue(c.result, 'dongKetQua'));
    final detailRows = rows
        .where((row) => xnInt(xnValue(row, 'grouplevel')) == 0)
        .toList();
    final info = _laboratoryInfo(c, detailRows);
    final notes = <String>{
      for (final row in detailRows)
        _firstText(row, const ['ghichudichvu', 'ghichu']),
      for (final row in xnRows(xnValue(c.result, 'ghiChu'))) ...[
        _firstText(row, const ['ghichudichvu']),
        _firstText(row, const ['ghichubarcode', 'ghichu']),
      ],
    }..removeWhere((value) => value.isEmpty);
    final performer = _firstText(info, const ['ktvlam', 'bslam']);
    return [
      _header609(c, info),
      pw.SizedBox(height: 5),
      _title('PHIẾU KẾT QUẢ HUYẾT ĐỒ'),
      pw.SizedBox(height: 7),
      ..._clinicalInfo609(info),
      pw.SizedBox(height: 5),
      _hematologyTable609(rows),
      pw.SizedBox(height: 5),
      pw.Text(
        'Nhận xét và Kết luận:',
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      if (notes.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2),
          child: pw.Text(
            notes.join('\n'),
            style: const pw.TextStyle(fontSize: 8.5),
          ),
        ),
      pw.SizedBox(height: 7),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _line('Người thực hiện xét nghiệm', performer, bold: true),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: _signature(
              c,
              info,
              dateKey: 'ngaylam',
              heading: 'BS/KTV XÉT NGHIỆM',
              vietnameseTimeWords: true,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 18),
      pw.Text(
        '- Xét nghiệm có dấu "*" là xét nghiệm đạt chứng nhận ISO 15189:2022\n'
        '- Các giá trị in đậm là giá trị nằm ngoài khoảng tham chiếu',
        style: const pw.TextStyle(fontSize: 7),
      ),
    ];
  }

  static List<pw.Widget> _laboratory301(_PdfContext c) {
    final rows = xnRows(xnValue(c.result, 'dongKetQua'));
    final detailRows = rows
        .where((row) => xnInt(xnValue(row, 'grouplevel')) == 0)
        .toList();
    final info = _laboratoryInfo(c, detailRows);
    final notes = <String>{
      for (final row in detailRows)
        _firstText(row, const ['ghichudichvu', 'ghichu']),
      for (final row in xnRows(xnValue(c.result, 'ghiChu'))) ...[
        _firstText(row, const ['ghichudichvu']),
        _firstText(row, const ['ghichubarcode', 'ghichu']),
      ],
    }..removeWhere((value) => value.isEmpty);
    final performer = _firstText(info, const ['ktvlam', 'bslam']);
    return [
      _header609(c, info),
      pw.SizedBox(height: 4),
      _title('PHIẾU KẾT QUẢ XÉT NGHIỆM'),
      pw.SizedBox(height: 7),
      ..._clinicalInfo301(info),
      pw.SizedBox(height: 4),
      _laboratoryTable301(rows),
      pw.SizedBox(height: 5),
      _line('Ghi chú', notes.join('\n')),
      pw.SizedBox(height: 7),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _line('Người thực hiện xét nghiệm', performer, bold: true),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: _signature(
              c,
              info,
              dateKey: 'ngaylam',
              heading: 'BS/KTV XÉT NGHIỆM',
              vietnameseTimeWords: true,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 38),
      pw.Text(
        '- Xét nghiệm có dấu "*" là xét nghiệm đạt chứng nhận ISO 15189:2022\n'
        '- Các giá trị in đậm là giá trị nằm ngoài khoảng tham chiếu.',
        style: const pw.TextStyle(fontSize: 7),
      ),
    ];
  }

  static List<pw.Widget> _hsv391(_PdfContext c) => _molecularPcrReport(
    c,
    specimenKeys: const ['tenloaimau', 'tenloaimaugop', 'ghichu'],
    fixedDevice: 'CFX-96',
    showNote: true,
  );

  static List<pw.Widget> _hbv388(_PdfContext c) {
    final rows = xnRows(xnValue(c.result, 'dongKetQua'));
    final detailRows = rows
        .where((row) => xnInt(xnValue(row, 'grouplevel')) == 0)
        .toList();
    final result = detailRows.isEmpty ? <String, dynamic>{} : detailRows.first;
    final info = _laboratoryInfo(c, detailRows);
    var requestedTest = _firstText(c.result, const ['tenDichVu']);
    if (requestedTest.isEmpty) {
      requestedTest = _firstText(result, const ['tenchiso_goc', 'tenchiso']);
    }
    final specimen = _firstText(info, const [
      'tenloaimau',
      'tenloaimaugop',
      'ghichu',
    ]);
    final performer = _firstText(info, const ['ktvlam', 'bslam']);
    final protocol = _firstText(info, const ['quytrinhxn']);
    final notes = <String>{
      for (final row in xnRows(xnValue(c.result, 'ghiChu'))) ...[
        _firstText(row, const ['ghichudichvu']),
        _firstText(row, const ['ghichubarcode', 'ghichu']),
      ],
    }..removeWhere((value) => value.isEmpty);
    final chart = _hbvChart388(c.result);

    return [
      _header609(c, info),
      pw.SizedBox(height: 4),
      _title('PHIẾU KẾT QUẢ XÉT NGHIỆM'),
      pw.SizedBox(height: 6),
      ..._clinicalInfo477(
        info,
        specimen: specimen,
        requestedTest: requestedTest,
      ),
      pw.SizedBox(height: 3),
      _hpvMethod477(device: 'CFX-96', protocol: protocol),
      _hbvQuantitativeTable388(result),
      pw.SizedBox(height: 2),
      _molecularNote(notes.join('\n')),
      pw.SizedBox(height: 5),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.SizedBox(
                  height: 145,
                  child: chart == null
                      ? pw.SizedBox()
                      : pw.Image(chart, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(height: 8),
                _line('Người thực hiện xét nghiệm', performer, bold: true),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _hbvChartLegend388(),
                pw.SizedBox(height: 30),
                _signature(
                  c,
                  info,
                  dateKey: 'ngaylam',
                  heading: 'BS/KTV XÉT NGHIỆM',
                  vietnameseTimeWords: true,
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Text(
        '- Xét nghiệm có dấu "*" là xét nghiệm đạt chứng nhận ISO 15189:2022\n'
        '- Các giá trị in đậm là giá trị nằm ngoài khoảng tham chiếu.',
        style: const pw.TextStyle(fontSize: 7),
      ),
    ];
  }

  static List<pw.Widget> _pcrPathogen474(_PdfContext c) => _molecularPcrReport(
    c,
    specimenKeys: const ['ghichu', 'tenloaimaugop', 'tenloaimau'],
    fixedDevice: 'CFX-96',
    showDetectionUnit: true,
  );

  static List<pw.Widget> _hpv477(_PdfContext c) => _molecularPcrReport(
    c,
    specimenKeys: const ['ghichu', 'tenloaimaugop', 'tenloaimau'],
  );

  static List<pw.Widget> _molecularPcrReport(
    _PdfContext c, {
    required List<String> specimenKeys,
    String? fixedDevice,
    bool showNote = false,
    bool showDetectionUnit = false,
  }) {
    final rows = xnRows(xnValue(c.result, 'dongKetQua'));
    final detailRows = rows
        .where((row) => xnInt(xnValue(row, 'grouplevel')) == 0)
        .toList();
    final info = _laboratoryInfo(c, detailRows);
    var requestedTest = _firstText(c.result, const ['tenDichVu']);
    if (requestedTest.isEmpty && detailRows.isNotEmpty) {
      requestedTest = _firstText(detailRows.first, const [
        'tenchiso_goc',
        'tenchiso',
      ]);
    }
    final specimen = _firstText(info, specimenKeys);
    final performer = _firstText(info, const ['ktvlam', 'bslam']);
    final device =
        fixedDevice ?? _firstText(info, const ['tenmaylam', 'InstrumentID']);
    final protocol = _firstText(info, const ['quytrinhxn']);
    final notes = <String>{
      for (final row in xnRows(xnValue(c.result, 'ghiChu'))) ...[
        _firstText(row, const ['ghichudichvu']),
        _firstText(row, const ['ghichubarcode', 'ghichu']),
      ],
    }..removeWhere((value) => value.isEmpty);

    return [
      _header609(c, info),
      pw.SizedBox(height: 4),
      _title('PHIẾU KẾT QUẢ XÉT NGHIỆM'),
      pw.SizedBox(height: 6),
      ..._clinicalInfo477(
        info,
        specimen: specimen,
        requestedTest: requestedTest,
      ),
      pw.SizedBox(height: 3),
      _hpvMethod477(device: device, protocol: protocol),
      showDetectionUnit ? _pcrPathogenTable474(rows) : _hpvTable477(rows),
      if (showNote && notes.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        _molecularNote(notes.join('\n')),
      ],
      pw.SizedBox(height: 7),
      if (showDetectionUnit)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _pcrDetectionLegend474(),
                  pw.SizedBox(height: 12),
                  _line('Người thực hiện xét nghiệm', performer, bold: true),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _signature(
                c,
                info,
                dateKey: 'ngaylam',
                heading: 'BS/KTV XÉT NGHIỆM',
                vietnameseTimeWords: true,
              ),
            ),
          ],
        )
      else
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _line('Người thực hiện xét nghiệm', performer, bold: true),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _signature(
                c,
                info,
                dateKey: 'ngaylam',
                heading: 'BS/KTV XÉT NGHIỆM',
                vietnameseTimeWords: true,
              ),
            ),
          ],
        ),
      pw.SizedBox(height: 13),
      pw.Text(
        '- Xét nghiệm có dấu "*" là xét nghiệm đạt chứng nhận ISO 15189:2022\n'
        '- Các giá trị in đậm là giá trị nằm ngoài khoảng tham chiếu.',
        style: const pw.TextStyle(fontSize: 7),
      ),
    ];
  }

  static List<pw.Widget> _fungalCulture764(_PdfContext c) =>
      _microbiologyResult(
        c,
        organismLabel: 'Tên vi nấm',
        susceptibilityLabel: 'Kết quả kháng nấm đồ - MIC',
      );

  static List<pw.Widget> _microbiology351(_PdfContext c) => _microbiologyResult(
    c,
    organismLabel: 'Tên vi khuẩn',
    susceptibilityLabel: 'Kết quả kháng sinh đồ - MIC',
    emphasizeOrganism: true,
  );

  static List<pw.Widget> _microbiology743(_PdfContext c) => _microbiologyResult(
    c,
    organismLabel: 'Tên vi khuẩn',
    susceptibilityLabel: 'Kết quả',
    emphasizeOrganism: true,
    emphasizeSusceptibilityResult: true,
  );

  static List<pw.Widget> _microbiologyResult(
    _PdfContext c, {
    required String organismLabel,
    required String susceptibilityLabel,
    bool emphasizeOrganism = false,
    bool emphasizeSusceptibilityResult = false,
  }) {
    final organisms = xnRows(xnValue(c.result, 'viKhuanVaChiDinh'));
    final organism = organisms.isEmpty ? <String, dynamic>{} : organisms.first;
    final drugs = xnRows(
      xnValue(c.result, 'khangSinh'),
    ).where((row) => xnSameOrganism(organism, row)).toList();
    final patient = c.patient;
    final diagnosis = c.diagnosis;
    final note = xnDisplayText(xnValue(organism, 'ghichuvitheokhuan'));
    final requestedTest = xnDisplayText(xnValue(organism, 'tendichvu'));
    final commonDiagnosis = xnDisplayText(xnValue(diagnosis, 'benhchung'));
    final mainDiagnosis = xnDisplayText(xnValue(diagnosis, 'benhchinh'));
    final susceptibilityResult = xnDisplayText(xnValue(organism, 'ketluan'));
    final organismName = xnDisplayText(xnValue(organism, 'tenvikhuan'));
    return [
      _header764(c, organism),
      pw.SizedBox(height: 6),
      _title('KẾT QUẢ XÉT NGHIỆM NUÔI CẤY VI SINH'),
      pw.SizedBox(height: 8),
      _two(
        _line('Bệnh nhân', _text(patient, 'hoten'), bold: true),
        _two(
          _line('Tuổi', _text(patient, 'tuoi')),
          _line('Giới tính', _text(patient, 'tenphai')),
        ),
      ),
      _line('Số điện thoại', _text(patient, 'dienthoai')),
      _line('Địa chỉ', _text(patient, 'diachi')),
      _two(
        _line('Nơi gửi', _text(organism, 'noigui')),
        _line('Ngày nhận mẫu', _date(xnValue(organism, 'ngaynhanbp'))),
      ),
      _line(
        'Chẩn đoán',
        commonDiagnosis.isEmpty ? mainDiagnosis : commonDiagnosis,
      ),
      _line('Mẫu bệnh phẩm', _text(organism, 'tenloaimau')),
      _two(
        _line('Kỹ thuật viên', _text(organism, 'ktvlam')),
        xnText(xnValue(organism, 'maylam')).isNotEmpty
            ? _line('Máy làm', _text(organism, 'maylam'))
            : pw.SizedBox(),
      ),
      _line(
        'Yêu cầu xét nghiệm',
        requestedTest.isEmpty ? _text(c.result, 'tenDichVu') : requestedTest,
      ),
      _line(
        organismLabel,
        organismName,
        bold: emphasizeOrganism,
        italic: emphasizeOrganism,
      ),
      _line(
        susceptibilityLabel,
        susceptibilityResult,
        bold: emphasizeSusceptibilityResult,
      ),
      if (drugs.isNotEmpty) ...[
        pw.SizedBox(height: 7),
        _fungalDrugTable(drugs),
      ],
      pw.SizedBox(height: 9),
      _line('Ghi chú', note.isEmpty ? '' : note),
      pw.SizedBox(height: 4),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: _line(
              'Người thực hiện xét nghiệm',
              _text(organism, 'ktvlam'),
              bold: true,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: _signature(
              c,
              organism,
              dateKey: 'ngaylam',
              heading: 'BS/KTV Xét nghiệm',
              vietnameseTimeWords: true,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Kết quả có giá trị trên mẫu xét nghiệm\n'
        'Kết quả in đậm ngoài ngưỡng sinh học. Yêu cầu gặp bác sĩ chỉ định\n'
        'Mẫu bệnh phẩm được lưu giữ 24h tại khoa xét nghiệm',
        style: const pw.TextStyle(fontSize: 9),
      ),
      pw.SizedBox(height: drugs.isEmpty ? 190 : 48),
      pw.Text(
        'Nhóm KS: A – ưu tiên lựa chọn đầu tiên. B - lựa chọn tiếp theo. '
        'C – Chỉ chọn khi các kháng sinh nhóm A & B đều kháng, U – KS chỉ '
        'dành cho điều trị đường tiết niệu. (Theo hướng dẫn của Bộ Y Tế và '
        'CLSI – Viện tiêu chuẩn lâm sàng và phòng thí nghiệm USA 2020)',
        style: const pw.TextStyle(fontSize: 6.5),
      ),
    ];
  }

  static List<pw.Widget> _generic(_PdfContext c) {
    final kind = XnResultKind.parse(xnValue(c.result, 'loaiKetQua'));
    final title = switch (kind) {
      XnResultKind.laboratory => 'PHIẾU KẾT QUẢ XÉT NGHIỆM',
      XnResultKind.pathology => 'PHIẾU KẾT QUẢ GIẢI PHẪU BỆNH',
      XnResultKind.antibiogram => 'PHIẾU KẾT QUẢ KHÁNG SINH ĐỒ',
      null => 'PHIẾU KẾT QUẢ CẬN LÂM SÀNG',
    };
    final rows = xnRows(xnValue(c.result, 'ketQua'));
    final firstResult = rows.isEmpty ? <String, dynamic>{} : rows.first;
    final content = <pw.Widget>[
      _header(c, firstResult),
      pw.SizedBox(height: 10),
      _title(title),
      pw.SizedBox(height: 9),
      ..._clinicalInfo(c),
      pw.SizedBox(height: 7),
    ];
    switch (kind) {
      case XnResultKind.laboratory:
        content.add(_laboratoryTable(c.result));
      case XnResultKind.antibiogram:
        content.addAll(_antibiogram(c.result));
      case XnResultKind.pathology:
      case null:
        content.addAll(_textResults(c.result));
    }
    content.addAll([pw.SizedBox(height: 10), _signature(c, firstResult)]);
    return content;
  }

  static pw.Widget _header(_PdfContext c, XnRow result) {
    final patient = c.patient;
    final makcb = _text(patient, 'makcb');
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Image(c.logo, width: 43, height: 43),
        pw.SizedBox(width: 7),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BỆNH VIỆN ĐA KHOA HÙNG VƯƠNG',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Khu Phượng Hùng, xã Chí Đám, tỉnh Phú Thọ',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Hotline: 18009415',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(
          width: 145,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (makcb != '—')
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code39(),
                  data: makcb,
                  width: 105,
                  height: 25,
                  drawText: false,
                ),
              pw.Text(
                'Mã BN: ${_text(patient, 'mabn')}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text('Mã KCB: $makcb', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                'Mã BP: ${_text(result, 'barcode')}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _header381(_PdfContext c, XnRow result) {
    final patient = c.patient;
    final makcb = _text(patient, 'makcb');
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Image(c.logo, width: 43, height: 43),
        pw.SizedBox(width: 7),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SỞ Y TẾ PHÚ THỌ',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'BỆNH VIỆN ĐA KHOA HÙNG VƯƠNG',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Khu Phượng Hùng, xã Chí Đám, tỉnh Phú Thọ',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text('18009415', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        pw.SizedBox(
          width: 145,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (makcb != '—')
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code39(),
                  data: makcb,
                  width: 105,
                  height: 25,
                  drawText: false,
                ),
              pw.Text(
                'Mã BN: ${_text(patient, 'mabn')}',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
              pw.Text(
                'Mã KCB: $makcb',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
              pw.Text(
                'Mã BP: ${_text(result, 'barcode')}',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _header764(_PdfContext c, XnRow organism) {
    final patient = c.patient;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Image(c.logo, width: 48, height: 48),
        pw.SizedBox(width: 7),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BỆNH VIỆN ĐA KHOA HÙNG VƯƠNG',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Khu Phượng Hùng, xã Chí Đám, tỉnh Phú Thọ',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text('SĐT: 1800 9415', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        pw.SizedBox(
          width: 145,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SID: ${_text(organism, 'barcode')}',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
              pw.Text(
                'Số vào viện: ${_text(patient, 'makcb')}',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
              pw.Text(
                'Mã y tế: ${_text(patient, 'mabn')}',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _header609(_PdfContext c, XnRow info) {
    final makcb = _firstText(info, const ['makcb']);
    final barcode = _firstText(info, const ['barcode']);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Image(c.logo, width: 43, height: 43),
        pw.SizedBox(width: 7),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BỆNH VIỆN ĐA KHOA HÙNG VƯƠNG',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Khu Phượng Hùng, xã Chí Đám, tỉnh Phú Thọ',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'SĐT: 1800 9415',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(
          width: 145,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('MS: 17/BV2', style: const pw.TextStyle(fontSize: 8.5)),
              pw.Text(
                'Mã KCB: $makcb',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
              if (barcode.isNotEmpty)
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code39(),
                  data: barcode,
                  width: 105,
                  height: 24,
                  drawText: false,
                ),
              if (barcode.isNotEmpty)
                pw.SizedBox(
                  width: 105,
                  child: pw.Text(
                    barcode,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static XnRow _laboratoryInfo(_PdfContext c, List<XnRow> detailRows) {
    final appRows = xnRows(xnValue(c.result, 'appThongTin'));
    final serverRows = xnRows(xnValue(c.result, 'thongTin'));
    final diagnosisRows = xnRows(xnValue(c.result, 'chanDoan'));
    return <String, dynamic>{
      if (appRows.isNotEmpty) ...appRows.first,
      if (detailRows.isNotEmpty) ...detailRows.first,
      ...c.result,
      ...c.order,
      ...c.patient,
      if (diagnosisRows.isNotEmpty) ...diagnosisRows.first,
      if (serverRows.isNotEmpty) ...serverRows.first,
    };
  }

  static List<pw.Widget> _clinicalInfo609(XnRow info) {
    var birthYear = _firstText(info, const ['namsinh']);
    if (birthYear.isEmpty) {
      final birthDate = DateTime.tryParse(_firstText(info, const ['ngaysinh']));
      if (birthDate != null) birthYear = birthDate.year.toString();
    }
    final room = _firstText(info, const ['tenphong', 'phongcd']);
    final bed = _firstText(info, const ['sogiuong']);
    final roomAndBed = [
      room,
      bed,
    ].where((value) => value.isNotEmpty).join(' - ');
    return [
      _two(
        _line('Họ tên', _firstText(info, const ['hoten']), bold: true),
        _two(
          _line('Năm sinh', birthYear),
          _line('Giới tính', _firstText(info, const ['tenphai', 'gioitinh'])),
        ),
      ),
      _line('Địa chỉ', _firstText(info, const ['diachi'])),
      _two(
        _line('Đối tượng', _firstText(info, const ['tendoituong'])),
        _line('Điện thoại', _firstText(info, const ['dienthoai'])),
      ),
      _two(
        _line('Khoa', _firstText(info, const ['tenkk', 'khoacd'])),
        _line('Phòng', roomAndBed),
      ),
      _two(
        _line('Ngày chỉ định', _firstDate(info, const ['ngayke', 'ngaycd'])),
        _line(
          'Bác sĩ chỉ định',
          _firstText(info, const ['tennv', 'bschidinh', 'tennguoicd']),
        ),
      ),
      _two(
        _line('Thời gian lấy mẫu', _firstDate(info, const ['ngaylaymau'])),
        _line('Thời gian nhận mẫu', _firstDate(info, const ['ngaykhopBC'])),
      ),
      _two(
        _line(
          'Nhân viên lấy mẫu',
          _firstText(info, const ['tennhanvienlaymau']),
        ),
        _line(
          'Nhân viên nhận mẫu',
          _firstText(info, const ['tennhanviennhan']),
        ),
      ),
      _two(
        _line(
          'Tình trạng NB khi lấy mẫu',
          _firstText(info, const ['tinhtrangnguoibenh']),
        ),
        _line(
          'Tình trạng mẫu',
          _firstText(info, const ['tenchatluong', 'tinhtrangmau']),
        ),
      ),
      _line(
        'Chẩn đoán',
        _firstText(info, const ['tenbenh', 'benhchung', 'benhchinh']),
      ),
    ];
  }

  static List<pw.Widget> _clinicalInfo301(XnRow info) {
    var birthYear = _firstText(info, const ['namsinh']);
    if (birthYear.isEmpty) {
      final birthDate = DateTime.tryParse(_firstText(info, const ['ngaysinh']));
      if (birthDate != null) birthYear = birthDate.year.toString();
    }
    final room = _firstText(info, const ['tenphong', 'phongcd']);
    final bed = _firstText(info, const ['sogiuong']);
    final roomAndBed = [
      room,
      bed,
    ].where((value) => value.isNotEmpty).join(' - ');
    return [
      _two(
        _line('Họ tên', _firstText(info, const ['hoten']), bold: true),
        _two(
          _line('Năm sinh', birthYear),
          _line('Giới tính', _firstText(info, const ['tenphai', 'gioitinh'])),
        ),
      ),
      _line('Địa chỉ', _firstText(info, const ['diachi'])),
      _two(
        _line('Đối tượng', _firstText(info, const ['tendoituong'])),
        _line('Điện thoại', _firstText(info, const ['dienthoai'])),
      ),
      _two(
        _line('Khoa', _firstText(info, const ['tenkk', 'khoacd'])),
        _line('Phòng', roomAndBed),
      ),
      _two(
        _line('Ngày chỉ định', _firstDate(info, const ['ngayke', 'ngaycd'])),
        _line(
          'Bác sĩ chỉ định',
          _firstText(info, const ['tennv', 'bschidinh', 'tennguoicd']),
        ),
      ),
      _two(
        _line(
          'Thời gian lấy mẫu',
          _firstDate(info, const ['ngaygiao', 'ngaylaymau']),
        ),
        _line('Thời gian nhận mẫu', _firstDate(info, const ['ngaykhopBC'])),
      ),
      _two(
        _line(
          'Nhân viên lấy mẫu',
          _firstText(info, const ['nguoigiao', 'tennhanvienlaymau']),
        ),
        _line(
          'Nhân viên nhận mẫu',
          _firstText(info, const ['tennhanviennhan']),
        ),
      ),
      _two(
        _line(
          'Tình trạng NB khi lấy mẫu',
          _firstText(info, const ['tinhtrangnguoibenh']),
        ),
        _line(
          'Tình trạng mẫu',
          _firstText(info, const ['tinhtrangmau', 'tenchatluong']),
        ),
      ),
      _line(
        'Chẩn đoán',
        _firstText(info, const ['tenbenh', 'benhchung', 'benhchinh']),
      ),
    ];
  }

  static List<pw.Widget> _clinicalInfo477(
    XnRow info, {
    required String specimen,
    required String requestedTest,
  }) {
    var birthYear = _firstText(info, const ['namsinh']);
    if (birthYear.isEmpty) {
      final birthDate = DateTime.tryParse(_firstText(info, const ['ngaysinh']));
      if (birthDate != null) birthYear = birthDate.year.toString();
    }
    return [
      _two(
        _line('Họ tên', _firstText(info, const ['hoten']), bold: true),
        _two(
          _line('Năm sinh', birthYear),
          _line('Giới tính', _firstText(info, const ['tenphai', 'gioitinh'])),
        ),
      ),
      _line('Địa chỉ', _firstText(info, const ['diachi'])),
      _two(
        _line('Số điện thoại', _firstText(info, const ['dienthoai'])),
        _line('Đối tượng', _firstText(info, const ['tendoituong'])),
      ),
      _two(
        _line('Khoa', _firstText(info, const ['tenkk', 'khoacd'])),
        _two(
          _line('Phòng', _firstText(info, const ['tenphong', 'phongcd'])),
          _line('Giường', _firstText(info, const ['sogiuong'])),
        ),
      ),
      _two(
        _line('Ngày chỉ định', _firstDate(info, const ['ngayke', 'ngaycd'])),
        _line(
          'Bác sĩ chỉ định',
          _firstText(info, const ['tennv', 'bschidinh', 'tennguoicd']),
        ),
      ),
      _two(
        _line(
          'Thời gian lấy mẫu',
          _firstDate(info, const ['ngaygiao', 'ngaylaymau']),
        ),
        _line('Thời gian nhận mẫu', _firstDate(info, const ['ngaykhopBC'])),
      ),
      _two(
        _line(
          'Nhân viên lấy mẫu',
          _firstText(info, const ['nguoigiao', 'tennhanvienlaymau']),
        ),
        _line(
          'Nhân viên nhận mẫu',
          _firstText(info, const ['tennhanviennhan']),
        ),
      ),
      _two(
        _line(
          'Tình trạng NB khi lấy mẫu',
          _firstText(info, const ['tinhtrangnguoibenh']),
        ),
        _line(
          'Tình trạng mẫu',
          _firstText(info, const ['tinhtrangmau', 'tenchatluong']),
        ),
      ),
      _line(
        'Chẩn đoán',
        _firstText(info, const ['tenbenh', 'benhchung', 'benhchinh']),
      ),
      _line('Bệnh phẩm', specimen),
      _line('Yêu cầu xét nghiệm', requestedTest, bold: true),
    ];
  }

  static List<pw.Widget> _clinicalInfo(_PdfContext c) {
    final p = c.patient;
    final order = c.order;
    final diagnosis = c.diagnosis;
    return [
      _two(
        _line('Bệnh nhân', _text(p, 'hoten'), bold: true),
        _line('Tuổi/Giới tính', '${_text(p, 'tuoi')} / ${_text(p, 'tenphai')}'),
      ),
      _line('Địa chỉ', _text(p, 'diachi')),
      _two(
        _line('Mã thẻ BHYT', _text(p, 'sothebhyt')),
        _line('Điện thoại', _text(p, 'dienthoai')),
      ),
      _two(
        _line('Bác sĩ chỉ định', _text(order, 'tennv')),
        _line('Nơi chỉ định', _text(order, 'tenkk')),
      ),
      _line('Chẩn đoán', _text(diagnosis, 'benhchinh')),
      _line('Chỉ định', _text(c.result, 'tenDichVu')),
    ];
  }

  static List<pw.Widget> _clinicalInfo381(_PdfContext c) {
    final p = c.patient;
    final order = c.order;
    final diagnosis = c.diagnosis;
    return [
      _two(
        _line('Bệnh nhân', _text(p, 'hoten'), bold: true),
        _two(
          _line('Tuổi', _text(p, 'tuoi')),
          _line('Giới tính', _text(p, 'tenphai')),
        ),
      ),
      _line('Địa chỉ', _text(p, 'diachi')),
      _two(
        _line('Mã thẻ BHYT', _text(p, 'sothebhyt')),
        _line('Điện thoại', _text(p, 'dienthoai')),
      ),
      _two(
        _line('Bác sĩ chỉ định', _text(order, 'bschidinh', fallback: 'tennv')),
        _line('Nơi chỉ định', _text(order, 'tenkk')),
      ),
      _line('Ngày chỉ định', _date(xnValue(order, 'ngay'))),
      _line('Chẩn đoán', _text(diagnosis, 'benhchinh')),
      _line('Chỉ định', _text(c.result, 'tenDichVu')),
    ];
  }

  static List<pw.Widget> _clinicalInfo383(_PdfContext c, XnRow result) {
    final p = c.patient;
    final order = c.order;
    final diagnosis = c.diagnosis;
    return [
      _two(
        _line('Bệnh nhân', _text(p, 'hoten'), bold: true),
        _two(
          _line('Tuổi', _text(p, 'tuoi')),
          _line('Giới tính', _text(p, 'tenphai')),
        ),
      ),
      _line('Địa chỉ', _text(p, 'diachi')),
      _two(
        _line('Mã thẻ BHYT', _text(p, 'sothebhyt')),
        _line('Điện thoại', _text(p, 'dienthoai')),
      ),
      _two(
        _line('Bác sĩ chỉ định', _text(order, 'bschidinh', fallback: 'tennv')),
        _line('Nơi chỉ định', _text(order, 'tenkk')),
      ),
      _two(
        _line('Ngày chỉ định', _date(xnValue(order, 'ngay'))),
        _line('Ngày thực hiện', _date(xnValue(result, 'ngayth'))),
      ),
      _line('Chẩn đoán', _text(diagnosis, 'benhchinh')),
      _line('Chỉ định', _text(c.result, 'tenDichVu')),
    ];
  }

  static pw.Widget _samplePosition(String value) {
    if (value == '—') return _line('Vị trí lấy mẫu', value);
    if (value.toLowerCase().startsWith('vị trí lấy mẫu')) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      );
    }
    return _line('Vị trí lấy mẫu', value);
  }

  static pw.Widget _checkLine(XnGpb376Field definition, List<XnRow> fields) {
    final matches = fields
        .where(
          (row) =>
              xnText(xnValue(row, 'name')).toLowerCase() ==
              definition.name.toLowerCase(),
        )
        .toList();
    final value = matches.length == 1
        ? xnValue(matches.single, 'giaTriBoolean')
        : null;
    final mark = value is bool ? (value ? 'X' : '') : '—';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 11,
            height: 11,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: .7)),
            child: pw.Text(mark, style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              definition.label,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: definition.bold
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
                fontStyle: definition.italic
                    ? pw.FontStyle.italic
                    : pw.FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _group(List<XnRow> fields, String group) => [
    for (final definition in xnGpb376Fields.where(
      (item) => item.group == group,
    ))
      _checkLine(definition, fields),
  ];

  static pw.Widget _parentWithColumns(List<XnRow> fields, String group) {
    final items = _group(fields, group);
    if (items.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        items.first,
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 14),
          child: pw.Wrap(
            spacing: 7,
            runSpacing: 1,
            children: [
              for (final item in items.skip(1))
                pw.SizedBox(width: 158, child: item),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _laboratoryTable(XnRow result) {
    final rows = xnRows(xnValue(result, 'dongKetQua'))
        .where((row) => xnInt(xnValue(row, 'grouplevel')) == 0)
        .map(
          (row) => [
            xnDisplayText(xnValue(row, 'tenchiso_goc')),
            xnDisplayText(xnValue(row, 'ketqua_goc')),
            xnDisplayText(xnValue(row, 'tendonvitinh')),
            xnDisplayText(xnValue(row, 'giatribinhthuong')),
          ],
        )
        .toList();
    return pw.TableHelper.fromTextArray(
      headers: const [
        'Tên xét nghiệm',
        'Kết quả',
        'Đơn vị',
        'Khoảng tham chiếu',
      ],
      data: rows,
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      border: pw.TableBorder.all(width: .5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.1),
        3: pw.FlexColumnWidth(2),
      },
    );
  }

  static pw.Widget _laboratoryTable301(List<XnRow> rows) {
    pw.Widget cell(
      String value, {
      pw.TextAlign align = pw.TextAlign.left,
      bool bold = false,
      bool italic = false,
      bool underline = false,
      PdfColor color = PdfColors.black,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1.4),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.4,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
          decoration: underline
              ? pw.TextDecoration.underline
              : pw.TextDecoration.none,
          color: color,
        ),
      ),
    );

    PdfColor fallbackColor(XnRow row) {
      final flag = _firstText(row, const ['HL']).toUpperCase();
      if (flag.isEmpty) return PdfColors.black;
      if (flag.contains('L') || flag.contains('↓')) return PdfColors.blue;
      return PdfColors.red;
    }

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        children: [
          cell('STT', align: pw.TextAlign.center, bold: true),
          cell('Tên xét nghiệm', align: pw.TextAlign.center, bold: true),
          cell('Kết quả', align: pw.TextAlign.center, bold: true),
          cell('Khoảng tham\nchiếu', align: pw.TextAlign.center, bold: true),
          cell('QTXN', align: pw.TextAlign.center, bold: true),
          cell('Máy XN', align: pw.TextAlign.center, bold: true),
        ],
      ),
    ];
    for (final row in rows) {
      final isGroup = xnInt(xnValue(row, 'grouplevel')) != 0;
      final name = isGroup
          ? _firstText(row, const ['grheadertext', 'tenchiso_goc', 'tenchiso'])
          : _firstText(row, const ['tenchiso_goc', 'tenchiso']);
      final result = xnFormattedText(
        xnValue(row, 'ketluan'),
        fallbackText: xnValue(row, 'ketqua_goc'),
      );
      final flag = _firstText(row, const ['HL']);
      final useFlagStyle = !result.hasColor && flag.isNotEmpty;
      final color = result.hasColor
          ? PdfColor(result.red! / 255, result.green! / 255, result.blue! / 255)
          : fallbackColor(row);
      tableRows.add(
        pw.TableRow(
          decoration: isGroup
              ? const pw.BoxDecoration(color: PdfColors.grey100)
              : null,
          children: [
            cell(
              _firstText(row, const ['STT_DV']),
              align: pw.TextAlign.center,
              bold: isGroup,
            ),
            cell(name, bold: isGroup),
            cell(
              isGroup ? '' : result.text,
              align: pw.TextAlign.center,
              bold: result.bold || useFlagStyle,
              italic: result.italic,
              underline: result.underline,
              color: color,
            ),
            cell(
              isGroup ? '' : _firstText(row, const ['giatribinhthuong']),
              align: pw.TextAlign.center,
            ),
            cell(
              isGroup ? '' : _firstText(row, const ['quytrinhxn']),
              align: pw.TextAlign.center,
            ),
            cell(
              isGroup
                  ? ''
                  : _firstText(row, const ['tenmaylam', 'InstrumentID']),
              align: pw.TextAlign.center,
            ),
          ],
        ),
      );
    }
    return pw.Table(
      border: pw.TableBorder.all(width: .45),
      columnWidths: const {
        0: pw.FlexColumnWidth(.45),
        1: pw.FlexColumnWidth(3.5),
        2: pw.FlexColumnWidth(1.7),
        3: pw.FlexColumnWidth(1.55),
        4: pw.FlexColumnWidth(1.8),
        5: pw.FlexColumnWidth(1.25),
      },
      children: tableRows,
    );
  }

  static pw.Widget _molecularNote(String value) {
    final hasLabel = value.toLowerCase().startsWith('ghi chú');
    if (hasLabel) {
      return pw.Text(value, style: const pw.TextStyle(fontSize: 9));
    }
    return _line('Ghi chú', value);
  }

  static pw.MemoryImage? _hbvChart388(XnRow data) {
    for (final row in xnRows(xnValue(data, 'hinhAnh'))) {
      final raw = _firstText(row, const ['anhBase64', 'Anh']);
      if (raw.isEmpty) continue;
      final image = _optionalBase64Image(raw);
      if (image != null) return image;
    }
    return null;
  }

  static pw.Widget _hbvChartLegend388() {
    pw.Widget item(PdfColor color, String label) => pw.Row(
      children: [
        pw.Container(width: 22, height: 14, color: color),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8.5)),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        item(PdfColors.red, 'Chứng chuẩn'),
        item(PdfColors.green, 'Chứng nội tại mẫu'),
        item(const PdfColor(0, 0, .5), 'Mẫu'),
        item(const PdfColor(.58, .88, .9), 'Chứng âm'),
      ],
    );
  }

  static pw.Widget _pcrDetectionLegend474() => pw.Text(
    'Ghi chú:\n'
    '- DU: Detection unit (1DU = 5 copies)\n'
    '- 1E+n : 1x10n\n'
    '- Tác nhân gây bệnh chính ≥ 10^5\n'
    '- Tác nhân gây bệnh phối hợp trong khoảng 10^4 - 10^5\n'
    '- Tác nhân hiện diện không có ý nghĩa ≤ 10^3\n'
    '- w/r: chờ kết quả',
    style: const pw.TextStyle(fontSize: 7.5),
  );

  static pw.Widget _hpvMethod477({
    required String device,
    required String protocol,
  }) {
    pw.Widget cell(
      String value, {
      bool bold = false,
      bool italic = false,
      pw.TextAlign align = pw.TextAlign.left,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
        ),
      ),
    );

    pw.Widget section(String value) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.3),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: .55)),
      child: pw.Text(
        value,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        section('PHƯƠNG PHÁP THỰC HIỆN'),
        pw.Table(
          border: pw.TableBorder(
            left: const pw.BorderSide(width: .55),
            right: const pw.BorderSide(width: .55),
            bottom: const pw.BorderSide(width: .55),
            horizontalInside: const pw.BorderSide(width: .45),
            verticalInside: const pw.BorderSide(width: .45),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.25),
            1: pw.FlexColumnWidth(4.75),
          },
          children: [
            pw.TableRow(
              children: [
                cell('Kỹ thuật thực hiện', italic: true),
                cell('Realtime PCR'),
              ],
            ),
            pw.TableRow(
              children: [
                cell('Thiết bị thực hiện', italic: true),
                cell(device),
              ],
            ),
            pw.TableRow(children: [cell('QTXN', italic: true), cell(protocol)]),
          ],
        ),
        section('KẾT QUẢ'),
      ],
    );
  }

  static pw.Widget _hpvTable477(List<XnRow> rows) {
    pw.Widget cell(
      String value, {
      pw.TextAlign align = pw.TextAlign.left,
      bool bold = false,
      bool italic = false,
      bool underline = false,
      PdfColor color = PdfColors.black,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.05),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.6,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
          decoration: underline
              ? pw.TextDecoration.underline
              : pw.TextDecoration.none,
          color: color,
        ),
      ),
    );

    PdfColor colorOf(XnFormattedText value) => value.hasColor
        ? PdfColor(value.red! / 255, value.green! / 255, value.blue! / 255)
        : PdfColors.black;

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        children: [
          cell('Tên tác nhân', align: pw.TextAlign.center, bold: true),
          cell('Kết quả', align: pw.TextAlign.center, bold: true),
        ],
      ),
    ];

    for (final row in rows) {
      if (xnInt(xnValue(row, 'grouplevel')) != 0) continue;
      final name = xnFormattedText(
        xnValue(row, 'tenchiso'),
        fallbackText: xnValue(row, 'tenchiso_goc'),
      );
      final result = xnFormattedText(
        xnValue(row, 'ketluan'),
        fallbackText: xnValue(row, 'ketqua_goc'),
      );
      if (name.text.isEmpty && result.text.isEmpty) continue;
      tableRows.add(
        pw.TableRow(
          children: [
            cell(
              name.text,
              bold: name.bold,
              italic: name.italic,
              underline: name.underline,
              color: colorOf(name),
            ),
            cell(
              result.text,
              align: pw.TextAlign.center,
              bold: result.bold,
              italic: result.italic,
              underline: result.underline,
              color: colorOf(result),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder(
        left: const pw.BorderSide(width: .55),
        right: const pw.BorderSide(width: .55),
        bottom: const pw.BorderSide(width: .55),
        horizontalInside: const pw.BorderSide(width: .45),
        verticalInside: const pw.BorderSide(width: .45),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.05),
        1: pw.FlexColumnWidth(.95),
      },
      children: tableRows,
    );
  }

  static pw.Widget _hbvQuantitativeTable388(XnRow row) {
    pw.Widget cell(
      String value, {
      bool bold = false,
      bool italic = false,
      bool underline = false,
      PdfColor color = PdfColors.black,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.8),
      child: pw.Text(
        value,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8.2,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
          decoration: underline
              ? pw.TextDecoration.underline
              : pw.TextDecoration.none,
          color: color,
        ),
      ),
    );

    PdfColor colorOf(XnFormattedText value) => value.hasColor
        ? PdfColor(value.red! / 255, value.green! / 255, value.blue! / 255)
        : PdfColors.black;

    final quantitativeResult = xnFormattedText(
      xnValue(row, 'ketluan'),
      fallbackText: xnValue(row, 'ketqua_goc'),
    );
    final threshold = _firstText(row, const ['giatribinhthuong']);
    final unit = _firstText(row, const ['tendonvitinh']);
    final thresholdWithUnit = [
      threshold,
      if (unit.isNotEmpty &&
          !threshold.toLowerCase().contains(unit.toLowerCase()))
        unit,
    ].where((value) => value.isNotEmpty).join(' ');

    return pw.Table(
      border: pw.TableBorder(
        left: const pw.BorderSide(width: .55),
        right: const pw.BorderSide(width: .55),
        bottom: const pw.BorderSide(width: .55),
        horizontalInside: const pw.BorderSide(width: .45),
        verticalInside: const pw.BorderSide(width: .45),
      ),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
      children: [
        pw.TableRow(
          children: [
            cell('Kết quả định lượng', bold: true),
            cell('Ngưỡng phát hiện', bold: true),
          ],
        ),
        pw.TableRow(
          children: [
            cell(
              quantitativeResult.text,
              bold: true,
              italic: quantitativeResult.italic,
              underline: quantitativeResult.underline,
              color: colorOf(quantitativeResult),
            ),
            cell(thresholdWithUnit),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pcrPathogenTable474(List<XnRow> rows) {
    pw.Widget cell(
      String value, {
      pw.TextAlign align = pw.TextAlign.left,
      bool bold = false,
      bool italic = false,
      bool underline = false,
      PdfColor color = PdfColors.black,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.2),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
          decoration: underline
              ? pw.TextDecoration.underline
              : pw.TextDecoration.none,
          color: color,
        ),
      ),
    );

    PdfColor colorOf(XnFormattedText value) => value.hasColor
        ? PdfColor(value.red! / 255, value.green! / 255, value.blue! / 255)
        : PdfColors.black;

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        children: [
          cell('Tên tác nhân', align: pw.TextAlign.center, bold: true),
          cell('Kết quả', align: pw.TextAlign.center, bold: true),
          cell('DU', align: pw.TextAlign.center, bold: true),
        ],
      ),
    ];

    for (final row in rows) {
      if (xnInt(xnValue(row, 'grouplevel')) != 0) continue;
      final name = xnFormattedText(
        xnValue(row, 'tenchiso'),
        fallbackText: xnValue(row, 'tenchiso_goc'),
      );
      final result = xnFormattedText(xnValue(row, 'mota'));
      final detectionUnit = xnFormattedText(
        xnValue(row, 'ketluan'),
        fallbackText: xnValue(row, 'ketqua_goc'),
      );
      if (name.text.isEmpty &&
          result.text.isEmpty &&
          detectionUnit.text.isEmpty) {
        continue;
      }
      tableRows.add(
        pw.TableRow(
          children: [
            cell(
              name.text,
              bold: name.bold,
              italic: name.italic,
              underline: name.underline,
              color: colorOf(name),
            ),
            cell(
              result.text,
              align: pw.TextAlign.center,
              bold: result.bold,
              italic: result.italic,
              underline: result.underline,
              color: colorOf(result),
            ),
            cell(
              detectionUnit.text,
              align: pw.TextAlign.center,
              bold: detectionUnit.bold,
              italic: detectionUnit.italic,
              underline: detectionUnit.underline,
              color: colorOf(detectionUnit),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder(
        left: const pw.BorderSide(width: .55),
        right: const pw.BorderSide(width: .55),
        bottom: const pw.BorderSide(width: .55),
        horizontalInside: const pw.BorderSide(width: .45),
        verticalInside: const pw.BorderSide(width: .45),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(1.45),
        2: pw.FlexColumnWidth(1.15),
      },
      children: tableRows,
    );
  }

  static pw.Widget _hematologyTable609(List<XnRow> rows) {
    pw.Widget cell(
      String value, {
      pw.TextAlign align = pw.TextAlign.left,
      bool bold = false,
      bool italic = false,
      bool underline = false,
      PdfColor color = PdfColors.black,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1.2),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.2,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
          decoration: underline
              ? pw.TextDecoration.underline
              : pw.TextDecoration.none,
          color: color,
        ),
      ),
    );

    PdfColor fallbackResultColor(XnRow row) {
      final flag = _firstText(row, const ['HL']).toUpperCase();
      if (flag.isEmpty) return PdfColors.black;
      if (flag.contains('L') || flag.contains('↓')) return PdfColors.blue;
      return PdfColors.red;
    }

    PdfColor configuredColor(XnFormattedText value, XnRow row) => value.hasColor
        ? PdfColor(value.red! / 255, value.green! / 255, value.blue! / 255)
        : fallbackResultColor(row);

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          cell('STT', align: pw.TextAlign.center, bold: true),
          cell('Tên xét nghiệm', align: pw.TextAlign.center, bold: true),
          cell('Kết quả', align: pw.TextAlign.center, bold: true),
          cell('Đơn vị', align: pw.TextAlign.center, bold: true),
          cell('Khoảng tham\nchiếu', align: pw.TextAlign.center, bold: true),
          cell('QTXN', align: pw.TextAlign.center, bold: true),
          cell('Máy XN', align: pw.TextAlign.center, bold: true),
        ],
      ),
    ];
    for (final row in rows) {
      final isGroup = xnInt(xnValue(row, 'grouplevel')) != 0;
      final name = isGroup
          ? _firstText(row, const ['grheadertext', 'tenchiso_goc', 'tenchiso'])
          : _firstText(row, const ['tenchiso_goc', 'tenchiso']);
      final result = xnFormattedText(
        xnValue(row, 'ketluan'),
        fallbackText: xnValue(row, 'ketqua_goc'),
      );
      final color = configuredColor(result, row);
      final useFlagStyle =
          !result.hasColor && _firstText(row, const ['HL']).isNotEmpty;
      tableRows.add(
        pw.TableRow(
          decoration: isGroup
              ? const pw.BoxDecoration(color: PdfColors.grey100)
              : null,
          children: [
            cell(
              _firstText(row, const ['STT_DV']),
              align: pw.TextAlign.center,
              bold: isGroup,
            ),
            cell(name, bold: isGroup),
            cell(
              isGroup ? '' : result.text,
              align: pw.TextAlign.center,
              bold: result.bold || useFlagStyle,
              italic: result.italic,
              underline: result.underline,
              color: color,
            ),
            cell(
              isGroup ? '' : _firstText(row, const ['tendonvitinh']),
              align: pw.TextAlign.center,
            ),
            cell(
              isGroup ? '' : _firstText(row, const ['giatribinhthuong']),
              align: pw.TextAlign.center,
            ),
            cell(
              isGroup ? '' : _firstText(row, const ['quytrinhxn']),
              align: pw.TextAlign.center,
            ),
            cell(
              isGroup
                  ? ''
                  : _firstText(row, const ['InstrumentID', 'tenmaylam']),
              align: pw.TextAlign.center,
            ),
          ],
        ),
      );
    }
    return pw.Table(
      border: pw.TableBorder.all(width: .45),
      columnWidths: const {
        0: pw.FlexColumnWidth(.5),
        1: pw.FlexColumnWidth(3.5),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(.8),
        4: pw.FlexColumnWidth(1.35),
        5: pw.FlexColumnWidth(1.65),
        6: pw.FlexColumnWidth(1.4),
      },
      children: tableRows,
    );
  }

  static List<pw.Widget> _antibiogram(XnRow result) {
    final organisms = xnRows(xnValue(result, 'viKhuanVaChiDinh'));
    final antibiotics = xnRows(xnValue(result, 'khangSinh'));
    return [
      for (final organism in organisms) ...[
        pw.Text(
          _text(organism, 'tenvikhuan'),
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.TableHelper.fromTextArray(
          headers: const ['Kháng sinh', 'MIC', 'S/I/R'],
          data: [
            for (final row in antibiotics)
              if (xnSameOrganism(organism, row))
                [
                  _text(row, 'tenkhangsinh'),
                  _text(row, 'MIC'),
                  _text(row, 'SIR'),
                ],
          ],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          border: pw.TableBorder.all(width: .5),
        ),
        pw.SizedBox(height: 7),
      ],
    ];
  }

  static pw.Widget _fungalDrugTable(List<XnRow> rows) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Nhóm KS', 'Tên kháng sinh', 'Kết quả', 'SRI', 'PPXN'],
      data: [
        for (final row in rows)
          [
            xnDisplayText(xnValue(row, 'tennhomks')),
            xnDisplayText(xnValue(row, 'tenkhangsinh')),
            xnText(xnValue(row, 'duongkinh')).isNotEmpty
                ? xnDisplayText(xnValue(row, 'duongkinh'))
                : xnDisplayText(xnValue(row, 'MIC')),
            xnDisplayText(xnValue(row, 'SIR')),
            xnText(xnValue(row, 'duongkinh')).isNotEmpty ? 'DISK' : 'MIC',
          ],
      ],
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      border: pw.TableBorder.all(width: .5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1),
        1: pw.FlexColumnWidth(2.8),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(.8),
        4: pw.FlexColumnWidth(.9),
      },
    );
  }

  static List<pw.Widget> _textResults(XnRow data) {
    final layout = xnGpbLayout(
      xnText(xnValue(data, 'idMauIn')),
      xnInt(xnValue(data, 'idMauKqKhac')),
    );
    return [
      for (final row in xnRows(xnValue(data, 'ketQua')))
        for (final entry in layout.resultLabels.entries)
          if (xnDisplayText(xnValue(row, entry.key)).isNotEmpty)
            _line(
              entry.value,
              xnDisplayText(xnValue(row, entry.key)),
              bold: entry.key == 'ketluan',
            ),
    ];
  }

  static pw.Widget _resultParagraph(
    String label,
    dynamic raw, {
    bool valueBold = false,
  }) {
    final value = xnDisplayText(raw);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          if (value.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12, top: 1),
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.justify,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: valueBold
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static List<pw.Widget> _resultImages(XnRow data) {
    final output = <pw.Widget>[];
    for (final row in xnRows(xnValue(data, 'hinhAnh'))) {
      final image = _optionalBase64Image(xnText(xnValue(row, 'anhBase64')));
      if (image == null) continue;
      output.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Center(
            child: pw.Image(image, height: 120, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    return output;
  }

  /// Ảnh từ HIS là dữ liệu phụ. Dòng cũ có thể chứa file rỗng, định dạng ảnh
  /// không được hỗ trợ hoặc data-URI thay cho Base64 thuần. Các trường hợp đó
  /// không được làm hỏng toàn bộ phiếu kết quả.
  static pw.MemoryImage? _optionalBase64Image(String value) {
    var raw = value.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('data:')) {
      final separator = raw.indexOf(',');
      if (separator < 0) return null;
      raw = raw.substring(separator + 1);
    }
    try {
      return pw.MemoryImage(base64Decode(raw));
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _signature(
    _PdfContext c,
    XnRow result, {
    String dateKey = 'ngaylam',
    String heading = 'BÁC SĨ CHUYÊN KHOA',
    bool vietnameseTimeWords = false,
  }) {
    final date = vietnameseTimeWords
        ? _longDateWithWords(xnValue(result, dateKey))
        : _longDate(xnValue(result, dateKey));
    final signed = xnBool(xnValue(c.signature, 'daKyHIS')) == true;
    final green =
        signed &&
        xnBool(xnValue(c.signature, 'dangKyHsmHopLe')) == true &&
        xnBool(xnValue(c.signature, 'hienThiTichXanh')) == true;
    final name = _text(c.signature, 'tenthuonggoi', fallback: 'tenNguoiKy');
    final signedAt = _date(xnValue(c.signature, 'ngayKy'));
    final signatureImage = _optionalBase64Image(
      xnText(xnValue(c.signature, 'anhBase64')),
    );
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 230,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              date,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
            ),
            pw.Text(
              heading,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            if (signed && (signatureImage != null || green))
              pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  if (signatureImage != null)
                    pw.Image(
                      signatureImage,
                      width: 145,
                      height: 52,
                      fit: pw.BoxFit.contain,
                    ),
                  if (green)
                    pw.Positioned(
                      left: 15,
                      top: 5,
                      child: pw.SvgImage(
                        width: 18,
                        height: 18,
                        svg:
                            '<svg viewBox="0 0 24 24" '
                            'xmlns="http://www.w3.org/2000/svg">'
                            '<path fill="#36a852" d="M9.2 18.1 3.8 12.7l2.1-2.1 '
                            '3.3 3.3 8.9-8.9 2.1 2.1z"/></svg>',
                      ),
                    ),
                ],
              ),
            if (signedAt.isNotEmpty)
              pw.Text(
                'Ngày ký: $signedAt',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            if (name != '—')
              pw.Text(
                name,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _title(String value) => pw.Center(
    child: pw.Text(
      value,
      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
    ),
  );

  static pw.Widget _line(
    String label,
    String value, {
    bool bold = false,
    bool italic = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(fontSize: 9),
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
            ),
          ),
        ],
      ),
    ),
  );

  static pw.Widget _two(pw.Widget left, pw.Widget right) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(child: left),
      pw.SizedBox(width: 10),
      pw.Expanded(child: right),
    ],
  );

  static String _text(XnRow row, String key, {String? fallback}) {
    final value = xnDisplayText(xnValue(row, key));
    if (value.isNotEmpty) return value;
    final second = fallback == null
        ? ''
        : xnDisplayText(xnValue(row, fallback));
    return second.isEmpty ? '—' : second;
  }

  static String _firstText(XnRow row, List<String> keys) {
    for (final key in keys) {
      final value = xnDisplayText(xnValue(row, key));
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _firstDate(XnRow row, List<String> keys) {
    for (final key in keys) {
      final raw = xnText(xnValue(row, key));
      if (raw.isNotEmpty) return _date(raw);
    }
    return '';
  }

  static String _date(dynamic value) {
    final raw = xnText(value);
    if (raw.isEmpty) return '';
    final date = DateTime.tryParse(raw);
    return date == null ? raw : DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String _dateOnly(dynamic value) {
    final raw = xnText(value);
    if (raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw);
    return date == null ? raw : DateFormat('dd/MM/yyyy').format(date);
  }

  static String _longDate(dynamic value) {
    final date = DateTime.tryParse(xnText(value));
    return date == null
        ? ''
        : DateFormat("HH:mm, 'Ngày' dd 'tháng' MM 'năm' yyyy").format(date);
  }

  static String _longDateWithWords(dynamic value) {
    final date = DateTime.tryParse(xnText(value));
    return date == null
        ? ''
        : DateFormat(
            "HH 'giờ' mm 'phút, Ngày' dd 'tháng' MM 'năm' yyyy",
          ).format(date);
  }
}

class _PdfContext {
  const _PdfContext(this.result, this.signature, this.logo);
  final XnRow result;
  final XnRow signature;
  final pw.MemoryImage logo;

  XnRow get patient {
    final rows = xnRows(xnValue(result, 'benhNhan'));
    if (rows.isNotEmpty) return rows.first;
    final value = xnValue(result, 'benhNhan');
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  XnRow get order {
    final rows = xnRows(xnValue(result, 'chiDinh'));
    return rows.isEmpty ? const {} : rows.first;
  }

  XnRow get diagnosis {
    final rows = xnRows(xnValue(result, 'chanDoan'));
    return rows.isEmpty ? const {} : rows.first;
  }
}
