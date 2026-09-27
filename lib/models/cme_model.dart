import 'dart:typed_data';

class CmeStatus {
  static const String choDuyet = 'CHO_DUYET';
  static const String daDuyet = 'DA_DUYET';
  static const String tuChoi = 'TU_CHOI';

  static const String pending = choDuyet;
  static const String approved = daDuyet;
  static const String rejected = tuChoi;

  static const List<String> values = <String>[choDuyet, daDuyet, tuChoi];

  const CmeStatus._();
}

class CmeTrainingType {
  final int idHinhThucDaoTao;
  final String? tenHinhThucDaoTao;

  const CmeTrainingType({
    required this.idHinhThucDaoTao,
    this.tenHinhThucDaoTao,
  });

  int get id => idHinhThucDaoTao;

  String get name => tenHinhThucDaoTao?.trim() ?? '';

  factory CmeTrainingType.fromJson(Map<String, dynamic> json) {
    return CmeTrainingType(
      idHinhThucDaoTao:
          _asInt(json['idHinhThucDaoTao'] ?? json['IdHinhThucDaoTao']) ?? 0,
      tenHinhThucDaoTao: _asString(
        json['tenHinhThucDaoTao'] ?? json['TenHinhThucDaoTao'],
      ),
    );
  }
}

class CmeDepartment {
  final String maKhoa;
  final String? tenKhoa;

  const CmeDepartment({required this.maKhoa, this.tenKhoa});

  String get name => tenKhoa?.trim() ?? '';

  String get displayName => name.isEmpty ? maKhoa : name;

  String get searchableText => '$maKhoa $name'.toLowerCase();

  factory CmeDepartment.fromJson(Map<String, dynamic> json) {
    return CmeDepartment(
      maKhoa:
          _asString(
            json['maKhoa'] ??
                json['MaKhoa'] ??
                json['makhoa'] ??
                json['Makhoa'],
          ) ??
          '',
      tenKhoa: _asString(
        json['tenKhoa'] ??
            json['TenKhoa'] ??
            json['tenkhoa'] ??
            json['Tenkhoa'],
      ),
    );
  }
}

class CmeRequestModel {
  final int id;
  final String maSoNguoiGui;
  final String? tenNguoiGui;
  final String? maKhoa;
  final String? tenKhoa;
  final String tenChungChi;
  final String? soChungChi;
  final String? donViDaoTao;
  final int? idHinhThucDaoTao;
  final String? tenHinhThucDaoTao;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;
  final double? soTiet;
  final DateTime? ngayCap;
  final int? chuKy;
  final DateTime? ngayHetHan;
  final int idFile;
  final String? fileName;
  final String? fileType;
  final DateTime ngayGui;
  final String trangThai;
  final String? maSoNguoiDuyet;
  final String? tenNguoiDuyet;
  final DateTime? ngayDuyet;
  final String? lyDoTuChoi;
  final int? idChungChi;

  const CmeRequestModel({
    required this.id,
    required this.maSoNguoiGui,
    this.tenNguoiGui,
    this.maKhoa,
    this.tenKhoa,
    required this.tenChungChi,
    this.soChungChi,
    this.donViDaoTao,
    this.idHinhThucDaoTao,
    this.tenHinhThucDaoTao,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.soTiet,
    this.ngayCap,
    this.chuKy,
    this.ngayHetHan,
    required this.idFile,
    this.fileName,
    this.fileType,
    required this.ngayGui,
    required this.trangThai,
    this.maSoNguoiDuyet,
    this.tenNguoiDuyet,
    this.ngayDuyet,
    this.lyDoTuChoi,
    this.idChungChi,
  });

  bool get isPending => trangThai.toUpperCase() == CmeStatus.choDuyet;

  bool get isApproved => trangThai.toUpperCase() == CmeStatus.daDuyet;

  bool get isRejected => trangThai.toUpperCase() == CmeStatus.tuChoi;

