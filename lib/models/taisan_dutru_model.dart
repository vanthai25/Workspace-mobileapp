class TaiSanDuTru {
  final String maPhieuDuTru;
  final String? ngayDuTru;
  final String? maKhoaDeNghi;
  final String? maNguoiYeuCau;
  final String? ghiChuDuTru;
  final int? trangThaiPhieu;
  final String? maNguoiTiepNhan;
  final String? nguoiDuyetDuTru;
  final String? tenKhoaDeNghi;
  final String? tenNguoiYeuCau;
  final String? tenNguoiTiepNhan;
  final String? tenNguoiDuyetDuTru;
  final String? ngayDuyetDuTru;
  final String? ngayTtmsnhan;
  final String? manvTtms;
  final String? tennvTtms;
  final String? maOtp;
  final String? ngayLdkhoaDuyet;
  final String? manvHdqt;
  final String? ngayHdqtduyet;
  final bool? duyetKho;
  final String? tenHDQT;
  final String? lydoHDTVtuchoi; 
  final String? ghichuHDTVduyet;
  final String? lydoHDTVchuyen;
  final int? mucUuTien;
  final List<TaiSanDuTruChiTiet> chiTiets;

  TaiSanDuTru({
    required this.maPhieuDuTru,
    this.ngayDuTru,
    this.maKhoaDeNghi,
    this.maNguoiYeuCau,
    this.ghiChuDuTru,
    this.trangThaiPhieu,
    this.maNguoiTiepNhan,
    this.nguoiDuyetDuTru,
    this.tenKhoaDeNghi,
    this.tenNguoiYeuCau,
    this.tenNguoiTiepNhan,
    this.tenNguoiDuyetDuTru,
    this.ngayDuyetDuTru,
    this.ngayTtmsnhan,
    this.manvTtms,
    this.tennvTtms,
    this.maOtp,
    this.ngayLdkhoaDuyet,
    this.manvHdqt,
    this.ngayHdqtduyet,
    this.duyetKho,
    this.tenHDQT,
    this.lydoHDTVtuchoi, 
    this.ghichuHDTVduyet,
    this.lydoHDTVchuyen,
    this.mucUuTien,
    this.chiTiets = const [],
  });

  factory TaiSanDuTru.fromJson(Map<String, dynamic> json) {
    return TaiSanDuTru(
      maPhieuDuTru: json['maPhieuDuTru'] ?? '',
      ngayDuTru: json['ngayDuTru'],
      maKhoaDeNghi: json['maKhoaDeNghi'],
      maNguoiYeuCau: json['maNguoiYeuCau'],
      ghiChuDuTru: json['ghiChuDuTru'],
      trangThaiPhieu: json['trangThaiPhieu'] != null ? int.tryParse(json['trangThaiPhieu'].toString()) : 0,
      maNguoiTiepNhan: json['maNguoiTiepNhan'],
      nguoiDuyetDuTru: json['nguoiDuyetDuTru'],
      tenKhoaDeNghi: json['tenKhoaDeNghi'],
      tenNguoiYeuCau: json['tenNguoiYeuCau'],
      tenNguoiTiepNhan: json['tenNguoiTiepNhan'],
      tenNguoiDuyetDuTru: json['tenNguoiDuyetDuTru'],
      ngayDuyetDuTru: json['ngayDuyetDuTru'],
      ngayTtmsnhan: json['ngayTtmsnhan'],
      manvTtms: json['manvTtms'],
      tennvTtms: json['tennvTtms'],
      maOtp: json['maOtp'],
      ngayLdkhoaDuyet: json['ngayLdkhoaDuyet'],
      manvHdqt: json['manvHdqt'],
      ngayHdqtduyet: json['ngayHdqtduyet'],
      duyetKho: json['duyetKho'],
      tenHDQT: json['tenHDQT'],
      lydoHDTVtuchoi: json['lydoHDTVtuchoi'],
      ghichuHDTVduyet: json['ghichuHDTVduyet'],
      lydoHDTVchuyen: json['lydoHDTVchuyen'],
      mucUuTien: json['mucUuTien'] is int
      ? json['mucUuTien']
      : int.tryParse(
          json['mucUuTien']?.toString() ?? '',
        ),
      chiTiets: (json['taiSanDuTruChiTiets'] as List<dynamic>?)
              ?.map((e) => TaiSanDuTruChiTiet.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}

class TaiSanDuTruChiTiet {
  final int? maTaiSanDuTruChiTiet;
  final String? tenTaiSan;
  final String? donViTinh;
  final num? soLuong;
  final String? ghiChuDuTruChiTiet;
  final String? model;

  TaiSanDuTruChiTiet({
    this.maTaiSanDuTruChiTiet,
    this.tenTaiSan,
    this.donViTinh,
    this.soLuong,
    this.ghiChuDuTruChiTiet,
    this.model,
  });

  factory TaiSanDuTruChiTiet.fromJson(Map<String, dynamic> json) {
    return TaiSanDuTruChiTiet(
      maTaiSanDuTruChiTiet: json['maTaiSanDuTruChiTiet'],
      tenTaiSan: json['tenTaiSan'],
      donViTinh: json['donViTinh'],
      soLuong: json['soLuong'],
      ghiChuDuTruChiTiet: json['ghiChuDuTruChiTiet'],
      model: json['model'],
    );
  }
}