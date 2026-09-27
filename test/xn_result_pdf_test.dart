import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp_bvhv/services/xn_result_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tạo được PDF mẫu 376 và PDF xét nghiệm dùng chung', () async {
    const service = XnResultPdfService();
    final common = <String, dynamic>{
      'idMauIn': '376',
      'idMauKqKhac': 12,
      'loaiKetQua': 'GPB',
      'tenDichVu': 'Dịch vụ kiểm thử',
      'benhNhan': [
        {
          'mabn': '000001',
          'makcb': '2600200001',
          'hoten': 'BỆNH NHÂN KIỂM THỬ',
          'tuoi': '30 tuổi',
          'tenphai': 'Nữ',
        },
      ],
      'ketQua': [
        {
          'barcode': 'TEST-001',
          'ketluan': 'Kết luận kiểm thử',
          'ngaylam': '2026-09-18T09:20:00',
        },
      ],
      'truongKetQuaKhac': const <Map<String, dynamic>>[],
    };
    final gpb = await service.build(result: common);
    expect(utf8.decode(gpb.take(4).toList()), '%PDF');
    expect(gpb.length, greaterThan(1000));
    expect(latin1.decode(gpb).contains('/Count 1'), isTrue);

    final pdfWithInvalidOptionalImages = await service.build(
      result: {
        ...common,
        'hinhAnh': [
          {'anhBase64': base64Encode(utf8.encode('not an image'))},
        ],
      },
      signature: {
        'daKyHIS': true,
        'anhBase64': base64Encode(utf8.encode('not an image')),
      },
    );
    expect(utf8.decode(pdfWithInvalidOptionalImages.take(4).toList()), '%PDF');

    final pathology381 = await service.build(
      result: {
        ...common,
        'idMauIn': '381',
        'idMauKqKhac': null,
        'ketQua': [
          {
            'barcode': 'HV26_TEST',
            'docketqua': 'Nhận xét đại thể kiểm thử.',
            'mota': 'Nhận xét vi thể kiểm thử.',
            'ketluan': 'Chẩn đoán mô bệnh học kiểm thử.',
            'ngayth': '2026-09-18T08:30:00',
            'ngaytraKQ': '2026-09-18T09:20:00',
            'Solam': 1,
          },
        ],
        'dichVu': [
          {'ghichudv': 'Vị trí lấy mẫu kiểm thử'},
        ],
        'nhanVien': [
          {'bslam2': 'Người pha kiểm thử', 'ktvlam': 'Kỹ thuật viên kiểm thử'},
        ],
      },
    );
    expect(utf8.decode(pathology381.take(4).toList()), '%PDF');
    expect(latin1.decode(pathology381).contains('/Count 1'), isTrue);

    final cytology383 = await service.build(
      result: {
        ...common,
        'idMauIn': '383',
        'idMauKqKhac': null,
        'ketQua': [
          {
            'barcode': 'TBH26_TEST',
            'mota': 'Nhận xét vi thể kiểm thử.',
            'ketluan': 'Chẩn đoán tế bào học kiểm thử.',
            'ngayth': '2026-09-18T08:30:00',
            'ngaytraKQ': '2026-09-18T10:31:00',
            'Solam': 2,
          },
        ],
        'dichVu': [
          {'ghichudv': 'Vị trí lấy mẫu: vị trí kiểm thử'},
        ],
      },
    );
    expect(utf8.decode(cytology383.take(4).toList()), '%PDF');
    expect(latin1.decode(cytology383).contains('/Count 1'), isTrue);

    final fungalCulture764 = await service.build(
      result: {
        'idMauIn': '764',
        'idMauKqKhac': null,
        'loaiKetQua': 'KHANG_SINH_DO',
        'tenDichVu': 'Vi nấm nuôi cấy định danh phương pháp thông thường',
        'benhNhan': [
          {
            'mabn': '000184645',
            'makcb': '2600159173',
            'hoten': 'NGUYỄN THỊ NHÀN',
            'tuoi': '59 tuổi',
            'tenphai': 'Nữ',
            'dienthoai': '0948475596',
            'diachi': 'Thôn kiểm thử, tỉnh Phú Thọ',
          },
        ],
        'viKhuanVaChiDinh': [
          {
            'barcode': '310726-90540',
            'noigui': 'Khoa Khám Bệnh',
            'ngaynhanbp': '2026-07-31T09:33:00',
            'tenloaimau': 'Da',
            'ktvlam': 'Nguyễn Văn Mười',
            'tendichvu': 'Vi nấm nuôi cấy định danh phương pháp thông thường',
            'tenvikhuan': 'Epidermophyton floccosum',
            'ketluan': 'Epidermophyton floccosum',
            'ngaylam': '2026-08-07T10:41:00',
            'ghichuvitheokhuan': '',
          },
        ],
        'khangSinh': const <Map<String, dynamic>>[],
        'chanDoan': [
          {'benhchung': 'Bệnh da do nấm sợi, không xác định'},
        ],
      },
    );
    expect(utf8.decode(fungalCulture764.take(4).toList()), '%PDF');
    expect(fungalCulture764.length, greaterThan(1000));
    expect(latin1.decode(fungalCulture764).contains('/Count 1'), isTrue);

    final microbiology351 = await service.build(
      result: {
        'idMauIn': '351',
        'idMauKqKhac': null,
        'loaiKetQua': 'KHANG_SINH_DO',
        'tenDichVu': 'Vi nấm kháng thuốc định tính',
        'benhNhan': [
          {
            'mabn': '0000195134',
            'makcb': '2600188697',
            'hoten': 'NGUYỄN THỊ NHƯ QUỲNH',
            'tuoi': '24 tuổi',
            'tenphai': 'Nữ',
            'dienthoai': '0353454152',
            'diachi': 'Xã Hoàng Cương, tỉnh Phú Thọ',
          },
        ],
        'viKhuanVaChiDinh': [
          {
            'vikhuanid': 10,
            'mavikhuan': 'CAN-SPP',
            'barcode': '020926-20765',
            'noigui': 'PKĐK Hùng Vương - Chân Mộng',
            'ngaynhanbp': '2026-09-02T14:03:00',
            'tenloaimau': 'Dịch âm đạo',
            'ktvlam': 'Nguyễn Thị Diệu Linh',
            'tendichvu': 'Vi nấm kháng thuốc định tính',
            'tenvikhuan': 'Candida spp',
            'ketluan': '',
            'ngaylam': '2026-09-02T14:13:00',
            'ghichuvitheokhuan': '',
          },
        ],
        'khangSinh': [
          for (final item in const [
            ('Amphotericin B', '8', 'S'),
            ('Caspofungin', '8', 'S'),
            ('Fluconazole', '8', 'S'),
            ('Itraconazole', '1', 'R'),
            ('Ketoconazole', '8', 'S'),
            ('Micafungin', '8', 'S'),
          ])
            {
              'vikhuanid': 10,
              'mavikhuan': 'CAN-SPP',
              'tennhomks': '',
              'tenkhangsinh': item.$1,
              'duongkinh': item.$2,
              'MIC': '',
              'SIR': item.$3,
            },
        ],
        'chanDoan': const <Map<String, dynamic>>[],
      },
    );
    expect(utf8.decode(microbiology351.take(4).toList()), '%PDF');
    expect(microbiology351.length, greaterThan(1000));
    expect(latin1.decode(microbiology351).contains('/Count 1'), isTrue);

    final microbiology743 = await service.build(
      result: {
        'idMauIn': '743',
        'idMauKqKhac': null,
        'loaiKetQua': 'KHANG_SINH_DO',
        'tenDichVu':
            'Nuôi cấy định danh vi khuẩn Streptococcus agalactiae (Liên cầu B)',
        'benhNhan': [
          {
            'mabn': '0000193495',
            'makcb': '2600183629',
            'hoten': 'LÊ THỊ HOÀ',
            'tuoi': '35 tuổi',
            'tenphai': 'Nữ',
            'dienthoai': '0973703291',
            'diachi': 'Xã Hạ Hoà, tỉnh Phú Thọ',
          },
        ],
        'viKhuanVaChiDinh': [
          {
            'vikhuanid': 20,
            'mavikhuan': 'GBS',
            'barcode': '280826-17588',
            'noigui': 'Khoa Khám Bệnh',
            'ngaynhanbp': '2026-08-28T09:50:00',
            'tenloaimau': 'Dịch âm đạo, trực tràng',
            'ktvlam': 'Nguyễn Văn Mười',
            'tendichvu':
                'Nuôi cấy định danh vi khuẩn Streptococcus agalactiae (Liên cầu B)',
            'tenvikhuan': '',
            'ketluan': 'ÂM TÍNH',
            'ngaylam': '2026-08-30T08:16:00',
            'ghichuvitheokhuan': '',
          },
        ],
        'khangSinh': const <Map<String, dynamic>>[],
        'chanDoan': [
          {'benhchung': 'Theo dõi thai phụ đã đến nhiều lần'},
        ],
      },
    );
    expect(utf8.decode(microbiology743.take(4).toList()), '%PDF');
    expect(microbiology743.length, greaterThan(1000));
    expect(latin1.decode(microbiology743).contains('/Count 1'), isTrue);

    final hematology609 = await service.build(
      result: {
        'idMauIn': '609',
        'idMauKqKhac': null,
        'loaiKetQua': 'XET_NGHIEM',
        'thongTin': [
          {
            'makcb': '2600166010',
            'barcode': '110826-97411',
            'hoten': 'PHẠM MINH THƯ',
            'namsinh': '1950',
            'tenphai': 'Nam',
            'diachi': 'Thôn Phượng Hùng 2, xã Chí Đám, tỉnh Phú Thọ',
            'tendoituong': 'BHYT',
            'dienthoai': '0982541894',
            'tenkk': 'Khoa Nội Tổng Hợp',
            'tenphong': 'G504',
            'sogiuong': 'G504-02-PL',
            'ngayke': '2026-08-11T15:39:00',
            'tennv': 'Miêu Thị Vân',
            'ngaylaymau': '2026-08-11T16:28:00',
            'ngaykhopBC': '2026-08-11T16:28:00',
            'tennhanvienlaymau': 'Nguyễn Thị Diệu Linh',
            'tennhanviennhan': 'Nguyễn Thị Diệu Linh',
          },
        ],
        'chanDoan': [
          {'tenbenh': 'Nhồi máu não không xác định'},
        ],
        'ghiChu': [
          {
            'ghichudichvu': 'Hình ảnh thiếu máu hồng cầu bình sắc.',
            'ghichubarcode': '',
          },
        ],
        'dongKetQua': [
          {
            'grouplevel': 1,
            'STT_DV': 1,
            'grheadertext': 'Huyết đồ (bằng phương pháp thủ công)',
          },
          for (final item in const [
            ('Số lượng bạch cầu (WBC)', '12.11', 'G/L', '4.00 - 10.00', 'H'),
            ('- Bạch cầu trung tính', '74', '%', '45 - 75', ''),
            ('- Bạch cầu Lymphocyte', '17', '%', '20 - 45', 'L'),
            ('- Bạch cầu Monocyte', '8', '%', '3 - 11', ''),
            ('- Bạch cầu ưa axit', '1', '%', '0 - 8', ''),
            ('- Bạch cầu ưa bazơ', '0', '%', '0 - 1', ''),
            ('Số lượng bạch cầu trung tính', '8.96', 'G/L', '1.50 - 6.50', 'H'),
            ('Số lượng bạch cầu Lymphocyte', '2.06', 'G/L', '1.00 - 3.00', ''),
            ('Số lượng bạch cầu Monocyte', '0.97', 'G/L', '0.20 - 0.80', 'H'),
            ('Số lượng bạch cầu ưa axit', '0.12', 'G/L', '0.00 - 0.50', ''),
            ('Số lượng hồng cầu (RBC)', '2.77', 'T/L', '4.20 - 5.40', 'L'),
            ('Lượng huyết sắc tố (Hb)', '87', 'g/L', '130 - 160', 'L'),
            ('Thể tích khối hồng cầu (HCT)', '26.1', '%', '40 - 47', 'L'),
            ('Thể tích trung bình hồng cầu', '94.2', 'fL', '80 - 100', ''),
            ('Lượng Hb trung bình hồng cầu', '31.4', 'pg', '28 - 32', ''),
            ('Nồng độ Hb trung bình hồng cầu', '333', 'g/L', '320 - 360', ''),
            ('Độ phân bố hồng cầu', '17.0', '%', '11 - 14', 'H'),
            ('Số lượng tiểu cầu (PLT)', '1199', 'G/L', '140 - 440', 'H'),
            ('Thể tích trung bình tiểu cầu', '9.5', 'fL', '7.0 - 11.0', ''),
            ('Độ phân bố tiểu cầu', '9.3', '%', '10 - 18', 'L'),
          ])
            {
              'grouplevel': 0,
              'tenchiso_goc': item.$1,
              'ketqua_goc': item.$2,
              'ketluan': item.$5 == 'H'
                  ? '<fc255,0,0><fnTimes New Roman><fs12><b>${item.$2}'
                  : item.$5 == 'L'
                  ? '<fc0,0,255><fnTimes New Roman><fs12><b>${item.$2}'
                  : item.$2,
              'tendonvitinh': item.$3,
              'giatribinhthuong': item.$4,
              'HL': item.$5,
              'quytrinhxn': 'LAB-QTXN-HH-11',
              'InstrumentID': 'SysmexXN1000',
              'bslam': 'Lê Thị Lan',
              'ngaylam': '2026-08-12T07:59:00',
            },
        ],
      },
    );
    expect(utf8.decode(hematology609.take(4).toList()), '%PDF');
    expect(hematology609.length, greaterThan(1000));
    expect(latin1.decode(hematology609).contains('/Count 1'), isTrue);

    final laboratory301 = await service.build(
      result: {
        'idMauIn': '301',
        'idMauKqKhac': null,
        'loaiKetQua': 'XET_NGHIEM',
        'thongTin': [
          {
            'makcb': '2600100001',
            'barcode': 'TEST301-001',
            'hoten': 'BỆNH NHÂN KIỂM THỬ',
            'namsinh': '2021',
            'tenphai': 'Nữ',
            'diachi': 'Địa chỉ kiểm thử',
            'tendoituong': 'BHYT',
            'dienthoai': '0900000000',
            'tenkk': 'Khoa Khám Bệnh',
            'tenphong': 'PK A102 (Dạ Liễu)',
            'ngayke': '2026-07-29T16:15:00',
            'tennv': 'Bác sĩ kiểm thử',
            'ngaygiao': '2026-07-29T16:20:00',
            'nguoigiao': 'Nhân viên lấy mẫu',
            'ngaykhopBC': '2026-07-29T16:31:00',
            'tennhanviennhan': 'Nhân viên nhận mẫu',
            'tinhtrangmau': 'Đạt',
            'ktvlam': 'Kỹ thuật viên kiểm thử',
            'ngaylam': '2026-07-30T15:27:00',
          },
        ],
        'chanDoan': [
          {'tenbenh': 'L50.1-Bệnh mày đay vô căn'},
        ],
        'ghiChu': [
          {'ghichudichvu': '', 'ghichubarcode': ''},
        ],
        'dongKetQua': [
          {
            'STT_DV': 1,
            'machiso': 984,
            'tenchiso':
                '<fnTimes New Roman><fs12>Toxocara (Giun đũa chó mèo) Ab miễn dịch tự động',
            'ketluan': '0.24',
            'giatribinhthuong': '< 0.3',
            'tenmaylam': 'ELISA IMMUNOMAT TỰ ĐỘNG 4 KHAY',
            'quytrinhxn': '',
            'grouplevel': 0,
            'daduyet': true,
            'mathanhtoanct': 123,
            'mahh': 8703,
          },
        ],
      },
    );
    expect(utf8.decode(laboratory301.take(4).toList()), '%PDF');
    expect(laboratory301.length, greaterThan(1000));
    expect(latin1.decode(laboratory301).contains('/Count 1'), isTrue);

    final hbv388 = await service.build(
      result: {
        'idMauIn': '388',
        'idMauKqKhac': null,
        'loaiKetQua': 'XET_NGHIEM',
        'tenDichVu': 'PCR HBV định lượng',
        'thongTin': [
          {
            'makcb': '2600203309',
            'barcode': '180926-29944',
            'hoten': 'TRƯƠNG HOÀI NGỌC',
            'namsinh': '1986',
            'tenphai': 'Nữ',
            'diachi': 'Địa chỉ kiểm thử',
            'dienthoai': '0970000000',
            'tendoituong': 'BHYT',
            'tenkk': 'Khoa Khám Bệnh',
            'tenphong': 'Phòng khám A111',
            'ngayke': '2026-09-18T17:00:00',
            'tennv': 'Bác sĩ chỉ định',
            'ngaygiao': '2026-09-18T17:38:00',
            'ngaykhopBC': '2026-09-18T18:31:00',
            'nguoigiao': 'Nguyễn Mỹ Linh',
            'tennhanviennhan': 'Nguyễn Mỹ Linh',
            'tinhtrangmau': 'Đạt',
            'ktvlam': 'Trần Thanh Mai',
            'ngaylam': '2026-09-19T15:43:00',
          },
        ],
        'chanDoan': [
          {'tenbenh': 'Viêm gan virus B mạn tính'},
        ],
        'ghiChu': [
          {'ghichudichvu': '', 'ghichubarcode': ''},
        ],
        'hinhAnh': [
          {
            'contentType': 'image/png',
            'anhBase64':
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          },
        ],
        'dongKetQua': [
          {
            'grouplevel': 0,
            'tenchiso_goc': 'PCR HBV định lượng',
            'tenchiso': 'PCR HBV định lượng',
            'ketqua_goc': '7.15 x 10^8 IU/mL',
            'ketluan': '7.15 x 10^8 IU/mL',
            'giatribinhthuong': '15',
            'tendonvitinh': 'IU/mL',
            'tenloaimau': 'Huyết tương',
            'quytrinhxn': 'LAB-QTXN-SHPT-15',
          },
        ],
      },
    );
    expect(utf8.decode(hbv388.take(4).toList()), '%PDF');
    expect(hbv388.length, greaterThan(1000));
    expect(latin1.decode(hbv388).contains('/Count 1'), isTrue);

    final hsv391 = await service.build(
      result: {
        'idMauIn': '391',
        'idMauKqKhac': null,
        'loaiKetQua': 'XET_NGHIEM',
        'tenDichVu': 'PCR HSV 1/2 (Herpes simplex virus) định type',
        'thongTin': [
          {
            'makcb': '2600203242',
            'barcode': '180926-29900',
            'hoten': 'LÊ PHẠM ANH NGUYÊN',
            'namsinh': '2025',
            'tenphai': 'Nữ',
            'diachi': 'Địa chỉ kiểm thử',
            'dienthoai': '0980000000',
            'tendoituong': 'BHYT',
            'tenkk': 'Khoa Nhi',
            'tenphong': 'G314',
            'sogiuong': 'G314-06-P',
            'ngayke': '2026-09-18T17:20:00',
            'tennv': 'Bác sĩ chỉ định',
            'ngaygiao': '2026-09-18T18:28:00',
            'ngaykhopBC': '2026-09-18T19:00:00',
            'nguoigiao': 'Nguyễn Thị Nga',
            'tennhanviennhan': 'Nguyễn Mỹ Linh',
            'tinhtrangmau': 'Đạt',
            'tenloaimau': 'Khác',
            'ktvlam': 'Trần Thanh Mai',
            'ngaylam': '2026-09-19T14:27:00',
          },
        ],
        'chanDoan': [
          {'tenbenh': 'Viêm niêm mạc miệng; sốt xác định khác'},
        ],
        'ghiChu': [
          {'ghichudichvu': '', 'ghichubarcode': 'BP: Dịch họng'},
        ],
        'dongKetQua': [
          {
            'grouplevel': 0,
            'tenchiso_goc': 'PCR HSV 1/2 (Herpes simplex virus) định type',
            'tenchiso': '<b>PCR HSV 1/2 (Herpes simplex virus) định type',
            'ketqua_goc': '',
            'ketluan': '',
            'tenloaimau': 'Khác',
            'tenmaylam': 'MÁY XÉT NGHIỆM REAL TIME PCR',
            'quytrinhxn': 'LAB-QTXN-SHPT-12',
          },
          for (final type in const ['1', '2'])
            {
              'grouplevel': 0,
              'tenchiso_goc': 'Herpes Simplex Virus type $type',
              'tenchiso': 'Herpes Simplex Virus type $type',
              'ketqua_goc': 'ÂM TÍNH',
              'ketluan': 'ÂM TÍNH',
            },
        ],
      },
    );
    expect(utf8.decode(hsv391.take(4).toList()), '%PDF');
    expect(hsv391.length, greaterThan(1000));
    expect(latin1.decode(hsv391).contains('/Count 1'), isTrue);

    final pcrPathogen474 = await service.build(
      result: {
        'idMauIn': '474',
        'idMauKqKhac': null,
        'loaiKetQua': 'XET_NGHIEM',
        'tenDichVu':
            'PCR Phát hiện 6 tác nhân vi khuẩn nhóm nhiễm trùng cộng đồng',
        'thongTin': [
          {
            'makcb': '2600203344',
            'barcode': '180926-29890',
            'hoten': 'NGUYỄN MINH NHẬT',
            'namsinh': '1977',
            'tenphai': 'Nữ',
            'diachi': 'Địa chỉ kiểm thử',
            'dienthoai': '0970000000',
            'tendoituong': 'BHYT',
            'tenkk': 'Khoa Nội Tổng Hợp',
            'tenphong': 'G512',
            'sogiuong': 'G512-05-P',
            'ngayke': '2026-09-18T15:45:00',
            'tennv': 'Bác sĩ chỉ định',
            'ngaygiao': '2026-09-18T16:19:00',
            'ngaykhopBC': '2026-09-18T16:52:00',
            'nguoigiao': 'Nguyễn Thị Hiền',
            'tennhanviennhan': 'Nguyễn Thu Uyên',
            'tinhtrangmau': 'Đạt',
            'ktvlam': 'Trần Thanh Mai',
            'ngaylam': '2026-09-19T14:32:00',
          },
        ],
        'chanDoan': [
          {'tenbenh': 'Viêm phế quản cấp tính'},
        ],
        'ghiChu': [
          {'ghichudichvu': '', 'ghichubarcode': ''},
        ],
        'dongKetQua': [
          {
            'grouplevel': 0,
            'tenchiso_goc':
                'PCR Phát hiện 6 tác nhân vi khuẩn nhóm nhiễm trùng cộng đồng',
            'tenchiso':
                '<b>PCR Phát hiện 6 tác nhân vi khuẩn nhóm nhiễm trùng cộng đồng',
            'mota': '',
            'ketqua_goc': '',
            'ketluan': '',
            'ghichu': 'Dịch tỵ hầu',
            'quytrinhxn': 'LAB-QTXN-SHPT-05',
          },
          for (final item in const [
            ('S. pneumoniae (Streptococcus pneumoniae)', 'ÂM TÍNH', '-'),
            (
              'H. influenzae (Haemophilus influenzae)',
              'DƯƠNG TÍNH',
              '3.16E+08',
            ),
            ('M. catarrhalis (Moraxella catarrhalis)', 'ÂM TÍNH', '-'),
            ('S. pyogenes (GAS)', 'ÂM TÍNH', '-'),
            ('S. agalactiae (GBS)', 'ÂM TÍNH', '-'),
            ('S. suis (Streptococcus suis)', 'ÂM TÍNH', '-'),
            ('H. influenzae type b', 'ÂM TÍNH', '-'),
            ('F. nucleatum (Fusobacterium nucleatum)', 'ÂM TÍNH', '-'),
          ])
            {
              'grouplevel': 0,
              'tenchiso_goc': item.$1,
              'tenchiso': item.$1,
              'mota': item.$2,
              'ketqua_goc': item.$3,
              'ketluan': item.$3,
            },
        ],
      },
    );
    expect(utf8.decode(pcrPathogen474.take(4).toList()), '%PDF');
    expect(pcrPathogen474.length, greaterThan(1000));
    expect(latin1.decode(pcrPathogen474).contains('/Count 1'), isTrue);

    final hpv477 = await service.build(
      result: {
        'idMauIn': '477',
        'idMauKqKhac': null,
        'loaiKetQua': 'XET_NGHIEM',
        'tenDichVu': 'HPV genotype Real-time PCR',
        'thongTin': [
          {
            'makcb': '2600203263',
            'barcode': '180926-29923',
            'hoten': 'BÙI THỊ THANH',
            'namsinh': '1993',
            'tenphai': 'Nữ',
            'diachi': 'Địa chỉ kiểm thử',
            'dienthoai': '0980000000',
            'tendoituong': 'Khám sức khỏe đoàn',
            'tenkk': 'Khoa Khám Bệnh',
            'tenphong': 'Phòng Khám sức khỏe',
            'ngayke': '2026-09-18T17:20:00',
            'tennv': 'Bác sĩ chỉ định',
            'ngaygiao': '2026-09-18T17:28:00',
            'ngaykhopBC': '2026-09-18T18:36:00',
            'nguoigiao': 'Nguyễn Mỹ Linh',
            'tennhanviennhan': 'Nguyễn Mỹ Linh',
            'tinhtrangmau': 'Đạt',
            'ktvlam': 'Trần Thanh Mai',
            'ngaylam': '2026-09-19T11:14:00',
          },
        ],
        'chanDoan': [
          {'tenbenh': 'Chẩn đoán kiểm thử'},
        ],
        'ghiChu': [
          {'ghichudichvu': '', 'ghichubarcode': ''},
        ],
        'dongKetQua': [
          {
            'grouplevel': 0,
            'tenchiso_goc': 'HPV genotype Real-time PCR',
            'tenchiso': '<b>HPV genotype Real-time PCR',
            'ketqua_goc': '',
            'ketluan': '',
            'ghichu': 'Dịch âm đạo',
            'tenmaylam': '(HV) Máy xét nghiệm Real time PCR',
            'quytrinhxn': 'LAB-QTXN-SHPT-27',
          },
          {
            'grouplevel': 0,
            'tenchiso_goc': 'Type nguy cơ cao',
            'tenchiso': '<b><fc255,0,0>Type nguy cơ cao',
            'ketqua_goc': '',
            'ketluan': '',
          },
          for (final type in const [
            '16',
            '18',
            '26',
            '31',
            '33',
            '35',
            '39',
            '45',
            '51',
            '52',
            '53',
            '56',
            '58',
            '59',
            '66',
            '68',
            '69',
            '73',
            '82',
          ])
            {
              'grouplevel': 0,
              'tenchiso_goc': 'Type $type',
              'tenchiso': 'Type $type',
              'ketqua_goc': 'ÂM TÍNH',
              'ketluan': 'ÂM TÍNH',
            },
          {
            'grouplevel': 0,
            'tenchiso_goc': 'Type nguy cơ thấp',
            'tenchiso': '<b><fc255,0,0>Type nguy cơ thấp',
            'ketqua_goc': '',
            'ketluan': '',
          },
          for (final type in const [
            '6',
            '11',
            '40',
            '42',
            '43',
            '44',
            '54',
            '61',
            '70',
          ])
            {
              'grouplevel': 0,
              'tenchiso_goc': 'Type $type',
              'tenchiso': 'Type $type',
              'ketqua_goc': 'ÂM TÍNH',
              'ketluan': 'ÂM TÍNH',
            },
        ],
      },
    );
    expect(utf8.decode(hpv477.take(4).toList()), '%PDF');
    expect(hpv477.length, greaterThan(1000));
    expect(latin1.decode(hpv477).contains('/Count 1'), isTrue);

    final laboratory = await service.build(
      result: {
        ...common,
        'loaiKetQua': 'XET_NGHIEM',
        'idMauIn': '1',
        'idMauKqKhac': null,
        'dongKetQua': [
          {
            'grouplevel': 0,
            'tenchiso_goc': 'Chỉ số kiểm thử',
            'ketqua_goc': '<5',
            'tendonvitinh': 'mg/L',
            'giatribinhthuong': '4–6',
          },
        ],
      },
    );
    expect(utf8.decode(laboratory.take(4).toList()), '%PDF');
    expect(laboratory.length, greaterThan(1000));
  });
}
