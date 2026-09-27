class LopDaoTaoV2Model {
  final int idLopDaoTao;
  final String tenLopDaoTao;

  final double? soTiet;

  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;

  final int? idHinhThucDaoTao;
  final String? tenHinhThucDaoTao;

  final int? idNguonKinhPhi;
  final String? tenNguonKinhPhi;

  final double? kinhPhi;

  final int? idLoaiHinhDaoTao;
  final String? tenLoaiHinhDaoTao;

  final int? chuKy;

  final int? idFile;
  final String? fileName;
  final String? fileType;

  final DateTime? batDauDangKy;
  final DateTime? ketThucDangKy;

  final String? ghiChu;
  final String? donViDaoTao;
  final String? tenChungChi;

  final String? gioBatDauVanTayVao;
  final String? gioKetThucVanTayVao;
  final String? gioBatDauVanTayRa;
  final String? gioKetThucVanTayRa;

  final int soNguoiDangKy;

  final bool isDaDangKy;
  final bool isMoDangKy;
  final bool isHetHanDangKy;
  final bool isChuaMoDangKy;

  final bool canEdit;
  final bool canDelete;
  final String? baoCaoVien;
  final String? donViGiangDay;

  final bool isOnline;
  final bool isDangKyOnline;
  final String? kp;
  final DateTime? ngayInDiemDanh;
  final String? thoiGianDetails;
  final String? diaDiem;
  final String? tpThamDu;
  final int phamViDaoTao;

  final int? idKhoaPhong;
  final List<int> idKhoaPhongs;
  final String? tenKhoaPhong;

  final String? maNguoiTao;
  final bool isNguoiTao;

  final bool canPrintExport;
  final bool canBoSungHocVien;
  final bool canTaiLieu;

  final bool canXacNhanHocVien;
  final bool canDashboard;
  final bool canCapChungChi;
  const LopDaoTaoV2Model({
    required this.idLopDaoTao,
    required this.tenLopDaoTao,
    this.soTiet,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.idHinhThucDaoTao,
    this.tenHinhThucDaoTao,
    this.idNguonKinhPhi,
    this.tenNguonKinhPhi,
    this.kinhPhi,
    this.idLoaiHinhDaoTao,
    this.tenLoaiHinhDaoTao,
    this.chuKy,
    this.idFile,
    this.fileName,
    this.fileType,
    this.batDauDangKy,
    this.ketThucDangKy,
    this.ghiChu,
    this.donViDaoTao,
    this.tenChungChi,
    this.gioBatDauVanTayVao,
    this.gioKetThucVanTayVao,
    this.gioBatDauVanTayRa,
    this.gioKetThucVanTayRa,
    this.soNguoiDangKy = 0,
    this.isDaDangKy = false,
    this.isMoDangKy = false,
    this.isHetHanDangKy = false,
    this.isChuaMoDangKy = false,
    this.canEdit = false,
    this.canDelete = false,
    this.baoCaoVien,
    this.donViGiangDay,
    this.isOnline = false,
    this.isDangKyOnline = false,
    this.kp,
    this.ngayInDiemDanh,
    this.thoiGianDetails,
    this.diaDiem,
    this.tpThamDu,
    this.phamViDaoTao = 1,

    this.idKhoaPhong,
    this.idKhoaPhongs = const [],
    this.tenKhoaPhong,

    this.maNguoiTao,
    this.isNguoiTao = false,

    this.canPrintExport = false,
    this.canBoSungHocVien = false,
    this.canTaiLieu = false,

    this.canXacNhanHocVien = false,
    this.canDashboard = false,
    this.canCapChungChi = false,
  });

  factory LopDaoTaoV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return LopDaoTaoV2Model(
      idLopDaoTao:
          _toInt(json['idLopDaoTao']) ?? 0,

      tenLopDaoTao:
          json['tenLopDaoTao']?.toString() ?? '',

      soTiet:
          _toDouble(json['soTiet']),

      ngayBatDau:
          _toDate(json['ngayBatDau']),

      ngayKetThuc:
          _toDate(json['ngayKetThuc']),

      idHinhThucDaoTao:
          _toInt(json['idHinhThucDaoTao']),

      tenHinhThucDaoTao:
          json['tenHinhThucDaoTao']?.toString(),

      idNguonKinhPhi:
          _toInt(json['idNguonKinhPhi']),

      tenNguonKinhPhi:
          json['tenNguonKinhPhi']?.toString(),

      kinhPhi:
          _toDouble(json['kinhPhi']),

      idLoaiHinhDaoTao:
          _toInt(json['idLoaiHinhDaoTao']),

      tenLoaiHinhDaoTao:
          json['tenLoaiHinhDaoTao']?.toString(),

      chuKy:
          _toInt(json['chuKy']),

      idFile:
          _toInt(json['idFile']),

      fileName:
          json['fileName']?.toString(),

      fileType:
          json['fileType']?.toString(),

      batDauDangKy:
          _toDate(json['batDauDangKy']),

      ketThucDangKy:
          _toDate(json['ketThucDangKy']),

      ghiChu:
          json['ghiChu']?.toString(),

      donViDaoTao:
          json['donViDaoTao']?.toString(),

      tenChungChi:
          json['tenChungChi']?.toString(),

      gioBatDauVanTayVao:
          json['gioBatDauVanTayVao']?.toString(),

      gioKetThucVanTayVao:
          json['gioKetThucVanTayVao']?.toString(),

      gioBatDauVanTayRa:
          json['gioBatDauVanTayRa']?.toString(),

      gioKetThucVanTayRa:
          json['gioKetThucVanTayRa']?.toString(),

      soNguoiDangKy:
          _toInt(json['soNguoiDangKy']) ?? 0,

      isDaDangKy:
          _toBool(json['isDaDangKy']),

      isMoDangKy:
          _toBool(json['isMoDangKy']),

      isHetHanDangKy:
          _toBool(json['isHetHanDangKy']),

      isChuaMoDangKy:
          _toBool(json['isChuaMoDangKy']),

      canEdit:
          _toBool(json['canEdit']),

      canDelete:
          _toBool(json['canDelete']),
          baoCaoVien:
      json['baoCaoVien']?.toString(),

      donViGiangDay:
          json['donViGiangDay']?.toString(),

      isOnline:
          _toBool(json['isOnline']),

      isDangKyOnline:
          _toBool(json['isDangKyOnline']),
          kp:
      json['kp']?.toString(),

      ngayInDiemDanh:
          _toDate(
        json['ngayInDiemDanh'],
      ),

      thoiGianDetails:
          json['thoiGianDetails']
              ?.toString(),

      diaDiem:
          json['diaDiem']?.toString(),

      tpThamDu:
          json['tpThamDu']?.toString(),
      phamViDaoTao:
          _toInt(
            json['phamViDaoTao'],
          ) ??
          1,

      idKhoaPhongs: _parseKhoaPhongIds(json),

      idKhoaPhong:
          _toInt(
            json['idKhoaPhong'],
          ),

      tenKhoaPhong:
          json['tenKhoaPhong']
              ?.toString(),

      maNguoiTao:
          json['maNguoiTao']
              ?.toString(),

      isNguoiTao:
          _toBool(
            json['isNguoiTao'],
          ),

      canPrintExport:
          _toBool(
            json['canPrintExport'],
          ),

      canBoSungHocVien:
          _toBool(
            json['canBoSungHocVien'],
          ),

      canTaiLieu:
          _toBool(
            json['canTaiLieu'],
          ),

      canXacNhanHocVien:
          _toBool(
            json['canXacNhanHocVien'],
          ),

      canDashboard:
          _toBool(
            json['canDashboard'],
          ),

      canCapChungChi:
          _toBool(
            json['canCapChungChi'],
          ),
    );
  }
}


