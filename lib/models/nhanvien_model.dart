class NhanVien {
  final String manv;
  final String? tennv;
  final String? ngaysinh;
  final String? diachi;
  final String? tinh;
  final String? tamtru;
  final String? gioitinh;
  final String? dienthoai1;
  final String? dienthoai2;
  final String? email;
  final String? emailhungvuong;
  final String? dienthoaiZalo;
  final String? makhoa;
  final String? macv;
  final String? matd;
  final int? mato;
  final int? loai;
  final int? diemso;
  final bool? kethon;
  final String? anh;
  final String? maidcard;
  final String? ngaycapid;
  final String? noicapid;
  final String? noidaotao;
  final String? dantoc;
  final String? ngayhocviec;
  final String? ngaythuviec;
  final String? ngaybienche;
  final bool? vaodang;
  final String? chungchihanhnghe;
  final String? machucdanh;
  final int? lanthamnien;
  final int? luongthamnien;
  final String? abo;
  final String? rh;
  final String? dinguyen;
  final String? ngayNghiViec;
  final String? ghiChu;
  final String? donthuocquocgiaMalienthong;
  final String? tenchucdanh;
  final String? tencv;
  final String? tentd;
  final String? tenkhoa;

  NhanVien({
    required this.manv,
    this.tennv,
    this.ngaysinh,
    this.diachi,
    this.tinh,
    this.tamtru,
    this.gioitinh,
    this.dienthoai1,
    this.dienthoai2,
    this.email,
    this.emailhungvuong,
    this.dienthoaiZalo,
    this.makhoa,
    this.macv,
    this.matd,
    this.mato,
    this.loai,
    this.diemso,
    this.kethon,
    this.anh,
    this.maidcard,
    this.ngaycapid,
    this.noicapid,
    this.noidaotao,
    this.dantoc,
    this.ngayhocviec,
    this.ngaythuviec,
    this.ngaybienche,
    this.vaodang,
    this.chungchihanhnghe,
    this.machucdanh,
    this.lanthamnien,
    this.luongthamnien,
    this.abo,
    this.rh,
    this.dinguyen,
    this.ngayNghiViec,
    this.ghiChu,
    this.donthuocquocgiaMalienthong,
    this.tenchucdanh,
    this.tencv,
    this.tentd,
    this.tenkhoa,
  });

  factory NhanVien.fromJson(Map<String, dynamic> json) {
    return NhanVien(
      manv: json['manv'] ?? '',
      tennv: json['tennv'],
      ngaysinh: json['ngaysinh'],
      diachi: json['diachi'],
      tinh: json['tinh'],
      tamtru: json['tamtru'],
      gioitinh: json['gioitinh'],
      dienthoai1: json['dienthoai1'],
      dienthoai2: json['dienthoai2'],
      email: json['email'],
      emailhungvuong: json['emailhungvuong'],
      dienthoaiZalo: json['dienthoaiZalo'],
      makhoa: json['makhoa'],
      macv: json['macv'],
      matd: json['matd'],
      mato: json['mato'],
      loai: json['loai'],
      diemso: json['diemso'],
      kethon: json['kethon'],
      anh: json['anh'],
      maidcard: json['maidcard'],
      ngaycapid: json['ngaycapid'],
      noicapid: json['noicapid'],
      noidaotao: json['noidaotao'],
      dantoc: json['dantoc'],
      ngayhocviec: json['ngayhocviec'],
      ngaythuviec: json['ngaythuviec'],
      ngaybienche: json['ngaybienche'],
      vaodang: json['vaodang'],
      chungchihanhnghe: json['chungchihanhnghe'],
      machucdanh: json['machucdanh'],
      lanthamnien: json['lanthamnien'],
      luongthamnien: json['luongthamnien'],
      abo: json['abo'],
      rh: json['rh'],
      dinguyen: json['dinguyen'],
      ngayNghiViec: json['ngayNghiViec'],
      ghiChu: json['ghiChu'],
      donthuocquocgiaMalienthong: json['donthuocquocgiaMalienthong'],
      tenchucdanh: json['tenchucdanh']?.toString(), 
      tencv: json['tencv']?.toString(),
      tentd: json['tentd']?.toString(),
      tenkhoa: json['tenkhoa']?.toString(),
    );
  }
}