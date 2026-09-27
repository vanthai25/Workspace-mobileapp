class ThucHanhFileModel {
  final int idFile;
  final int? idNguoiThucHanhFile;
  final int? loaiFile;
  final String fileName;
  final String? fileType;
  final int fileSize;
  const ThucHanhFileModel({
    required this.idFile,
    this.idNguoiThucHanhFile,
    this.loaiFile,
    required this.fileName,
    this.fileType,
    this.fileSize = 0,
  });
  factory ThucHanhFileModel.fromJson(Map<String, dynamic> j) =>
      ThucHanhFileModel(
        idFile: _int(j['idFile']),
        idNguoiThucHanhFile: _nullableInt(j['idNguoiThucHanhFile']),
        loaiFile: _nullableInt(j['loaiFile']),
        fileName: j['fileName']?.toString() ?? 'file',
        fileType: j['fileType']?.toString(),
        fileSize: _int(j['fileSize']),
      );
}

class NguoiThucHanhModel {
  final int id;
  final String hoVaTen;
  final DateTime? ngaySinh;
  final bool? gioiTinh;
  final String? soCCCD,
      soDienThoai,
      email,
      truongDonVi,
      chuyenNganh,
      trinhDoChuyenMon;
  final String? ngayCapCCCDText,
      noiCapCCCD,
      diaChiThuongTru,
      noiOHienTai,
      queQuan,
      noiSinh,
      danToc,
      ghiChu;
  final int? loaiNhanVien;
  final String? tenLoaiNhanVien;
  final ThucHanhFileModel? anhDaiDien;
  final int soDotDaDangKy;
  final List<ThucHanhFileModel> files;
  final List<DangKyThucHanhModel> dangKys;
  const NguoiThucHanhModel({
    required this.id,
    required this.hoVaTen,
    this.ngaySinh,
    this.gioiTinh,
    this.soCCCD,
    this.soDienThoai,
    this.email,
    this.truongDonVi,
    this.chuyenNganh,
    this.trinhDoChuyenMon,
    this.ngayCapCCCDText,
    this.noiCapCCCD,
    this.diaChiThuongTru,
    this.noiOHienTai,
    this.queQuan,
    this.noiSinh,
    this.danToc,
    this.ghiChu,
    this.loaiNhanVien,
    this.tenLoaiNhanVien,
    this.anhDaiDien,
    this.soDotDaDangKy = 0,
    this.files = const [],
    this.dangKys = const [],
  });
  factory NguoiThucHanhModel.fromJson(Map<String, dynamic> j) =>
      NguoiThucHanhModel(
        id: _int(j['idNguoiThucHanh']),
        hoVaTen: j['hoVaTen']?.toString() ?? '',
        ngaySinh: _date(j['ngaySinh']),
        gioiTinh: _boolN(j['gioiTinh']),
        soCCCD: _str(j['soCCCD']),
        soDienThoai: _str(j['soDienThoai']),
        email: _str(j['email']),
        truongDonVi: _str(j['truongDonVi']),
        chuyenNganh: _str(j['chuyenNganh']),
        trinhDoChuyenMon: _str(j['trinhDoChuyenMon']),
        ngayCapCCCDText: _str(j['ngayCapCCCD']),
        noiCapCCCD: _str(j['noiCapCCCD']),
        diaChiThuongTru: _str(j['diaChiThuongTru']),
        noiOHienTai: _str(j['noiOHienTai']),
        queQuan: _str(j['queQuan']),
        noiSinh: _str(j['noiSinh']),
        danToc: _str(j['danToc']),
        ghiChu: _str(j['ghiChu']),
        loaiNhanVien: _nullableInt(j['loaiNhanVien']),
        tenLoaiNhanVien: _str(j['tenLoaiNhanVien']),
        anhDaiDien: _file(j['anhDaiDien']),
        soDotDaDangKy: _int(j['soDotDaDangKy']),
        files: _list(j['files'], ThucHanhFileModel.fromJson),
        dangKys: _list(j['dangKys'], DangKyThucHanhModel.fromJson),
      );
}