// ============================================================
// DANH MỤC
// ============================================================

class DaoTaoDanhMucItemV2Model {
  final int id;
  final String ten;

  const DaoTaoDanhMucItemV2Model({
    required this.id,
    required this.ten,
  });

  factory DaoTaoDanhMucItemV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return DaoTaoDanhMucItemV2Model(
      id: _toInt(json['id']) ?? 0,
      ten: json['ten']?.toString() ?? '',
    );
  }
}


class DaoTaoDanhMucV2Model {
  final List<DaoTaoDanhMucItemV2Model> khoaPhongs;
  final int? idKhoaPhongHienTai;
  final List<DaoTaoDanhMucItemV2Model>
      hinhThucDaoTaos;

  final List<DaoTaoDanhMucItemV2Model>
      loaiHinhDaoTaos;

  final List<DaoTaoDanhMucItemV2Model>
      nguonKinhPhis;

  const DaoTaoDanhMucV2Model({
    this.khoaPhongs = const [],
    this.idKhoaPhongHienTai,
    this.hinhThucDaoTaos = const [],
    this.loaiHinhDaoTaos = const [],
    this.nguonKinhPhis = const [],
  });

  factory DaoTaoDanhMucV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    List<DaoTaoDanhMucItemV2Model> parseList(
      dynamic value,
    ) {
      if (value is! List) {
        return [];
      }

      return value
          .whereType<Map>()
          .map(
            (e) =>
                DaoTaoDanhMucItemV2Model.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    return DaoTaoDanhMucV2Model(
      khoaPhongs: parseList(json['khoaPhongs']),
      idKhoaPhongHienTai: _toInt(json['idKhoaPhongHienTai']),
      hinhThucDaoTaos:
          parseList(json['hinhThucDaoTaos']),

      loaiHinhDaoTaos:
          parseList(json['loaiHinhDaoTaos']),

      nguonKinhPhis:
          parseList(json['nguonKinhPhis']),
    );
  }
}


// ============================================================
// FILE UPLOAD
// ============================================================

class DaoTaoUploadedFileV2Model {
  final int idFile;
  final String? fileName;
  final String? fileType;

