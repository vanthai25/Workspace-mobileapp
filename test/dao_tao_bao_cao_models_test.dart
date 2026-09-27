import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp_bvhv/models/dao_tao_bao_cao_models.dart';

void main() {
  test('parses training report and attendance scope totals', () {
    final report = DaoTaoBaoCaoTongHopModel.fromJson({
      'tuNgay': '2026-09-01T00:00:00',
      'denNgay': '2026-09-30T00:00:00',
      'soLopDaChon': 2,
      'tongNhanSu': 10,
      'soNguoiHopLe': 7,
      'soNguoiKhongThamGia': 2,
      'lopDaoTaos': [
        {
          'idLopDaoTao': 11,
          'tenLopDaoTao': 'An toàn người bệnh - buổi 1',
          'phamViDaoTao': 2,
          'tenPhamViDaoTao': 'Nội bộ khoa/phòng',
          'khoaPhongThamGia': 'Khoa Nội, Khoa Cấp cứu',
          'soDangKy': 8,
          'soHopLe': 6,
        },
      ],
      'caNhans': [
        {
          'maSo': '00123',
          'hoVaTen': 'Nguyễn Văn A',
          'soLopDaDangKy': 1,
          'soLopHopLe': 1,
          'soLopToanVien': 1,
          'soLopKhoaPhong': 0,
          'daHopLeBatKy': true,
          'ketQuaTheoLops': [
            {
              'idLopDaoTao': 11,
              'tenLopDaoTao': 'An toàn người bệnh - buổi 1',
              'trangThai': 'Hợp lệ',
              'daDangKy': true,
              'isHopLe': true,
            },
          ],
        },
      ],
    });

    expect(report.soLopDaChon, 2);
    expect(report.soNguoiHopLe, 7);
    expect(report.lopDaoTaos.single.soHopLe, 6);
    expect(report.lopDaoTaos.single.phamViDaoTao, 2);
    expect(report.lopDaoTaos.single.khoaPhongThamGia, 'Khoa Nội, Khoa Cấp cứu');
    expect(report.caNhans.single.daHopLeBatKy, isTrue);
    expect(report.caNhans.single.soLopToanVien, 1);
    expect(report.caNhans.single.ketQuaTheoLops.single.trangThai, 'Hợp lệ');
  });

  test('parses separate CME report with employee totals and details', () {
    final report = DaoTaoBaoCaoCmeModel.fromJson({
      'tuNgay': '2026-09-01T00:00:00',
      'denNgay': '2026-09-30T00:00:00',
      'tongNhanSu': 5,
      'tongChungChiCme': 3,
      'tongGioTinChi': 12.5,
      'theoLoaiNhanViens': [
        {
          'loaiNhanVien': 1,
          'tenLoaiNhanVien': 'Bác sĩ',
          'soNhanVien': 5,
          'soChungChi': 1,
          'soCme': 2,
          'tongGioTinChi': 12.5,
        },
      ],
      'caNhans': [
        {
          'maSo': '00123',
          'hoVaTen': 'Nguyễn Văn A',
          'soChungChi': 0,
          'soCme': 1,
          'tongChungChiCme': 1,
          'tongGioTinChi': 4.5,
        },
      ],
      'chiTiets': [
        {
          'idChungChi': 9,
          'maSo': '00123',
          'hoVaTen': 'Nguyễn Văn A',
          'tenChungChi': 'Cấp cứu cơ bản',
          'isCme': true,
          'ngayGhiNhan': '2026-09-12T00:00:00',
          'gioTinChi': 4.5,
        },
      ],
    });

    expect(report.tongGioTinChi, 12.5);
    expect(report.theoLoaiNhanViens.single.soCme, 2);
    expect(report.caNhans.single.tongChungChiCme, 1);
    expect(report.caNhans.single.tongGioTinChi, 4.5);
    expect(report.chiTiets.single.gioTinChi, 4.5);
  });
}
