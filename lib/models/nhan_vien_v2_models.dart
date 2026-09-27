import 'dart:convert';
import 'dart:typed_data';

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

bool? _toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;

  final text = value.toString().toLowerCase();

  if (text == 'true' || text == '1') {
    return true;
  }

  if (text == 'false' || text == '0') {
    return false;
  }

  return null;
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();

  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}

Uint8List? decodeNhanVienAvatarBytes(Object? rawValue) {
  if (rawValue == null) return null;
  if (rawValue is Uint8List) return rawValue.isEmpty ? null : rawValue;

  if (rawValue is List) {
    try {
      final bytes = Uint8List.fromList(
        rawValue.cast<num>().map((item) => item.toInt()).toList(),
      );
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  String value = rawValue.toString().trim();
  if (value.isEmpty) return null;

  final int commaIndex = value.indexOf(',');
  if (value.toLowerCase().startsWith('data:') && commaIndex >= 0) {
    value = value.substring(commaIndex + 1);
  }

  value = value.replaceAll(RegExp(r'\s+'), '');
  if (value.isEmpty) return null;

  try {
    final bytes = base64Decode(base64.normalize(value));
    return bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
}

class ViTriCongTacV2Model {
  final int idViTriCongTac;
  final String? maSo;

  final int? idKhoaPhong;
  final String? tenKhoaPhong;

  final int? idToDoi;
  final String? tenToDoi;

  final int? idChucDanh;
  final String? tenChucDanh;
  final String? vietTatChucDanh;

  final int? idChucVu;
  final String? tenChucVu;
  final String? vietTatChucVu;

  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;

  final int? fileId;
  final String? fileName;
  final String? fileType;

  final bool? isKiemNhiem;

  final int? idTinhTrang;
  final String? tenTinhTrang;

  final bool isHienTai;

  const ViTriCongTacV2Model({
    required this.idViTriCongTac,
    this.maSo,
    this.idKhoaPhong,
    this.tenKhoaPhong,
    this.idToDoi,
    this.tenToDoi,
    this.idChucDanh,
    this.tenChucDanh,
    this.vietTatChucDanh,
    this.idChucVu,
    this.tenChucVu,
    this.vietTatChucVu,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.fileId,
    this.fileName,
    this.fileType,
    this.isKiemNhiem,
    this.idTinhTrang,
    this.tenTinhTrang,
    this.isHienTai = false,
  });

  factory ViTriCongTacV2Model.fromJson(Map<String, dynamic> json) {
    return ViTriCongTacV2Model(
      idViTriCongTac: _toInt(json['idViTriCongTac']) ?? 0,
      maSo: json['maSo']?.toString(),
      idKhoaPhong: _toInt(json['idKhoaPhong']),
      tenKhoaPhong: json['tenKhoaPhong']?.toString(),
      idToDoi: _toInt(json['idToDoi']),
      tenToDoi: json['tenToDoi']?.toString(),
      idChucDanh: _toInt(json['idChucDanh']),
      tenChucDanh: json['tenChucDanh']?.toString(),
      vietTatChucDanh: json['vietTatChucDanh']?.toString(),
      idChucVu: _toInt(json['idChucVu']),
      tenChucVu: json['tenChucVu']?.toString(),
      vietTatChucVu: json['vietTatChucVu']?.toString(),
      ngayBatDau: _toDate(json['ngayBatDau']),
      ngayKetThuc: _toDate(json['ngayKetThuc']),
      fileId: _toInt(json['fileId']),
      fileName: json['fileName']?.toString(),
      fileType: json['fileType']?.toString(),
      isKiemNhiem: _toBool(json['isKiemNhiem']),
      idTinhTrang: _toInt(json['idTinhTrang']),
      tenTinhTrang: json['tenTinhTrang']?.toString(),
      isHienTai: _toBool(json['isHienTai']) ?? false,
    );
  }
}

class NhanVienV2Model {
  final String maSo;
  final String? hoVaTen;

  final DateTime? namSinh;
  final bool? gioiTinh;

  final int? anhDaiDien;
  final String? anhBase64;
  final String? anhFileName;
  final String? anhFileType;

  final String? soDienThoai;

  final int? idKhoaPhong;
  final String? tenKhoaPhong;

  final int? idToDoi;
  final String? tenToDoi;

  final int? idChucDanh;
  final String? tenChucDanh;
  final String? vietTatChucDanh;

  final int? idChucVu;
  final String? tenChucVu;
  final String? vietTatChucVu;

  final bool? isNghiViec;
  final bool coTaiKhoanHeThong;
  final bool taiKhoanDaKhoa;
  final int? loaiNhanVien;

  final List<ViTriCongTacV2Model> viTriCongTacHienTai;

  final List<ViTriCongTacV2Model> lichSuViTriCongTac;

  const NhanVienV2Model({
    required this.maSo,
    this.hoVaTen,
    this.namSinh,
    this.gioiTinh,
    this.anhDaiDien,
    this.anhBase64,
    this.anhFileName,
    this.anhFileType,
    this.soDienThoai,
    this.idKhoaPhong,
    this.tenKhoaPhong,
    this.idToDoi,
    this.tenToDoi,
    this.idChucDanh,
    this.tenChucDanh,
    this.vietTatChucDanh,
    this.idChucVu,
    this.tenChucVu,
    this.vietTatChucVu,
    this.isNghiViec,
    this.coTaiKhoanHeThong = false,
    this.taiKhoanDaKhoa = false,
    this.loaiNhanVien,
    this.viTriCongTacHienTai = const [],
    this.lichSuViTriCongTac = const [],
  });

  Uint8List? get avatarBytes {
    return decodeNhanVienAvatarBytes(anhBase64);
  }

  factory NhanVienV2Model.fromJson(Map<String, dynamic> json) {
    return NhanVienV2Model(
      maSo: json['maSo']?.toString() ?? '',
      hoVaTen: json['hoVaTen']?.toString(),
      namSinh: _toDate(json['namSinh']),
      gioiTinh: _toBool(json['gioiTinh']),
      anhDaiDien: _toInt(json['anhDaiDien']),
      anhBase64: json['anhBase64']?.toString(),
      anhFileName: json['anhFileName']?.toString(),
      anhFileType: json['anhFileType']?.toString(),
      soDienThoai: json['soDienThoai']?.toString(),
      idKhoaPhong: _toInt(json['idKhoaPhong']),
      tenKhoaPhong: json['tenKhoaPhong']?.toString(),
      idToDoi: _toInt(json['idToDoi']),
      tenToDoi: json['tenToDoi']?.toString(),
      idChucDanh: _toInt(json['idChucDanh']),
      tenChucDanh: json['tenChucDanh']?.toString(),
      vietTatChucDanh: json['vietTatChucDanh']?.toString(),
      idChucVu: _toInt(json['idChucVu']),
      tenChucVu: json['tenChucVu']?.toString(),
      vietTatChucVu: json['vietTatChucVu']?.toString(),
      isNghiViec: _toBool(json['isNghiViec']),
      coTaiKhoanHeThong: _toBool(json['coTaiKhoanHeThong']) ?? false,
      taiKhoanDaKhoa: _toBool(json['taiKhoanDaKhoa']) ?? false,
      loaiNhanVien: _toInt(json['loaiNhanVien']),
      viTriCongTacHienTai: (json['viTriCongTacHienTai'] as List? ?? [])
          .whereType<Map>()
          .map(
            (e) => ViTriCongTacV2Model.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      lichSuViTriCongTac: (json['lichSuViTriCongTac'] as List? ?? [])
          .whereType<Map>()
          .map(
            (e) => ViTriCongTacV2Model.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

class ChungChiNhanVienV2Model {
  final int idChungChi;
  final String? maSo;
  final String? tenChungChi;
  final bool? cme;
  final String? donViDaoTao;

  final int? idHinhThucDaoTao;
  final String? tenHinhThucDaoTao;

  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;

  final double? soTiet;
  final DateTime? ngayCap;

  final int? idFile;
  final String? fileName;
  final String? fileType;

  final DateTime? ngayHetHan;

  final String? soChungChi;
  final int? idLopDaoTao;
  final int? chuKy;
  final DateTime? ngayUd;
  final String? nguoiUd;
  const ChungChiNhanVienV2Model({
    required this.idChungChi,
    this.maSo,
    this.tenChungChi,
    this.cme,
    this.donViDaoTao,
    this.idHinhThucDaoTao,
    this.tenHinhThucDaoTao,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.soTiet,
    this.ngayCap,
    this.idFile,
    this.fileName,
    this.fileType,
    this.ngayHetHan,
    this.soChungChi,
    this.idLopDaoTao,
    this.chuKy,
    this.ngayUd,
    this.nguoiUd,
  });

  factory ChungChiNhanVienV2Model.fromJson(Map<String, dynamic> json) {
    return ChungChiNhanVienV2Model(
      idChungChi: _toInt(json['idChungChi']) ?? 0,
      maSo: json['maSo']?.toString(),
      tenChungChi: json['tenChungChi']?.toString(),
      cme: _toBool(json['cme']),
      donViDaoTao: json['donViDaoTao']?.toString(),
      idHinhThucDaoTao: _toInt(json['idHinhThucDaoTao']),
      tenHinhThucDaoTao: json['tenHinhThucDaoTao']?.toString(),
      ngayBatDau: _toDate(json['ngayBatDau']),
      ngayKetThuc: _toDate(json['ngayKetThuc']),
      soTiet: _toDouble(json['soTiet']),
      ngayCap: _toDate(json['ngayCap']),
      idFile: _toInt(json['idFile']),
      fileName: json['fileName']?.toString(),
      fileType: json['fileType']?.toString(),
      ngayHetHan: _toDate(json['ngayHetHan']),
      soChungChi: json['soChungChi']?.toString(),
      idLopDaoTao: _toInt(json['idLopDaoTao']),
      chuKy: _toInt(json['chuKy']),
      ngayUd: _toDate(json['ngayUd']),
      nguoiUd: json['nguoiUd']?.toString(),
    );
  }
}

class BangCapV2Model {
  final int idBangCap;
  final String? maSo;
  final String tenBangCap;

  final int? idTrinhDo;
  final String? tenTrinhDo;

  final String? donViDaoTao;

  final int? idHinhThucDaoTao;
  final String? tenHinhThucDaoTao;

  final String? namTotNghiep;

  final int? idXepLoaiDaoTao;
  final String? tenXepLoaiDaoTao;

  final int? idFile;
  final String? fileName;
  final String? fileType;

  const BangCapV2Model({
    required this.idBangCap,
    required this.tenBangCap,
    this.maSo,
    this.idTrinhDo,
    this.tenTrinhDo,
    this.donViDaoTao,
    this.idHinhThucDaoTao,
    this.tenHinhThucDaoTao,
    this.namTotNghiep,
    this.idXepLoaiDaoTao,
    this.tenXepLoaiDaoTao,
    this.idFile,
    this.fileName,
    this.fileType,
  });

  factory BangCapV2Model.fromJson(Map<String, dynamic> json) {
    return BangCapV2Model(
      idBangCap: _toInt(json['idBangCap']) ?? 0,
      maSo: json['maSo']?.toString(),
      tenBangCap: json['tenBangCap']?.toString() ?? '',
      idTrinhDo: _toInt(json['idTrinhDo']),
      tenTrinhDo: json['tenTrinhDo']?.toString(),
      donViDaoTao: json['donViDaoTao']?.toString(),
      idHinhThucDaoTao: _toInt(json['idHinhThucDaoTao']),
      tenHinhThucDaoTao: json['tenHinhThucDaoTao']?.toString(),
      namTotNghiep: json['namTotNghiep']?.toString(),
      idXepLoaiDaoTao: _toInt(json['idXepLoaiDaoTao']),
      tenXepLoaiDaoTao: json['tenXepLoaiDaoTao']?.toString(),
      idFile: _toInt(json['idFile']),
      fileName: json['fileName']?.toString(),
      fileType: json['fileType']?.toString(),
    );
  }
}

class CchnV2Model {
  final int idCchn;
  final String maSo;

  final String? soCchn;
  final String? noiCap;

  final String? vanBangChuyenMon;
  final String? phamViHoatDong;

  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;

  final int? idFile;
  final String? fileName;
  final String? fileType;

  final bool? isPhamViBoSung;

  const CchnV2Model({
    required this.idCchn,
    required this.maSo,
    this.soCchn,
    this.noiCap,
    this.vanBangChuyenMon,
    this.phamViHoatDong,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.idFile,
    this.fileName,
    this.fileType,
    this.isPhamViBoSung,
  });

  factory CchnV2Model.fromJson(Map<String, dynamic> json) {
    return CchnV2Model(
      idCchn: _toInt(json['idCchn']) ?? 0,
      maSo: json['maSo']?.toString() ?? '',
      soCchn: json['soCchn']?.toString(),
      noiCap: json['noiCap']?.toString(),
      vanBangChuyenMon: json['vanBangChuyenMon']?.toString(),
      phamViHoatDong: json['phamViHoatDong']?.toString(),
      ngayBatDau: _toDate(json['ngayBatDau']),
      ngayKetThuc: _toDate(json['ngayKetThuc']),
      idFile: _toInt(json['idFile']),
      fileName: json['fileName']?.toString(),
      fileType: json['fileType']?.toString(),
      isPhamViBoSung: _toBool(json['isPhamViBoSung']),
    );
  }
}

class HopDongLaoDongV2Model {
  final int idHopDong;
  final String maSo;
  final String soHopDong;

  final int? idLoaiHopDong;
  final String? tenLoaiHopDong;

  final DateTime? ngayKy;
  final DateTime? ngayKetThuc;

  final int? idFile;
  final String? fileName;
  final String? fileType;

  final DateTime? ngayTao;

  const HopDongLaoDongV2Model({
    required this.idHopDong,
    required this.maSo,
    required this.soHopDong,
    this.idLoaiHopDong,
    this.tenLoaiHopDong,
    this.ngayKy,
    this.ngayKetThuc,
    this.idFile,
    this.fileName,
    this.fileType,
    this.ngayTao,
  });

  factory HopDongLaoDongV2Model.fromJson(Map<String, dynamic> json) {
    return HopDongLaoDongV2Model(
      idHopDong: _toInt(json['idHopDong']) ?? 0,
      maSo: json['maSo']?.toString() ?? '',
      soHopDong: json['soHopDong']?.toString() ?? '',
      idLoaiHopDong: _toInt(json['idLoaiHopDong']),
      tenLoaiHopDong: json['tenLoaiHopDong']?.toString(),
      ngayKy: _toDate(json['ngayKy']),
      ngayKetThuc: _toDate(json['ngayKetThuc']),
      idFile: _toInt(json['idFile']),
      fileName: json['fileName']?.toString(),
      fileType: json['fileType']?.toString(),
      ngayTao: _toDate(json['ngayTao']),
    );
  }
}

class ThanNhanV2Model {
  final int idThanNhan;

  final String tenThanNhan;

  final String? maSo;
  final String? moiQuanHe;
  final String? soCCCD;

  const ThanNhanV2Model({
    required this.idThanNhan,
    required this.tenThanNhan,
    this.maSo,
    this.moiQuanHe,
    this.soCCCD,
  });

  factory ThanNhanV2Model.fromJson(Map<String, dynamic> json) {
    return ThanNhanV2Model(
      idThanNhan: _toInt(json['idThanNhan']) ?? 0,
      tenThanNhan: json['tenThanNhan']?.toString() ?? '',
      maSo: json['maSo']?.toString(),
      moiQuanHe: json['moiQuanHe']?.toString(),
      soCCCD: json['soCCCD']?.toString(),
    );
  }
}

class NhanVienProfileV2Model {
  final String maSo;
  final String? hoVaTen;

  final DateTime? namSinh;
  final bool? gioiTinh;

  final int? anhDaiDien;
  final String? anhBase64;

  final String? soCCCD;
  final DateTime? ngayCapCCCD;
  final String? noiCapCCCD;

  final String? diaChiThuongTru;
  final String? noiOHienTai;
  final String? queQuan;
  final String? noiSinh;

  final String? danToc;

  final int? idTonGiao;
  final String? tenTonGiao;

  final int? idTinhTrangHonNhan;
  final String? tenTinhTrangHonNhan;

  final int? idKhoaPhong;
  final String? tenKhoaPhong;

  final int? idToDoi;
  final String? tenToDoi;

  final int? idChucDanh;
  final String? tenChucDanh;

  final int? idChucVu;
  final String? tenChucVu;

  final bool? isNghiViec;
  final bool coTaiKhoanHeThong;
  final bool taiKhoanDaKhoa;

  final String? soBHXH;

  final String? taiKhoanNH;
  final String? tenTaiKhoanNH;
  final String? tenNH;

  final String? soDienThoai;

  final List<ViTriCongTacV2Model> viTriCongTacHienTai;

  final List<ViTriCongTacV2Model> lichSuViTriCongTac;

  final List<ChungChiNhanVienV2Model> chungChiCme;

  final List<ChungChiNhanVienV2Model> chungChiKhac;

  final List<BangCapV2Model> bangCap;

  final List<CchnV2Model> cchn;

  final List<HopDongLaoDongV2Model> hopDongLaoDong;
  final List<DaoTaoNoiVienNhanVienV2Model> daoTaoNoiVien;
  final List<ThanNhanV2Model> thanNhan;
  final List<NhanVienThucHanhV2Model> thucHanhs;
  final String? anhFileName;
  final String? anhFileType;

  final int? idTuyenDung;
  final String? maBNMinhLo;
  final int? loaiNhanVien;
  const NhanVienProfileV2Model({
    required this.maSo,
    this.hoVaTen,
    this.namSinh,
    this.gioiTinh,
    this.anhDaiDien,
    this.anhBase64,
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
    this.idKhoaPhong,
    this.tenKhoaPhong,
    this.idToDoi,
    this.tenToDoi,
    this.idChucDanh,
    this.tenChucDanh,
    this.idChucVu,
    this.tenChucVu,
    this.isNghiViec,
    this.coTaiKhoanHeThong = false,
    this.taiKhoanDaKhoa = false,
    this.soBHXH,
    this.taiKhoanNH,
    this.tenTaiKhoanNH,
    this.tenNH,
    this.soDienThoai,
    this.viTriCongTacHienTai = const [],
    this.lichSuViTriCongTac = const [],
    this.chungChiCme = const [],
    this.chungChiKhac = const [],
    this.bangCap = const [],
    this.cchn = const [],
    this.hopDongLaoDong = const [],
    this.thanNhan = const [],
    this.thucHanhs = const [],
    this.anhFileName,
    this.anhFileType,
    this.idTuyenDung,
    this.maBNMinhLo,
    this.loaiNhanVien,
    this.daoTaoNoiVien = const [],
  });

  Uint8List? get avatarBytes {
    return decodeNhanVienAvatarBytes(anhBase64);
  }

  factory NhanVienProfileV2Model.fromJson(Map<String, dynamic> json) {
    return NhanVienProfileV2Model(
      maSo: json['maSo']?.toString() ?? '',
      hoVaTen: json['hoVaTen']?.toString(),
      namSinh: _toDate(json['namSinh']),
      gioiTinh: _toBool(json['gioiTinh']),
      anhDaiDien: _toInt(json['anhDaiDien']),
      anhBase64: json['anhBase64']?.toString(),
      soCCCD: json['soCCCD']?.toString(),
      ngayCapCCCD: _toDate(json['ngayCapCCCD']),
      noiCapCCCD: json['noiCapCCCD']?.toString(),
      diaChiThuongTru: json['diaChiThuongTru']?.toString(),
      noiOHienTai: json['noiOHienTai']?.toString(),
      queQuan: json['queQuan']?.toString(),
      noiSinh: json['noiSinh']?.toString(),
      danToc: json['danToc']?.toString(),
      idTonGiao: _toInt(json['idTonGiao']),
      tenTonGiao: json['tenTonGiao']?.toString(),
      idTinhTrangHonNhan: _toInt(json['idTinhTrangHonNhan']),
      tenTinhTrangHonNhan: json['tenTinhTrangHonNhan']?.toString(),
      idKhoaPhong: _toInt(json['idKhoaPhong']),
      tenKhoaPhong: json['tenKhoaPhong']?.toString(),
      idToDoi: _toInt(json['idToDoi']),
      tenToDoi: json['tenToDoi']?.toString(),
      idChucDanh: _toInt(json['idChucDanh']),
      tenChucDanh: json['tenChucDanh']?.toString(),
      idChucVu: _toInt(json['idChucVu']),
      tenChucVu: json['tenChucVu']?.toString(),
      isNghiViec: _toBool(json['isNghiViec']),
      coTaiKhoanHeThong: _toBool(json['coTaiKhoanHeThong']) ?? false,
      taiKhoanDaKhoa: _toBool(json['taiKhoanDaKhoa']) ?? false,
      soBHXH: json['soBHXH']?.toString(),
      taiKhoanNH: json['taiKhoanNH']?.toString(),
      tenTaiKhoanNH: json['tenTaiKhoanNH']?.toString(),
      tenNH: json['tenNH']?.toString(),
      soDienThoai: json['soDienThoai']?.toString(),

      viTriCongTacHienTai: _parseList(
        json['viTriCongTacHienTai'],
        ViTriCongTacV2Model.fromJson,
      ),

      lichSuViTriCongTac: _parseList(
        json['lichSuViTriCongTac'],
        ViTriCongTacV2Model.fromJson,
      ),

      chungChiCme: _parseList(
        json['chungChiCme'],
        ChungChiNhanVienV2Model.fromJson,
      ),

      chungChiKhac: _parseList(
        json['chungChiKhac'],
        ChungChiNhanVienV2Model.fromJson,
      ),

      bangCap: _parseList(json['bangCap'], BangCapV2Model.fromJson),

      cchn: _parseList(json['cchn'], CchnV2Model.fromJson),

      hopDongLaoDong: _parseList(
        json['hopDongLaoDong'],
        HopDongLaoDongV2Model.fromJson,
      ),

      thanNhan: _parseList(json['thanNhan'], ThanNhanV2Model.fromJson),
      thucHanhs: _parseList(
        json['thucHanhs'],
        NhanVienThucHanhV2Model.fromJson,
      ),
      anhFileName: json['anhFileName']?.toString(),

      anhFileType: json['anhFileType']?.toString(),

      idTuyenDung: _toInt(json['idTuyenDung']),

      maBNMinhLo: json['maBNMinhLo']?.toString(),

      loaiNhanVien: _toInt(json['loaiNhanVien']),
      daoTaoNoiVien: _parseList(
        json['daoTaoNoiVien'],
        DaoTaoNoiVienNhanVienV2Model.fromJson,
      ),
    );
  }
}

List<T> _parseList<T>(dynamic value, T Function(Map<String, dynamic>) builder) {
  if (value is! List) {
    return [];
  }

  return value
      .whereType<Map>()
      .map((e) => builder(Map<String, dynamic>.from(e)))
      .toList();
}

class KhoaPhongV2Model {
  final int idKhoaPhong;
  final String? tenKhoaPhong;

  const KhoaPhongV2Model({required this.idKhoaPhong, this.tenKhoaPhong});

  factory KhoaPhongV2Model.fromJson(Map<String, dynamic> json) {
    return KhoaPhongV2Model(
      idKhoaPhong: _toInt(json['idKhoaPhong']) ?? 0,
      tenKhoaPhong: json['tenKhoaPhong']?.toString(),
    );
  }
}

class NhanVienV2PageResult {
  final List<NhanVienV2Model> items;

  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const NhanVienV2PageResult({
    required this.items,
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });
}

class NhanVienDanhMucItemV2Model {
  final int id;
  final String? ten;

  final bool? ksd;
  final int? stt;

  final int? idKhoaPhong;

  final String? vietTat;

  final bool? isKyThuatHaTang;
  final String? maBHXH;
  final String? tenBHXH;

  final String? maViTriBHXH;

  const NhanVienDanhMucItemV2Model({
    required this.id,
    this.ten,
    this.ksd,
    this.stt,
    this.idKhoaPhong,
    this.vietTat,
    this.isKyThuatHaTang,
    this.maBHXH,
    this.tenBHXH,
    this.maViTriBHXH,
  });

  factory NhanVienDanhMucItemV2Model.fromJson(Map<String, dynamic> json) {
    return NhanVienDanhMucItemV2Model(
      id: _toInt(json['id']) ?? 0,
      ten: json['ten']?.toString(),
      ksd: _toBool(json['ksd']),
      stt: _toInt(json['stt']),
      idKhoaPhong: _toInt(json['idKhoaPhong']),
      vietTat: json['vietTat']?.toString(),
      isKyThuatHaTang: _toBool(json['isKyThuatHaTang']),
      maBHXH: json['maBHXH']?.toString(),
      tenBHXH: json['tenBHXH']?.toString(),
      maViTriBHXH: json['maViTriBHXH']?.toString(),
    );
  }
}

class NhanVienDanhMucV2Model {
  final List<NhanVienDanhMucItemV2Model> tonGiaos;

  final List<NhanVienDanhMucItemV2Model> tinhTrangHonNhans;

  final List<NhanVienDanhMucItemV2Model> khoaPhongs;

  final List<NhanVienDanhMucItemV2Model> toDois;

  final List<NhanVienDanhMucItemV2Model> chucDanhs;

  final List<NhanVienDanhMucItemV2Model> chucVus;

  final List<NhanVienDanhMucItemV2Model> trinhDos;

  final List<NhanVienDanhMucItemV2Model> hinhThucDaoTaos;

  final List<NhanVienDanhMucItemV2Model> xepLoaiDaoTaos;

  final List<NhanVienDanhMucItemV2Model> loaiHopDongs;

  final List<NhanVienDanhMucItemV2Model> loaiNhanViens;

  final List<NhanVienDanhMucItemV2Model> tinhTrangs;

  const NhanVienDanhMucV2Model({
    this.tonGiaos = const [],
    this.tinhTrangHonNhans = const [],
    this.khoaPhongs = const [],
    this.toDois = const [],
    this.chucDanhs = const [],
    this.chucVus = const [],
    this.trinhDos = const [],
    this.hinhThucDaoTaos = const [],
    this.xepLoaiDaoTaos = const [],
    this.loaiHopDongs = const [],
    this.loaiNhanViens = const [],
    this.tinhTrangs = const [],
  });

  factory NhanVienDanhMucV2Model.fromJson(Map<String, dynamic> json) {
    List<NhanVienDanhMucItemV2Model> parse(dynamic data) {
      if (data is! List) return [];

      return data
          .whereType<Map>()
          .map(
            (e) => NhanVienDanhMucItemV2Model.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    return NhanVienDanhMucV2Model(
      tonGiaos: parse(json['tonGiaos']),
      tinhTrangHonNhans: parse(json['tinhTrangHonNhans']),
      khoaPhongs: parse(json['khoaPhongs']),
      toDois: parse(json['toDois']),
      chucDanhs: parse(json['chucDanhs']),
      chucVus: parse(json['chucVus']),
      trinhDos: parse(json['trinhDos']),
      hinhThucDaoTaos: parse(json['hinhThucDaoTaos']),
      xepLoaiDaoTaos: parse(json['xepLoaiDaoTaos']),
      loaiHopDongs: parse(json['loaiHopDongs']),
      loaiNhanViens: parse(json['loaiNhanViens']),
      tinhTrangs: parse(json['tinhTrangs']),
    );
  }
}

class UploadedFileV2Model {
  final int idFile;

  final String? fileName;

  final String? fileType;

  const UploadedFileV2Model({
    required this.idFile,
    this.fileName,
    this.fileType,
  });

  factory UploadedFileV2Model.fromJson(Map<String, dynamic> json) {
    return UploadedFileV2Model(
      idFile: _toInt(json['idFile']) ?? 0,
      fileName: json['fileName']?.toString(),
      fileType: json['fileType']?.toString(),
    );
  }
}

class NhanVienTongQuanV2Model {
  final int tongNhanVien;
  final int dangLamViec;
  final int daNghiViec;
  final String? maSoLonNhat;

  const NhanVienTongQuanV2Model({
    required this.tongNhanVien,
    required this.dangLamViec,
    required this.daNghiViec,
    this.maSoLonNhat,
  });

  factory NhanVienTongQuanV2Model.fromJson(Map<String, dynamic> json) {
    return NhanVienTongQuanV2Model(
      tongNhanVien: _toInt(json['tongNhanVien']) ?? 0,

      dangLamViec: _toInt(json['dangLamViec']) ?? 0,

      daNghiViec: _toInt(json['daNghiViec']) ?? 0,

      maSoLonNhat: json['maSoLonNhat']?.toString(),
    );
  }
}

class DaoTaoNoiVienNhanVienV2Model {
  final int idDangKyDaoTao;
  final int idLopDaoTao;

  final String tenLopDaoTao;

  final double? soTiet;

  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;

  final String? donViDaoTao;

  final String? baoCaoVien;
  final String? donViGiangDay;

  final int? idHinhThucDaoTao;
  final String? tenHinhThucDaoTao;

  final int? idLoaiHinhDaoTao;
  final String? tenLoaiHinhDaoTao;

  final bool isOnline;
  final bool isDangKyOnline;
  final bool isBoSungSau;

  final String? diaDiem;
  final String? thoiGianDetails;
  final String? tpThamDu;

  final String? ghiChu;

  const DaoTaoNoiVienNhanVienV2Model({
    required this.idDangKyDaoTao,
    required this.idLopDaoTao,
    required this.tenLopDaoTao,
    this.soTiet,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.donViDaoTao,
    this.baoCaoVien,
    this.donViGiangDay,
    this.idHinhThucDaoTao,
    this.tenHinhThucDaoTao,
    this.idLoaiHinhDaoTao,
    this.tenLoaiHinhDaoTao,
    this.isOnline = false,
    this.isDangKyOnline = false,
    this.isBoSungSau = false,
    this.diaDiem,
    this.thoiGianDetails,
    this.tpThamDu,
    this.ghiChu,
  });

  factory DaoTaoNoiVienNhanVienV2Model.fromJson(Map<String, dynamic> json) {
    return DaoTaoNoiVienNhanVienV2Model(
      idDangKyDaoTao: _toInt(json['idDangKyDaoTao']) ?? 0,

      idLopDaoTao: _toInt(json['idLopDaoTao']) ?? 0,

      tenLopDaoTao: json['tenLopDaoTao']?.toString() ?? '',

      soTiet: _toDouble(json['soTiet']),

      ngayBatDau: _toDate(json['ngayBatDau']),

      ngayKetThuc: _toDate(json['ngayKetThuc']),

      donViDaoTao: json['donViDaoTao']?.toString(),

      baoCaoVien: json['baoCaoVien']?.toString(),

      donViGiangDay: json['donViGiangDay']?.toString(),

      idHinhThucDaoTao: _toInt(json['idHinhThucDaoTao']),

      tenHinhThucDaoTao: json['tenHinhThucDaoTao']?.toString(),

      idLoaiHinhDaoTao: _toInt(json['idLoaiHinhDaoTao']),

      tenLoaiHinhDaoTao: json['tenLoaiHinhDaoTao']?.toString(),

      isOnline: _toBool(json['isOnline']) ?? false,

      isDangKyOnline: _toBool(json['isDangKyOnline']) ?? false,

      isBoSungSau: _toBool(json['isBoSungSau']) ?? false,

      diaDiem: json['diaDiem']?.toString(),

      thoiGianDetails: json['thoiGianDetails']?.toString(),

      tpThamDu: json['tpThamDu']?.toString(),

      ghiChu: json['ghiChu']?.toString(),
    );
  }
}

class KhoaTaiKhoanHeThongV2Model {
  final String heThong;
  final bool thanhCong;
  final bool daKhoaTruocDo;
  final int soBanGhiAnhHuong;
  final String? thongBao;

  const KhoaTaiKhoanHeThongV2Model({
    required this.heThong,
    required this.thanhCong,
    required this.daKhoaTruocDo,
    required this.soBanGhiAnhHuong,
    this.thongBao,
  });

  factory KhoaTaiKhoanHeThongV2Model.fromJson(Map<String, dynamic> json) {
    return KhoaTaiKhoanHeThongV2Model(
      heThong: json['heThong']?.toString() ?? '',
      thanhCong: _toBool(json['thanhCong']) ?? false,
      daKhoaTruocDo: _toBool(json['daKhoaTruocDo']) ?? false,
      soBanGhiAnhHuong: _toInt(json['soBanGhiAnhHuong']) ?? 0,
      thongBao: json['thongBao']?.toString(),
    );
  }
}

class KhoaTaiKhoanNhanVienV2Model {
  final bool apiSuccess;
  final String message;
  final String maSo;
  final String nguoiThaoTac;
  final DateTime? ngayThaoTac;
  final List<KhoaTaiKhoanHeThongV2Model> ketQua;

  const KhoaTaiKhoanNhanVienV2Model({
    required this.apiSuccess,
    required this.message,
    required this.maSo,
    required this.nguoiThaoTac,
    required this.ngayThaoTac,
    required this.ketQua,
  });

  bool get thanhCongToanBo =>
      ketQua.isNotEmpty && ketQua.every((item) => item.thanhCong);

  factory KhoaTaiKhoanNhanVienV2Model.fromApiResponse(
    Map<String, dynamic> json,
  ) {
    final dynamic rawData = json['data'];
    final Map<String, dynamic> data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    final dynamic rawResults = data['ketQua'];

    return KhoaTaiKhoanNhanVienV2Model(
      apiSuccess: _toBool(json['success']) ?? false,
      message: json['message']?.toString() ?? '',
      maSo: data['maSo']?.toString() ?? '',
      nguoiThaoTac: data['nguoiThaoTac']?.toString() ?? '',
      ngayThaoTac: _toDate(data['ngayThaoTac']),
      ketQua: rawResults is List
          ? rawResults
                .whereType<Map>()
                .map(
                  (item) => KhoaTaiKhoanHeThongV2Model.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const <KhoaTaiKhoanHeThongV2Model>[],
    );
  }
}

class NhanVienTaiLieuKhacV2Model {
  final int idTaiLieuNhanVien;
  final String maSo;

  final int idFile;

  final String? tenTaiLieu;

  final String fileName;
  final String? fileType;
  final int fileSize;

  final DateTime? ngayTaiLieu;

  final String? ghiChu;

  final int? stt;

  final DateTime? ngayTao;

  final String? nguoiTao;

  const NhanVienTaiLieuKhacV2Model({
    required this.idTaiLieuNhanVien,
    required this.maSo,
    required this.idFile,
    this.tenTaiLieu,
    required this.fileName,
    this.fileType,
    this.fileSize = 0,
    this.ngayTaiLieu,
    this.ghiChu,
    this.stt,
    this.ngayTao,
    this.nguoiTao,
  });

  factory NhanVienTaiLieuKhacV2Model.fromJson(Map<String, dynamic> json) {
    return NhanVienTaiLieuKhacV2Model(
      idTaiLieuNhanVien: _toInt(json['idTaiLieuNhanVien']) ?? 0,

      maSo: json['maSo']?.toString() ?? '',

      idFile: _toInt(json['idFile']) ?? 0,

      tenTaiLieu: json['tenTaiLieu']?.toString(),

      fileName: json['fileName']?.toString() ?? '',

      fileType: json['fileType']?.toString(),

      fileSize: _toInt(json['fileSize']) ?? 0,

      ngayTaiLieu: _toDate(json['ngayTaiLieu']),

      ghiChu: json['ghiChu']?.toString(),

      stt: _toInt(json['stt']),

      ngayTao: _toDate(json['ngayTao']),

      nguoiTao: json['nguoiTao']?.toString(),
    );
  }
}

class NhanVienThucHanhV2Model {
  final int idCapCCCHN;
  final String hoVaTen;
  final int idKhoaPhong;
  final String? tenKhoaPhong;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;
  final String? maSoNguoiHuongDan;
  final String? tenNguoiHuongDan;

  const NhanVienThucHanhV2Model({
    required this.idCapCCCHN,
    required this.hoVaTen,
    required this.idKhoaPhong,
    this.tenKhoaPhong,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.maSoNguoiHuongDan,
    this.tenNguoiHuongDan,
  });

  factory NhanVienThucHanhV2Model.fromJson(Map<String, dynamic> json) =>
      NhanVienThucHanhV2Model(
        idCapCCCHN: _toInt(json['idCapCCCHN']) ?? 0,
        hoVaTen: json['hoVaTen']?.toString() ?? '',
        idKhoaPhong: _toInt(json['idKhoaPhong']) ?? 0,
        tenKhoaPhong: json['tenKhoaPhong']?.toString(),
        ngayBatDau: _toDate(json['ngayBatDau']),
        ngayKetThuc: _toDate(json['ngayKetThuc']),
        maSoNguoiHuongDan: json['maSoNguoiHuongDan']?.toString(),
        tenNguoiHuongDan: json['tenNguoiHuongDan']?.toString(),
      );
}