  const DaoTaoUploadedFileV2Model({
    required this.idFile,
    this.fileName,
    this.fileType,
  });

  factory DaoTaoUploadedFileV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return DaoTaoUploadedFileV2Model(
      idFile:
          _toInt(json['idFile']) ?? 0,

      fileName:
          json['fileName']?.toString(),

      fileType:
          json['fileType']?.toString(),
    );
  }
}


// ============================================================
// HELPERS
// ============================================================

List<int> _parseKhoaPhongIds(Map<String, dynamic> json) {
  if ((_toInt(json['phamViDaoTao']) ?? 1) != 2) return [];
  final raw = json['idKhoaPhongs'];
  final ids = <int>{
    if (raw is List) ...raw.map(_toInt).whereType<int>(),
    if (_toInt(json['idKhoaPhong']) case final int id) id,
  };
  return ids.where((id) => id > 0).toList()..sort();
}

int? _toInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  );
}


double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString(),
  );
}


bool _toBool(dynamic value) {
  if (value == null) {
    return false;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final text =
      value.toString().toLowerCase();

  return text == 'true' ||
      text == '1';
}


DateTime? _toDate(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  final text =
      value.toString().trim();

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}
class DaoTaoKhoaPhongDashboardV2Model {
  final int idKhoaPhong;
  final String tenKhoaPhong;

  final int tongNhanSu;
  final int soNguoiDangKy;

  final double tyLeThamGia;

  final bool daCoDangKy;
  final String trangThai;

  const DaoTaoKhoaPhongDashboardV2Model({
    required this.idKhoaPhong,
    required this.tenKhoaPhong,
    required this.tongNhanSu,
    required this.soNguoiDangKy,
    required this.tyLeThamGia,
    required this.daCoDangKy,
    required this.trangThai,
  });

  factory DaoTaoKhoaPhongDashboardV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return DaoTaoKhoaPhongDashboardV2Model(
      idKhoaPhong:
          _toInt(json['idKhoaPhong']) ?? 0,

      tenKhoaPhong:
          json['tenKhoaPhong']?.toString() ?? '',

      tongNhanSu:
          _toInt(json['tongNhanSu']) ?? 0,

      soNguoiDangKy:
          _toInt(json['soNguoiDangKy']) ?? 0,

      tyLeThamGia:
          _toDouble(json['tyLeThamGia']) ?? 0,

      daCoDangKy:
          _toBool(json['daCoDangKy']),

      trangThai:
          json['trangThai']?.toString() ?? '',
    );
  }
}


class DaoTaoDashboardV2Model {
  final int idLopDaoTao;
  final String tenLopDaoTao;

  final int tongNguoiDangKy;
  final int tongNhanSu;
  final int tongDangKyTheoKhoa;

  final int soDangKyKhongXacDinhKhoa;

  final double tyLeThamGia;

  final int soKhoaCoDangKy;
  final int soKhoaChuaDangKy;

  final List<DaoTaoKhoaPhongDashboardV2Model>
      khoaPhongs;

