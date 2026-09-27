import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp_bvhv/models/cap_cchn_models.dart';

void main() {
  test('đọc trạng thái tổng hợp các đợt hướng dẫn CCHN', () {
    final CapCchnModel model = CapCchnModel.fromJson(<String, dynamic>{
      'idCapCCCHN': 12,
      'maSo': '00123',
      'hoVaTen': 'Nguyễn Văn A',
      'soNguoiHuongDan': 4,
      'soDotDangThucHanh': 1,
      'soDotSapKetThuc': 1,
      'soDotDaHoanThanh': 2,
      'soDotSapBatDau': 1,
      'ngayKetThucGanNhat': '2030-10-20',
    });

    expect(model.idCapCCCHN, 12);
    expect(model.soNguoiHuongDan, 4);
    expect(model.soDotDangThucHanh, 1);
    expect(model.soDotSapKetThuc, 1);
    expect(model.soDotDaHoanThanh, 2);
    expect(model.soDotSapBatDau, 1);
    expect(model.ngayKetThucGanNhat, DateTime(2030, 10, 20));
  });

  test('mỗi trang danh sách mặc định chỉ lấy 12 hồ sơ', () {
    const CapCchnPageResult result = CapCchnPageResult();
    expect(result.pageSize, 12);
  });

  test('đọc hồ sơ người thực hành độc lập và trạng thái liên kết nhân sự', () {
    final model = CapCchnModel.fromJson(<String, dynamic>{
      'idCapCCCHN': 20,
      'maSo': '00123',
      'hoVaTen': 'Nguyễn Văn A',
      'ngaySinh': '2000-01-02',
      'soCCCD': '012345678901',
      'loaiNhanVien': 2,
      'tenLoaiNhanVien': 'Bác sĩ',
      'idTinhTrang': 1,
      'hocPhi': 1500000,
      'anhDaiDien': <String, dynamic>{'idFile': 9, 'fileName': 'avatar.jpg'},
    });

    expect(model.ngaySinh, DateTime(2000, 1, 2));
    expect(model.soCCCD, '012345678901');
    expect(model.loaiNhanVien, 2);
    expect(model.idTinhTrang, 1);
    expect(model.hocPhi, 1500000);
    expect(model.anhDaiDien?.fileName, 'avatar.jpg');
  });

  test('đọc danh mục khoa phòng và loại nhân viên', () {
    final catalog = CapCchnCatalog.fromJson(<String, dynamic>{
      'khoaPhongs': [
        <String, dynamic>{'id': 10, 'ten': 'Khoa Nội'},
      ],
      'loaiNhanViens': [
        <String, dynamic>{'id': 7, 'ten': 'Học viên'},
      ],
    });
    expect(catalog.khoaPhongs.single.id, 10);
    expect(catalog.loaiNhanViens.single.ten, 'Học viên');
  });

  test('đọc tải hướng dẫn, danh sách học viên và lịch được gợi ý', () {
    final mentor = CapCchnMentorOption.fromJson(<String, dynamic>{
      'maSo': '00001',
      'hoVaTen': 'Bác sĩ Hướng dẫn',
      'soNguoiDangHuongDan': 5,
      'ngayBatDauGoiY': '2030-10-01',
      'ngayKetThucGoiY': '2030-12-31',
      'nguoiDangHuongDan': <Map<String, dynamic>>[
        <String, dynamic>{
          'idCapCchn': 21,
          'hoVaTen': 'Người thực hành A',
          'idKhoaPhong': 10,
          'tenKhoaPhong': 'Khoa Nội',
          'ngayBatDau': '2030-07-01',
          'ngayKetThuc': '2030-09-30',
        },
      ],
    });

    expect(mentor.daDuSoLuong, isTrue);
    expect(mentor.nguoiDangHuongDan.single.hoVaTen, 'Người thực hành A');
    expect(mentor.ngayBatDauGoiY, DateTime(2030, 10, 1));
    expect(mentor.ngayKetThucGoiY, DateTime(2030, 12, 31));
  });
}
