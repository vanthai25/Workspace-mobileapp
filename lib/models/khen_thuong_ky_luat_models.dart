int? _intValue(Object? value) => value is int ? value : int.tryParse('$value');
double? _doubleValue(Object? value) => value == null
    ? null
    : value is num
    ? value.toDouble()
    : double.tryParse('$value');
DateTime? _dateValue(Object? value) =>
    value == null ? null : DateTime.tryParse('$value');
bool _boolValue(Object? value) =>
    value == true || value == 1 || '$value'.toLowerCase() == 'true';

class KhenThuongKyLuatFileModel {
  final int idFile;
  final String fileName;
  final String? fileType;
  final int fileSize;

  const KhenThuongKyLuatFileModel({
    required this.idFile,
    required this.fileName,
    this.fileType,
    required this.fileSize,
  });

  factory KhenThuongKyLuatFileModel.fromJson(Map<String, dynamic> json) =>
      KhenThuongKyLuatFileModel(
        idFile: _intValue(json['idFile']) ?? 0,
        fileName: json['fileName']?.toString() ?? 'File đính kèm',
        fileType: json['fileType']?.toString(),
        fileSize: _intValue(json['fileSize']) ?? 0,
      );
}

class KhenThuongNhanVienModel {
  final String maKhenThuong;
  final String maSo;
  final String? canCuKhen;
  final String? lyDoKhen;
  final String? hinhThucKhen;
  final double? soTienKhen;
  final int? soDiemKhen;
  final DateTime? ngayKhen;
  final String? soQuyetDinhKhen;
  final String? nguoiKhen;
  final String? ghiChu;
  final KhenThuongKyLuatFileModel? file;

  const KhenThuongNhanVienModel({
    required this.maKhenThuong,
    required this.maSo,
    this.canCuKhen,
    this.lyDoKhen,
    this.hinhThucKhen,
    this.soTienKhen,
    this.soDiemKhen,
    this.ngayKhen,
    this.soQuyetDinhKhen,
    this.nguoiKhen,
    this.ghiChu,
    this.file,
  });

  factory KhenThuongNhanVienModel.fromJson(Map<String, dynamic> json) =>
      KhenThuongNhanVienModel(
        maKhenThuong: json['maKhenThuong']?.toString() ?? '',
        maSo: json['maSo']?.toString() ?? '',
        canCuKhen: json['canCuKhen']?.toString(),
        lyDoKhen: json['lyDoKhen']?.toString(),
        hinhThucKhen: json['hinhThucKhen']?.toString(),
        soTienKhen: _doubleValue(json['soTienKhen']),
        soDiemKhen: _intValue(json['soDiemKhen']),
        ngayKhen: _dateValue(json['ngayKhen']),
        soQuyetDinhKhen: json['soQuyetDinhKhen']?.toString(),
        nguoiKhen: json['nguoiKhen']?.toString(),
        ghiChu: json['ghiChu']?.toString(),
        file: json['file'] is Map
            ? KhenThuongKyLuatFileModel.fromJson(
                Map<String, dynamic>.from(json['file'] as Map),
              )
            : null,
      );
}

class KyLuatNhanVienModel {
  final String maKyLuat;
  final String maSo;
  final String? lyDoKyLuat;
  final String? diaDiemXayRa;
  final String? moTaSuViec;
  final String? hinhThucKyLuat;
  final DateTime? ngayXayRa;
  final DateTime? ngayKy;
  final String? nguoiKy;
  final double? soTienKyLuat;
  final int? soDiemKyLuat;
  final String? soQuyetDinhKyLuat;
  final bool keoDaiThamNien;
  final int? soThangKeoDaiThamNien;
  final DateTime? ngayBatDauKeoDaiThamNien;
  final String? ghiChu;
  final KhenThuongKyLuatFileModel? file;

  const KyLuatNhanVienModel({
    required this.maKyLuat,
    required this.maSo,
    this.lyDoKyLuat,
    this.diaDiemXayRa,
    this.moTaSuViec,
    this.hinhThucKyLuat,
    this.ngayXayRa,
    this.ngayKy,
    this.nguoiKy,
    this.soTienKyLuat,
    this.soDiemKyLuat,
    this.soQuyetDinhKyLuat,
    this.keoDaiThamNien = false,
    this.soThangKeoDaiThamNien,
    this.ngayBatDauKeoDaiThamNien,
    this.ghiChu,
    this.file,
  });

  factory KyLuatNhanVienModel.fromJson(Map<String, dynamic> json) =>
      KyLuatNhanVienModel(
        maKyLuat: json['maKyLuat']?.toString() ?? '',
        maSo: json['maSo']?.toString() ?? '',
        lyDoKyLuat: json['lyDoKyLuat']?.toString(),
        diaDiemXayRa: json['diaDiemXayRa']?.toString(),
        moTaSuViec: json['moTaSuViec']?.toString(),
        hinhThucKyLuat: json['hinhThucKyLuat']?.toString(),
        ngayXayRa: _dateValue(json['ngayXayRa']),
        ngayKy: _dateValue(json['ngayKy']),
        nguoiKy: json['nguoiKy']?.toString(),
        soTienKyLuat: _doubleValue(json['soTienKyLuat']),
        soDiemKyLuat: _intValue(json['soDiemKyLuat']),
        soQuyetDinhKyLuat: json['soQuyetDinhKyLuat']?.toString(),
        keoDaiThamNien: _boolValue(json['keoDaiThamNien']),
        soThangKeoDaiThamNien: _intValue(json['soThangKeoDaiThamNien']),
        ngayBatDauKeoDaiThamNien: _dateValue(json['ngayBatDauKeoDaiThamNien']),
        ghiChu: json['ghiChu']?.toString(),
        file: json['file'] is Map
            ? KhenThuongKyLuatFileModel.fromJson(
                Map<String, dynamic>.from(json['file'] as Map),
              )
            : null,
      );
}

class NhanVienKhenThuongKyLuatModel {
  final List<KhenThuongNhanVienModel> khenThuongs;
  final List<KyLuatNhanVienModel> kyLuats;
  final int tongSoThangKeoDaiThamNien;

  const NhanVienKhenThuongKyLuatModel({
    this.khenThuongs = const [],
    this.kyLuats = const [],
    this.tongSoThangKeoDaiThamNien = 0,
  });

  factory NhanVienKhenThuongKyLuatModel.fromJson(
    Map<String, dynamic> json,
  ) => NhanVienKhenThuongKyLuatModel(
    khenThuongs: (json['khenThuongs'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => KhenThuongNhanVienModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList(),
    kyLuats: (json['kyLuats'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => KyLuatNhanVienModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    tongSoThangKeoDaiThamNien:
        _intValue(json['tongSoThangKeoDaiThamNien']) ?? 0,
  );
}
