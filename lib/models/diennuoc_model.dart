class DienNuoc {
  int? id;
  int? idHoGiaDinh;
  String? soPhong;
  String? hoGiaDinh;
  String? khuVuc;
  int? thang;
  int? nam;
  int? csdienCu;
  int? csdienMoi;
  int? tongDien;
  int? csnuocCu;
  int? csnuocMoi;
  int? tongNuoc;
  String? ghiChu;
  DateTime? sysdate;
  String? manv;
  String? tennv;
  bool? isLatest;

  DienNuoc({
    this.id,
    this.idHoGiaDinh,
    this.soPhong,
    this.hoGiaDinh,
    this.khuVuc,
    this.thang,
    this.nam,
    this.csdienCu,
    this.csdienMoi,
    this.tongDien,
    this.csnuocCu,
    this.csnuocMoi,
    this.tongNuoc,
    this.ghiChu,
    this.sysdate,
    this.manv,
    this.tennv,
    this.isLatest,
  });

  factory DienNuoc.fromJson(Map<String, dynamic> json) {
    return DienNuoc(
      id: json['id'],
      idHoGiaDinh: json['idHoGiaDinh'],
      soPhong: json['soPhong'],
      hoGiaDinh: json['hoGiaDinh'],
      khuVuc: json['khuVuc'],
      thang: json['thang'],
      nam: json['nam'],
      csdienCu: json['csdienCu'],
      csdienMoi: json['csdienMoi'],
      tongDien: json['tongDien'],
      csnuocCu: json['csnuocCu'],
      csnuocMoi: json['csnuocMoi'],
      tongNuoc: json['tongNuoc'],
      ghiChu: json['ghiChu'],
      sysdate: json['sysdate'] != null ? DateTime.parse(json['sysdate']) : null,
      manv: json['manv'],
      tennv: json['tennv'],
      isLatest: json['isLatest'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idHoGiaDinh': idHoGiaDinh,
      'thang': thang,
      'nam': nam,
      'csdienCu': csdienCu,
      'csdienMoi': csdienMoi,
      'csnuocCu': csnuocCu,
      'csnuocMoi': csnuocMoi,
      'ghiChu': ghiChu,
    };
  }
}