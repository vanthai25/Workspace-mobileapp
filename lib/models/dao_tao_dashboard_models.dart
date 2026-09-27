int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

bool _bool(Object? value) =>
    value == true || value == 1 || '$value'.toLowerCase() == 'true';

String _string(Object? value) => value?.toString().trim() ?? '';

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value');

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    value is List ? value.map((item) => parse(_map(item))).toList() : <T>[];

class DaoTaoDashboardModel {
  final DateTime? thoiDiemThongKe;
  final bool coQuyenLopDaoTao;
  final bool coQuyenThucHanhNoiBo;
  final bool coQuyenThucHanhNgoaiVien;
  final DaoTaoLopDashboardModel lopDaoTao;
  final DaoTaoCapCchnDashboardModel thucHanhNoiBo;
  final DaoTaoNgoaiVienDashboardModel thucHanhNgoaiVien;

  const DaoTaoDashboardModel({
    this.thoiDiemThongKe,
    this.coQuyenLopDaoTao = false,
    this.coQuyenThucHanhNoiBo = false,
    this.coQuyenThucHanhNgoaiVien = false,
    this.lopDaoTao = const DaoTaoLopDashboardModel(),
    this.thucHanhNoiBo = const DaoTaoCapCchnDashboardModel(),
    this.thucHanhNgoaiVien = const DaoTaoNgoaiVienDashboardModel(),
  });

  factory DaoTaoDashboardModel.fromJson(Map<String, dynamic> json) {
    return DaoTaoDashboardModel(
      thoiDiemThongKe: _date(
        json['thoiDiemThongKe'] ?? json['ThoiDiemThongKe'],
      ),
      coQuyenLopDaoTao: _bool(
        json['coQuyenLopDaoTao'] ?? json['CoQuyenLopDaoTao'],
      ),
      coQuyenThucHanhNoiBo: _bool(
        json['coQuyenThucHanhNoiBo'] ?? json['CoQuyenThucHanhNoiBo'],
      ),
      coQuyenThucHanhNgoaiVien: _bool(
        json['coQuyenThucHanhNgoaiVien'] ?? json['CoQuyenThucHanhNgoaiVien'],
      ),
      lopDaoTao: DaoTaoLopDashboardModel.fromJson(
        _map(json['lopDaoTao'] ?? json['LopDaoTao']),
      ),
      thucHanhNoiBo: DaoTaoCapCchnDashboardModel.fromJson(
        _map(json['thucHanhNoiBo'] ?? json['ThucHanhNoiBo']),
      ),
      thucHanhNgoaiVien: DaoTaoNgoaiVienDashboardModel.fromJson(
        _map(json['thucHanhNgoaiVien'] ?? json['ThucHanhNgoaiVien']),
      ),
    );
  }
}

class DaoTaoLopDashboardModel {
  final int tongSoLop;
  final int dangMoDangKy;
  final int dangDienRa;
  final int sapDienRa;
  final int daKetThuc;
  final int tongLuotDangKy;

  const DaoTaoLopDashboardModel({
    this.tongSoLop = 0,
    this.dangMoDangKy = 0,
    this.dangDienRa = 0,
    this.sapDienRa = 0,
    this.daKetThuc = 0,
    this.tongLuotDangKy = 0,
  });

  factory DaoTaoLopDashboardModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoLopDashboardModel(
        tongSoLop: _int(json['tongSoLop'] ?? json['TongSoLop']),
        dangMoDangKy: _int(json['dangMoDangKy'] ?? json['DangMoDangKy']),
        dangDienRa: _int(json['dangDienRa'] ?? json['DangDienRa']),
        sapDienRa: _int(json['sapDienRa'] ?? json['SapDienRa']),
        daKetThuc: _int(json['daKetThuc'] ?? json['DaKetThuc']),
        tongLuotDangKy: _int(json['tongLuotDangKy'] ?? json['TongLuotDangKy']),
      );
}

