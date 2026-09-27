import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/xn_gpb_376_template.dart';
import '../models/xn_trasau_ket_qua.dart';

/// Native Flutter rendition of the reviewed .prt, not a general PRT engine.
/// The source's SQL and expressions are never evaluated by the application.
class XnGpb376Report extends StatelessWidget {
  const XnGpb376Report({
    super.key,
    required this.data,
    required this.signature,
    this.images = const [],
  });
  final XnRow data;
  final Widget signature;
  final List<Widget> images;

  @override
  Widget build(BuildContext context) {
    final fields = xnRows(xnValue(data, 'truongKetQuaKhac'));
    final knownNames = xnGpb376Labels.keys.toSet();
    final extra = fields
        .where(
          (f) => !knownNames.contains(xnText(xnValue(f, 'name')).toLowerCase()),
        )
        .toList();
    final results = xnRows(xnValue(data, 'ketQua'));
    final patients = xnRows(xnValue(data, 'benhNhan'));
    final orders = xnRows(xnValue(data, 'chiDinh'));
    final diagnoses = xnRows(xnValue(data, 'chanDoan'));
    final incomplete = xnGpb376Fields.any((definition) {
      final matches = _matching(fields, definition.name);
      return matches.length != 1 ||
          xnValue(matches.single, 'giaTriBoolean') is! bool;
    });
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            fontFamily: 'HisReport',
            fontSize: 17,
            color: Colors.black,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(
                patients.isEmpty ? const {} : patients.first,
                results.isEmpty ? const {} : results.first,
              ),
              const SizedBox(height: 24),
              const Text(
                'PHIẾU KẾT QUẢ GIẢI PHẪU BỆNH',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              for (final patient in patients) ...[
                _line('Bệnh nhân', _text(patient, 'hoten'), bold: true),
                _columns([
                  _line('Tuổi', _text(patient, 'tuoi')),
                  _line('Giới tính', _text(patient, 'tenphai')),
                ]),
                _line('Địa chỉ', _text(patient, 'diachi')),
                _columns([
                  _line('Mã thẻ BHYT', _text(patient, 'sothebhyt')),
                  _line('Điện thoại', _text(patient, 'dienthoai')),
                ]),
              ],
              for (final order in orders) ...[
                _columns([
                  _line(
                    'Bác sĩ chỉ định',
                    _text(order, 'bschidinh', fallback: 'tennv'),
                  ),
                  _line('Nơi chỉ định', _text(order, 'tenkk')),
                ]),
                _line('Ngày chỉ định', _date(xnValue(order, 'ngay'))),
              ],
              for (final result in results)
                _line('Ngày thực hiện', _date(xnValue(result, 'ngayth'))),
              for (final diagnosis in diagnoses)
                _line('Chẩn đoán', _text(diagnosis, 'benhchinh')),
              _line('Chỉ định', _text(data, 'tenDichVu')),
              const SizedBox(height: 12),
              _columns([
                const Text(
                  'Đánh giá tiêu bản:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._group(fields, 'assessment'),
              ], maxColumns: 3),
              const SizedBox(height: 14),
              const Text(
                'KẾT QUẢ TẾ BÀO HỌC CỔ TỬ CUNG THEO HỆ THỐNG BETHESDA 2014',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (incomplete)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Ô có dấu “—” chưa có dữ liệu xác định.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ..._group(fields, 'negative'),
              _parentAndChildren(fields, 'non_neoplastic'),
              _parentAndChildren(fields, 'infection'),
              ..._group(fields, 'endometrial'),
              ..._group(fields, 'epithelial'),
              _columns([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _group(fields, 'squamous'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _group(fields, 'glandular'),
                ),
              ], breakpoint: 740),
              ..._group(fields, 'other'),
              if (extra.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Trường bổ sung chưa có trong mẫu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final field in extra) _unknown(field),
              ],
              const Divider(height: 28),
              for (final result in results) ...[
                _line('Kết luận', _text(result, 'ketluan'), bold: true),
                if (xnText(xnValue(result, 'denghi')).isNotEmpty)
                  _line('Đề nghị', _text(result, 'denghi')),
                // Preserve additional content if the API supplies it for this print.
                if (xnText(xnValue(result, 'mota')).isNotEmpty)
                  _line('Mô tả', _text(result, 'mota')),
                if (xnText(xnValue(result, 'docketqua')).isNotEmpty)
                  _line('Nội dung bổ sung', _text(result, 'docketqua')),
              ],
              ...images,
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth < 420
                      ? constraints.maxWidth
                      : 420.0;
                  return Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final result in results)
                            Text(
                              _longDate(xnValue(result, 'ngaylam')),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 5),
                          const Text(
                            'BÁC SĨ CHUYÊN KHOA',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          signature,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(XnRow patient, XnRow result) => LayoutBuilder(
    builder: (context, constraints) {
      final organization = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/LOGO.png', width: 64, height: 64),
          const SizedBox(width: 12),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BỆNH VIỆN ĐA KHOA HÙNG VƯƠNG',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text('Khu Phượng Hùng, xã Chí Đám, tỉnh Phú Thọ'),
                Text('Hotline: 18009415'),
              ],
            ),
          ),
        ],
      );
      final code = _text(patient, 'makcb');
      final identifiers = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          XnCode39(value: code),
          const SizedBox(height: 5),
          Text('Mã BN: ${_text(patient, 'mabn')}'),
          Text('Mã KCB: $code'),
          Text('Mã BP: ${_text(result, 'barcode')}'),
        ],
      );
      if (constraints.maxWidth < 680) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [organization, const SizedBox(height: 16), identifiers],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: organization),
          identifiers,
        ],
      );
    },
  );

  List<XnRow> _matching(List<XnRow> fields, String name) => fields
      .where(
        (f) => xnText(xnValue(f, 'name')).toLowerCase() == name.toLowerCase(),
      )
      .toList();

  Widget _check(List<XnRow> fields, XnGpb376Field definition) => XnGpb376Check(
    definition: definition,
    values: _matching(fields, definition.name),
  );

  List<Widget> _group(List<XnRow> fields, String group) => [
    for (final definition in xnGpb376Fields.where((f) => f.group == group))
      _check(fields, definition),
  ];

  Widget _parentAndChildren(List<XnRow> fields, String group) {
    final items = _group(fields, group);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        items.first,
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: _columns(items.skip(1).toList(), maxColumns: 3),
        ),
      ],
    );
  }

  Widget _columns(
    List<Widget> children, {
    int maxColumns = 2,
    double breakpoint = 640,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth >= breakpoint ? maxColumns : 1;
      const gap = 18.0;
      final width = (constraints.maxWidth - (count - 1) * gap) / count;
      return Wrap(
        spacing: gap,
        runSpacing: 4,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );

  String _text(XnRow row, String name, {String? fallback}) {
    final value =
        xnValue(row, name) ??
        (fallback == null ? null : xnValue(row, fallback));
    final text = xnDisplayText(value);
    return text.isEmpty ? '—' : text;
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(xnText(value));
    return date == null
        ? (xnText(value).isEmpty ? '—' : xnText(value))
        : DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _longDate(dynamic value) {
    final date = DateTime.tryParse(xnText(value));
    if (date == null) return '';
    return DateFormat("HH:mm, 'Ngày' dd 'tháng' MM 'năm' yyyy").format(date);
  }

  Widget _line(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: SelectableText(
      '$label: $value',
      style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
    ),
  );

  Widget _unknown(XnRow field) {
    final value = xnDisplayText(xnValue(field, 'value'));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(xnText(xnValue(field, 'name'))),
          Text(value.isEmpty ? 'Chưa có dữ liệu' : value),
        ],
      ),
    );
  }
}

