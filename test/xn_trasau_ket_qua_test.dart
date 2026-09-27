import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp_bvhv/models/xn_trasau_ket_qua.dart';
import 'package:mobileapp_bvhv/models/xn_trasau_model.dart';
import 'package:mobileapp_bvhv/screens/xn_trasau_ket_qua_screen.dart';
import 'package:mobileapp_bvhv/services/xn_trasau_ket_qua_service.dart';

const _detail = 100;
XnRow _configuration({
  List<String> templates = const ['376'],
  String kind = 'GPB',
  List<int> forms = const [12],
}) => {
  'id': 1,
  'mathanhtoanct': _detail,
  'suDungKetQuaKhacV2': true,
  'danhSachMau': [
    for (final id in templates) {'idMauIn': id, 'loaiKetQua': kind},
  ],
  'danhSachForm': [
    for (final id in forms) {'idForm': id},
  ],
};
XnRow _result(String template, {String kind = 'GPB', int? form = 12}) => {
  'id': 1,
  'mathanhtoanct': _detail,
  'idMauIn': template,
  'loaiKetQua': kind,
  'idMauKqKhac': form,
  'ketQua': [
    {'ketluan': 'Kết luận mẫu $template', 'mota': 'Mô tả mô bệnh học'},
  ],
  'truongKetQuaKhac': [
    {'name': 'tthnoibieumoactinh', 'value': 'True', 'giaTriBoolean': true},
    {'name': 'chua_co_gia_tri', 'value': null, 'giaTriBoolean': null},
  ],
};

class _Gateway implements XnResultGateway {
  XnRow config = _configuration();
  int calls = 0;
  Future<XnRow> Function(String template, int? form)? onResult;
  Future<XnRow> Function()? onSignature;

  @override
  Future<XnRow> configuration(int id, CancelToken token) async => config;
  @override
  Future<XnRow> result(
    int id,
    XnResultKind kind,
    String template,
    int? form,
    CancelToken token,
  ) async {
    calls++;
    return onResult != null
        ? await onResult!(template, form)
        : _result(template, kind: kind.code, form: form);
  }

  @override
  Future<XnRow> signature(int id, CancelToken token) async =>
      onSignature != null
      ? await onSignature!()
      : {'id': 1, 'mathanhtoanct': _detail, 'daKyHIS': false};
}