class DaoTaoCapCchnDashboardModel {
  final int tongHoSo;
  final int tongDotHuongDan;
  final int dangThucHanh;
  final int sapKetThuc7Ngay;
  final int ketThucNgayMai;
  final int dotDaHoanThanh;
  final int chuaPhanCong;
  final int hoSoChuaDayDu;
  final List<DaoTaoLoaiNhanVienDashboardModel> theoLoaiNhanVien;
  final List<DaoTaoCanhBaoDashboardModel> canhBaoSapKetThuc;

  const DaoTaoCapCchnDashboardModel({
    this.tongHoSo = 0,
    this.tongDotHuongDan = 0,
    this.dangThucHanh = 0,
    this.sapKetThuc7Ngay = 0,
    this.ketThucNgayMai = 0,
    this.dotDaHoanThanh = 0,
    this.chuaPhanCong = 0,
    this.hoSoChuaDayDu = 0,
    this.theoLoaiNhanVien = const [],
    this.canhBaoSapKetThuc = const [],
  });

  factory DaoTaoCapCchnDashboardModel.fromJson(
    Map<String, dynamic> json,
  ) => DaoTaoCapCchnDashboardModel(
    tongHoSo: _int(json['tongHoSo'] ?? json['TongHoSo']),
    tongDotHuongDan: _int(json['tongDotHuongDan'] ?? json['TongDotHuongDan']),
    dangThucHanh: _int(json['dangThucHanh'] ?? json['DangThucHanh']),
    sapKetThuc7Ngay: _int(json['sapKetThuc7Ngay'] ?? json['SapKetThuc7Ngay']),
    ketThucNgayMai: _int(json['ketThucNgayMai'] ?? json['KetThucNgayMai']),
    dotDaHoanThanh: _int(json['dotDaHoanThanh'] ?? json['DotDaHoanThanh']),
    chuaPhanCong: _int(json['chuaPhanCong'] ?? json['ChuaPhanCong']),
    hoSoChuaDayDu: _int(json['hoSoChuaDayDu'] ?? json['HoSoChuaDayDu']),
    theoLoaiNhanVien: _list(
      json['theoLoaiNhanVien'] ?? json['TheoLoaiNhanVien'],
      DaoTaoLoaiNhanVienDashboardModel.fromJson,
    ),
    canhBaoSapKetThuc: _list(
      json['canhBaoSapKetThuc'] ?? json['CanhBaoSapKetThuc'],
      DaoTaoCanhBaoDashboardModel.fromJson,
    ),
  );
}

class DaoTaoLoaiNhanVienDashboardModel {
  final int? loaiNhanVien;
  final String tenLoaiNhanVien;
  final int tongHoSo;
  final int dangThucHanh;
  final int soDotDaHoanThanh;

  const DaoTaoLoaiNhanVienDashboardModel({
    this.loaiNhanVien,
    this.tenLoaiNhanVien = '',
    this.tongHoSo = 0,
    this.dangThucHanh = 0,
    this.soDotDaHoanThanh = 0,
  });

  factory DaoTaoLoaiNhanVienDashboardModel.fromJson(
    Map<String, dynamic> json,
  ) => DaoTaoLoaiNhanVienDashboardModel(
    loaiNhanVien: (json['loaiNhanVien'] ?? json['LoaiNhanVien']) is num
        ? (json['loaiNhanVien'] ?? json['LoaiNhanVien'] as num).toInt()
        : int.tryParse('${json['loaiNhanVien'] ?? json['LoaiNhanVien'] ?? ''}'),
    tenLoaiNhanVien: _string(
      json['tenLoaiNhanVien'] ?? json['TenLoaiNhanVien'],
    ),
    tongHoSo: _int(json['tongHoSo'] ?? json['TongHoSo']),
    dangThucHanh: _int(json['dangThucHanh'] ?? json['DangThucHanh']),
    soDotDaHoanThanh: _int(
      json['soDotDaHoanThanh'] ?? json['SoDotDaHoanThanh'],
    ),
  );
}

class DaoTaoNgoaiVienDashboardModel {
  final int tongNguoiThucHanh;
  final int tongDotThucHanh;
  final int dotDangMoDangKy;
  final int tongDangKy;
  final int dangKyChuaPhanCong;
  final int dangThucHanh;
  final int sapKetThuc7Ngay;
  final int ketThucNgayMai;
  final int daHoanThanh;
  final int dangKyTuBenNgoai;
  final int dangKyNhapThuCong;
  final List<DaoTaoCanhBaoDashboardModel> canhBaoSapKetThuc;

