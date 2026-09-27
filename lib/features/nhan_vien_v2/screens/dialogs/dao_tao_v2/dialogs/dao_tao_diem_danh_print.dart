import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../../models/dao_tao_v2_models.dart';

class DaoTaoDiemDanhPrint {
  DaoTaoDiemDanhPrint._();

  static Future<void> print(DaoTaoInDiemDanhV2Model data) async {
    final bytes = await buildPdf(data);

    await Printing.layoutPdf(
      name:
          'Danh_sach_diem_danh_'
          '${data.idLopDaoTao}.pdf',

      onLayout: (_) async => bytes,
    );
  }

  static Future<Uint8List> buildPdf(DaoTaoInDiemDanhV2Model data) async {
    final pdf = pw.Document();

    // ======================================================
    // FONT VIỆT
    // ======================================================

    final font = pw.Font.ttf(
      await rootBundle.load(
        'assets/font-times-new-roman/times-new-roman-regular-unicode.ttf',
      ),
    );

    final fontBold = pw.Font.ttf(
      await rootBundle.load(
        'assets/font-times-new-roman/times-new-roman-bold-unicode.ttf',
      ),
    );

    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);

    // ======================================================
    // SỐ DÒNG / TRANG
    //
    // Cỡ chữ 14 phù hợp khoảng 13 dòng / A4.
    // ======================================================

    const firstPageRows = 15;
    const followingPageRows = 20;

    final items = List<DaoTaoInDiemDanhNhanVienV2Model>.from(data.danhSach)
      ..sort(_compareEmployeesByDepartment);

    final pages = <List<DaoTaoInDiemDanhNhanVienV2Model>>[];

    if (items.isEmpty) {
      pages.add(<DaoTaoInDiemDanhNhanVienV2Model>[]);
    } else {
      var offset = 0;
      while (offset < items.length) {
        final capacity = pages.isEmpty ? firstPageRows : followingPageRows;
        final end = (offset + capacity < items.length)
            ? offset + capacity
            : items.length;
        pages.add(items.sublist(offset, end));
        offset = end;
      }
    }

    var start = 0;
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageItems = pages[pageIndex];
      final isLastPage = pageIndex == pages.length - 1;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,

          margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 22),

          theme: theme,

          build: (_) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,

              children: [
                if (pageIndex == 0) ...[_header(data), pw.SizedBox(height: 8)],

                _table(pageItems, startIndex: start, fontSize: 14),

                if (isLastPage) ...[pw.SizedBox(height: 12), _signature()],
              ],
            );
          },
        ),
      );

      start += pageItems.length;
    }

    return pdf.save();
  }

  static Uint8List buildWordDocx(DaoTaoInDiemDanhV2Model data) {
    final items = List<DaoTaoInDiemDanhNhanVienV2Model>.from(data.danhSach)
      ..sort(_compareEmployeesByDepartment);
    final date = data.ngayInDiemDanh;
    final document =
        StringBuffer('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
''')
          ..write(
            _docxParagraph(
              'BỆNH VIỆN ĐA KHOA HÙNG VƯƠNG',
              bold: true,
              center: true,
            ),
          )
          ..write(
            _docxParagraph(
              'KHOA/PHÒNG: ${data.kp?.trim() ?? ''}',
              bold: true,
              center: true,
              underline: true,
            ),
          )
          ..write(_docxParagraph('', after: 80))
          ..write(
            _docxParagraph('DANH SÁCH ĐIỂM DANH', bold: true, center: true),
          )
          ..write(
            _docxParagraph(
              'Ngày ${date.day} tháng ${date.month} năm ${date.year}',
              center: true,
            ),
          )
          ..write(_docxParagraph('', after: 80))
          ..write(_docxInfoParagraph('Chương trình:', data.tenLopDaoTao))
          ..write(_docxInfoParagraph('BCV:', data.baoCaoVien))
          ..write(_docxInfoParagraph('Thời gian:', data.thoiGianDetails))
          ..write(_docxInfoParagraph('Địa điểm:', data.diaDiem))
          ..write(_docxInfoParagraph('Thành phần tham dự:', data.tpThamDu))
          ..write('''
<w:tbl>
  <w:tblPr>
    <w:tblW w:w="0" w:type="auto"/>
    <w:tblLayout w:type="fixed"/>
    <w:tblBorders>
      <w:top w:val="single" w:sz="6" w:color="000000"/>
      <w:left w:val="single" w:sz="6" w:color="000000"/>
      <w:bottom w:val="single" w:sz="6" w:color="000000"/>
      <w:right w:val="single" w:sz="6" w:color="000000"/>
      <w:insideH w:val="single" w:sz="6" w:color="000000"/>
      <w:insideV w:val="single" w:sz="6" w:color="000000"/>
    </w:tblBorders>
  </w:tblPr>
  <w:tblGrid>
    <w:gridCol w:w="500"/><w:gridCol w:w="1050"/><w:gridCol w:w="2800"/>
    <w:gridCol w:w="1550"/><w:gridCol w:w="2850"/><w:gridCol w:w="1750"/>
  </w:tblGrid>
''')
          ..write(
            _docxTableRow(const [
              'STT',
              'Mã NV',
              'Họ và tên',
              'Ngày tháng\nnăm sinh',
              'Khoa / Phòng',
              'Ký tên',
            ], header: true),
          );

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      document.write(
        _docxTableRow([
          '${index + 1}',
          item.maSo,
          item.hoVaTen,
          _formatDate(item.namSinh),
          item.tenKhoaPhong ?? '',
          '',
        ]),
      );
    }

    document
      ..write('</w:tbl>')
      ..write(_docxParagraph('', after: 120))
      ..write('''
<w:tbl>
  <w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblLayout w:type="fixed"/></w:tblPr>
  <w:tblGrid><w:gridCol w:w="3500"/><w:gridCol w:w="3500"/><w:gridCol w:w="3500"/></w:tblGrid>
  <w:tr>
    ${_docxCell('Lãnh đạo bệnh viện', 3500, center: true, bold: true, borderless: true)}
    ${_docxCell('Trưởng/phó khoa', 3500, center: true, bold: true, borderless: true)}
    ${_docxCell('Người tổng hợp', 3500, center: true, bold: true, borderless: true)}
  </w:tr>
</w:tbl>
<w:sectPr>
  <w:pgSz w:w="11906" w:h="16838"/>
  <w:pgMar w:top="1020" w:right="680" w:bottom="1020" w:left="680" w:header="360" w:footer="360" w:gutter="0"/>
</w:sectPr>
</w:body>
</w:document>
''');

    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _docxContentTypes))
      ..addFile(ArchiveFile.string('_rels/.rels', _docxRootRelationships))
      ..addFile(ArchiveFile.string('word/document.xml', document.toString()))
      ..addFile(ArchiveFile.string('word/styles.xml', _docxStyles))
      ..addFile(
        ArchiveFile.string(
          'word/_rels/document.xml.rels',
          _docxDocumentRelationships,
        ),
      );

    return ZipEncoder().encodeBytes(archive);
  }

  static String _docxParagraph(
    String value, {
    bool bold = false,
    bool center = false,
    bool underline = false,
    int after = 40,
  }) {
    return '<w:p><w:pPr>'
        '<w:spacing w:after="$after"/>'
        '${center ? '<w:jc w:val="center"/>' : ''}'
        '</w:pPr>${_docxRun(value, bold: bold, underline: underline)}</w:p>';
  }

  static String _docxInfoParagraph(String label, String? value) {
    return '<w:p><w:pPr><w:spacing w:after="20"/></w:pPr>'
        '${_docxRun('$label ', bold: true)}'
        '${_docxRun(value?.trim() ?? '')}</w:p>';
  }

  static String _docxRun(
    String value, {
    bool bold = false,
    bool underline = false,
  }) {
    final parts = value.split('\n');
    final content = <String>[];
    for (var index = 0; index < parts.length; index++) {
      if (index > 0) content.add('<w:br/>');
      content.add(
        '<w:t xml:space="preserve">${_escapeHtml(parts[index])}</w:t>',
      );
    }
    return '<w:r><w:rPr><w:rFonts w:ascii="Times New Roman" '
        'w:hAnsi="Times New Roman" w:eastAsia="Times New Roman"/>'
        '<w:sz w:val="28"/><w:szCs w:val="28"/>'
        '${bold ? '<w:b/>' : ''}${underline ? '<w:u w:val="single"/>' : ''}'
        '</w:rPr>${content.join()}</w:r>';
  }

  static String _docxTableRow(List<String> values, {bool header = false}) {
    const widths = [500, 1050, 2800, 1550, 2850, 1750];
    final cells = <String>[];
    for (var index = 0; index < values.length; index++) {
      cells.add(
        _docxCell(
          values[index],
          widths[index],
          center: header || index == 0 || index == 1 || index == 3,
          bold: header,
          shaded: header,
        ),
      );
    }
    return '<w:tr><w:trPr><w:cantSplit/><w:trHeight w:val="500" '
        'w:hRule="atLeast"/>${header ? '<w:tblHeader/>' : ''}</w:trPr>'
        '${cells.join()}</w:tr>';
  }

  static String _docxCell(
    String value,
    int width, {
    bool center = false,
    bool bold = false,
    bool shaded = false,
    bool borderless = false,
  }) {
    return '<w:tc><w:tcPr><w:tcW w:w="$width" w:type="dxa"/>'
        '<w:vAlign w:val="center"/>'
        '${shaded ? '<w:shd w:val="clear" w:fill="EEEEEE"/>' : ''}'
        '${borderless ? '<w:tcBorders><w:top w:val="nil"/><w:left w:val="nil"/><w:bottom w:val="nil"/><w:right w:val="nil"/></w:tcBorders>' : ''}'
        '</w:tcPr><w:p><w:pPr><w:spacing w:after="0"/>'
        '${center ? '<w:jc w:val="center"/>' : ''}</w:pPr>'
        '${_docxRun(value, bold: bold)}</w:p></w:tc>';
  }

  static const _docxContentTypes =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';

  static const _docxRootRelationships =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static const _docxDocumentRelationships =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

  static const _docxStyles =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault><w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:eastAsia="Times New Roman"/>
      <w:sz w:val="28"/><w:szCs w:val="28"/>
    </w:rPr></w:rPrDefault>
    <w:pPrDefault><w:pPr><w:spacing w:after="40"/></w:pPr></w:pPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/><w:qFormat/>
  </w:style>
</w:styles>''';

  static Uint8List buildWord(DaoTaoInDiemDanhV2Model data) {
    final items = List<DaoTaoInDiemDanhNhanVienV2Model>.from(data.danhSach)
      ..sort(_compareEmployeesByDepartment);
    final date = data.ngayInDiemDanh;
    final buffer = StringBuffer()
      ..write('''
<!DOCTYPE html>
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:w="urn:schemas-microsoft-com:office:word">
<head>
  <meta charset="utf-8">
  <title>Danh sách điểm danh</title>
  <style>
    @page { size: A4; margin: 18mm 12mm; }
    body { font-family: "Times New Roman", serif; font-size: 14pt; color: #000; }
    p { margin: 0 0 3pt 0; }
    .center { text-align: center; }
    .bold { font-weight: 700; }
    .department { text-decoration: underline; }
    .space { height: 7pt; }
    table { width: 100%; border-collapse: collapse; table-layout: fixed; margin-top: 8pt; }
    thead { display: table-header-group; }
    tr { page-break-inside: avoid; }
    th, td { border: 0.75pt solid #000; padding: 3pt; height: 25pt; vertical-align: middle; }
    th { text-align: center; font-weight: 700; background: #eee; }
    .c-stt { width: 5%; text-align: center; }
    .c-code { width: 10%; text-align: center; }
    .c-name { width: 27%; }
    .c-birth { width: 15%; text-align: center; }
    .c-department { width: 27%; }
    .c-sign { width: 16%; }
    .signatures { width: 100%; border: 0; margin-top: 14pt; }
    .signatures td { width: 33.33%; border: 0; text-align: center; vertical-align: top; font-weight: 700; }
  </style>
</head>
<body>
''')
      ..write(
        '<p class="center bold">${_escapeHtml('BỆNH VIỆN ĐA KHOA HÙNG VƯƠNG')}</p>',
      )
      ..write(
        '<p class="center bold department">${_escapeHtml('KHOA/PHÒNG: ${data.kp?.trim() ?? ''}')}</p>',
      )
      ..write('<div class="space"></div>')
      ..write(
        '<p class="center bold">${_escapeHtml('DANH SÁCH ĐIỂM DANH')}</p>',
      )
      ..write(
        '<p class="center">${_escapeHtml('Ngày ${date.day} tháng ${date.month} năm ${date.year}')}</p>',
      )
      ..write('<div class="space"></div>')
      ..write(_wordInfoLine('Chương trình:', data.tenLopDaoTao))
      ..write(_wordInfoLine('BCV:', data.baoCaoVien))
      ..write(_wordInfoLine('Thời gian:', data.thoiGianDetails))
      ..write(_wordInfoLine('Địa điểm:', data.diaDiem))
      ..write(_wordInfoLine('Thành phần tham dự:', data.tpThamDu))
      ..write('''
<table>
  <thead>
    <tr>
      <th class="c-stt">STT</th>
      <th class="c-code">Mã NV</th>
      <th class="c-name">Họ và tên</th>
      <th class="c-birth">Ngày tháng<br>năm sinh</th>
      <th class="c-department">Khoa / Phòng</th>
      <th class="c-sign">Ký tên</th>
    </tr>
  </thead>
  <tbody>
''');

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      buffer.write('''
    <tr>
      <td class="c-stt">${index + 1}</td>
      <td class="c-code">${_escapeHtml(item.maSo)}</td>
      <td class="c-name">${_escapeHtml(item.hoVaTen)}</td>
      <td class="c-birth">${_escapeHtml(_formatDate(item.namSinh))}</td>
      <td class="c-department">${_escapeHtml(item.tenKhoaPhong ?? '')}</td>
      <td class="c-sign"></td>
    </tr>
''');
    }

    buffer.write('''
  </tbody>
</table>
<table class="signatures">
  <tr>
    <td>Lãnh đạo bệnh viện</td>
    <td>Trưởng/phó khoa</td>
    <td>Người tổng hợp</td>
  </tr>
</table>
</body>
</html>
''');

    return Uint8List.fromList(utf8.encode('\uFEFF${buffer.toString()}'));
  }

  static String _wordInfoLine(String label, String? value) {
    return '<p><span class="bold">${_escapeHtml(label)}</span> '
        '${_escapeHtml(value?.trim() ?? '')}</p>';
  }

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static int _compareEmployeesByDepartment(
    DaoTaoInDiemDanhNhanVienV2Model first,
    DaoTaoInDiemDanhNhanVienV2Model second,
  ) {
    final firstDepartment = first.tenKhoaPhong?.trim() ?? '';
    final secondDepartment = second.tenKhoaPhong?.trim() ?? '';

    if (firstDepartment.isEmpty != secondDepartment.isEmpty) {
      return firstDepartment.isEmpty ? 1 : -1;
    }

    final departmentComparison = _vietnameseSortKey(
      firstDepartment,
    ).compareTo(_vietnameseSortKey(secondDepartment));
    if (departmentComparison != 0) {
      return departmentComparison;
    }

    if (first.stt > 0 && second.stt > 0 && first.stt != second.stt) {
      return first.stt.compareTo(second.stt);
    }

    return _vietnameseSortKey(
      first.hoVaTen,
    ).compareTo(_vietnameseSortKey(second.hoVaTen));
  }

  static String _vietnameseSortKey(String value) {
    var result = value.trim().toLowerCase();
    const characterGroups = <String, String>{
      'a': 'àáạảãâầấậẩẫăằắặẳẵ',
      'e': 'èéẹẻẽêềếệểễ',
      'i': 'ìíịỉĩ',
      'o': 'òóọỏõôồốộổỗơờớợởỡ',
      'u': 'ùúụủũưừứựửữ',
      'y': 'ỳýỵỷỹ',
      'd': 'đ',
    };

    for (final entry in characterGroups.entries) {
      for (final character in entry.value.split('')) {
        result = result.replaceAll(character, entry.key);
      }
    }

    return result;
  }

  // ========================================================
  // HEADER
  // ========================================================

  static pw.Widget _header(DaoTaoInDiemDanhV2Model data) {
    final date = data.ngayInDiemDanh;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,

      children: [
        pw.Center(
          child: pw.Text(
            'BỆNH VIỆN ĐA KHOA HÙNG VƯƠNG',

            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),

        pw.SizedBox(height: 2),

        pw.Center(
          child: pw.Text(
            'KHOA/PHÒNG: '
            '${data.kp?.trim() ?? ''}',

            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,

              decoration: pw.TextDecoration.underline,
            ),
          ),
        ),

        pw.SizedBox(height: 7),

        pw.Center(
          child: pw.Text(
            'DANH SÁCH ĐIỂM DANH',

            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),

        pw.SizedBox(height: 2),

        pw.Center(
          child: pw.Text(
            'Ngày ${date.day} '
            'tháng ${date.month} '
            'năm ${date.year}',

            style: const pw.TextStyle(fontSize: 14),
          ),
        ),

        pw.SizedBox(height: 8),

        _infoLine('Chương trình:', data.tenLopDaoTao),

        _infoLine('BCV:', data.baoCaoVien),

        _infoLine('Thời gian:', data.thoiGianDetails),

        _infoLine('Địa điểm:', data.diaDiem),

        _infoLine('Thành phần tham dự:', data.tpThamDu),
      ],
    );
  }

  static pw.Widget _infoLine(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),

      child: pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 14),

          children: [
            pw.TextSpan(
              text: '$label ',

              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),

            pw.TextSpan(text: value?.trim() ?? ''),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // TABLE
  // ========================================================

  static pw.Widget _table(
    List<DaoTaoInDiemDanhNhanVienV2Model> items, {
    required int startIndex,
    required double fontSize,
  }) {
    final rows = <pw.TableRow>[];

    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),

        children: [
          _headerCell('STT'),

          _headerCell('Mã NV'),

          _headerCell('Họ và tên'),

          _headerCell('Ngày tháng\nnăm sinh'),

          _headerCell('Khoa / Phòng'),

          _headerCell('Ký tên'),
        ],
      ),
    );

    for (var i = 0; i < items.length; i++) {
      final item = items[i];

      rows.add(
        pw.TableRow(
          children: [
            _cell(
              '${startIndex + i + 1}',

              align: pw.TextAlign.center,

              fontSize: fontSize,
            ),

            _cell(item.maSo, align: pw.TextAlign.center, fontSize: fontSize),

            _cell(item.hoVaTen, fontSize: fontSize),

            _cell(
              _formatDate(item.namSinh),

              align: pw.TextAlign.center,

              fontSize: fontSize,
            ),

            _cell(
              item.tenKhoaPhong ?? '',

              align: pw.TextAlign.left,

              fontSize: fontSize,
            ),

            _cell('', fontSize: fontSize),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(width: 0.55),

      columnWidths: {
        // STT
        0: pw.FlexColumnWidth(0.45),

        // Mã NV
        1: pw.FlexColumnWidth(0.8),

        // Họ và tên
        2: pw.FlexColumnWidth(2.2),

        // Ngày sinh
        3: pw.FlexColumnWidth(1.25),

        // Khoa / Phòng
        4: pw.FlexColumnWidth(2.0),

        // Ký tên
        5: pw.FlexColumnWidth(1.6),
      },

      children: rows,
    );
  }

  static pw.Widget _headerCell(String value) {
    return pw.Container(
      height: 42,

      alignment: pw.Alignment.center,

      padding: const pw.EdgeInsets.all(2),

      child: pw.Text(
        value,

        textAlign: pw.TextAlign.center,

        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _cell(
    String value, {
    pw.TextAlign align = pw.TextAlign.left,

    double fontSize = 14,
  }) {
    return pw.Container(
      height: 34,

      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : pw.Alignment.centerLeft,

      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),

      child: pw.Text(
        value,

        textAlign: align,

        maxLines: 2,

        style: pw.TextStyle(fontSize: fontSize),
      ),
    );
  }

  // ========================================================
  // CHỮ KÝ
  // ========================================================

  static pw.Widget _signature() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,

      children: [
        _signatureCell('Lãnh đạo bệnh viện'),

        _signatureCell('Trưởng/phó khoa'),

        _signatureCell('Người tổng hợp'),
      ],
    );
  }

  static pw.Widget _signatureCell(String text) {
    return pw.Expanded(
      child: pw.Container(
        height: 55,

        alignment: pw.Alignment.topCenter,

        child: pw.Text(
          text,

          textAlign: pw.TextAlign.center,

          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  // ========================================================
  // FORMAT
  // ========================================================

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}
