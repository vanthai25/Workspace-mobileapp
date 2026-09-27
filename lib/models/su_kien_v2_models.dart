class SuKienBannerV2Model {
  final int idBanner;
  final int idSuKien;
  final int idFile;

  final String? tieuDe;
  final String? moTa;

  final String? fileName;
  final String? fileType;
  final int fileSize;

  final String? actionType;
  final String? actionValue;
  final String? buttonText;

  final int thuTu;
  final bool isActive;

  const SuKienBannerV2Model({
    required this.idBanner,
    required this.idSuKien,
    required this.idFile,
    this.tieuDe,
    this.moTa,
    this.fileName,
    this.fileType,
    this.fileSize = 0,
    this.actionType,
    this.actionValue,
    this.buttonText,
    this.thuTu = 0,
    this.isActive = true,
  });

  factory SuKienBannerV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return SuKienBannerV2Model(
      idBanner:
          _toInt(json['idBanner']) ?? 0,

      idSuKien:
          _toInt(json['idSuKien']) ?? 0,

      idFile:
          _toInt(json['idFile']) ?? 0,

      tieuDe:
          json['tieuDe']?.toString(),

      moTa:
          json['moTa']?.toString(),

      fileName:
          json['fileName']?.toString(),

      fileType:
          json['fileType']?.toString(),

      fileSize:
          _toInt(json['fileSize']) ?? 0,

      actionType:
          json['actionType']?.toString(),

      actionValue:
          json['actionValue']?.toString(),

      buttonText:
          json['buttonText']?.toString(),

      thuTu:
          _toInt(json['thuTu']) ?? 0,

      isActive:
          _toBool(json['isActive'], true),
    );
  }
}


class SuKienV2Model {
  final int idSuKien;

  final String? maSuKien;

  final String tenSuKien;

  final String? moTa;

  final DateTime tuNgay;
  final DateTime denNgay;

  final DateTime? ngaySuKien;

  final bool isActive;
  final bool showCountdown;

  final String? effectType;

  final int mucUuTien;

  final DateTime? ngayTao;
  final String? nguoiTao;

  final DateTime? ngaySua;
  final String? nguoiSua;
  final String? effectConfig;
  final List<SuKienBannerV2Model>
      banners;

  const SuKienV2Model({
    required this.idSuKien,
    this.maSuKien,
    required this.tenSuKien,
    this.moTa,
    required this.tuNgay,
    required this.denNgay,
    this.ngaySuKien,
    required this.isActive,
    required this.showCountdown,
    this.effectType,
    this.mucUuTien = 0,
    this.ngayTao,
    this.nguoiTao,
    this.ngaySua,
    this.nguoiSua,
    this.banners = const [],
    this.effectConfig,
  });

  factory SuKienV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawBanners =
        json['banners'];

    return SuKienV2Model(
      idSuKien:
          _toInt(json['idSuKien']) ?? 0,

      maSuKien:
          json['maSuKien']?.toString(),

      tenSuKien:
          json['tenSuKien']
                  ?.toString() ??
              '',

      moTa:
          json['moTa']?.toString(),

      tuNgay:
          _toDate(json['tuNgay']) ??
              DateTime.now(),

      denNgay:
          _toDate(json['denNgay']) ??
              DateTime.now(),

      ngaySuKien:
          _toDate(json['ngaySuKien']),

      isActive:
          _toBool(
        json['isActive'],
        false,
      ),

      showCountdown:
          _toBool(
        json['showCountdown'],
        false,
      ),

      effectType:
          json['effectType']?.toString(),

      mucUuTien:
          _toInt(json['mucUuTien']) ??
              0,

      ngayTao:
          _toDate(json['ngayTao']),

      nguoiTao:
          json['nguoiTao']?.toString(),

      ngaySua:
          _toDate(json['ngaySua']),

      nguoiSua:
          json['nguoiSua']?.toString(),
      effectConfig:
        json['effectConfig']?.toString(),
      banners:
          rawBanners is List
              ? rawBanners
                  .whereType<Map>()
                  .map(
                    (e) =>
                        SuKienBannerV2Model
                            .fromJson(
                      Map<String, dynamic>
                          .from(e),
                    ),
                  )
                  .toList()
              : const [],
    );
  }
}


int? _toInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  );
}


bool _toBool(
  dynamic value,
  bool fallback,
) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final text =
      value?.toString().toLowerCase();

  if (text == 'true' ||
      text == '1') {
    return true;
  }

  if (text == 'false' ||
      text == '0') {
    return false;
  }

  return fallback;
}


DateTime? _toDate(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(
    value.toString(),
  );
}