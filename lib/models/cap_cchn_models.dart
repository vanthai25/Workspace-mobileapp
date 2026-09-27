class CapCchnFileModel {
  final int idFile;
  final String fileName;
  final String? fileType;
  final int fileSize;

  const CapCchnFileModel({
    required this.idFile,
    required this.fileName,
    this.fileType,
    this.fileSize = 0,
  });

  factory CapCchnFileModel.fromJson(Map<String, dynamic> json) {
    return CapCchnFileModel(
      idFile: _toInt(json['idFile']),
      fileName: json['fileName']?.toString() ?? '',
      fileType: json['fileType']?.toString(),
      fileSize: _toInt(json['fileSize']),
    );
  }
}

class CapCchnMentorModel {
  final int idNguoiHuongDan;
  final String maSo;
  final String? hoVaTen;
  final int idKhoaPhong;
  final String? tenKhoaPhong;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;
  final String? nguoiUD;
  final DateTime? ngayUD;

  const CapCchnMentorModel({
    required this.idNguoiHuongDan,
    required this.maSo,
    this.hoVaTen,
    required this.idKhoaPhong,
    this.tenKhoaPhong,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.nguoiUD,
    this.ngayUD,
  });

  factory CapCchnMentorModel.fromJson(Map<String, dynamic> json) {
    return CapCchnMentorModel(
      idNguoiHuongDan: _toInt(json['idNguoiHuongDan']),
      maSo: json['maSo']?.toString() ?? '',
      hoVaTen: json['hoVaTen']?.toString(),
      idKhoaPhong: _toInt(json['idKhoaPhong']),
      tenKhoaPhong: json['tenKhoaPhong']?.toString(),
      ngayBatDau: _toDate(json['ngayBatDau']),
      ngayKetThuc: _toDate(json['ngayKetThuc']),
      nguoiUD: json['nguoiUD']?.toString(),
      ngayUD: _toDate(json['ngayUD']),
    );
  }

  Map<String, dynamic> toWriteJson() => <String, dynamic>{
    'maSo': maSo,
    'idKhoaPhong': idKhoaPhong,
    'ngayBatDau': _toApiDate(ngayBatDau),
    'ngayKetThuc': _toApiDate(ngayKetThuc),
  };
}

class CapCchnModel {
  final int idCapCCCHN;
  final String maSo;
  final String? hoVaTen;
  final DateTime? ngaySinh;
  final bool? gioiTinh;
  final String? soCCCD;
  final DateTime? ngayCapCCCD;
  final String? soDienThoai;
  final String? diaChiThuongTru;
  final String? trinhDoChuyenMon;
  final String? truongDonVi;
  final DateTime? ngayBatDauThucHanh;
  final DateTime? ngayKetThucThucHanh;
  final double? hocPhi;
  final String? ghiChu;
  final int? loaiNhanVien;
  final String? tenLoaiNhanVien;
  final int? idTinhTrang;
  final CapCchnFileModel? anhDaiDien;
  final CapCchnFileModel? fileHocPhi;
  final String? tenKhoaPhong;
  final String? tenToDoi;
  final String? tenChucDanh;
  final String? tenChucVu;
  final bool isDeNghiTH;
  final bool isSoYeuLL;
  final bool isCCCD;
  final bool isVanBangCM;
  final bool isAnh34;
  final bool isNhatKyTH;
  final bool isBaoCaoTH;
  final int soNguoiHuongDan;
  final int soDotDangThucHanh;
  final int soDotSapKetThuc;
  final int soDotDaHoanThanh;
  final int soDotSapBatDau;
  final DateTime? ngayKetThucGanNhat;
  final CapCchnFileModel? fileHopDong;
  final CapCchnFileModel? fileQuyetDinh;
  final CapCchnFileModel? fileXacNhanTH;
  final CapCchnFileModel? fileThongBaoTiepNhan;
  final List<CapCchnMentorModel> nguoiHuongDans;
  final String? nguoiUD;
  final DateTime? ngayUD;

  const CapCchnModel({
    required this.idCapCCCHN,
    required this.maSo,
    this.hoVaTen,
    this.ngaySinh,
    this.gioiTinh,
    this.soCCCD,
    this.ngayCapCCCD,
    this.soDienThoai,
    this.diaChiThuongTru,
    this.trinhDoChuyenMon,
    this.truongDonVi,
    this.ngayBatDauThucHanh,
    this.ngayKetThucThucHanh,
    this.hocPhi,
    this.ghiChu,
    this.loaiNhanVien,
    this.tenLoaiNhanVien,
    this.idTinhTrang,
    this.anhDaiDien,
    this.fileHocPhi,
    this.tenKhoaPhong,
    this.tenToDoi,
    this.tenChucDanh,
    this.tenChucVu,
    this.isDeNghiTH = false,
    this.isSoYeuLL = false,
    this.isCCCD = false,
    this.isVanBangCM = false,
    this.isAnh34 = false,
    this.isNhatKyTH = false,
    this.isBaoCaoTH = false,
    this.soNguoiHuongDan = 0,
    this.soDotDangThucHanh = 0,
    this.soDotSapKetThuc = 0,
    this.soDotDaHoanThanh = 0,
    this.soDotSapBatDau = 0,
    this.ngayKetThucGanNhat,
    this.fileHopDong,
    this.fileQuyetDinh,
    this.fileXacNhanTH,
    this.fileThongBaoTiepNhan,
    this.nguoiHuongDans = const <CapCchnMentorModel>[],
    this.nguoiUD,
    this.ngayUD,
  });

