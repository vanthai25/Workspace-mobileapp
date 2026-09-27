class NuocThai {
  final int? id;
  final DateTime? ngay;
  final double? chiSoCu;
  final double? chiSoMoi;
  final double? tong;
  final String? maNhanVien;
  final String? chiNhanh;
  final String? ghiChu;
  final bool? batThuong;
  final DateTime? sysdate;
  final String? tennv;

  NuocThai({
    this.id,
    this.ngay,
    this.chiSoCu,
    this.chiSoMoi,
    this.tong,
    this.maNhanVien,
    this.chiNhanh,
    this.ghiChu,
    this.batThuong,
    this.sysdate,
    this.tennv,
  });

  factory NuocThai.fromJson(Map<String, dynamic> json) {
    return NuocThai(
      id: json['id'],
      ngay: json['ngay'] != null ? DateTime.parse(json['ngay']) : null,
      chiSoCu: json['chiSoCu']?.toDouble(),
      chiSoMoi: json['chiSoMoi']?.toDouble(),
      tong: json['tong']?.toDouble(),
      maNhanVien: json['maNhanVien']?.toString(),
      chiNhanh: json['chiNhanh']?.toString(),
      ghiChu: json['ghiChu']?.toString(),
      batThuong: json['batThuong'] ?? false,
      sysdate: json['sysdate'] != null ? DateTime.parse(json['sysdate']) : null,
      tennv: json['tennv']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'ngay': ngay?.toIso8601String(),
      'chiSoCu': chiSoCu,
      'chiSoMoi': chiSoMoi,
      if (tong != null) 'tong': tong,
      if (maNhanVien != null) 'maNhanVien': maNhanVien,
      'chiNhanh': chiNhanh,
      'ghiChu': ghiChu,
      'batThuong': batThuong,
    };
  }
}