  const DaoTaoDashboardV2Model({
    required this.idLopDaoTao,
    required this.tenLopDaoTao,
    required this.tongNguoiDangKy,
    required this.tongNhanSu,
    required this.tongDangKyTheoKhoa,
    required this.soDangKyKhongXacDinhKhoa,
    required this.tyLeThamGia,
    required this.soKhoaCoDangKy,
    required this.soKhoaChuaDangKy,
    required this.khoaPhongs,
  });

  factory DaoTaoDashboardV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawKhoaPhongs =
        json['khoaPhongs'];

    final khoaPhongs =
        rawKhoaPhongs is List
            ? rawKhoaPhongs
                .whereType<Map>()
                .map(
                  (e) =>
                      DaoTaoKhoaPhongDashboardV2Model
                          .fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
            : <DaoTaoKhoaPhongDashboardV2Model>[];

    return DaoTaoDashboardV2Model(
      idLopDaoTao:
          _toInt(json['idLopDaoTao']) ?? 0,

      tenLopDaoTao:
          json['tenLopDaoTao']?.toString() ?? '',

      tongNguoiDangKy:
          _toInt(json['tongNguoiDangKy']) ?? 0,

      tongNhanSu:
          _toInt(json['tongNhanSu']) ?? 0,

      tongDangKyTheoKhoa:
          _toInt(json['tongDangKyTheoKhoa']) ?? 0,

      soDangKyKhongXacDinhKhoa:
          _toInt(
            json['soDangKyKhongXacDinhKhoa'],
          ) ??
          0,

      tyLeThamGia:
          _toDouble(json['tyLeThamGia']) ?? 0,

      soKhoaCoDangKy:
          _toInt(json['soKhoaCoDangKy']) ?? 0,

      soKhoaChuaDangKy:
          _toInt(json['soKhoaChuaDangKy']) ?? 0,

      khoaPhongs:
          khoaPhongs,
    );
  }
}

// ============================================================
// CHẤM CÔNG ĐÀO TẠO
// ============================================================

class DaoTaoChamCongNgayV2Model {
  final DateTime? ngay;

  final bool duVao;
  final bool duRa;
  final bool duChamCong;

  final DateTime? gioVaoHopLe;
  final DateTime? gioRaHopLe;

  final List<DateTime> tatCaGioCham;

  const DaoTaoChamCongNgayV2Model({
    this.ngay,
    this.duVao = false,
    this.duRa = false,
    this.duChamCong = false,
    this.gioVaoHopLe,
    this.gioRaHopLe,
    this.tatCaGioCham = const [],
  });

  factory DaoTaoChamCongNgayV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawTimes =
        json['tatCaGioCham'];

    final times =
        rawTimes is List
            ? rawTimes
                .map(
                  (e) => _toDate(e),
                )
                .whereType<DateTime>()
                .toList()
            : <DateTime>[];

    return DaoTaoChamCongNgayV2Model(
      ngay:
          _toDate(json['ngay']),

      duVao:
          _toBool(json['duVao']),

      duRa:
          _toBool(json['duRa']),

      duChamCong:
          _toBool(json['duChamCong']),

      gioVaoHopLe:
          _toDate(json['gioVaoHopLe']),

      gioRaHopLe:
          _toDate(json['gioRaHopLe']),

      tatCaGioCham:
          times,
    );
  }
}


// ============================================================
// CHẤM CÔNG THEO NGƯỜI
// ============================================================

class DaoTaoChamCongNguoiV2Model {
  final String maSo;
  final String? hoVaTen;

  final int? idKhoaPhong;
  final String? tenKhoaPhong;

  final bool daDangKy;
  final bool duChamCong;

  final List<DaoTaoChamCongNgayV2Model>
      chiTietNgay;

  const DaoTaoChamCongNguoiV2Model({
    required this.maSo,
    this.hoVaTen,
    this.idKhoaPhong,
    this.tenKhoaPhong,
    this.daDangKy = false,
    this.duChamCong = false,
    this.chiTietNgay = const [],
  });

  factory DaoTaoChamCongNguoiV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw =
        json['chiTietNgay'];