  const DaoTaoNgoaiVienDashboardModel({
    this.tongNguoiThucHanh = 0,
    this.tongDotThucHanh = 0,
    this.dotDangMoDangKy = 0,
    this.tongDangKy = 0,
    this.dangKyChuaPhanCong = 0,
    this.dangThucHanh = 0,
    this.sapKetThuc7Ngay = 0,
    this.ketThucNgayMai = 0,
    this.daHoanThanh = 0,
    this.dangKyTuBenNgoai = 0,
    this.dangKyNhapThuCong = 0,
    this.canhBaoSapKetThuc = const [],
  });

  factory DaoTaoNgoaiVienDashboardModel.fromJson(
    Map<String, dynamic> json,
  ) => DaoTaoNgoaiVienDashboardModel(
    tongNguoiThucHanh: _int(
      json['tongNguoiThucHanh'] ?? json['TongNguoiThucHanh'],
    ),
    tongDotThucHanh: _int(json['tongDotThucHanh'] ?? json['TongDotThucHanh']),
    dotDangMoDangKy: _int(json['dotDangMoDangKy'] ?? json['DotDangMoDangKy']),
    tongDangKy: _int(json['tongDangKy'] ?? json['TongDangKy']),
    dangKyChuaPhanCong: _int(
      json['dangKyChuaPhanCong'] ?? json['DangKyChuaPhanCong'],
    ),
    dangThucHanh: _int(json['dangThucHanh'] ?? json['DangThucHanh']),
    sapKetThuc7Ngay: _int(json['sapKetThuc7Ngay'] ?? json['SapKetThuc7Ngay']),
    ketThucNgayMai: _int(json['ketThucNgayMai'] ?? json['KetThucNgayMai']),
    daHoanThanh: _int(json['daHoanThanh'] ?? json['DaHoanThanh']),
    dangKyTuBenNgoai: _int(
      json['dangKyTuBenNgoai'] ?? json['DangKyTuBenNgoai'],
    ),
    dangKyNhapThuCong: _int(
      json['dangKyNhapThuCong'] ?? json['DangKyNhapThuCong'],
    ),
    canhBaoSapKetThuc: _list(
      json['canhBaoSapKetThuc'] ?? json['CanhBaoSapKetThuc'],
      DaoTaoCanhBaoDashboardModel.fromJson,
    ),
  );
}

class DaoTaoCanhBaoDashboardModel {
  final String nhom;
  final int id;
  final String hoVaTen;
  final String loaiNhanVien;
  final String nguoiHuongDan;
  final String khoaPhong;
  final String tenDot;
  final DateTime? ngayKetThuc;
  final int soNgayConLai;

  const DaoTaoCanhBaoDashboardModel({
    this.nhom = '',
    this.id = 0,
    this.hoVaTen = '',
    this.loaiNhanVien = '',
    this.nguoiHuongDan = '',
    this.khoaPhong = '',
    this.tenDot = '',
    this.ngayKetThuc,
    this.soNgayConLai = 0,
  });

  factory DaoTaoCanhBaoDashboardModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoCanhBaoDashboardModel(
        nhom: _string(json['nhom'] ?? json['Nhom']),
        id: _int(json['id'] ?? json['Id']),
        hoVaTen: _string(json['hoVaTen'] ?? json['HoVaTen']),
        loaiNhanVien: _string(json['loaiNhanVien'] ?? json['LoaiNhanVien']),
        nguoiHuongDan: _string(json['nguoiHuongDan'] ?? json['NguoiHuongDan']),
        khoaPhong: _string(json['khoaPhong'] ?? json['KhoaPhong']),
        tenDot: _string(json['tenDot'] ?? json['TenDot']),
        ngayKetThuc: _date(json['ngayKetThuc'] ?? json['NgayKetThuc']),
        soNgayConLai: _int(json['soNgayConLai'] ?? json['SoNgayConLai']),
      );
}
