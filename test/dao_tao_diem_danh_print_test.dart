import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp_bvhv/features/nhan_vien_v2/screens/dialogs/dao_tao_v2/dialogs/dao_tao_diem_danh_print.dart';
import 'package:mobileapp_bvhv/models/dao_tao_v2_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tạo PDF điểm danh bằng Times New Roman Unicode cỡ 14', () async {
    final employees = List.generate(
      35,
      (index) => DaoTaoInDiemDanhNhanVienV2Model(
        maSo: (index + 1).toString().padLeft(5, '0'),
        hoVaTen: 'Nguyễn Thị Hồng Ánh ${index + 1}',
        namSinh: DateTime(1990, 9, 6),
        tenKhoaPhong: 'Phòng khám vệ tinh',
      ),
    );

    final bytes = await DaoTaoDiemDanhPrint.buildPdf(
      DaoTaoInDiemDanhV2Model(
        idLopDaoTao: 1,
        tenLopDaoTao: 'Đào tạo kiểm tra chữ Việt',
        loaiIn: 'DIEM_DANH',
        ngayInDiemDanh: DateTime(2026, 9, 7),
        kp: 'Phòng Công nghệ Thông tin',
        baoCaoVien: 'Nguyễn Văn Thái',
        thoiGianDetails: 'Từ 08 giờ 00 đến 17 giờ 00',
        diaDiem: 'Bệnh viện Đa khoa Hùng Vương',
        tpThamDu: 'Cán bộ nhân viên và phòng khám vệ tinh',
        danhSach: employees,
      ),
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(10000));
  });

  test('15 nhân viên nằm vừa trang đầu và có thể xuất Word', () async {
    final data = DaoTaoInDiemDanhV2Model(
      idLopDaoTao: 2,
      tenLopDaoTao: 'Sinh hoạt khoa học toàn viện',
      loaiIn: 'DIEM_DANH',
      ngayInDiemDanh: DateTime(2026, 9, 7),
      kp: 'Đào tạo',
      baoCaoVien: 'Nguyễn Văn Thái',
      thoiGianDetails: '11h30 - 12h30',
      diaDiem: 'Hội trường T',
      tpThamDu: 'Bác sĩ',
      danhSach: List.generate(
        15,
        (index) => DaoTaoInDiemDanhNhanVienV2Model(
          maSo: (index + 1).toString().padLeft(5, '0'),
          hoVaTen: 'Nguyễn Thị Hồng Ánh ${index + 1}',
          namSinh: DateTime(1990, 3, 1),
          tenKhoaPhong: 'Phòng Công Nghệ Thông Tin',
        ),
      ),
    );

    final pdfBytes = await DaoTaoDiemDanhPrint.buildPdf(data);
    final wordBytes = DaoTaoDiemDanhPrint.buildWordDocx(data);

    expect(pdfBytes, isNotEmpty);
    expect(wordBytes, isNotEmpty);
    expect(wordBytes.length, greaterThan(1000));
    expect(wordBytes.take(2), orderedEquals([0x50, 0x4B]));

    final wordArchive = ZipDecoder().decodeBytes(wordBytes);
    expect(
      wordArchive.files.any((file) => file.name == 'word/document.xml'),
      isTrue,
    );
  });
}
