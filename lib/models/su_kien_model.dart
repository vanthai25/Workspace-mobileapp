class SuKienModel {
  final int masukien;
  final String? tentiec;
  final DateTime? ngayketthucdky;
  final String? ghichu;

  final bool isAnOrKhongAn;
  final bool isEditSoLuong;

  final bool daDangKy;
  final int? dangKyId;
  final int? soLuongDaDangKy;

  const SuKienModel({
    required this.masukien,
    this.tentiec,
    this.ngayketthucdky,
    this.ghichu,
    required this.isAnOrKhongAn,
    required this.isEditSoLuong,
    required this.daDangKy,
    this.dangKyId,
    this.soLuongDaDangKy,
  });

  factory SuKienModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SuKienModel(
      masukien: _toInt(
        json['masukien'] ??
            json['Masukien'],
      ),
      tentiec:
          json['tentiec'] ??
          json['Tentiec'],
      ngayketthucdky:
          _toDate(
        json['ngayketthucdky'] ??
            json['Ngayketthucdky'],
      ),
      ghichu:
          json['ghichu'] ??
          json['Ghichu'],
      isAnOrKhongAn:
          _toBool(
        json['isAnOrKhongAn'] ??
            json['IsAnOrKhongAn'],
      ),
      isEditSoLuong:
          _toBool(
        json['isEditSoLuong'] ??
            json['IsEditSoLuong'],
      ),
      daDangKy:
          _toBool(
        json['daDangKy'] ??
            json['DaDangKy'],
      ),
      dangKyId:
          _toNullableInt(
        json['dangKyId'] ??
            json['DangKyId'],
      ),
      soLuongDaDangKy:
          _toNullableInt(
        json['soLuongDaDangKy'] ??
            json['SoLuongDaDangKy'],
      ),
    );
  }
}


class SuKienDangKyModel {
  final int id;
  final int masukien;

  final String? tentiec;
  final DateTime? ngayketthucdky;

  final bool isAnOrKhongAn;
  final bool isEditSoLuong;

  /// null = sự kiện không có ăn
  /// true = có ăn
  /// false = tham gia nhưng không ăn
  final bool? coAn;

  final bool conHanDangKy;

  final String? manv;
  final String? tennv;

  final int sk;

  final String? ghichu;
  final String? nguoibao;

  final int? soLuong;

  const SuKienDangKyModel({
    required this.id,
    required this.masukien,
    this.tentiec,
    this.ngayketthucdky,
    required this.isAnOrKhongAn,
    required this.isEditSoLuong,
    this.coAn,
    required this.conHanDangKy,
    this.manv,
    this.tennv,
    required this.sk,
    this.ghichu,
    this.nguoibao,
    this.soLuong,
  });

  factory SuKienDangKyModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SuKienDangKyModel(
      id: _toInt(
        json['id'] ??
            json['Id'],
      ),
      masukien: _toInt(
        json['masukien'] ??
            json['Masukien'],
      ),
      tentiec:
          json['tentiec'] ??
          json['Tentiec'],
      ngayketthucdky:
          _toDate(
        json['ngayketthucdky'] ??
            json['Ngayketthucdky'],
      ),
      isAnOrKhongAn:
          _toBool(
        json['isAnOrKhongAn'] ??
            json['IsAnOrKhongAn'],
      ),
      isEditSoLuong:
          _toBool(
        json['isEditSoLuong'] ??
            json['IsEditSoLuong'],
      ),
      coAn:
          _toNullableBool(
        json['coAn'] ??
            json['CoAn'],
      ),
      conHanDangKy:
          _toBool(
        json['conHanDangKy'] ??
            json['ConHanDangKy'],
      ),
      manv:
          json['manv'] ??
          json['Manv'],
      tennv:
          json['tennv'] ??
          json['Tennv'],
      sk: _toInt(
        json['sk'] ??
            json['SK'],
      ),
      ghichu:
          json['ghichu'] ??
          json['Ghichu'],
      nguoibao:
          json['nguoibao'] ??
          json['Nguoibao'],
      soLuong:
          _toNullableInt(
        json['soLuong'] ??
            json['SoLuong'],
      ),
    );
  }
}


int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
        value.toString(),
      ) ??
      0;
}


int? _toNullableInt(
  dynamic value,
) {
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


bool _toBool(dynamic value) {
  if (value == true ||
      value == 1) {
    return true;
  }

  return value
          ?.toString()
          .toLowerCase() ==
      'true';
}


bool? _toNullableBool(
  dynamic value,
) {
  if (value == null) {
    return null;
  }

  return _toBool(value);
}


DateTime? _toDate(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(
    value.toString(),
  );
}