    final days =
        raw is List
            ? raw
                .whereType<Map>()
                .map(
                  (e) =>
                      DaoTaoChamCongNgayV2Model.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
            : <DaoTaoChamCongNgayV2Model>[];

    return DaoTaoChamCongNguoiV2Model(
      maSo:
          json['maSo']?.toString() ?? '',

      hoVaTen:
          json['hoVaTen']?.toString(),

      idKhoaPhong:
          _toInt(json['idKhoaPhong']),

      tenKhoaPhong:
          json['tenKhoaPhong']?.toString(),

      daDangKy:
          _toBool(json['daDangKy']),

      duChamCong:
          _toBool(json['duChamCong']),

      chiTietNgay:
          days,
    );
  }
}


// ============================================================
// TẤT CẢ GIỜ CHẤM
// ============================================================

class DaoTaoGioChamV2Model {
  final String badgeNumber;
  final String maSo;

  final String? hoVaTen;

  final int? idKhoaPhong;
  final String? tenKhoaPhong;

  final DateTime? checkTime;

  final int? machineNumber;

  final bool daDangKy;

  final String phanLoai;

  const DaoTaoGioChamV2Model({
    required this.badgeNumber,
    required this.maSo,
    this.hoVaTen,
    this.idKhoaPhong,
    this.tenKhoaPhong,
    this.checkTime,
    this.machineNumber,
    this.daDangKy = false,
    required this.phanLoai,
  });

  factory DaoTaoGioChamV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return DaoTaoGioChamV2Model(
      badgeNumber:
          json['badgeNumber']?.toString() ?? '',

      maSo:
          json['maSo']?.toString() ?? '',

      hoVaTen:
          json['hoVaTen']?.toString(),

      idKhoaPhong:
          _toInt(json['idKhoaPhong']),

      tenKhoaPhong:
          json['tenKhoaPhong']?.toString(),

      checkTime:
          _toDate(json['checkTime']),

      machineNumber:
          _toInt(json['machineNumber']),

      daDangKy:
          _toBool(json['daDangKy']),

      phanLoai:
          json['phanLoai']?.toString() ?? '',
    );
  }
}


// ============================================================
// BÁO CÁO CHẤM CÔNG
// ============================================================

class DaoTaoChamCongBaoCaoV2Model {
  final int idLopDaoTao;
  final String tenLopDaoTao;

  final int tongDangKy;
  final int soDangKyDu;
  final int soDangKyThieu;
  final int soKhongDangKyCoCham;

  final List<DaoTaoChamCongNguoiV2Model>
      dangKyDu;

  final List<DaoTaoChamCongNguoiV2Model>
      dangKyThieu;

  final List<DaoTaoChamCongNguoiV2Model>
      khongDangKyCoCham;

  final List<DaoTaoGioChamV2Model>
      tatCaGioCham;

  const DaoTaoChamCongBaoCaoV2Model({
    required this.idLopDaoTao,
    required this.tenLopDaoTao,
    this.tongDangKy = 0,
    this.soDangKyDu = 0,
    this.soDangKyThieu = 0,
    this.soKhongDangKyCoCham = 0,
    this.dangKyDu = const [],
    this.dangKyThieu = const [],
    this.khongDangKyCoCham = const [],
    this.tatCaGioCham = const [],
  });