  factory CmeRequestModel.fromJson(Map<String, dynamic> json) {
    final DateTime? submittedAt = _asDate(json['ngayGui'] ?? json['NgayGui']);

    if (submittedAt == null) {
      throw const FormatException('Phản hồi CME không có ngày gửi hợp lệ.');
    }

    return CmeRequestModel(
      id: _asInt(json['id'] ?? json['Id']) ?? 0,
      maSoNguoiGui:
          _asString(json['maSoNguoiGui'] ?? json['MaSoNguoiGui']) ?? '',
      tenNguoiGui: _asString(json['tenNguoiGui'] ?? json['TenNguoiGui']),
      maKhoa: _asString(json['maKhoa'] ?? json['MaKhoa']),
      tenKhoa: _asString(json['tenKhoa'] ?? json['TenKhoa']),
      tenChungChi: _asString(json['tenChungChi'] ?? json['TenChungChi']) ?? '',
      soChungChi: _asString(json['soChungChi'] ?? json['SoChungChi']),
      donViDaoTao: _asString(json['donViDaoTao'] ?? json['DonViDaoTao']),
      idHinhThucDaoTao: _asInt(
        json['idHinhThucDaoTao'] ?? json['IdHinhThucDaoTao'],
      ),
      tenHinhThucDaoTao: _asString(
        json['tenHinhThucDaoTao'] ?? json['TenHinhThucDaoTao'],
      ),
      ngayBatDau: _asDate(json['ngayBatDau'] ?? json['NgayBatDau']),
      ngayKetThuc: _asDate(json['ngayKetThuc'] ?? json['NgayKetThuc']),
      soTiet: _asDouble(json['soTiet'] ?? json['SoTiet']),
      ngayCap: _asDate(json['ngayCap'] ?? json['NgayCap']),
      chuKy: _asInt(json['chuKy'] ?? json['ChuKy']),
      ngayHetHan: _asDate(json['ngayHetHan'] ?? json['NgayHetHan']),
      idFile: _asInt(json['idFile'] ?? json['IdFile']) ?? 0,
      fileName: _asString(json['fileName'] ?? json['FileName']),
      fileType: _asString(json['fileType'] ?? json['FileType']),
      ngayGui: submittedAt,
      trangThai: _asString(json['trangThai'] ?? json['TrangThai']) ?? '',
      maSoNguoiDuyet: _asString(
        json['maSoNguoiDuyet'] ?? json['MaSoNguoiDuyet'],
      ),
      tenNguoiDuyet: _asString(json['tenNguoiDuyet'] ?? json['TenNguoiDuyet']),
      ngayDuyet: _asDate(json['ngayDuyet'] ?? json['NgayDuyet']),
      lyDoTuChoi: _asString(json['lyDoTuChoi'] ?? json['LyDoTuChoi']),
      idChungChi: _asInt(json['idChungChi'] ?? json['IdChungChi']),
    );
  }
}

class CmePagedResult {
  final List<CmeRequestModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const CmePagedResult({
    this.items = const <CmeRequestModel>[],
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.totalPages = 0,
  });

  bool get hasNextPage => page < totalPages;

  bool get hasPreviousPage => page > 1;

  factory CmePagedResult.fromJson(Map<String, dynamic> json) {
    final dynamic rawItems = json['items'] ?? json['Items'];
    final List<CmeRequestModel> parsedItems = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (Map<dynamic, dynamic> item) =>
                    CmeRequestModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(growable: false)
        : const <CmeRequestModel>[];

    return CmePagedResult(
      items: List<CmeRequestModel>.unmodifiable(parsedItems),
      page: _asInt(json['page'] ?? json['Page']) ?? 1,
      pageSize: _asInt(json['pageSize'] ?? json['PageSize']) ?? 20,
      totalCount: _asInt(json['totalCount'] ?? json['TotalCount']) ?? 0,
      totalPages: _asInt(json['totalPages'] ?? json['TotalPages']) ?? 0,
    );
  }
}

class CmeDashboardSummary {
  final int soNgaySapHetHan;
  final int tongChoDuyet;
  final List<CmeRequestModel> yeuCauChoDuyet;
  final int tongSapHetHan;
  final List<CmeExpiringCertificate> chungChiSapHetHan;

