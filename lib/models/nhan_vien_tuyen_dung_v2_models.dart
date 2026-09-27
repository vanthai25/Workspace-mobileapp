import 'dart:typed_data';

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

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString(),
  );
}

bool? _toBool(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final text =
      value.toString().toLowerCase();

  if (text == 'true' ||
      text == '1') {
    return true;
  }

  if (text == 'false' ||
      text == '0') {
    return false;
  }

  return null;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(
    value.toString(),
  );
}

// ============================================================
// DANH SÁCH ỨNG VIÊN
// ============================================================

class NhanVienTuyenDungItemV2Model {
  final int idTuyenDung;
  final String? hoVaTen;
  final DateTime? namSinh;
  final bool? gioiTinh;
  final String? soCCCD;
  final String? soDienThoai;
  final String? email;
  final String? anhDaiDienUrl;
  final int? idDotTuyenDung;
  final String? tenDotTuyenDung;
  final int? idViTriTuyenDung;
  final String? viTriChiTiet;
  final DateTime? ngayUD;

  const NhanVienTuyenDungItemV2Model({
    required this.idTuyenDung,
    this.hoVaTen,
    this.namSinh,
    this.gioiTinh,
    this.soCCCD,
    this.soDienThoai,
    this.email,
    this.anhDaiDienUrl,
    this.idDotTuyenDung,
    this.tenDotTuyenDung,
    this.idViTriTuyenDung,
    this.viTriChiTiet,
    this.ngayUD,
  });

  factory NhanVienTuyenDungItemV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return NhanVienTuyenDungItemV2Model(
      idTuyenDung:
          _toInt(json['idTuyenDung']) ?? 0,
      hoVaTen:
          json['hoVaTen']?.toString(),
      namSinh:
          _toDateTime(json['namSinh']),
      gioiTinh:
          _toBool(json['gioiTinh']),
      soCCCD:
          json['soCCCD']?.toString(),
      soDienThoai:
          json['soDienThoai']?.toString(),
      email:
          json['email']?.toString(),
      anhDaiDienUrl:
          json['anhDaiDienUrl']?.toString(),
      idDotTuyenDung:
          _toInt(json['idDotTuyenDung']),
      tenDotTuyenDung:
          json['tenDotTuyenDung']?.toString(),
      idViTriTuyenDung:
          _toInt(json['idViTriTuyenDung']),
      viTriChiTiet:
          json['viTriChiTiet']?.toString(),
      ngayUD:
          _toDateTime(json['ngayUD']),
    );
  }
}


class NhanVienTuyenDungNhanVienDraftV2Model {
  String maSo;
  final int idTuyenDung;

  String? hoVaTen;
  DateTime? namSinh;
  bool? gioiTinh;

  String? anhDaiDienUrl;

  String? soCCCD;
  DateTime? ngayCapCCCD;
  String? noiCapCCCD;

  String? diaChiThuongTru;
  String? noiOHienTai;
  String? queQuan;
  String? noiSinh;
  String? danToc;

  int? idTonGiao;
  String? tenTonGiao;

  int? idTinhTrangHonNhan;
  String? tenTinhTrangHonNhan;

  String? soDienThoai;

  String? soBHXH;

  String? taiKhoanNH;
  String? tenTaiKhoanNH;
  String? tenNH;

  String? maBNMinhLo;

  int? loaiNhanVien;

  bool isNghiViec;
  Uint8List? replacementAvatarBytes;
  String? replacementAvatarFileName;
  Uint8List? sourceAvatarBytes;
  Map<String, dynamic> toJson() {
    return {
      'maSo': maSo.trim(),
      'idTuyenDung': idTuyenDung,
      'hoVaTen': hoVaTen?.trim(),
      'namSinh': _dateToJson(namSinh),
      'gioiTinh': gioiTinh,
      'anhDaiDienUrl': anhDaiDienUrl?.trim(),
      'soCCCD': soCCCD?.trim(),
      'ngayCapCCCD': _dateToJson(ngayCapCCCD),
      'noiCapCCCD': noiCapCCCD?.trim(),
      'diaChiThuongTru': diaChiThuongTru?.trim(),
      'noiOHienTai': noiOHienTai?.trim(),
      'queQuan': queQuan?.trim(),
      'noiSinh': noiSinh?.trim(),
      'danToc': danToc?.trim(),
      'idTonGiao': idTonGiao,
      'idTinhTrangHonNhan': idTinhTrangHonNhan,
      'soDienThoai': soDienThoai?.trim(),
      'soBHXH': soBHXH?.trim(),
      'taiKhoanNH': taiKhoanNH?.trim(),
      'tenTaiKhoanNH': tenTaiKhoanNH?.trim(),
      'tenNH': tenNH?.trim(),
      'maBNMinhLo': maBNMinhLo?.trim(),
      'loaiNhanVien': loaiNhanVien,
      'isNghiViec': isNghiViec,
    };
  }
  NhanVienTuyenDungNhanVienDraftV2Model({
    required this.maSo,
    required this.idTuyenDung,
    this.hoVaTen,
    this.namSinh,
    this.gioiTinh,
    this.anhDaiDienUrl,
    this.soCCCD,
    this.ngayCapCCCD,
    this.noiCapCCCD,
    this.diaChiThuongTru,
    this.noiOHienTai,
    this.queQuan,
    this.noiSinh,
    this.danToc,
    this.idTonGiao,
    this.tenTonGiao,
    this.idTinhTrangHonNhan,
    this.tenTinhTrangHonNhan,
    this.soDienThoai,
    this.soBHXH,
    this.taiKhoanNH,
    this.tenTaiKhoanNH,
    this.tenNH,
    this.maBNMinhLo,
    this.loaiNhanVien,
    this.isNghiViec = false,
  });

