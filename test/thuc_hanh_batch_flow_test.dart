import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobileapp_bvhv/models/thuc_hanh_models.dart';
import 'package:mobileapp_bvhv/providers/thuc_hanh_provider.dart';
import 'package:mobileapp_bvhv/services/nhan_vien_v2_service.dart';
import 'package:mobileapp_bvhv/services/thuc_hanh_service.dart';
import 'package:mobileapp_bvhv/screens/thuc_hanh/thuc_hanh_admin_screen.dart';
import 'package:mobileapp_bvhv/screens/thuc_hanh/thuc_hanh_public_screen.dart';

DotThucHanhModel batch(int id) => DotThucHanhModel(
  id: id,
  maDot: 'TH$id',
  tenDot: 'Đợt thực hành $id',
  batDauDangKy: DateTime(2026, 9, 1),
  ketThucDangKy: DateTime(2026, 10, 30),
  publicToken: 'token-$id',
  trangThai: 1,
  fileQuyetDinh: const ThucHanhFileModel(
    idFile: 10,
    fileName: 'quyet-dinh.pdf',
  ),
);

class FakeService extends ThucHanhService {
  FakeService() : super(Dio());
  final requestedBatches = <int?>[];
  final pending = <int, Completer<ThucHanhPage<DangKyThucHanhModel>>>{};
  bool delayRegistrations = false;
  @override
  Future<ThucHanhPage<DotThucHanhModel>> getBatches({
    String? keyword,
    int? registrationState,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  }) async => ThucHanhPage(items: [batch(1), batch(2)], totalCount: 2);
  @override
  Future<DotThucHanhModel> getPublicBatch(String token) async => batch(1);
  @override
  Future<ThucHanhPage<NguoiThucHanhModel>> getPeople({
    String? keyword,
    int? batchId,
    int page = 1,
    int pageSize = 20,
  }) async => const ThucHanhPage();
  @override
  Future<ThucHanhPage<DangKyThucHanhModel>> getRegistrations({
    String? keyword,
    int? batchId,
    int? practiceState,
    int? source,
    int page = 1,
    int pageSize = 20,
  }) {
    requestedBatches.add(batchId);
    if (delayRegistrations) {
      return (pending[batchId!] =
              Completer<ThucHanhPage<DangKyThucHanhModel>>())
          .future;
    }
    return Future.value(const ThucHanhPage());
  }
}

void main() {
  test('date filters are sent to API before pagination', () async {
    final dio = Dio();
    late RequestOptions request;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response(
              requestOptions: options,
              data: {'success': true, 'data': []},
            ),
          );
        },
      ),
    );
    await ThucHanhService(dio).getBatches(
      fromDate: DateTime(2026, 9, 1),
      toDate: DateTime(2026, 9, 30),
      page: 3,
    );
    expect(request.queryParameters['tuNgay'], '2026-09-01T00:00:00.000');
    expect(request.queryParameters['denNgay'], '2026-09-30T00:00:00.000');
    expect(request.queryParameters['page'], 3);
  });

  test(
    'switching batch clears filters and ignores previous batch response',
    () async {
      final service = FakeService()..delayRegistrations = true;
      final provider = ThucHanhProvider(service);
      final first = provider.selectBatch(1);
      provider.keywordRegistrations = 'old';
      provider.registrationPracticeState = 2;
      final second = provider.selectBatch(2);
      service.pending[2]!.complete(const ThucHanhPage(totalCount: 2));
      await second;
      service.pending[1]!.complete(const ThucHanhPage(totalCount: 99));
      await first;
      expect(provider.registrationBatchId, 2);
      expect(provider.registrations.totalCount, 2);
      expect(provider.keywordRegistrations, isEmpty);
      expect(provider.registrationPracticeState, isNull);
      provider.dispose();
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(320, 640),
    const Size(1280, 900),
  ]) {
    testWidgets('batch opens its own list at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeService();
      final provider = ThucHanhProvider(service);
      await provider.initialize();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: ThucHanhAdminScreen(
              nhanVienService: NhanVienV2Service(Dio()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Tab, 'Đăng ký'), findsNothing);
      expect(find.widgetWithText(Tab, 'Hồ sơ'), findsOneWidget);
      await tester.tap(find.text('Đợt thực hành 1'));
      await tester.pumpAndSettle();
      expect(service.requestedBatches, [1]);
      expect(find.text('Thêm vào đợt'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Quay lại danh sách đợt'));
      await tester.pumpAndSettle();
      expect(find.text('Từ ngày'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'public form requires new fields and offers decision at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: ThucHanhPublicScreen(
              publicToken: 'token-1',
              service: FakeService(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Xem quyết định'), findsOneWidget);
        final form = tester.state<FormState>(find.byType(Form));
        expect(form.validate(), isFalse);
        await tester.pump();
        expect(find.text('Vui lòng chọn ngày sinh'), findsOneWidget);
        expect(find.text('Vui lòng chọn giới tính'), findsOneWidget);
        expect(find.text('Vui lòng chọn ảnh đại diện'), findsOneWidget);
        for (final label in [
          'Trường/đơn vị *',
          'Chuyên ngành *',
          'Trình độ chuyên môn *',
        ]) {
          final field = tester.widget<TextFormField>(
            find.widgetWithText(TextFormField, label),
          );
          expect(field.validator!('  '), isNotNull);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