  factory DaoTaoChamCongBaoCaoV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    List<DaoTaoChamCongNguoiV2Model>
        parseNguoiList(
      dynamic value,
    ) {
      if (value is! List) {
        return [];
      }

      return value
          .whereType<Map>()
          .map(
            (e) =>
                DaoTaoChamCongNguoiV2Model.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    List<DaoTaoGioChamV2Model>
        parseGioList(
      dynamic value,
    ) {
      if (value is! List) {
        return [];
      }

      return value
          .whereType<Map>()
          .map(
            (e) =>
                DaoTaoGioChamV2Model.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    return DaoTaoChamCongBaoCaoV2Model(
      idLopDaoTao:
          _toInt(json['idLopDaoTao']) ?? 0,

      tenLopDaoTao:
          json['tenLopDaoTao']?.toString() ?? '',

      tongDangKy:
          _toInt(json['tongDangKy']) ?? 0,

      soDangKyDu:
          _toInt(json['soDangKyDu']) ?? 0,

      soDangKyThieu:
          _toInt(json['soDangKyThieu']) ?? 0,

      soKhongDangKyCoCham:
          _toInt(
            json['soKhongDangKyCoCham'],
          ) ??
          0,

      dangKyDu:
          parseNguoiList(
        json['dangKyDu'],
      ),

      dangKyThieu:
          parseNguoiList(
        json['dangKyThieu'],
      ),

      khongDangKyCoCham:
          parseNguoiList(
        json['khongDangKyCoCham'],
      ),

      tatCaGioCham:
          parseGioList(
        json['tatCaGioCham'],
      ),
    );
  }
}


// ============================================================
// NGƯỜI ĐĂNG KÝ - PHỤC VỤ CẤP CME / CHỨNG CHỈ
// ============================================================

class DaoTaoNguoiDangKyV2Model {
  final int idDangKyDaoTao;

  final String maSo;
  final String? hoVaTen;

  final int? idKhoaPhong;
  final String? tenKhoaPhong;

  final DateTime? ngayDangKy;

  final bool daCapCme;
  final bool daCapChungChi;
  final bool isBoSungSau;
  final bool isDangKyOnline;
  final bool? isHopLeDaoTao;
  const DaoTaoNguoiDangKyV2Model({
    required this.idDangKyDaoTao,
    required this.maSo,
    this.hoVaTen,
    this.idKhoaPhong,
    this.tenKhoaPhong,
    this.ngayDangKy,
    this.daCapCme = false,
    this.daCapChungChi = false,
    this.isBoSungSau = false,
    this.isDangKyOnline = false,
    this.isHopLeDaoTao,
  });

  factory DaoTaoNguoiDangKyV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return DaoTaoNguoiDangKyV2Model(
      idDangKyDaoTao:
          _toInt(json['idDangKyDaoTao']) ?? 0,

      maSo:
          json['maSo']?.toString() ?? '',

      hoVaTen:
          json['hoVaTen']?.toString(),

      idKhoaPhong:
          _toInt(json['idKhoaPhong']),

      tenKhoaPhong:
          json['tenKhoaPhong']?.toString(),

      ngayDangKy:
          _toDate(json['ngayDangKy']),

      daCapCme:
          _toBool(json['daCapCme']),

      daCapChungChi:
          _toBool(json['daCapChungChi']),
          isBoSungSau:
      _toBool(json['isBoSungSau']),

      isDangKyOnline:
          _toBool(json['isDangKyOnline']),
          isHopLeDaoTao:
      json['isHopLeDaoTao'] == null
        ? null
        : _toBool(
            json['isHopLeDaoTao'],
          ),
    );
  }
}


// ============================================================
// KẾT QUẢ CẤP CME / CHỨNG CHỈ
// ============================================================

class CapChungChiDaoTaoResultV2Model {
  final int soNguoiDuocCap;
  final int soNguoiBoQua;

  final List<String> daCap;
  final List<String> boQua;

  const CapChungChiDaoTaoResultV2Model({
    this.soNguoiDuocCap = 0,
    this.soNguoiBoQua = 0,
    this.daCap = const [],
    this.boQua = const [],
  });

  factory CapChungChiDaoTaoResultV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    List<String> parseStrings(
      dynamic value,
    ) {
      if (value is! List) {
        return [];
      }

      return value
          .map(
            (e) => e.toString(),
          )
          .toList();
    }

    return CapChungChiDaoTaoResultV2Model(
      soNguoiDuocCap:
          _toInt(json['soNguoiDuocCap']) ?? 0,

      soNguoiBoQua:
          _toInt(json['soNguoiBoQua']) ?? 0,

      daCap:
          parseStrings(
        json['daCap'],
      ),

      boQua:
          parseStrings(
        json['boQua'],
      ),
    );
  }
}
class LopDaoTaoFileV2Model {
  final int id;
  final int idLopDaoTao;
  final int idFile;

  final String fileName;
  final String? fileType;

  final int fileSize;
  final int? stt;
  final DateTime? ngayTao;

  const LopDaoTaoFileV2Model({
    required this.id,
    required this.idLopDaoTao,
    required this.idFile,
    required this.fileName,
    this.fileType,
    required this.fileSize,
    this.stt,
    this.ngayTao,
  });