  factory NhanVienTuyenDungNhanVienDraftV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return NhanVienTuyenDungNhanVienDraftV2Model(
      maSo:
          json['maSo']?.toString() ?? '',
      idTuyenDung:
          _toInt(json['idTuyenDung']) ?? 0,
      hoVaTen:
          json['hoVaTen']?.toString(),
      namSinh:
          _toDateTime(json['namSinh']),
      gioiTinh:
          _toBool(json['gioiTinh']),
      anhDaiDienUrl:
          json['anhDaiDienUrl']?.toString(),
      soCCCD:
          json['soCCCD']?.toString(),
      ngayCapCCCD:
          _toDateTime(json['ngayCapCCCD']),
      noiCapCCCD:
          json['noiCapCCCD']?.toString(),
      diaChiThuongTru:
          json['diaChiThuongTru']?.toString(),
      noiOHienTai:
          json['noiOHienTai']?.toString(),
      queQuan:
          json['queQuan']?.toString(),
      noiSinh:
          json['noiSinh']?.toString(),
      danToc:
          json['danToc']?.toString(),
      idTonGiao:
          _toInt(json['idTonGiao']),
      tenTonGiao:
          json['tenTonGiao']?.toString(),
      idTinhTrangHonNhan:
          _toInt(json['idTinhTrangHonNhan']),
      tenTinhTrangHonNhan:
          json['tenTinhTrangHonNhan']?.toString(),
      soDienThoai:
          json['soDienThoai']?.toString(),
      soBHXH:
          json['soBHXH']?.toString(),
      taiKhoanNH:
          json['taiKhoanNH']?.toString(),
      tenTaiKhoanNH:
          json['tenTaiKhoanNH']?.toString(),
      tenNH:
          json['tenNH']?.toString(),
      maBNMinhLo:
          json['maBNMinhLo']?.toString(),
      loaiNhanVien:
          _toInt(json['loaiNhanVien']),
      isNghiViec:
          _toBool(json['isNghiViec']) ?? false,
    );
    
  }
}

// ============================================================
// BẰNG CẤP
// ============================================================

class NhanVienTuyenDungBangCapDraftV2Model {
  final int idBangCapTuyenDung;

  String? tenBangCap;
  int? idTrinhDo;
  String? donViDaoTao;
  int? idHinhThucDaoTao;
  String? namTotNghiep;
  int? idXepLoaiDaoTao;
  String? fileUrl;
  Uint8List? replacementFileBytes;
  String? replacementFileName;  
  Uint8List? sourcePreviewBytes;
  Map<String, dynamic> toJson() {
    return {
      'idBangCapTuyenDung': idBangCapTuyenDung,
      'tenBangCap': tenBangCap?.trim(),
      'idTrinhDo': idTrinhDo,
      'donViDaoTao': donViDaoTao?.trim(),
      'idHinhThucDaoTao': idHinhThucDaoTao,
      'namTotNghiep': namTotNghiep?.trim(),
      'idXepLoaiDaoTao': idXepLoaiDaoTao,
      'fileUrl': fileUrl?.trim(),
    };
  }
  NhanVienTuyenDungBangCapDraftV2Model({
    required this.idBangCapTuyenDung,
    this.tenBangCap,
    this.idTrinhDo,
    this.donViDaoTao,
    this.idHinhThucDaoTao,
    this.namTotNghiep,
    this.idXepLoaiDaoTao,
    this.fileUrl,
  });