class XnGpb376Check extends StatelessWidget {
  const XnGpb376Check({
    super.key,
    required this.definition,
    required this.values,
  });
  final XnGpb376Field definition;
  final List<XnRow> values;

  @override
  Widget build(BuildContext context) {
    final typed = values.length == 1
        ? xnValue(values.single, 'giaTriBoolean')
        : null;
    final bool? checked = typed is bool ? typed : null;
    final raw = values.length == 1
        ? xnText(xnValue(values.single, 'value'))
        : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              checked: checked,
              label: checked == null
                  ? 'Chưa có dữ liệu xác định'
                  : checked
                  ? 'Được tích'
                  : 'Không được tích',
              child: ExcludeSemantics(
                child: Container(
                  width: 21,
                  height: 21,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 1.5,
                      color: checked == null ? Colors.grey : Colors.black,
                    ),
                  ),
                  child: Text(
                    checked == null
                        ? '—'
                        : checked
                        ? 'X'
                        : '',
                    style: TextStyle(
                      fontFamily: 'HisReport',
                      fontSize: 17,
                      height: 1,
                      fontWeight: FontWeight.bold,
                      color: checked == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  definition.label,
                  style: TextStyle(
                    fontWeight: definition.bold
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontStyle: definition.italic
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                if (values.length > 1)
                  const Text(
                    'Có nhiều giá trị cho mục này; cần đối chiếu HIS.',
                    style: TextStyle(fontSize: 13, color: Colors.orange),
                  ),
                if (checked == null && raw.isNotEmpty)
                  Text('Giá trị HIS: $raw'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Code 39 is supported by common clinical barcode scanners. The displayed
/// value is exactly makcb; start/stop markers are encoded but not shown.
class XnCode39 extends StatelessWidget {
  const XnCode39({super.key, required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final valid = RegExp(r'^[0-9A-Z \-\.\$/\+%]+$').hasMatch(value);
    if (!valid || value == '—') return const SizedBox(height: 52);
    return Semantics(
      label: 'Mã vạch Mã KCB: $value',
      image: true,
      child: CustomPaint(
        size: const Size(150, 52),
        painter: _Code39Painter(value),
      ),
    );
  }
}

class _Code39Painter extends CustomPainter {
  const _Code39Painter(this.value);
  final String value;

  static const _patterns = <String, String>{
    '0': 'nnnwwnwnn',
    '1': 'wnnwnnnnw',
    '2': 'nnwwnnnnw',
    '3': 'wnwwnnnnn',
    '4': 'nnnwwnnnw',
    '5': 'wnnwwnnnn',
    '6': 'nnwwwnnnn',
    '7': 'nnnwnnwnw',
    '8': 'wnnwnnwnn',
    '9': 'nnwwnnwnn',
    '-': 'nnnwnwnnw',
    '.': 'wnnwnwnnn',
    ' ': 'nwwnnwnnn',
    r'$': 'nwnwnwnnn',
    '/': 'nwnnnwnwn',
    '+': 'nwnnnwnnn',
    '%': 'nnnwnwnwn',
    '*': 'nwnnwnwnn',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final all = '*$value*';
    var units = 0;
    for (final char in all.split('')) {
      for (final width in _patterns[char]!.split('')) {
        units += width == 'w' ? 3 : 1;
      }
      units += 1;
    }
    final unit = size.width / units;
    final paint = Paint()..color = Colors.black;
    var x = 0.0;
    for (final char in all.split('')) {
      final pattern = _patterns[char]!;
      for (var index = 0; index < pattern.length; index++) {
        final width = unit * (pattern[index] == 'w' ? 3 : 1);
        if (index.isEven) {
          canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), paint);
        }
        x += width;
      }
      x += unit;
    }
  }

  @override
  bool shouldRepaint(covariant _Code39Painter oldDelegate) =>
      oldDelegate.value != value;
}