  const CmeDashboardSummary({
    this.soNgaySapHetHan = 60,
    this.tongChoDuyet = 0,
    this.yeuCauChoDuyet = const <CmeRequestModel>[],
    this.tongSapHetHan = 0,
    this.chungChiSapHetHan = const <CmeExpiringCertificate>[],
  });

  int get pendingCount => tongChoDuyet;

  int get expiringCount => tongSapHetHan;

  bool get hasNotifications => tongChoDuyet > 0 || tongSapHetHan > 0;

  factory CmeDashboardSummary.fromJson(Map<String, dynamic> json) {
    final List<CmeRequestModel> pendingRequests = _asCmeRequestList(
      json['yeuCauChoDuyet'] ?? json['YeuCauChoDuyet'],
    );
    final List<CmeExpiringCertificate> expiringCertificates =
        _asCmeExpiringCertificateList(
          json['chungChiSapHetHan'] ?? json['ChungChiSapHetHan'],
        );

    return CmeDashboardSummary(
      soNgaySapHetHan:
          _asInt(json['soNgaySapHetHan'] ?? json['SoNgaySapHetHan']) ?? 60,
      tongChoDuyet:
          _asInt(
            json['tongChoDuyet'] ??
                json['TongChoDuyet'] ??
                json['tongYeuCauChoDuyet'] ??
                json['TongYeuCauChoDuyet'],
          ) ??
          pendingRequests.length,
      yeuCauChoDuyet: List<CmeRequestModel>.unmodifiable(pendingRequests),
      tongSapHetHan:
          _asInt(
            json['tongSapHetHan'] ??
                json['TongSapHetHan'] ??
                json['tongChungChiSapHetHan'] ??
                json['TongChungChiSapHetHan'],
          ) ??
          expiringCertificates.length,
      chungChiSapHetHan: List<CmeExpiringCertificate>.unmodifiable(
        expiringCertificates,
      ),
    );
  }
}

class CmeExpiringCertificate {
  final int idChungChi;
  final int? idYeuCau;
  final String maSo;
  final String? tenNhanVien;
  final String? maKhoa;
  final String? tenKhoa;
  final String tenChungChi;
  final String? soChungChi;
  final DateTime? ngayHetHan;
  final int? soNgayConLai;

  const CmeExpiringCertificate({
    required this.idChungChi,
    this.idYeuCau,
    required this.maSo,
    this.tenNhanVien,
    this.maKhoa,
    this.tenKhoa,
    required this.tenChungChi,
    this.soChungChi,
    this.ngayHetHan,
    this.soNgayConLai,
  });

  String get employeeName => tenNhanVien?.trim() ?? '';

  String get departmentName => tenKhoa?.trim() ?? '';

  bool get isExpired => soNgayConLai != null && soNgayConLai! < 0;

  factory CmeExpiringCertificate.fromJson(Map<String, dynamic> json) {
    return CmeExpiringCertificate(
      idChungChi: _asInt(json['idChungChi'] ?? json['IdChungChi']) ?? 0,
      idYeuCau: _asInt(json['idYeuCau'] ?? json['IdYeuCau']),
      maSo: _asString(json['maSo'] ?? json['MaSo']) ?? '',
      tenNhanVien: _asString(json['tenNhanVien'] ?? json['TenNhanVien']),
      maKhoa: _asString(json['maKhoa'] ?? json['MaKhoa']),
      tenKhoa: _asString(json['tenKhoa'] ?? json['TenKhoa']),
      tenChungChi: _asString(json['tenChungChi'] ?? json['TenChungChi']) ?? '',
      soChungChi: _asString(json['soChungChi'] ?? json['SoChungChi']),
      ngayHetHan: _asDate(json['ngayHetHan'] ?? json['NgayHetHan']),
      soNgayConLai: _asInt(json['soNgayConLai'] ?? json['SoNgayConLai']),
    );
  }
}

class CmeQuery {
  static const Object _unset = Object();

  final String? trangThai;
  final String? keyword;
  final String? maKhoa;
  final DateTime? tuNgay;
  final DateTime? denNgay;
  final int page;
  final int pageSize;