  factory NhanVienTuyenDungBangCapDraftV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return NhanVienTuyenDungBangCapDraftV2Model(
      idBangCapTuyenDung:
          _toInt(
            json['idBangCapTuyenDung'],
          ) ??
          0,
      tenBangCap:
          json['tenBangCap']?.toString(),
      idTrinhDo:
          _toInt(json['idTrinhDo']),
      donViDaoTao:
          json['donViDaoTao']?.toString(),
      idHinhThucDaoTao:
          _toInt(json['idHinhThucDaoTao']),
      namTotNghiep:
          json['namTotNghiep']?.toString(),
      idXepLoaiDaoTao:
          _toInt(json['idXepLoaiDaoTao']),
      fileUrl:
          json['fileUrl']?.toString(),
    );
  }
  
}

// ============================================================
// CHỨNG CHỈ
// ============================================================

class NhanVienTuyenDungChungChiDraftV2Model {
  final int idChungChiTuyenDung;

  String? tenChungChi;
  bool? cme;
  String? donViDaoTao;
  int? idHinhThucDaoTao;

  DateTime? ngayBatDau;
  DateTime? ngayKetThuc;

  double? soTiet;

  DateTime? ngayCap;

  String? fileUrl;

  String? soChungChi;
  DateTime? ngayHetHan;
  int? chuKy;
  Uint8List? replacementFileBytes;
  String? replacementFileName;
  Uint8List? sourcePreviewBytes;
  Map<String, dynamic> toJson() {
    return {
      'idChungChiTuyenDung': idChungChiTuyenDung,
      'tenChungChi': tenChungChi?.trim(),
      'cme': cme,
      'donViDaoTao': donViDaoTao?.trim(),
      'idHinhThucDaoTao': idHinhThucDaoTao,
      'ngayBatDau': _dateToJson(ngayBatDau),
      'ngayKetThuc': _dateToJson(ngayKetThuc),
      'soTiet': soTiet,
      'ngayCap': _dateToJson(ngayCap),
      'fileUrl': fileUrl?.trim(),
      'soChungChi': soChungChi?.trim(),
      'ngayHetHan': _dateToJson(ngayHetHan),
      'chuKy': chuKy,
    };
  }
  NhanVienTuyenDungChungChiDraftV2Model({
    required this.idChungChiTuyenDung,
    this.tenChungChi,
    this.cme,
    this.donViDaoTao,
    this.idHinhThucDaoTao,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.soTiet,
    this.ngayCap,
    this.fileUrl,
    this.soChungChi,
    this.ngayHetHan,
    this.chuKy,
  });

  factory NhanVienTuyenDungChungChiDraftV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return NhanVienTuyenDungChungChiDraftV2Model(
      idChungChiTuyenDung:
          _toInt(
            json['idChungChiTuyenDung'],
          ) ??
          0,
      tenChungChi:
          json['tenChungChi']?.toString(),
      cme:
          _toBool(json['cme']),
      donViDaoTao:
          json['donViDaoTao']?.toString(),
      idHinhThucDaoTao:
          _toInt(json['idHinhThucDaoTao']),
      ngayBatDau:
          _toDateTime(json['ngayBatDau']),
      ngayKetThuc:
          _toDateTime(json['ngayKetThuc']),
      soTiet:
          _toDouble(json['soTiet']),
      ngayCap:
          _toDateTime(json['ngayCap']),
      fileUrl:
          json['fileUrl']?.toString(),
      soChungChi:
          json['soChungChi']?.toString(),
      ngayHetHan:
          _toDateTime(json['ngayHetHan']),
      chuKy:
          _toInt(json['chuKy']),
    );
  }
}

// ============================================================
// CCHN
// ============================================================

class NhanVienTuyenDungCchnDraftV2Model {
  String? soCchn;
  String? noiCap;
  String? vanBangChuyenMon;
  String? phamViHoatDong;

  DateTime? ngayCapGphn;

  DateTime? ngayBatDau;
  DateTime? ngayKetThuc;

  bool? isPhamViBoSung;
  Map<String, dynamic> toJson() {
    return {
      'soCchn': soCchn?.trim(),
      'noiCap': noiCap?.trim(),
      'vanBangChuyenMon': vanBangChuyenMon?.trim(),
      'phamViHoatDong': phamViHoatDong?.trim(),
      'ngayCapGphn': _dateToJson(ngayCapGphn),
      'ngayBatDau': _dateToJson(ngayBatDau),
      'ngayKetThuc': _dateToJson(ngayKetThuc),
      'isPhamViBoSung': isPhamViBoSung,
    };
  }
  NhanVienTuyenDungCchnDraftV2Model({
    this.soCchn,
    this.noiCap,
    this.vanBangChuyenMon,
    this.phamViHoatDong,
    this.ngayCapGphn,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.isPhamViBoSung,
  });