  int get completedDocumentCount => <bool>[
    isDeNghiTH,
    isSoYeuLL,
    isCCCD,
    isVanBangCM,
    isAnh34,
    isNhatKyTH,
    isBaoCaoTH,
  ].where((bool value) => value).length;

  int? get daysUntilNearestEnd {
    if (ngayKetThucGanNhat == null) return null;
    final DateTime today = DateTime.now();
    final DateTime normalizedToday = DateTime(
      today.year,
      today.month,
      today.day,
    );
    final DateTime end = DateTime(
      ngayKetThucGanNhat!.year,
      ngayKetThucGanNhat!.month,
      ngayKetThucGanNhat!.day,
    );
    return end.difference(normalizedToday).inDays;
  }

  factory CapCchnModel.fromJson(Map<String, dynamic> json) {
    CapCchnFileModel? file(String key) {
      final dynamic value = json[key];
      return value is Map
          ? CapCchnFileModel.fromJson(Map<String, dynamic>.from(value))
          : null;
    }

    final dynamic rawMentors = json['nguoiHuongDans'];
    final List<CapCchnMentorModel> mentors = rawMentors is List
        ? rawMentors
              .whereType<Map>()
              .map(
                (Map value) => CapCchnMentorModel.fromJson(
                  Map<String, dynamic>.from(value),
                ),
              )
              .toList()
        : const <CapCchnMentorModel>[];

    return CapCchnModel(
      idCapCCCHN: _toInt(json['idCapCCCHN']),
      maSo: json['maSo']?.toString() ?? '',
      hoVaTen: json['hoVaTen']?.toString(),
      ngaySinh: _toDate(json['ngaySinh']),
      gioiTinh: json['gioiTinh'] == null ? null : _toBool(json['gioiTinh']),
      soCCCD: json['soCCCD']?.toString(),
      ngayCapCCCD: _toDate(json['ngayCapCCCD']),
      soDienThoai: json['soDienThoai']?.toString(),
      diaChiThuongTru: json['diaChiThuongTru']?.toString(),
      trinhDoChuyenMon: json['trinhDoChuyenMon']?.toString(),
      truongDonVi: json['truongDonVi']?.toString(),
      ngayBatDauThucHanh: _toDate(json['ngayBatDauThucHanh']),
      ngayKetThucThucHanh: _toDate(json['ngayKetThucThucHanh']),
      hocPhi: _toDouble(json['hocPhi']),
      ghiChu: json['ghiChu']?.toString(),
      loaiNhanVien: _toNullableInt(json['loaiNhanVien']),
      tenLoaiNhanVien: json['tenLoaiNhanVien']?.toString(),
      idTinhTrang: _toNullableInt(json['idTinhTrang']),
      anhDaiDien: file('anhDaiDien'),
      fileHocPhi: file('fileHocPhi'),
      tenKhoaPhong: json['tenKhoaPhong']?.toString(),
      tenToDoi: json['tenToDoi']?.toString(),
      tenChucDanh: json['tenChucDanh']?.toString(),
      tenChucVu: json['tenChucVu']?.toString(),
      isDeNghiTH: _toBool(json['isDeNghiTH']),
      isSoYeuLL: _toBool(json['isSoYeuLL']),
      isCCCD: _toBool(json['isCCCD']),
      isVanBangCM: _toBool(json['isVanBangCM']),
      isAnh34: _toBool(json['isAnh34']),
      isNhatKyTH: _toBool(json['isNhatKyTH']),
      isBaoCaoTH: _toBool(json['isBaoCaoTH']),
      soNguoiHuongDan: _toInt(json['soNguoiHuongDan']),
      soDotDangThucHanh: _toInt(json['soDotDangThucHanh']),
      soDotSapKetThuc: _toInt(json['soDotSapKetThuc']),
      soDotDaHoanThanh: _toInt(json['soDotDaHoanThanh']),
      soDotSapBatDau: _toInt(json['soDotSapBatDau']),
      ngayKetThucGanNhat: _toDate(json['ngayKetThucGanNhat']),
      fileHopDong: file('fileHopDong'),
      fileQuyetDinh: file('fileQuyetDinh'),
      fileXacNhanTH: file('fileXacNhanTH'),
      fileThongBaoTiepNhan: file('fileThongBaoTiepNhan'),
      nguoiHuongDans: mentors,
      nguoiUD: json['nguoiUD']?.toString(),
      ngayUD: _toDate(json['ngayUD']),
    );
  }
}

