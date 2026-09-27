import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp_bvhv/models/khen_thuong_ky_luat_models.dart';

void main() {
  test('parse danh sách khen thưởng và kỷ luật kèm file', () {
    final model = NhanVienKhenThuongKyLuatModel.fromJson({
      'khenThuongs': [
        {
          'maKhenThuong': 'KT-1',
          'maSo': '00001',
          'lyDoKhen': 'Hoàn thành tốt nhiệm vụ',
          'soTienKhen': 1500000,
          'ngayKhen': '2026-09-25T00:00:00',
          'file': {
            'idFile': 12,
            'fileName': 'quyet-dinh.pdf',
            'fileType': 'pdf',
            'fileSize': 1024,
          },
        },
      ],
      'kyLuats': [
        {
          'maKyLuat': 'KL-1',
          'maSo': '00001',
          'lyDoKyLuat': 'Vi phạm nội quy',
          'keoDaiThamNien': true,
          'soThangKeoDaiThamNien': 18,
          'ngayBatDauKeoDaiThamNien': '2026-10-01',
          'soDiemKyLuat': 2,
        },
      ],
      'tongSoThangKeoDaiThamNien': 18,
    });

    expect(model.khenThuongs, hasLength(1));
    expect(model.khenThuongs.single.soTienKhen, 1500000);
    expect(model.khenThuongs.single.file?.fileName, 'quyet-dinh.pdf');
    expect(model.kyLuats, hasLength(1));
    expect(model.kyLuats.single.keoDaiThamNien, isTrue);
    expect(model.kyLuats.single.soDiemKyLuat, 2);
    expect(model.kyLuats.single.soThangKeoDaiThamNien, 18);
    expect(model.kyLuats.single.ngayBatDauKeoDaiThamNien?.day, 1);
    expect(model.tongSoThangKeoDaiThamNien, 18);
  });
}
