class TapTin {
  final int? id;
  final String? tenTapTin;
  final String? duongDan;
  final String? moTa;
  final dynamic loaiId;
  final String? tenLoai;
  final String? ngayUp;

  TapTin({
    this.id,
    this.tenTapTin,
    this.duongDan,
    this.moTa,
    this.loaiId,
    this.tenLoai,
    this.ngayUp,
  });

  factory TapTin.fromJson(Map<String, dynamic> json) {
    return TapTin(
      id: json['id'],
      tenTapTin: json['tenTapTin']?.toString(),
      duongDan: json['duongDan']?.toString(),
      moTa: json['moTa']?.toString(),
      loaiId: json['loaiId'],
      tenLoai: json['loai'] != null ? json['loai']['tenLoai']?.toString() : null,
      ngayUp: json['ngayUp']?.toString(),
    );
  }
}