  factory LopDaoTaoFileV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return LopDaoTaoFileV2Model(
      id:
          (json['id'] as num?)?.toInt() ??
          0,

      idLopDaoTao:
          (json['idLopDaoTao'] as num?)
                  ?.toInt() ??
              0,

      idFile:
          (json['idFile'] as num?)
                  ?.toInt() ??
              0,

      fileName:
          json['fileName']
                  ?.toString() ??
              '',

      fileType:
          json['fileType']
              ?.toString(),

      fileSize:
          (json['fileSize'] as num?)
                  ?.toInt() ??
              0,

      stt:
          (json['stt'] as num?)
              ?.toInt(),

      ngayTao:
          json['ngayTao'] == null
              ? null
              : DateTime.tryParse(
                  json['ngayTao']
                      .toString(),
                ),
    );
  }
}
class DaoTaoThongTinOnlineV2Model {
  final int idLopDaoTao;
  final String tenLopDaoTao;

  final String? linkZoom;
  final String? linkChat;
  final String? zoomID;
  final String? zoomPasscode;

  const DaoTaoThongTinOnlineV2Model({
    required this.idLopDaoTao,
    required this.tenLopDaoTao,
    this.linkZoom,
    this.linkChat,
    this.zoomID,
    this.zoomPasscode,
  });

  factory DaoTaoThongTinOnlineV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return DaoTaoThongTinOnlineV2Model(
      idLopDaoTao:
          _toInt(json['idLopDaoTao']) ?? 0,

      tenLopDaoTao:
          json['tenLopDaoTao']?.toString() ?? '',

      linkZoom:
          json['linkZoom']?.toString(),

      linkChat:
          json['linkChat']?.toString(),

      zoomID:
          json['zoomID']?.toString(),

      zoomPasscode:
          json['zoomPasscode']?.toString(),
    );
  }
}


// ============================================================
// NHÂN VIÊN CHƯA ĐĂNG KÝ
// ============================================================

class DaoTaoNhanVienChuaDangKyV2Model {
  final String maSo;
  final String? hoVaTen;

  final int? idKhoaPhong;
  final String? tenKhoaPhong;

  const DaoTaoNhanVienChuaDangKyV2Model({
    required this.maSo,
    this.hoVaTen,
    this.idKhoaPhong,
    this.tenKhoaPhong,
  });

  factory DaoTaoNhanVienChuaDangKyV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return DaoTaoNhanVienChuaDangKyV2Model(
      maSo:
          json['maSo']?.toString() ?? '',

      hoVaTen:
          json['hoVaTen']?.toString(),

      idKhoaPhong:
          _toInt(json['idKhoaPhong']),

      tenKhoaPhong:
          json['tenKhoaPhong']?.toString(),
    );
  }
}


// ============================================================
// KẾT QUẢ BỔ SUNG HỌC VIÊN
// ============================================================

class BoSungNguoiDangKyResultV2Model {
  final int soNguoiBoSung;

  final List<String> daBoSung;
  final List<String> daTonTai;
  final List<String> khongHopLe;

  const BoSungNguoiDangKyResultV2Model({
    this.soNguoiBoSung = 0,
    this.daBoSung = const [],
    this.daTonTai = const [],
    this.khongHopLe = const [],
  });

  factory BoSungNguoiDangKyResultV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    List<String> parseList(
      dynamic value,
    ) {
      if (value is! List) {
        return [];
      }

      return value
          .map((e) => e.toString())
          .toList();
    }

    return BoSungNguoiDangKyResultV2Model(
      soNguoiBoSung:
          _toInt(json['soNguoiBoSung']) ?? 0,

      daBoSung:
          parseList(json['daBoSung']),

      daTonTai:
          parseList(json['daTonTai']),

      khongHopLe:
          parseList(json['khongHopLe']),
    );
  }
}
class DaoTaoXacNhanHocVienV2Model {
  final int idDangKyDaoTao;

  final String maSo;
  final String? hoVaTen;

  final int? idKhoaPhong;
  final String? tenKhoaPhong;

  final bool isBoSungSau;
  final bool isDangKyOnline;

  final bool? isHopLeDaoTao;

  final bool duChamCong;

  final bool macDinhHopLe;

  final String trangThaiThamDu;

  const DaoTaoXacNhanHocVienV2Model({
    required this.idDangKyDaoTao,
    required this.maSo,
    this.hoVaTen,
    this.idKhoaPhong,
    this.tenKhoaPhong,
    this.isBoSungSau = false,
    this.isDangKyOnline = false,
    this.isHopLeDaoTao,
    this.duChamCong = false,
    this.macDinhHopLe = false,
    this.trangThaiThamDu = '',
  });