class DotThucHanhModel {
  final int id;
  final String maDot, tenDot;
  final String? moTa;
  final DateTime batDauDangKy, ketThucDangKy;
  final DateTime? ngayBatDauDuKien, ngayKetThucDuKien;
  final int? soLuongToiDa;
  final String publicToken;
  final int trangThai, soNguoiDangKy;
  final ThucHanhFileModel? fileQuyetDinh;
  const DotThucHanhModel({
    required this.id,
    required this.maDot,
    required this.tenDot,
    this.moTa,
    required this.batDauDangKy,
    required this.ketThucDangKy,
    this.ngayBatDauDuKien,
    this.ngayKetThucDuKien,
    this.soLuongToiDa,
    required this.publicToken,
    required this.trangThai,
    this.soNguoiDangKy = 0,
    this.fileQuyetDinh,
  });
  factory DotThucHanhModel.fromJson(Map<String, dynamic> j) => DotThucHanhModel(
    id: _int(j['idDotThucHanh']),
    maDot: j['maDot']?.toString() ?? '',
    tenDot: j['tenDot']?.toString() ?? '',
    moTa: _str(j['moTa']),
    batDauDangKy: _date(j['batDauDangKy']) ?? DateTime.now(),
    ketThucDangKy: _date(j['ketThucDangKy']) ?? DateTime.now(),
    ngayBatDauDuKien: _date(j['ngayBatDauDuKien']),
    ngayKetThucDuKien: _date(j['ngayKetThucDuKien']),
    soLuongToiDa: _nullableInt(j['soLuongToiDa']),
    publicToken: j['publicToken']?.toString() ?? '',
    trangThai: _int(j['trangThai']),
    soNguoiDangKy: _int(j['soNguoiDangKy']),
    fileQuyetDinh: _file(j['fileQuyetDinh']),
  );
}

class PhanCongThucHanhModel {
  final int id, idDangKy, idKhoaPhong;
  final String maSoNguoiHuongDan;
  final String? hoVaTenNguoiHuongDan, tenKhoaPhong, vaiTro, ghiChu;
  final DateTime ngayBatDau, ngayKetThuc;
  const PhanCongThucHanhModel({
    required this.id,
    required this.idDangKy,
    required this.idKhoaPhong,
    required this.maSoNguoiHuongDan,
    this.hoVaTenNguoiHuongDan,
    this.tenKhoaPhong,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    this.vaiTro,
    this.ghiChu,
  });
  factory PhanCongThucHanhModel.fromJson(Map<String, dynamic> j) =>
      PhanCongThucHanhModel(
        id: _int(j['idPhanCong']),
        idDangKy: _int(j['idDangKyThucHanh']),
        idKhoaPhong: _int(j['idKhoaPhong']),
        maSoNguoiHuongDan: j['maSoNguoiHuongDan']?.toString() ?? '',
        hoVaTenNguoiHuongDan: _str(j['hoVaTenNguoiHuongDan']),
        tenKhoaPhong: _str(j['tenKhoaPhong']),
        ngayBatDau: _date(j['ngayBatDau']) ?? DateTime.now(),
        ngayKetThuc: _date(j['ngayKetThuc']) ?? DateTime.now(),
        vaiTro: _str(j['vaiTro']),
        ghiChu: _str(j['ghiChu']),
      );
}

class DangKyThucHanhModel {
  final int id, idDot, idNguoi, nguonDangKy, soPhanCong, tinhTrangThucHanh;
  final String maDot, tenDot, hoVaTen, maTraCuu;
  final String? soCCCD, soDienThoai, noiDungDangKy, lyDoTuChoi;
  final String? khoaHoc, hocKy;
  final DateTime ngayDangKy;
  final DateTime? ngayBatDauThucHanh, ngayKetThucThucHanh;
  final DateTime? thoiGianHocTuNgay, thoiGianHocDenNgay;
  final List<PhanCongThucHanhModel> phanCongs;
  const DangKyThucHanhModel({
    required this.id,
    required this.idDot,
    required this.idNguoi,
    required this.maDot,
    required this.tenDot,
    required this.hoVaTen,
    required this.maTraCuu,
    required this.ngayDangKy,
    required this.nguonDangKy,
    this.tinhTrangThucHanh = 0,
    this.soCCCD,
    this.soDienThoai,
    this.noiDungDangKy,
    this.lyDoTuChoi,
    this.soPhanCong = 0,
    this.ngayBatDauThucHanh,
    this.ngayKetThucThucHanh,
    this.thoiGianHocTuNgay,
    this.thoiGianHocDenNgay,
    this.khoaHoc,
    this.hocKy,
    this.phanCongs = const [],
  });
  factory DangKyThucHanhModel.fromJson(Map<String, dynamic> j) =>
      DangKyThucHanhModel(
        id: _int(j['idDangKyThucHanh']),
        idDot: _int(j['idDotThucHanh']),
        idNguoi: _int(j['idNguoiThucHanh']),
        maDot: j['maDot']?.toString() ?? '',
        tenDot: j['tenDot']?.toString() ?? '',
        hoVaTen: j['hoVaTen']?.toString() ?? '',
        maTraCuu: j['maTraCuu']?.toString() ?? '',
        ngayDangKy: _date(j['ngayDangKy']) ?? DateTime.now(),
        nguonDangKy: _int(j['nguonDangKy']),
        tinhTrangThucHanh: _int(j['tinhTrangThucHanh']),
        soCCCD: _str(j['soCCCD']),
        soDienThoai: _str(j['soDienThoai']),
        noiDungDangKy: _str(j['noiDungDangKy']),
        lyDoTuChoi: _str(j['lyDoTuChoi']),
        soPhanCong: _int(j['soPhanCong']),
        ngayBatDauThucHanh: _date(j['ngayBatDauThucHanh']),
        ngayKetThucThucHanh: _date(j['ngayKetThucThucHanh']),
        thoiGianHocTuNgay: _date(j['thoiGianHocTuNgay']),
        thoiGianHocDenNgay: _date(j['thoiGianHocDenNgay']),
        khoaHoc: _str(j['khoaHoc']),
        hocKy: _str(j['hocKy']),
        phanCongs: _list(j['phanCongs'], PhanCongThucHanhModel.fromJson),
      );
}

