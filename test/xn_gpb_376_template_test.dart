import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp_bvhv/models/xn_gpb_376_template.dart';
import 'package:mobileapp_bvhv/widgets/xn_gpb_376_report.dart';

Map<String, dynamic> reportData() => {
  'tenDichVu': 'Thin Prep',
  'benhNhan': [
    {
      'hoten': 'BỆNH NHÂN KIỂM THỬ',
      'tuoi': '30 tuổi',
      'tenphai': 'Nữ',
      'diachi': 'Địa chỉ minh họa',
      'sothebhyt': '—',
      'dienthoai': '—',
    },
  ],
  'chiDinh': [
    {
      'tennv': 'Bác sĩ chỉ định kiểm thử',
      'tenkk': 'Khoa khám bệnh',
      'ngay': '2026-09-17T08:00:00',
    },
  ],
  'ketQua': [
    {
      'ketluan': 'Nội dung kết luận minh họa để kiểm tra bố cục.',
      'barcode': 'TEST-376',
      'ngayth': '2026-09-17T09:00:00',
    },
  ],
  'chanDoan': [
    {'benhchinh': 'Nội dung chẩn đoán minh họa'},
  ],
  'truongKetQuaKhac': <Map<String, dynamic>>[
    for (final field in xnGpb376Fields)
      {
        'name': field.name,
        'value': ['dgtbdat', 'tthnoibieumoactinh'].contains(field.name)
            ? 'True'
            : 'False',
        'giaTriBoolean': ['dgtbdat', 'tthnoibieumoactinh'].contains(field.name),
      },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('32 nhãn, nhóm và kiểu chữ khớp dữ liệu trích từ PRT', () {
    final manifest =
        jsonDecode(
              File(
                'docs/xn-tra-sau-api/gpb_376_template.json',
              ).readAsStringSync(),
            )
            as Map;
    final fields = manifest['fields'] as List;
    expect(manifest['templateId'], '376');
    expect(fields.length, 32);
    expect(xnGpb376Fields.length, 32);
    expect(xnGpb376Labels.length, 32);
    for (var i = 0; i < fields.length; i++) {
      final actual = xnGpb376Fields[i];
      expect(actual.name, fields[i]['name']);
      expect(actual.label, fields[i]['label']);
      expect(actual.group, fields[i]['group']);
      expect(actual.bold, fields[i]['bold']);
      expect(actual.italic, fields[i]['italic']);
    }
    expect(xnGpb376Labels['tvaginalis'], 'T. Vaginalis');
    expect(xnGpb376Labels['cbvaginalis'], 'G. Vaginalis');
    expect(
      xnGpb376Labels['btgmotuyen1'],
      'TB biểu mô tuyến không điển hình (AGUS)',
    );
  });

  testWidgets('Đủ 32 ô, không suy ra checkbox cha từ con', (tester) async {
    final data = reportData();
    final fields = data['truongKetQuaKhac'] as List;
    final child = fields.firstWhere((f) => f['name'] == 'dsvay') as Map;
    child['giaTriBoolean'] = true;
    child['value'] = 'True';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: XnGpb376Report(
              data: data,
              signature: const Text('Chữ ký kiểm thử'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(XnGpb376Check), findsNWidgets(32));
    expect(find.text('X'), findsNWidgets(3));
    expect(find.text('—'), findsNothing);
  });

  testWidgets('Ô thiếu dữ liệu và dữ liệu trùng không bị coi là không tích', (
    tester,
  ) async {
    final data = reportData();
    final fields = data['truongKetQuaKhac'] as List;
    fields.removeWhere((f) => f['name'] == 'dgtbdat');
    fields.add({'name': 'cboxteo', 'value': 'True', 'giaTriBoolean': true});
    fields.add({
      'name': 'truong_moi',
      'value': 'Giá trị bổ sung',
      'giaTriBoolean': null,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: XnGpb376Report(
              data: data,
              signature: const Text('Chữ ký kiểm thử'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNWidgets(2));
    expect(
      find.text('Có nhiều giá trị cho mục này; cần đối chiếu HIS.'),
      findsOneWidget,
    );
    expect(find.text('Giá trị bổ sung'), findsOneWidget);
  });

  for (final width in [320.0, 1100.0]) {
    testWidgets(
      'Phiếu 376 tại chiều rộng $width không tràn và giữ hai nhóm biểu mô',
      (tester) async {
        const capture = bool.fromEnvironment('XN_CAPTURE_PREVIEW');
        tester.view.physicalSize = Size(width, capture ? 7000 : 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (capture) {
          await (FontLoader('HisReport')..addFont(
                rootBundle.load(
                  'assets/font-times-new-roman/times-new-roman-regular-unicode.ttf',
                ),
              ))
              .load();
        }
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RepaintBoundary(
                  key: key,
                  child: XnGpb376Report(
                    data: reportData(),
                    signature: const Text(
                      'Bác sĩ kiểm thử\nNgày ký: 17/09/2026 09:30',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final left = tester.getTopLeft(find.text('BẤT THƯỜNG BIỂU MÔ VẢY'));
        final right = tester.getTopLeft(find.text('BẤT THƯỜNG BIỂU MÔ TUYẾN'));
        if (width >= 740) {
          expect(right.dx, greaterThan(left.dx));
          expect(right.dy, closeTo(left.dy, 1));
        } else {
          expect(right.dy, greaterThan(left.dy));
        }
        if (capture) {
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              'build/gpb_376_preview_${width.toInt()}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
  }
}
