class ChamCongTangCaModel {
  final int id;
  final String manv;
  final String tenNV;

  final String maKhoa;
  final String tenKhoa;

  final DateTime ngayLap;
  final DateTime batDau;
  final DateTime ketThuc;
  final int soPhut;
  final String lyDoTangCa;
  final int trangThaiDuyet;

  final String? ldKhoaDuyet;
  final String? tenLDKhoaDuyet;
  final DateTime? ngayLDKhoaDuyet;

  final String? ldBVDuyet;
  final String? tenLDBVDuyet;
  final DateTime? ngayLDBVDuyet;

  final String? lyDoTuChoi;

  ChamCongTangCaModel({
    required this.id,
    required this.manv,
    required this.tenNV,
    required this.maKhoa,
    required this.tenKhoa,
    required this.ngayLap,
    required this.batDau,
    required this.ketThuc,
    required this.soPhut,
    required this.lyDoTangCa,
    required this.trangThaiDuyet,
    this.ldKhoaDuyet,
    this.tenLDKhoaDuyet,
    this.ngayLDKhoaDuyet,
    this.ldBVDuyet,
    this.tenLDBVDuyet,
    this.ngayLDBVDuyet,
    this.lyDoTuChoi,
  });

  factory ChamCongTangCaModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic value) {
      if (value == null || value.toString().isEmpty) return null;
      return DateTime.tryParse(value.toString());
    }

    return ChamCongTangCaModel(
      id: json['id'] ?? json['Id'] ?? 0,
      manv: json['manv'] ?? json['Manv'] ?? '',
      tenNV: json['tenNV'] ?? json['TenNV'] ?? '',

      maKhoa: json['maKhoa'] ?? json['Makhoa'] ?? '',
      tenKhoa: json['tenKhoa'] ?? json['TenKhoa'] ?? '',

      ngayLap: parseNullableDate(
            json['ngayLap'] ?? json['NgayLap'],
          ) ??
          DateTime.now(),

      batDau: parseNullableDate(
            json['batDau'] ?? json['BatDau'],
          ) ??
          DateTime.now(),

      ketThuc: parseNullableDate(
            json['ketThuc'] ?? json['KetThuc'],
          ) ??
          DateTime.now(),

      soPhut: json['soPhut'] ?? json['SoPhut'] ?? 0,
      lyDoTangCa:
          json['lyDoTangCa'] ?? json['LyDoTangCa'] ?? '',

      trangThaiDuyet:
          json['trangThaiDuyet'] ?? json['TrangThaiDuyet'] ?? 0,

      ldKhoaDuyet:
          json['ldKhoaDuyet'] ?? json['LDKhoaDuyet'],

      tenLDKhoaDuyet:
          json['tenLDKhoaDuyet'] ?? json['TenLDKhoaDuyet'],

      ngayLDKhoaDuyet: parseNullableDate(
        json['ngayLDKhoaDuyet'] ?? json['NgayLDKhoaDuyet'],
      ),

      ldBVDuyet: json['ldBVDuyet'] ??
          json['ldbvDuyet'] ??
          json['LDBVDuyet'],

      tenLDBVDuyet:
          json['tenLDBVDuyet'] ?? json['TenLDBVDuyet'],

      ngayLDBVDuyet: parseNullableDate(
        json['ngayLDBVDuyet'] ?? json['NgayLDBVDuyet'],
      ),

      lyDoTuChoi:
          json['lyDoTuChoi'] ?? json['LyDoTuChoi'],
    );
  }

  bool get biKhoaTuChoi {
    return trangThaiDuyet == 3 &&
        (ldBVDuyet == null || ldBVDuyet!.trim().isEmpty);
  }

  bool get biBVTuChoi {
    return trangThaiDuyet == 3 &&
        ldBVDuyet != null &&
        ldBVDuyet!.trim().isNotEmpty;
  }
}