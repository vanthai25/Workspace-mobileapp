class DaoTaoBaoCaoDanhMucModel {
  final List<DaoTaoBaoCaoLopOptionModel> lopDaoTaos;
  final List<String> diaDiems;
  final List<DaoTaoBaoCaoLoaiNhanVienModel> loaiNhanViens;

  const DaoTaoBaoCaoDanhMucModel({
    this.lopDaoTaos = const [],
    this.diaDiems = const [],
    this.loaiNhanViens = const [],
  });

  factory DaoTaoBaoCaoDanhMucModel.fromJson(Map<String, dynamic> json) {
    return DaoTaoBaoCaoDanhMucModel(
      lopDaoTaos: _maps(
        json['lopDaoTaos'],
      ).map(DaoTaoBaoCaoLopOptionModel.fromJson).toList(),
      diaDiems: (json['diaDiems'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      loaiNhanViens: _maps(
        json['loaiNhanViens'],
      ).map(DaoTaoBaoCaoLoaiNhanVienModel.fromJson).toList(),
    );
  }
}

class DaoTaoBaoCaoLopOptionModel {
  final int idLopDaoTao;
  final String tenLopDaoTao;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;
  final String? diaDiem;
  final String? tpThamDu;
  final int? phamViDaoTao;
  final String tenPhamViDaoTao;
  final String? tenKhoaPhong;
  final String? khoaPhongThamGia;

  const DaoTaoBaoCaoLopOptionModel({
    required this.idLopDaoTao,
    required this.tenLopDaoTao,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.diaDiem,
    this.tpThamDu,
    this.phamViDaoTao,
    this.tenPhamViDaoTao = '',
    this.tenKhoaPhong,
    this.khoaPhongThamGia,
  });

  factory DaoTaoBaoCaoLopOptionModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoBaoCaoLopOptionModel(
        idLopDaoTao: _int(json['idLopDaoTao']),
        tenLopDaoTao: json['tenLopDaoTao']?.toString() ?? '',
        ngayBatDau: _date(json['ngayBatDau']),
        ngayKetThuc: _date(json['ngayKetThuc']),
        diaDiem: json['diaDiem']?.toString(),
        tpThamDu: json['tpThamDu']?.toString(),
        phamViDaoTao: _nullableInt(json['phamViDaoTao']),
        tenPhamViDaoTao: json['tenPhamViDaoTao']?.toString() ?? '',
        tenKhoaPhong: json['tenKhoaPhong']?.toString(),
        khoaPhongThamGia: json['khoaPhongThamGia']?.toString(),
      );
}

class DaoTaoBaoCaoLoaiNhanVienModel {
  final int loaiNhanVien;
  final String tenLoaiNhanVien;

  const DaoTaoBaoCaoLoaiNhanVienModel({
    required this.loaiNhanVien,
    required this.tenLoaiNhanVien,
  });

  factory DaoTaoBaoCaoLoaiNhanVienModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoBaoCaoLoaiNhanVienModel(
        loaiNhanVien: _int(json['loaiNhanVien']),
        tenLoaiNhanVien: json['tenLoaiNhanVien']?.toString() ?? '',
      );
}

class DaoTaoBaoCaoTongHopModel {
  final DateTime? tuNgay;
  final DateTime? denNgay;
  final int soLopDaChon;
  final int tongNhanSu;
  final int soNguoiHopLe;
  final int soNguoiKhongThamGia;
  final List<DaoTaoBaoCaoLopModel> lopDaoTaos;
  final List<DaoTaoBaoCaoCaNhanModel> caNhans;

  const DaoTaoBaoCaoTongHopModel({
    this.tuNgay,
    this.denNgay,
    this.soLopDaChon = 0,
    this.tongNhanSu = 0,
    this.soNguoiHopLe = 0,
    this.soNguoiKhongThamGia = 0,
    this.lopDaoTaos = const [],
    this.caNhans = const [],
  });

  factory DaoTaoBaoCaoTongHopModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoBaoCaoTongHopModel(
        tuNgay: _date(json['tuNgay']),
        denNgay: _date(json['denNgay']),
        soLopDaChon: _int(json['soLopDaChon']),
        tongNhanSu: _int(json['tongNhanSu']),
        soNguoiHopLe: _int(json['soNguoiHopLe']),
        soNguoiKhongThamGia: _int(json['soNguoiKhongThamGia']),
        lopDaoTaos: _maps(
          json['lopDaoTaos'],
        ).map(DaoTaoBaoCaoLopModel.fromJson).toList(),
        caNhans: _maps(
          json['caNhans'],
        ).map(DaoTaoBaoCaoCaNhanModel.fromJson).toList(),
      );
}

class DaoTaoBaoCaoLopModel {
  final int idLopDaoTao;
  final String tenLopDaoTao;
  final DateTime? ngayBatDau;
  final String? diaDiem;
  final String? tpThamDu;
  final int? phamViDaoTao;
  final String tenPhamViDaoTao;
  final String? khoaPhongThamGia;
  final int soDangKy;
  final int soHopLe;
  final int soKhongHopLe;
  final int soChuaXacNhan;

  const DaoTaoBaoCaoLopModel({
    required this.idLopDaoTao,
    required this.tenLopDaoTao,
    this.ngayBatDau,
    this.diaDiem,
    this.tpThamDu,
    this.phamViDaoTao,
    this.tenPhamViDaoTao = '',
    this.khoaPhongThamGia,
    this.soDangKy = 0,
    this.soHopLe = 0,
    this.soKhongHopLe = 0,
    this.soChuaXacNhan = 0,
  });

  factory DaoTaoBaoCaoLopModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoBaoCaoLopModel(
        idLopDaoTao: _int(json['idLopDaoTao']),
        tenLopDaoTao: json['tenLopDaoTao']?.toString() ?? '',
        ngayBatDau: _date(json['ngayBatDau']),
        diaDiem: json['diaDiem']?.toString(),
        tpThamDu: json['tpThamDu']?.toString(),
        phamViDaoTao: _nullableInt(json['phamViDaoTao']),
        tenPhamViDaoTao: json['tenPhamViDaoTao']?.toString() ?? '',
        khoaPhongThamGia: json['khoaPhongThamGia']?.toString(),
        soDangKy: _int(json['soDangKy']),
        soHopLe: _int(json['soHopLe']),
        soKhongHopLe: _int(json['soKhongHopLe']),
        soChuaXacNhan: _int(json['soChuaXacNhan']),
      );
}

class DaoTaoBaoCaoCaNhanModel {
  final String maSo;
  final String hoVaTen;
  final String? tenKhoaPhong;
  final String? tenLoaiNhanVien;
  final int soLopDaDangKy;
  final int soLopHopLe;
  final int soLopToanVien;
  final int soLopKhoaPhong;
  final bool daHopLeBatKy;
  final List<DaoTaoBaoCaoCaNhanLopModel> ketQuaTheoLops;

  const DaoTaoBaoCaoCaNhanModel({
    required this.maSo,
    required this.hoVaTen,
    this.tenKhoaPhong,
    this.tenLoaiNhanVien,
    this.soLopDaDangKy = 0,
    this.soLopHopLe = 0,
    this.soLopToanVien = 0,
    this.soLopKhoaPhong = 0,
    this.daHopLeBatKy = false,
    this.ketQuaTheoLops = const [],
  });

  factory DaoTaoBaoCaoCaNhanModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoBaoCaoCaNhanModel(
        maSo: json['maSo']?.toString() ?? '',
        hoVaTen: json['hoVaTen']?.toString() ?? '',
        tenKhoaPhong: json['tenKhoaPhong']?.toString(),
        tenLoaiNhanVien: json['tenLoaiNhanVien']?.toString(),
        soLopDaDangKy: _int(json['soLopDaDangKy']),
        soLopHopLe: _int(json['soLopHopLe']),
        soLopToanVien: _int(json['soLopToanVien']),
        soLopKhoaPhong: _int(json['soLopKhoaPhong']),
        daHopLeBatKy: json['daHopLeBatKy'] == true,
        ketQuaTheoLops: _maps(
          json['ketQuaTheoLops'],
        ).map(DaoTaoBaoCaoCaNhanLopModel.fromJson).toList(),
      );
}

class DaoTaoBaoCaoCmeTheoLoaiNhanVienModel {
  final int? loaiNhanVien;
  final String tenLoaiNhanVien;
  final int soNhanVien;
  final int soChungChi;
  final int soCme;
  final double tongGioTinChi;

  const DaoTaoBaoCaoCmeTheoLoaiNhanVienModel({
    this.loaiNhanVien,
    required this.tenLoaiNhanVien,
    this.soNhanVien = 0,
    this.soChungChi = 0,
    this.soCme = 0,
    this.tongGioTinChi = 0,
  });

  factory DaoTaoBaoCaoCmeTheoLoaiNhanVienModel.fromJson(
    Map<String, dynamic> json,
  ) => DaoTaoBaoCaoCmeTheoLoaiNhanVienModel(
    loaiNhanVien: _nullableInt(json['loaiNhanVien']),
    tenLoaiNhanVien: json['tenLoaiNhanVien']?.toString() ?? '',
    soNhanVien: _int(json['soNhanVien']),
    soChungChi: _int(json['soChungChi']),
    soCme: _int(json['soCme']),
    tongGioTinChi: _double(json['tongGioTinChi']),
  );
}

class DaoTaoBaoCaoCmeDanhMucModel {
  final List<DaoTaoBaoCaoLoaiNhanVienModel> loaiNhanViens;

  const DaoTaoBaoCaoCmeDanhMucModel({this.loaiNhanViens = const []});

  factory DaoTaoBaoCaoCmeDanhMucModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoBaoCaoCmeDanhMucModel(
        loaiNhanViens: _maps(
          json['loaiNhanViens'],
        ).map(DaoTaoBaoCaoLoaiNhanVienModel.fromJson).toList(),
      );
}

class DaoTaoBaoCaoCmeModel {
  final DateTime? tuNgay;
  final DateTime? denNgay;
  final int tongNhanSu;
  final int tongChungChiCme;
  final double tongGioTinChi;
  final List<DaoTaoBaoCaoCmeTheoLoaiNhanVienModel> theoLoaiNhanViens;
  final List<DaoTaoBaoCaoCmeCaNhanModel> caNhans;
  final List<DaoTaoBaoCaoChungChiCmeModel> chiTiets;

  const DaoTaoBaoCaoCmeModel({
    this.tuNgay,
    this.denNgay,
    this.tongNhanSu = 0,
    this.tongChungChiCme = 0,
    this.tongGioTinChi = 0,
    this.theoLoaiNhanViens = const [],
    this.caNhans = const [],
    this.chiTiets = const [],
  });

  factory DaoTaoBaoCaoCmeModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoBaoCaoCmeModel(
        tuNgay: _date(json['tuNgay']),
        denNgay: _date(json['denNgay']),
        tongNhanSu: _int(json['tongNhanSu']),
        tongChungChiCme: _int(json['tongChungChiCme']),
        tongGioTinChi: _double(json['tongGioTinChi']),
        theoLoaiNhanViens: _maps(
          json['theoLoaiNhanViens'],
        ).map(DaoTaoBaoCaoCmeTheoLoaiNhanVienModel.fromJson).toList(),
        caNhans: _maps(
          json['caNhans'],
        ).map(DaoTaoBaoCaoCmeCaNhanModel.fromJson).toList(),
        chiTiets: _maps(
          json['chiTiets'],
        ).map(DaoTaoBaoCaoChungChiCmeModel.fromJson).toList(),
      );
}

class DaoTaoBaoCaoCmeCaNhanModel {
  final String maSo;
  final String hoVaTen;
  final String? tenKhoaPhong;
  final String? tenLoaiNhanVien;
  final int soChungChi;
  final int soCme;
  final int tongChungChiCme;
  final double tongGioTinChi;

  const DaoTaoBaoCaoCmeCaNhanModel({
    required this.maSo,
    required this.hoVaTen,
    this.tenKhoaPhong,
    this.tenLoaiNhanVien,
    this.soChungChi = 0,
    this.soCme = 0,
    this.tongChungChiCme = 0,
    this.tongGioTinChi = 0,
  });

  factory DaoTaoBaoCaoCmeCaNhanModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoBaoCaoCmeCaNhanModel(
        maSo: json['maSo']?.toString() ?? '',
        hoVaTen: json['hoVaTen']?.toString() ?? '',
        tenKhoaPhong: json['tenKhoaPhong']?.toString(),
        tenLoaiNhanVien: json['tenLoaiNhanVien']?.toString(),
        soChungChi: _int(json['soChungChi']),
        soCme: _int(json['soCme']),
        tongChungChiCme: _int(json['tongChungChiCme']),
        tongGioTinChi: _double(json['tongGioTinChi']),
      );
}

class DaoTaoBaoCaoChungChiCmeModel {
  final int idChungChi;
  final String maSo;
  final String hoVaTen;
  final String? tenKhoaPhong;
  final String? tenLoaiNhanVien;
  final String tenChungChi;
  final bool isCme;
  final String? soChungChi;
  final String? donViDaoTao;
  final String? tenHinhThucDaoTao;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;
  final DateTime? ngayCap;
  final DateTime? ngayGhiNhan;
  final double gioTinChi;

  const DaoTaoBaoCaoChungChiCmeModel({
    required this.idChungChi,
    required this.maSo,
    required this.hoVaTen,
    required this.tenChungChi,
    this.tenKhoaPhong,
    this.tenLoaiNhanVien,
    this.isCme = false,
    this.soChungChi,
    this.donViDaoTao,
    this.tenHinhThucDaoTao,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.ngayCap,
    this.ngayGhiNhan,
    this.gioTinChi = 0,
  });

  factory DaoTaoBaoCaoChungChiCmeModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoBaoCaoChungChiCmeModel(
        idChungChi: _int(json['idChungChi']),
        maSo: json['maSo']?.toString() ?? '',
        hoVaTen: json['hoVaTen']?.toString() ?? '',
        tenKhoaPhong: json['tenKhoaPhong']?.toString(),
        tenLoaiNhanVien: json['tenLoaiNhanVien']?.toString(),
        tenChungChi: json['tenChungChi']?.toString() ?? '',
        isCme: json['isCme'] == true,
        soChungChi: json['soChungChi']?.toString(),
        donViDaoTao: json['donViDaoTao']?.toString(),
        tenHinhThucDaoTao: json['tenHinhThucDaoTao']?.toString(),
        ngayBatDau: _date(json['ngayBatDau']),
        ngayKetThuc: _date(json['ngayKetThuc']),
        ngayCap: _date(json['ngayCap']),
        ngayGhiNhan: _date(json['ngayGhiNhan']),
        gioTinChi: _double(json['gioTinChi']),
      );
}

class DaoTaoBaoCaoCaNhanLopModel {
  final int idLopDaoTao;
  final String tenLopDaoTao;
  final String trangThai;
  final bool daDangKy;
  final bool isHopLe;

  const DaoTaoBaoCaoCaNhanLopModel({
    required this.idLopDaoTao,
    required this.tenLopDaoTao,
    required this.trangThai,
    this.daDangKy = false,
    this.isHopLe = false,
  });

  factory DaoTaoBaoCaoCaNhanLopModel.fromJson(Map<String, dynamic> json) =>
      DaoTaoBaoCaoCaNhanLopModel(
        idLopDaoTao: _int(json['idLopDaoTao']),
        tenLopDaoTao: json['tenLopDaoTao']?.toString() ?? '',
        trangThai: json['trangThai']?.toString() ?? '',
        daDangKy: json['daDangKy'] == true,
        isHopLe: json['isHopLe'] == true,
      );
}

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

int? _nullableInt(dynamic value) =>
    value == null ? null : int.tryParse('$value');

double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.tryParse('$value');
