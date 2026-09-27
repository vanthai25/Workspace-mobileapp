class XNTraSau {
  final int id;
  final String? ngay;
  final String? hoten;
  final int? namsinh;
  final String? gioitinh;
  final int? mahh;
  final String? tenhh;
  final String? maview;
  final String? nguoitra;
  final String? makcb;
  final String? tuoi;
  final String? barcode;
  final String? khoacd;
  final String? phongcd;
  final String? ngaycd;
  final String? nguoicd;
  final int? mathanhtoanct;
  final String? diachi;
  final String? dienthoai;
  final int? state;
  final String? ngaytraML;
  final String? bstrabn;
  final String? ngaybstrabn;
  final String? tennguoicd;
  final String? tenChucDanh;
  final String? tenbstrabn;
  final String? tenNguoiTraKhoaXN;

  XNTraSau({
    required this.id,
    this.ngay,
    this.hoten,
    this.namsinh,
    this.gioitinh,
    this.mahh,
    this.tenhh,
    this.maview,
    this.nguoitra,
    this.makcb,
    this.tuoi,
    this.barcode,
    this.khoacd,
    this.phongcd,
    this.ngaycd,
    this.nguoicd,
    this.mathanhtoanct,
    this.diachi,
    this.dienthoai,
    this.state,
    this.ngaytraML,
    this.bstrabn,
    this.ngaybstrabn,
    this.tennguoicd,
    this.tenChucDanh,
    this.tenbstrabn,
    this.tenNguoiTraKhoaXN,
  });

  factory XNTraSau.fromJson(Map<String, dynamic> json) {
    return XNTraSau(
      id: json['id'] ?? 0,
      ngay: json['ngay'],
      hoten: json['hoten'],
      namsinh: json['namsinh'],
      gioitinh: json['gioitinh'],
      mahh: json['mahh'],
      tenhh: json['tenhh'],
      maview: json['maview'],
      nguoitra: json['nguoitra'],
      makcb: json['makcb'],
      tuoi: json['tuoi'],
      barcode: json['barcode'],
      khoacd: json['khoacd'],
      phongcd: json['phongcd'],
      ngaycd: json['ngaycd'],
      nguoicd: json['nguoicd'],
      mathanhtoanct: json['mathanhtoanct'],
      diachi: json['diachi'],
      dienthoai: json['dienthoai'],
      state: json['state'],
      ngaytraML: json['ngaytraML'],
      bstrabn: json['bstrabn'],
      ngaybstrabn: json['ngaybstrabn'],
      tennguoicd: json['tennguoicd'],
      tenChucDanh: json['tenChucDanh'],
      tenbstrabn: json['tenbstrabn'],
      tenNguoiTraKhoaXN: json['tenNguoiTraKhoaXN'],
    );
  }
}