Future<void> _open(WidgetTester tester, _Gateway gateway) async {
  await tester.pumpWidget(
    MaterialApp(
      home: XNTraSauKetQuaScreen(
        item: XNTraSau(
          id: 1,
          hoten: 'Bệnh nhân kiểm thử',
          mathanhtoanct: _detail,
        ),
        gateway: gateway,
        pdfPreview: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Service giữ nguyên lựa chọn GPB và lỗi nghiệp vụ từ API', () async {
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'data': _result('376')},
            ),
          );
        },
      ),
    );
    final service = XnResultService(dio: dio);
    await service.result(1, XnResultKind.pathology, '376', 12, CancelToken());
    expect(requests.single.path, endsWith('/XNTraSau/1/ket-qua/gpb'));
    expect(requests.single.queryParameters, {
      'idMauIn': '376',
      'idMauKqKhac': 12,
    });
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 409,
                data: {
                  'success': false,
                  'code': 'KET_QUA_CHUA_DUYET',
                  'message': 'Kết quả chưa duyệt',
                },
              ),
            ),
          );
        },
      ),
    );
    await expectLater(
      service.result(1, XnResultKind.antibiogram, '351', null, CancelToken()),
      throwsA(
        isA<XnResultException>()
            .having((e) => e.code, 'code', 'KET_QUA_CHUA_DUYET')
            .having((e) => e.message, 'message', 'Kết quả chưa duyệt'),
      ),
    );
  });

  testWidgets(
    'Xét nghiệm giữ kết quả gốc và bỏ dòng nhóm khỏi dữ liệu xét nghiệm',
    (tester) async {
      final gateway = _Gateway()
        ..config = _configuration(
          templates: ['1'],
          kind: 'XET_NGHIEM',
          forms: [],
        )
        ..onResult = (t, f) async => {
          ..._result(t, kind: 'XET_NGHIEM', form: null),
          'dongKetQua': [
            {
              'grouplevel': 1,
              'grheadertext': 'Sinh hóa',
              'ketluan': 'Không phải dữ liệu',
            },
            {
              'grouplevel': 0,
              'tenchiso_goc': 'Chỉ số kiểm thử',
              'ketqua_goc': '<5',
              'ketluan': 'KHÔNG DÙNG GIÁ TRỊ ĐỊNH DẠNG',
              'giatribinhthuong': '4–6',
              'tendonvitinh': null,
            },
          ],
        };
      await _open(tester, gateway);
      expect(find.text('Sinh hóa'), findsOneWidget);
      expect(find.text('Chỉ số kiểm thử'), findsOneWidget);
      expect(find.textContaining('<5'), findsOneWidget);
      expect(find.textContaining('KHÔNG DÙNG GIÁ TRỊ'), findsNothing);
      expect(find.text('Không phải dữ liệu'), findsNothing);
    },
  );

  testWidgets('KSD cùng tên vi khuẩn vẫn tách kháng sinh theo mã', (
    tester,
  ) async {
    final gateway = _Gateway()
      ..config = _configuration(
        templates: ['351'],
        kind: 'KHANG_SINH_DO',
        forms: [],
      )
      ..onResult = (t, f) async => {
        ..._result(t, kind: 'KHANG_SINH_DO', form: null),
        'viKhuanVaChiDinh': [
          {'vikhuanid': 1, 'mavikhuan': 10, 'tenvikhuan': 'Vi khuẩn kiểm thử'},
          {'vikhuanid': 1, 'mavikhuan': 20, 'tenvikhuan': 'Vi khuẩn kiểm thử'},
        ],
        'khangSinh': [
          {
            'vikhuanid': 1,
            'mavikhuan': 10,
            'tenkhangsinh': 'Kháng sinh A',
            'MIC': '<1',
            'SIR': 'S',
          },
          {
            'vikhuanid': 1,
            'mavikhuan': 20,
            'tenkhangsinh': 'Kháng sinh B',
            'MIC': '>8',
            'SIR': 'R',
          },
        ],
      };
    await _open(tester, gateway);
    expect(find.text('Vi khuẩn kiểm thử'), findsNWidgets(2));
    expect(find.text('Kháng sinh A'), findsOneWidget);
    expect(find.text('Kháng sinh B'), findsOneWidget);
  });

  test('Bố cục GPB chọn theo mẫu và form, không dùng checkbox cho mọi GPB', () {
    expect(xnGpbLayout('376', 12).fieldLabels, isNotEmpty);
    expect(xnGpbLayout('376', 14).fieldLabels, isEmpty);
    expect(xnGpbLayout('381', null).resultLabels['docketqua'], 'Đại thể');
    expect(xnGpbLayout('381', null).resultLabels['mota'], 'Vi thể');
    expect(xnGpbLayout('383', null).title, 'Kết quả tế bào học');
    expect(xnGpbLayout('999', null).title, 'Kết quả giải phẫu bệnh');
  });

  for (final template in ['381', '383']) {
    testWidgets('Mẫu $template hiển thị nội dung văn bản khi không có form', (
      tester,
    ) async {
      final gateway = _Gateway()
        ..config = _configuration(templates: [template], forms: [])
        ..onResult = (t, f) async => {
          ..._result(t, form: null),
          'truongKetQuaKhac': [],
          'ketQua': [
            {
              'docketqua': 'Mô tả bệnh phẩm kiểm thử',
              'mota': 'Nội dung mô tả kiểm thử',
              'ketluan': 'Kết luận kiểm thử',
            },
          ],
        };
      await _open(tester, gateway);
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
      expect(find.byType(XnGpbField), findsNothing);
      expect(find.text('Nội dung mô tả kiểm thử'), findsOneWidget);
      expect(find.text('Kết luận kiểm thử'), findsOneWidget);
      expect(
        find.text(template == '381' ? 'Đại thể' : 'Mô tả tế bào học'),
        findsOneWidget,
      );
    });
  }

  testWidgets('Chữ ký khác chỉ định không được gắn vào phiếu', (tester) async {
    final gateway = _Gateway()
      ..onSignature = () async => {
        'id': 1,
        'mathanhtoanct': 999,
        'daKyHIS': true,
        'tenNguoiKy': 'Không được hiển thị',
      };
    await _open(tester, gateway);
    expect(find.textContaining('Kết luận mẫu 376'), findsOneWidget);
    expect(find.text('Không được hiển thị'), findsNothing);
    expect(
      find.textContaining('Dữ liệu trả về không khớp chỉ định'),
      findsOneWidget,
    );
  });

  test('Giữ giá trị chưa xác định, dấu so sánh và định danh vi khuẩn', () {
    expect(xnBool(null), isNull);
    expect(xnBool(''), isNull);
    expect(xnBool('khác'), isNull);
    expect(xnBool('False'), isFalse);
    expect(xnDisplayText('<fnTimes New Roman><fs12>Chỉ số <5'), 'Chỉ số <5');
    expect(
      xnDisplayText('Line 1\r\nLine 2\rLine 3\u0007'),
      'Line 1\nLine 2\nLine 3',
    );
    final formatted = xnFormattedText(
      '<fc255,0,0><fnTimes New Roman><fs12><b><i><u>formatted value',
      fallbackText: '12.11',
    );
    expect(formatted.text, '12.11');
    expect(formatted.bold, isTrue);
    expect(formatted.italic, isTrue);
    expect(formatted.underline, isTrue);
    expect([formatted.red, formatted.green, formatted.blue], [255, 0, 0]);
    expect(
      xnDisplayText('<fc0,0,255><b><5'),
      '<5',
    );
    expect(
      xnDisplayText('<fnTimes New Roman><fs12>Chỉ số<i> * </i>'),
      'Chỉ số *',
    );
    expect(
      xnSameOrganism(
        {'vikhuanid': 1, 'mavikhuan': 2},
        {'vikhuanid': 1, 'mavikhuan': 3},
      ),
      isFalse,
    );
    expect(xnValue({'MIC': '<0.5'}, 'mic'), '<0.5');
  });

  testWidgets('GPB có mô tả và checkbox, null không biến thành false', (
    tester,
  ) async {
    await _open(tester, _Gateway());
    expect(find.textContaining('Mô tả mô bệnh học'), findsOneWidget);
    expect(
      find.text('ÂM TÍNH VỚI TỔN THƯƠNG NỘI BIỂU MÔ HOẶC ÁC TÍNH'),
      findsOneWidget,
    );
    expect(find.text('X'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(31));
    expect(find.text('Chưa có dữ liệu'), findsOneWidget);
    expect(find.text('Chưa ký trên HIS.'), findsOneWidget);
  });

  testWidgets('Nhiều mẫu hoặc nhiều form phải chọn trước khi gọi kết quả', (
    tester,
  ) async {
    final gateway = _Gateway()
      ..config = _configuration(templates: ['376', '377'], forms: [12, 14]);
    await _open(tester, gateway);
    expect(gateway.calls, 0);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giải phẫu bệnh · Mẫu 376').last);
    await tester.pumpAndSettle();
    expect(gateway.calls, 0);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Form 14').last);
    await tester.pumpAndSettle();
    expect(gateway.calls, 1);
  });

  testWidgets('Không lấy kết quả khi cấu hình trả sai chỉ định', (
    tester,
  ) async {
    final gateway = _Gateway()
      ..config = {..._configuration(), 'mathanhtoanct': 999};
    await _open(tester, gateway);
    expect(gateway.calls, 0);
    expect(
      find.textContaining('Thông tin chỉ định không khớp'),
      findsOneWidget,
    );
  });

  testWidgets('Kết quả sai mẫu không được hiển thị', (tester) async {
    final gateway = _Gateway()..onResult = (t, f) async => _result('999');
    await _open(tester, gateway);
    expect(find.text('Kết luận mẫu 999'), findsNothing);
    expect(find.textContaining('Kết quả không khớp mẫu'), findsOneWidget);
  });

  testWidgets('Kết quả đến muộn của mẫu cũ không ghi đè mẫu mới', (
    tester,
  ) async {
    final delayed = Completer<XnRow>();
    final gateway = _Gateway()
      ..config = _configuration(templates: ['376', '377'])
      ..onResult = (template, form) =>
          template == '376' ? delayed.future : Future.value(_result(template));
    await _open(tester, gateway);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giải phẫu bệnh · Mẫu 376').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Giải phẫu bệnh · Mẫu 377').last);
    await tester.pumpAndSettle();
    expect(find.text('Kết luận mẫu 377'), findsOneWidget);
    delayed.complete(_result('376'));
    await tester.pumpAndSettle();
    expect(find.text('Kết luận mẫu 377'), findsOneWidget);
    expect(find.textContaining('Kết luận mẫu 376'), findsNothing);
  });

  testWidgets('HSM chưa xác định không hiển thị tích xanh', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: XnSignatureView(
            data: {
              'daKyHIS': true,
              'dangKyHsmHopLe': null,
              'hienThiTichXanh': true,
              'tenNguoiKy': 'Người kiểm thử',
            },
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.verified), findsNothing);
    expect(find.text('Chưa xác định trạng thái đăng ký HSM.'), findsOneWidget);
  });

  testWidgets('Lỗi chữ ký không che mất kết quả GPB đã tải', (tester) async {
    final gateway = _Gateway()
      ..onSignature = () async =>
          throw const XnResultException('Chưa tải được chữ ký');
    await _open(tester, gateway);
    expect(find.textContaining('Kết luận mẫu 376'), findsOneWidget);
    expect(find.text('Chưa tải được chữ ký'), findsOneWidget);
  });

  for (final width in [320.0, 1400.0]) {
    testWidgets('Bảng kết quả vừa màn hình $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: XnResultTable(
                  headers: ['Xét nghiệm', 'Kết quả', 'Đơn vị', 'Tham chiếu'],
                  rows: [
                    [
                      'Xét nghiệm có tên dài để kiểm tra việc xuống dòng',
                      '<5',
                      '',
                      '4.2 – 6.4',
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Table), width >= 720 ? findsOneWidget : findsNothing);
    });
  }
}
