import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp_bvhv/models/thuc_hanh_models.dart';

void main() {
  test('đọc đầy đủ hồ sơ và phân công từ API tra cứu thực hành', () {
    final model = TraCuuThucHanhModel.fromJson({
      'maTraCuu': '32e6a679-77c7-432f-9640-7b50bcc30001',
      'tenDot': 'Đợt thực hành tháng 9',
      'hoVaTen': 'Nguyễn Văn A',
      'email': 'a@example.com',
      'ngayDangKy': '2026-09-20T08:30:00',
      'tinhTrangThucHanh': 2,
      'ngayBatDauThucHanh': '2026-09-15',
      'ngayKetThucThucHanh': '2026-10-15',
      'phanCongs': [
        {
          'idPhanCong': 1,
          'idDangKyThucHanh': 2,
          'maSoNguoiHuongDan': '00123',
          'hoVaTenNguoiHuongDan': 'Trần Thị B',
          'idKhoaPhong': 10,
          'tenKhoaPhong': 'Khoa Nội',
          'ngayBatDau': '2026-09-15',
          'ngayKetThuc': '2026-10-15',
        },
      ],
    });

    expect(model.email, 'a@example.com');
    expect(model.tinhTrangThucHanh, 2);
    expect(model.phanCongs, hasLength(1));
    expect(model.phanCongs.single.tenKhoaPhong, 'Khoa Nội');
  });
}