  factory NhanVienTuyenDungCchnDraftV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return NhanVienTuyenDungCchnDraftV2Model(
      soCchn:
          json['soCchn']?.toString(),
      noiCap:
          json['noiCap']?.toString(),
      vanBangChuyenMon:
          json['vanBangChuyenMon']?.toString(),
      phamViHoatDong:
          json['phamViHoatDong']?.toString(),
      ngayCapGphn:
          _toDateTime(json['ngayCapGphn']),
      ngayBatDau:
          _toDateTime(json['ngayBatDau']),
      ngayKetThuc:
          _toDateTime(json['ngayKetThuc']),
      isPhamViBoSung:
          _toBool(json['isPhamViBoSung']),
    );
  }
}

// ============================================================
// PREVIEW
// ============================================================

class NhanVienTuyenDungPreviewV2Model {
  final int idTuyenDung;

  final String maSoDuKien;

  final int? idDotTuyenDung;

  final String? tenDotTuyenDung;

  final String? viTriChiTiet;

  final NhanVienTuyenDungNhanVienDraftV2Model nhanVien;

  final List<NhanVienTuyenDungBangCapDraftV2Model> bangCaps;

  final List<NhanVienTuyenDungChungChiDraftV2Model> chungChis;

  NhanVienTuyenDungCchnDraftV2Model? cchn;

  final List<String> canhBao;
  Map<String, dynamic> toImportJson() {
    return {
      'nhanVien': nhanVien.toJson(),
      'bangCaps': bangCaps
          .map((e) => e.toJson())
          .toList(),
      'chungChis': chungChis
          .map((e) => e.toJson())
          .toList(),
      'cchn': cchn?.toJson(),
    };
  }
  NhanVienTuyenDungPreviewV2Model({
    required this.idTuyenDung,
    required this.maSoDuKien,
    required this.nhanVien,
    required this.bangCaps,
    required this.chungChis,
    required this.canhBao,
    this.idDotTuyenDung,
    this.tenDotTuyenDung,
    this.viTriChiTiet,
    this.cchn,
  });

  factory NhanVienTuyenDungPreviewV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    final nhanVienJson =
        json['nhanVien'];

    final bangCapJson =
        json['bangCaps'];

    final chungChiJson =
        json['chungChis'];

    final cchnJson =
        json['cchn'];

    final canhBaoJson =
        json['canhBao'];

    return NhanVienTuyenDungPreviewV2Model(
      idTuyenDung:
          _toInt(json['idTuyenDung']) ?? 0,
      maSoDuKien:
          json['maSoDuKien']?.toString() ?? '',
      idDotTuyenDung:
          _toInt(json['idDotTuyenDung']),
      tenDotTuyenDung:
          json['tenDotTuyenDung']?.toString(),
      viTriChiTiet:
          json['viTriChiTiet']?.toString(),

      nhanVien:
          NhanVienTuyenDungNhanVienDraftV2Model.fromJson(
        nhanVienJson is Map
            ? Map<String, dynamic>.from(
                nhanVienJson,
              )
            : <String, dynamic>{},
      ),

      bangCaps:
          bangCapJson is List
              ? bangCapJson
                  .whereType<Map>()
                  .map(
                    (e) =>
                        NhanVienTuyenDungBangCapDraftV2Model
                            .fromJson(
                      Map<String, dynamic>.from(
                        e,
                      ),
                    ),
                  )
                  .toList()
              : [],

      chungChis:
          chungChiJson is List
              ? chungChiJson
                  .whereType<Map>()
                  .map(
                    (e) =>
                        NhanVienTuyenDungChungChiDraftV2Model
                            .fromJson(
                      Map<String, dynamic>.from(
                        e,
                      ),
                    ),
                  )
                  .toList()
              : [],

      cchn:
          cchnJson is Map
              ? NhanVienTuyenDungCchnDraftV2Model.fromJson(
                  Map<String, dynamic>.from(
                    cchnJson,
                  ),
                )
              : null,

      canhBao:
          canhBaoJson is List
              ? canhBaoJson
                  .map(
                    (e) => e.toString(),
                  )
                  .toList()
              : [],
    );
  }
}
String? _dateToJson(DateTime? value) {
  if (value == null) {
    return null;
  }

  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}