  const CmeQuery({
    this.trangThai,
    this.keyword,
    this.maKhoa,
    this.tuNgay,
    this.denNgay,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (_hasText(trangThai)) 'TrangThai': trangThai!.trim(),
      if (_hasText(keyword)) 'Keyword': keyword!.trim(),
      if (_hasText(maKhoa)) 'MaKhoa': maKhoa!.trim(),
      if (tuNgay != null) 'TuNgay': _dateOnly(tuNgay!),
      if (denNgay != null) 'DenNgay': _dateOnly(denNgay!),
      'Page': page < 1 ? 1 : page,
      'PageSize': pageSize.clamp(1, 100),
    };
  }

  CmeQuery copyWith({
    Object? trangThai = _unset,
    Object? keyword = _unset,
    Object? maKhoa = _unset,
    Object? tuNgay = _unset,
    Object? denNgay = _unset,
    int? page,
    int? pageSize,
  }) {
    return CmeQuery(
      trangThai: identical(trangThai, _unset)
          ? this.trangThai
          : trangThai as String?,
      keyword: identical(keyword, _unset) ? this.keyword : keyword as String?,
      maKhoa: identical(maKhoa, _unset) ? this.maKhoa : maKhoa as String?,
      tuNgay: identical(tuNgay, _unset) ? this.tuNgay : tuNgay as DateTime?,
      denNgay: identical(denNgay, _unset) ? this.denNgay : denNgay as DateTime?,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class CmeCreateInput {
  final String tenChungChi;
  final String? soChungChi;
  final String? donViDaoTao;
  final int? idHinhThucDaoTao;
  final DateTime? ngayBatDau;
  final DateTime? ngayKetThuc;
  final double? soTiet;
  final DateTime? ngayCap;
  final int? chuKy;
  final DateTime? ngayHetHan;
  final Uint8List fileBytes;
  final String fileName;

  const CmeCreateInput({
    required this.tenChungChi,
    this.soChungChi,
    this.donViDaoTao,
    this.idHinhThucDaoTao,
    this.ngayBatDau,
    this.ngayKetThuc,
    this.soTiet,
    this.ngayCap,
    this.chuKy,
    this.ngayHetHan,
    required this.fileBytes,
    required this.fileName,
  });
}

class CmeAttachment {
  final Uint8List bytes;
  final String fileName;
  final String contentType;

  const CmeAttachment({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  bool get isPdf {
    final String normalizedType = contentType
        .split(';')
        .first
        .trim()
        .toLowerCase();
    final String normalizedName = fileName.trim().toLowerCase();

    return normalizedType == 'application/pdf' ||
        normalizedType == 'pdf' ||
        normalizedType == '.pdf' ||
        normalizedName.endsWith('.pdf');
  }

  bool get isImage => contentType.toLowerCase().startsWith('image/');
}

class CmeApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const CmeApiException({required this.message, this.statusCode, this.code});

  @override
  String toString() => message;
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return value == null ? null : int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return value == null ? null : double.tryParse(value.toString());
}

String? _asString(dynamic value) {
  if (value == null) {
    return null;
  }

  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _asDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  return value == null ? null : DateTime.tryParse(value.toString());
}

List<CmeRequestModel> _asCmeRequestList(dynamic value) {
  if (value is! List) {
    return const <CmeRequestModel>[];
  }

  final List<CmeRequestModel> result = <CmeRequestModel>[];
  for (final dynamic item in value) {
    if (item is! Map) {
      continue;
    }

    try {
      result.add(CmeRequestModel.fromJson(Map<String, dynamic>.from(item)));
    } on FormatException {
      // Một dòng cũ thiếu dữ liệu không làm hỏng toàn bộ thông báo CME.
    }
  }
  return result;
}

List<CmeExpiringCertificate> _asCmeExpiringCertificateList(dynamic value) {
  if (value is! List) {
    return const <CmeExpiringCertificate>[];
  }

  return value
      .whereType<Map>()
      .map(
        (Map<dynamic, dynamic> item) =>
            CmeExpiringCertificate.fromJson(Map<String, dynamic>.from(item)),
      )
      .toList(growable: false);
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _dateOnly(DateTime value) {
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-$month-$day';
}
