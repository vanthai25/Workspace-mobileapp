import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:provider/provider.dart';
import 'package:mobileapp_bvhv/providers/dao_tao_v2_provider.dart';
import 'package:mobileapp_bvhv/services/dao_tao_v2_service.dart';
import 'package:mobileapp_bvhv/features/nhan_vien_v2/screens/dialogs/dao_tao_v2/dialogs/lop_dao_tao_form_dialog.dart';
import 'package:mobileapp_bvhv/models/dao_tao_v2_models.dart';
import 'package:mobileapp_bvhv/features/nhan_vien_v2/screens/dialogs/dao_tao_v2/dialogs/lop_khoa_phong_selector.dart';

void main() {
  testWidgets('Form quyền 48 chọn sẵn khoa gốc, gửi thêm khoa được chọn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = _RecordingProvider()
      ..danhMuc = const DaoTaoDanhMucV2Model(
        idKhoaPhongHienTai: 12,
        khoaPhongs: [
          DaoTaoDanhMucItemV2Model(id: 12, ten: 'Khoa Nội'),
          DaoTaoDanhMucItemV2Model(id: 21, ten: 'Khoa Ngoại'),
        ],
      );
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<DaoTaoV2Provider>.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: LopDaoTaoFormDialog(isRole47: false)),
        ),
      ),
    );
    expect(find.text('Áp dụng toàn viện'), findsNothing);
    final owner = find.byKey(const ValueKey('khoa-phong-12'));
    expect(tester.widget<CheckboxListTile>(owner).value, isTrue);
    expect(tester.widget<CheckboxListTile>(owner).onChanged, isNull);
    await tester.enterText(find.byType(TextFormField).first, 'Lớp liên khoa');
    final extra = find.byKey(const ValueKey('khoa-phong-21'));
    await tester.ensureVisible(extra);
    await tester.tap(extra);
    await tester.pump();
    await tester.tap(find.text('Thêm lớp'));
    await tester.pump();
    expect(provider.payload?['idKhoaPhongs'], [12, 21]);
    expect(provider.payload?['tenLopDaoTao'], 'Lớp liên khoa');
    expect(provider.payload?.containsKey('phamViDaoTao'), isFalse);
    expect(tester.takeException(), isNull);
  });
  test('Lớp cũ vẫn có phạm vi khoa/phòng từ IdKhoaPhong', () {
    final lop = LopDaoTaoV2Model.fromJson({
      'phamViDaoTao': 2,
      'idKhoaPhong': 12,
    });
    expect(lop.idKhoaPhongs, [12]);
  });

  test('Đọc nhiều khoa/phòng và giữ khoa gốc, loại mã trùng/sai', () {
    final lop = LopDaoTaoV2Model.fromJson({
      'phamViDaoTao': 2,
      'idKhoaPhong': 12,
      'idKhoaPhongs': [3, '21', 3, null, -1],
    });
    expect(lop.idKhoaPhongs, [3, 12, 21]);
  });

  test('Lớp toàn viện không lấy giới hạn khoa/phòng từ dữ liệu cũ', () {
    final lop = LopDaoTaoV2Model.fromJson({
      'phamViDaoTao': 1,
      'idKhoaPhong': 12,
      'idKhoaPhongs': [12, 21],
    });
    expect(lop.idKhoaPhongs, isEmpty);
  });

  test('Danh mục trả khoa hiện tại để chọn sẵn và các khoa được chọn thêm', () {
    final dm = DaoTaoDanhMucV2Model.fromJson({
      'idKhoaPhongHienTai': 12,
      'khoaPhongs': [
        {'id': 12, 'ten': 'Khoa Nội'},
        {'id': 21, 'ten': 'Khoa Ngoại'},
      ],
    });
    expect(dm.idKhoaPhongHienTai, 12);
    expect(dm.khoaPhongs.map((k) => k.id), [12, 21]);
  });

  testWidgets('Chọn thêm, bỏ khoa bổ sung và tìm kiếm giữ khoa đã chọn', (
    tester,
  ) async {
    var selected = <int>{12};
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return LopKhoaPhongSelector(
                items: const [
                  DaoTaoDanhMucItemV2Model(id: 12, ten: 'Khoa Nội'),
                  DaoTaoDanhMucItemV2Model(id: 21, ten: 'Khoa Ngoại'),
                ],
                selectedIds: selected,
                lockedIds: const {12},
                onChanged: (ids) => setState(() => selected = ids),
              );
            },
          ),
        ),
      ),
    );
    final owner = find.byKey(const ValueKey('khoa-phong-12'));
    final extra = find.byKey(const ValueKey('khoa-phong-21'));
    expect(tester.widget<CheckboxListTile>(owner).onChanged, isNull);
    await tester.tap(extra);
    await tester.pump();
    expect(selected, {12, 21});
    await tester.enterText(find.byType(TextField), 'Ngoại');
    await tester.pump();
    expect(owner, findsNothing);
    expect(selected, {12, 21});
    await tester.tap(extra);
    await tester.pump();
    expect(selected, {12});
    expect(tester.takeException(), isNull);
  });
}

class _RecordingProvider extends DaoTaoV2Provider {
  _RecordingProvider() : super(service: DaoTaoV2Service(Dio()));
  Map<String, dynamic>? payload;

  @override
  Future<bool> createLop(
    Map<String, dynamic> data, {
    required List<fp.PlatformFile> files,
  }) async {
    payload = data;
    return false;
  }
}
