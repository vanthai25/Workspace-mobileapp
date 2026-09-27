class Khoa {
  final String? makhoa;
  final String? tenkhoa;
  final int? soluongnv;
  final String? loaikhoa;
  final int? soThuTu;
  final bool? trangThaiSuDung;

  Khoa({
    this.makhoa,
    this.tenkhoa,
    this.soluongnv,
    this.loaikhoa,
    this.soThuTu,
    this.trangThaiSuDung,
  });

  factory Khoa.fromJson(Map<String, dynamic> json) {
    return Khoa(
      makhoa: json['makhoa']?.toString(),
      tenkhoa: json['tenkhoa']?.toString(),
      // Xử lý an toàn phòng trường hợp API trả về chuỗi thay vì số
      soluongnv: json['soluongnv'] is int ? json['soluongnv'] : int.tryParse(json['soluongnv']?.toString() ?? ''),
      loaikhoa: json['loaikhoa']?.toString(),
      soThuTu: json['soThuTu'] is int ? json['soThuTu'] : int.tryParse(json['soThuTu']?.toString() ?? ''),
      trangThaiSuDung: json['trangThaiSuDung'],
    );
  }
}