  factory DaoTaoXacNhanHocVienV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return DaoTaoXacNhanHocVienV2Model(
      idDangKyDaoTao:
          _toInt(json['idDangKyDaoTao']) ?? 0,

      maSo:
          json['maSo']?.toString() ?? '',

      hoVaTen:
          json['hoVaTen']?.toString(),

      idKhoaPhong:
          _toInt(json['idKhoaPhong']),

      tenKhoaPhong:
          json['tenKhoaPhong']?.toString(),

      isBoSungSau:
          _toBool(json['isBoSungSau']),

      isDangKyOnline:
          _toBool(json['isDangKyOnline']),

      isHopLeDaoTao:
          json['isHopLeDaoTao'] == null
              ? null
              : _toBool(
                  json['isHopLeDaoTao'],
                ),

      duChamCong:
          _toBool(json['duChamCong']),

      macDinhHopLe:
          _toBool(json['macDinhHopLe']),

      trangThaiThamDu:
          json['trangThaiThamDu']
                  ?.toString() ??
              '',
    );
  }
}
class DaoTaoInDiemDanhNhanVienV2Model {
  final int stt;

  final String maSo;
  final String hoVaTen;

  final DateTime? namSinh;

  final int? idKhoaPhong;
  final String? tenKhoaPhong;

  const DaoTaoInDiemDanhNhanVienV2Model({
    this.stt = 0,
    required this.maSo,
    required this.hoVaTen,
    this.namSinh,
    this.idKhoaPhong,
    this.tenKhoaPhong,
  });

  factory DaoTaoInDiemDanhNhanVienV2Model
      .fromJson(
    Map<String, dynamic> json,
  ) {
    return DaoTaoInDiemDanhNhanVienV2Model(
      stt:
          _toInt(
            json['stt'] ??
                json['sTT'],
          ) ??
          0,

      maSo:
          json['maSo']
                  ?.toString() ??
              '',

      hoVaTen:
          json['hoVaTen']
                  ?.toString() ??
              '',

      namSinh:
          _toDate(
        json['namSinh'],
      ),

      idKhoaPhong:
          _toInt(
        json['idKhoaPhong'],
      ),

      tenKhoaPhong:
          json['tenKhoaPhong']
              ?.toString(),
    );
  }
}


class DaoTaoInDiemDanhV2Model {
  final int idLopDaoTao;

  final String tenLopDaoTao;

  final String loaiIn;

  final DateTime ngayInDiemDanh;


  final String? kp;

  final String? baoCaoVien;

  final String? thoiGianDetails;

  final String? diaDiem;

  final String? tpThamDu;


  final List<
      DaoTaoInDiemDanhNhanVienV2Model>
      danhSach;


  const DaoTaoInDiemDanhV2Model({
    required this.idLopDaoTao,
    required this.tenLopDaoTao,
    required this.loaiIn,
    required this.ngayInDiemDanh,
    this.kp,
    this.baoCaoVien,
    this.thoiGianDetails,
    this.diaDiem,
    this.tpThamDu,
    this.danhSach = const [],
  });


  factory DaoTaoInDiemDanhV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw =
        json['danhSach'];


    final danhSach =
        raw is List
            ? raw
                .whereType<Map>()
                .map(
                  (e) =>
                      DaoTaoInDiemDanhNhanVienV2Model
                          .fromJson(
                    Map<String, dynamic>.from(
                      e,
                    ),
                  ),
                )
                .toList()
            : <DaoTaoInDiemDanhNhanVienV2Model>[];


    return DaoTaoInDiemDanhV2Model(
      idLopDaoTao:
          _toInt(
            json['idLopDaoTao'],
          ) ??
          0,

      tenLopDaoTao:
          json['tenLopDaoTao']
                  ?.toString() ??
              '',

      loaiIn:
          json['loaiIn']
                  ?.toString() ??
              '',

      ngayInDiemDanh:
          _toDate(
                json['ngayInDiemDanh'],
              ) ??
              DateTime.now(),

      kp:
          json['kp']
              ?.toString(),

      baoCaoVien:
          json['baoCaoVien']
              ?.toString(),

      thoiGianDetails:
          json['thoiGianDetails']
              ?.toString(),

      diaDiem:
          json['diaDiem']
              ?.toString(),

      tpThamDu:
          json['tpThamDu']
              ?.toString(),

      danhSach:
          danhSach,
    );
  }
}
