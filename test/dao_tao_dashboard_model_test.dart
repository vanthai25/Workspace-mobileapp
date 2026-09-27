import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp_bvhv/models/dao_tao_dashboard_models.dart';

void main() {
  test('parses training dashboard sections and employee types', () {
    final model = DaoTaoDashboardModel.fromJson({
      'thoiDiemThongKe': '2026-09-20T10:30:00',
      'coQuyenLopDaoTao': true,
      'coQuyenThucHanhNoiBo': true,
      'coQuyenThucHanhNgoaiVien': true,
      'lopDaoTao': {'tongSoLop': 12, 'dangDienRa': 2},
      'thucHanhNoiBo': {
        'tongHoSo': 9,
        'dangThucHanh': 4,
        'theoLoaiNhanVien': [
          {
            'loaiNhanVien': 1,
            'tenLoaiNhanVien': 'Bác sĩ',
            'tongHoSo': 5,
            'dangThucHanh': 3,
            'soDotDaHoanThanh': 7,
          },
        ],
        'canhBaoSapKetThuc': [
          {
            'id': 8,
            'hoVaTen': 'Nguyễn Văn A',
            'ngayKetThuc': '2026-09-21T00:00:00',
            'soNgayConLai': 1,
          },
        ],
      },
      'thucHanhNgoaiVien': {
        'tongNguoiThucHanh': 6,
        'dangKyTuBenNgoai': 4,
        'dangKyNhapThuCong': 2,
      },
    });

    expect(model.coQuyenThucHanhNoiBo, isTrue);
    expect(model.lopDaoTao.tongSoLop, 12);
    expect(
      model.thucHanhNoiBo.theoLoaiNhanVien.single.tenLoaiNhanVien,
      'Bác sĩ',
    );
    expect(model.thucHanhNoiBo.canhBaoSapKetThuc.single.soNgayConLai, 1);
    expect(model.thucHanhNgoaiVien.dangKyTuBenNgoai, 4);
  });

  test('accepts PascalCase API payloads', () {
    final model = DaoTaoDashboardModel.fromJson({
      'CoQuyenThucHanhNoiBo': true,
      'ThucHanhNoiBo': {
        'TongHoSo': 3,
        'TheoLoaiNhanVien': [
          {'LoaiNhanVien': 2, 'TenLoaiNhanVien': 'Điều dưỡng'},
        ],
      },
    });

    expect(model.coQuyenThucHanhNoiBo, isTrue);
    expect(model.thucHanhNoiBo.tongHoSo, 3);
    expect(model.thucHanhNoiBo.theoLoaiNhanVien.single.loaiNhanVien, 2);
  });
}