class CapCchnPageResult {
  final List<CapCchnModel> items;
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const CapCchnPageResult({
    this.items = const <CapCchnModel>[],
    this.currentPage = 1,
    this.pageSize = 12,
    this.totalCount = 0,
    this.totalPages = 0,
  });
}

class CapCchnCatalogItem {
  final int id;
  final String ten;

  const CapCchnCatalogItem({required this.id, required this.ten});

  factory CapCchnCatalogItem.fromJson(Map<String, dynamic> json) =>
      CapCchnCatalogItem(
        id: _toInt(json['id']),
        ten: json['ten']?.toString() ?? '',
      );
}

class CapCchnCatalog {
  final List<CapCchnCatalogItem> khoaPhongs;
  final List<CapCchnCatalogItem> loaiNhanViens;

  const CapCchnCatalog({
    this.khoaPhongs = const [],
    this.loaiNhanViens = const [],
  });

  factory CapCchnCatalog.fromJson(Map<String, dynamic> json) => CapCchnCatalog(
    khoaPhongs: _parseCatalog(json['khoaPhongs']),
    loaiNhanViens: _parseCatalog(json['loaiNhanViens']),
  );
}

class CapCchnMentorOption {
  final String maSo;
  final String hoVaTen;
  final int? loaiNhanVien;
  final int soNguoiDangHuongDan;
  final DateTime? ngayBatDauGoiY;
  final DateTime? ngayKetThucGoiY;
  final List<CapCchnMentorAssignment> nguoiDangHuongDan;

  const CapCchnMentorOption({
    required this.maSo,
    required this.hoVaTen,
    this.loaiNhanVien,
    this.soNguoiDangHuongDan = 0,
    this.ngayBatDauGoiY,
    this.ngayKetThucGoiY,
    this.nguoiDangHuongDan = const <CapCchnMentorAssignment>[],
  });

  bool get daDuSoLuong => soNguoiDangHuongDan >= 5;

  factory CapCchnMentorOption.fromJson(Map<String, dynamic> json) {
    final dynamic rawAssignments = json['nguoiDangHuongDan'];
    return CapCchnMentorOption(
      maSo: json['maSo']?.toString() ?? '',
      hoVaTen: json['hoVaTen']?.toString() ?? '',
      loaiNhanVien: _toNullableInt(json['loaiNhanVien']),
      soNguoiDangHuongDan: _toInt(json['soNguoiDangHuongDan']),
      ngayBatDauGoiY: _toDate(json['ngayBatDauGoiY']),
      ngayKetThucGoiY: _toDate(json['ngayKetThucGoiY']),
      nguoiDangHuongDan: rawAssignments is List
          ? rawAssignments
                .whereType<Map>()
                .map(
                  (Map value) => CapCchnMentorAssignment.fromJson(
                    Map<String, dynamic>.from(value),
                  ),
                )
                .toList()
          : const <CapCchnMentorAssignment>[],
    );
  }
}

class CapCchnMentorAssignment {
  final int idCapCchn;
  final String hoVaTen;
  final String? soCCCD;
  final int idKhoaPhong;
  final String? tenKhoaPhong;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;

  const CapCchnMentorAssignment({
    required this.idCapCchn,
    required this.hoVaTen,
    this.soCCCD,
    required this.idKhoaPhong,
    this.tenKhoaPhong,
    this.ngayBatDau,
    this.ngayKetThuc,
  });

  factory CapCchnMentorAssignment.fromJson(Map<String, dynamic> json) =>
      CapCchnMentorAssignment(
        idCapCchn: _toInt(json['idCapCchn']),
        hoVaTen: json['hoVaTen']?.toString() ?? '',
        soCCCD: json['soCCCD']?.toString(),
        idKhoaPhong: _toInt(json['idKhoaPhong']),
        tenKhoaPhong: json['tenKhoaPhong']?.toString(),
        ngayBatDau: _toDate(json['ngayBatDau']),
        ngayKetThuc: _toDate(json['ngayKetThuc']),
      );
}

List<CapCchnCatalogItem> _parseCatalog(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map(
            (Map item) =>
                CapCchnCatalogItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList()
    : <CapCchnCatalogItem>[];

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString().toLowerCase() == 'true';
}

DateTime? _toDate(dynamic value) {
  final String text = value?.toString() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text);
}

String? _toApiDate(DateTime? value) {
  if (value == null) return null;
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
