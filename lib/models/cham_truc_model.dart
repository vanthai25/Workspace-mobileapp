class ChamTrucModel {
  final int id;

  final String manv;
  final String? tennv;

  final DateTime ngay;

  final String? kyHieuId;
  final String? tenLoaiCong;

  final String? ghiChu;
  final int? tong;

  final String? makhoa;
  final String? tenkhoa;

  final int? mato;
  final String? tento;

  final String? dienthoai1;
  final String? dienthoai2;

  final String coSo;

  const ChamTrucModel({
    required this.id,
    required this.manv,
    required this.tennv,
    required this.ngay,
    required this.kyHieuId,
    required this.tenLoaiCong,
    required this.ghiChu,
    required this.tong,
    required this.makhoa,
    required this.tenkhoa,
    required this.mato,
    required this.tento,
    required this.dienthoai1,
    required this.dienthoai2,
    required this.coSo,
  });

  factory ChamTrucModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ChamTrucModel(
      id: _parseInt(
            json['id'] ?? json['Id'],
          ) ??
          0,

      manv: (
        json['manv'] ??
            json['Manv'] ??
            ''
      ).toString().trim(),

      tennv: _parseString(
        json['tennv'] ??
            json['Tennv'],
      ),

      ngay: DateTime.tryParse(
            (
              json['ngay'] ??
                  json['Ngay'] ??
                  ''
            ).toString(),
          ) ??
          DateTime.now(),

      kyHieuId: _parseString(
        json['kyHieuId'] ??
            json['KyHieuId'],
      ),

      tenLoaiCong: _parseString(
        json['tenLoaiCong'] ??
            json['TenLoaiCong'],
      ),

      ghiChu: _parseString(
        json['ghiChu'] ??
            json['GhiChu'],
      ),

      tong: _parseInt(
        json['tong'] ??
            json['Tong'],
      ),

      makhoa: _parseString(
        json['makhoa'] ??
            json['Makhoa'],
      ),

      tenkhoa: _parseString(
        json['tenkhoa'] ??
            json['Tenkhoa'],
      ),

      mato: _parseInt(
        json['mato'] ??
            json['Mato'],
      ),

      tento: _parseString(
        json['tento'] ??
            json['Tento'],
      ),

      dienthoai1: _parseString(
        json['dienthoai1'] ??
            json['Dienthoai1'],
      ),

      dienthoai2: _parseString(
        json['dienthoai2'] ??
            json['Dienthoai2'],
      ),

      coSo: (
        json['coSo'] ??
            json['CoSo'] ??
            ''
      ).toString().trim(),
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

  String get tenNhanVienHienThi {
    if (tennv != null &&
        tennv!.trim().isNotEmpty) {
      return tennv!;
    }

    return manv;
  }

  String get tenKhoaHienThi {
    if (tenkhoa != null &&
        tenkhoa!.trim().isNotEmpty) {
      return tenkhoa!;
    }

    return 'Chưa xác định khoa/phòng';
  }

  String get tenToHienThi {
    if (tento != null &&
        tento!.trim().isNotEmpty) {
      return tento!;
    }

    return 'Chưa xác định';
  }
}