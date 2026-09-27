class TaiSan {
  final String? maTaiSan;
  final String? tentaisan;
  final String? model;
  final String? seri;
  final String? makhoa;
  final String? viTriSuDung;
  final KhoaNavigation? makhoaNavigation;

  TaiSan({
    this.maTaiSan,
    this.tentaisan,
    this.model,
    this.seri,
    this.makhoa,
    this.viTriSuDung,
    this.makhoaNavigation,
  });

  factory TaiSan.fromJson(Map<String, dynamic> json) {
    return TaiSan(
      maTaiSan: json['maTaiSan']?.toString(),
      tentaisan: json['tentaisan']?.toString(),
      model: json['model']?.toString(),
      seri: json['seri']?.toString(),
      makhoa: json['makhoa']?.toString(),
      viTriSuDung: json['viTriSuDung']?.toString(),
      makhoaNavigation: json['makhoaNavigation'] != null 
          ? KhoaNavigation.fromJson(json['makhoaNavigation']) 
          : null,
    );
  }
}

class KhoaNavigation {
  final String? makhoa;
  final String? tenkhoa;
  final int? soluongnv;
  final String? loaikhoa;
  final int? soThuTu;
  final bool? trangThaiSuDung;

  KhoaNavigation({
    this.makhoa,
    this.tenkhoa,
    this.soluongnv,
    this.loaikhoa,
    this.soThuTu,
    this.trangThaiSuDung,
  });

  factory KhoaNavigation.fromJson(Map<String, dynamic> json) {
    bool? parseBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value.toString().toLowerCase() == 'true') return true;
      if (value.toString().toLowerCase() == 'false') return false;
      if (value == 1 || value == '1') return true;
      if (value == 0 || value == '0') return false;
      return null;
    }

    return KhoaNavigation(
      makhoa: json['makhoa']?.toString(),
      tenkhoa: json['tenkhoa']?.toString(),
      soluongnv: json['soluongnv'] is int ? json['soluongnv'] : int.tryParse(json['soluongnv']?.toString() ?? ''),
      loaikhoa: json['loaikhoa']?.toString(),
      soThuTu: json['soThuTu'] is int ? json['soThuTu'] : int.tryParse(json['soThuTu']?.toString() ?? ''),
      trangThaiSuDung: parseBool(json['trangThaiSuDung']),
    );
  }
}

class TaiSanResponse {
  final bool? success;
  final int? statusCode;
  final String? message;
  final List<TaiSan>? data;

  TaiSanResponse({this.success, this.statusCode, this.message, this.data});

  factory TaiSanResponse.fromJson(Map<String, dynamic> json) {
    return TaiSanResponse(
      success: json['success'] == true || json['success'] == 'true',
      statusCode: json['statusCode'] is int ? json['statusCode'] : int.tryParse(json['statusCode']?.toString() ?? ''),
      message: json['message']?.toString(),
      data: json['data'] != null && json['data'] is List
          ? (json['data'] as List).map((i) => TaiSan.fromJson(i)).toList() 
          : null,
    );
  }
}