class TraCuuThucHanhModel {
  final String maTraCuu, tenDot, hoVaTen, email;
  final String? soCCCD, soDienThoai, truongDonVi, chuyenNganh, trinhDoChuyenMon;
  final DateTime ngayDangKy;
  final DateTime? ngaySinh, ngayBatDauThucHanh, ngayKetThucThucHanh;
  final bool? gioiTinh;
  final int tinhTrangThucHanh;
  final List<PhanCongThucHanhModel> phanCongs;

  const TraCuuThucHanhModel({
    required this.maTraCuu,
    required this.tenDot,
    required this.hoVaTen,
    required this.email,
    required this.ngayDangKy,
    this.soCCCD,
    this.soDienThoai,
    this.truongDonVi,
    this.chuyenNganh,
    this.trinhDoChuyenMon,
    this.ngaySinh,
    this.gioiTinh,
    this.tinhTrangThucHanh = 0,
    this.ngayBatDauThucHanh,
    this.ngayKetThucThucHanh,
    this.phanCongs = const [],
  });

  factory TraCuuThucHanhModel.fromJson(Map<String, dynamic> j) =>
      TraCuuThucHanhModel(
        maTraCuu: j['maTraCuu']?.toString() ?? '',
        tenDot: j['tenDot']?.toString() ?? '',
        hoVaTen: j['hoVaTen']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        ngayDangKy: _date(j['ngayDangKy']) ?? DateTime.now(),
        ngaySinh: _date(j['ngaySinh']),
        gioiTinh: _boolN(j['gioiTinh']),
        soCCCD: _str(j['soCCCD']),
        soDienThoai: _str(j['soDienThoai']),
        truongDonVi: _str(j['truongDonVi']),
        chuyenNganh: _str(j['chuyenNganh']),
        trinhDoChuyenMon: _str(j['trinhDoChuyenMon']),
        tinhTrangThucHanh: _int(j['tinhTrangThucHanh']),
        ngayBatDauThucHanh: _date(j['ngayBatDauThucHanh']),
        ngayKetThucThucHanh: _date(j['ngayKetThucThucHanh']),
        phanCongs: _list(j['phanCongs'], PhanCongThucHanhModel.fromJson),
      );
}

class ThucHanhPage<T> {
  final List<T> items;
  final int page, totalPages, totalCount;
  const ThucHanhPage({
    this.items = const [],
    this.page = 1,
    this.totalPages = 0,
    this.totalCount = 0,
  });
}

int _int(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
int? _nullableInt(dynamic v) => v == null ? null : int.tryParse('$v');
String? _str(dynamic v) =>
    v == null || v.toString().trim().isEmpty ? null : v.toString();
DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());
bool? _boolN(dynamic v) => v is bool
    ? v
    : v == null
    ? null
    : v.toString() == 'true';
ThucHanhFileModel? _file(dynamic v) =>
    v is Map ? ThucHanhFileModel.fromJson(Map<String, dynamic>.from(v)) : null;
List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) parse) => v is List
    ? v
          .whereType<Map>()
          .map((e) => parse(Map<String, dynamic>.from(e)))
          .toList()
    : <T>[];
