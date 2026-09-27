class BaoComLechModel {
  final int id;

  final String manv;

  final DateTime? ngayLech;

  final String? noiDung;

  final String? phanHoi;

  final DateTime? ngayPhanHoi;

  final String? nguoiPhanHoi;

  final int keToanDuyet;

  final String? ngayDuyet;

  final int? soTien;

  final int? phanLoai;

  final String? tennvBaoCom;

  final String? ghiChu;

  final String? noiDungDuyet;

  final bool coHinhAnh;

  final String? hinhAnhUrl;

  const BaoComLechModel({
    required this.id,
    required this.manv,
    required this.ngayLech,
    required this.noiDung,
    required this.phanHoi,
    required this.ngayPhanHoi,
    required this.nguoiPhanHoi,
    required this.keToanDuyet,
    required this.ngayDuyet,
    required this.soTien,
    required this.phanLoai,
    required this.tennvBaoCom,
    required this.ghiChu,
    required this.noiDungDuyet,
    required this.coHinhAnh,
    required this.hinhAnhUrl,
  });

  factory BaoComLechModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return BaoComLechModel(
      id: _parseInt(
            json['id'] ??
                json['Id'],
          ) ??
          0,

      manv: (
        json['manv'] ??
            json['Manv'] ??
            ''
      ).toString(),

      ngayLech: _parseDate(
        json['ngayLech'] ??
            json['NgayLech'],
      ),

      noiDung: _parseString(
        json['noiDung'] ??
            json['NoiDung'],
      ),

      phanHoi: _parseString(
        json['phanHoi'] ??
            json['PhanHoi'],
      ),

      ngayPhanHoi: _parseDate(
        json['ngayPhanHoi'] ??
            json['NgayPhanHoi'],
      ),

      nguoiPhanHoi: _parseString(
        json['nguoiPhanHoi'] ??
            json['NguoiPhanHoi'],
      ),

      keToanDuyet: _parseInt(
            json['keToanDuyet'] ??
                json['KeToanDuyet'],
          ) ??
          0,

      ngayDuyet: _parseString(
        json['ngayDuyet'] ??
            json['NgayDuyet'],
      ),

      soTien: _parseInt(
        json['soTien'] ??
            json['SoTien'],
      ),

      phanLoai: _parseInt(
        json['phanLoai'] ??
            json['PhanLoai'],
      ),

      tennvBaoCom: _parseString(
        json['tennvBaoCom'] ??
            json['TennvBaoCom'],
      ),

      ghiChu: _parseString(
        json['ghiChu'] ??
            json['GhiChu'],
      ),

      noiDungDuyet: _parseString(
        json['noiDungDuyet'] ??
            json['NoiDungDuyet'],
      ),

      coHinhAnh:
          json['coHinhAnh'] == true ||
              json['CoHinhAnh'] == true,

      hinhAnhUrl: _parseString(
        json['hinhAnhUrl'] ??
            json['HinhAnhUrl'],
      ),
    );
  }

  static int? _parseInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static String? _parseString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String text =
        value.toString().trim();

    return text.isEmpty
        ? null
        : text;
  }

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // =========================================================
  // TRẠNG THÁI
  // =========================================================

  String get trangThaiText {
    switch (keToanDuyet) {
      case 0:
        return 'Tạo mới';

      case 1:
        return 'Chờ Kế toán duyệt';

      case 2:
        return 'Kế toán đã duyệt';

      default:
        return 'Không xác định';
    }
  }

  bool get duocPhanHoi =>
      keToanDuyet == 0;

  bool get duocSuaXoa =>
      keToanDuyet == 1;

  bool get daDuyet =>
      keToanDuyet == 2;
}