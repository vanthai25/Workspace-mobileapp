class LuongFieldModel {
  final String fieldName;
  final String textHienThi;
  final double? giaTri;
  final int thuTu;

  const LuongFieldModel({
    required this.fieldName,
    required this.textHienThi,
    required this.giaTri,
    required this.thuTu,
  });

  factory LuongFieldModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return LuongFieldModel(
      fieldName: (
        json['fieldName'] ??
        json['FieldName'] ??
        ''
      ).toString(),

      textHienThi: (
        json['textHienThi'] ??
        json['TextHienThi'] ??
        ''
      ).toString(),

      giaTri: _parseDouble(
        json['giaTri'] ??
        json['GiaTri'],
      ),

      thuTu: _parseInt(
        json['thuTu'] ??
        json['ThuTu'],
      ),
    );
  }

  static double? _parseDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static int _parseInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

class LuongSectionModel {
  final String maNhom;
  final String tenNhom;
  final bool coDuLieu;
  final List<LuongFieldModel> duLieu;

  const LuongSectionModel({
    required this.maNhom,
    required this.tenNhom,
    required this.coDuLieu,
    required this.duLieu,
  });

  factory LuongSectionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawData =
        json['duLieu'] ??
        json['DuLieu'];

    final List<LuongFieldModel> fields = [];

    if (rawData is List) {
      for (final dynamic item in rawData) {
        if (item is Map<String, dynamic>) {
          fields.add(
            LuongFieldModel.fromJson(
              item,
            ),
          );
        } else if (item is Map) {
          fields.add(
            LuongFieldModel.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          );
        }
      }
    }

    fields.sort(
      (
        LuongFieldModel a,
        LuongFieldModel b,
      ) {
        final int compare =
            a.thuTu.compareTo(
          b.thuTu,
        );

        if (compare != 0) {
          return compare;
        }

        return a.fieldName.compareTo(
          b.fieldName,
        );
      },
    );

    return LuongSectionModel(
      maNhom: (
        json['maNhom'] ??
        json['MaNhom'] ??
        ''
      ).toString(),

      tenNhom: (
        json['tenNhom'] ??
        json['TenNhom'] ??
        ''
      ).toString(),

      coDuLieu:
          _parseBool(
        json['coDuLieu'] ??
        json['CoDuLieu'],
      ),

      duLieu: fields,
    );
  }

  static bool _parseBool(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    final String raw =
        value?.toString().toLowerCase() ??
        '';

    return raw == 'true' ||
        raw == '1';
  }

  LuongFieldModel? getField(
    String fieldName,
  ) {
    for (final LuongFieldModel field
        in duLieu) {
      if (field.fieldName
          .toLowerCase()
          .trim() ==
          fieldName
              .toLowerCase()
              .trim()) {
        return field;
      }
    }

    return null;
  }
}

class LuongThangModel {
  final String manv;
  final int thang;
  final int nam;
  final List<LuongSectionModel>
      nhomLuong;

  const LuongThangModel({
    required this.manv,
    required this.thang,
    required this.nam,
    required this.nhomLuong,
  });

  factory LuongThangModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawSections =
        json['nhomLuong'] ??
        json['NhomLuong'];

    final List<LuongSectionModel>
        sections = [];

    if (rawSections is List) {
      for (final dynamic item
          in rawSections) {
        if (item
            is Map<String, dynamic>) {
          sections.add(
            LuongSectionModel.fromJson(
              item,
            ),
          );
        } else if (item is Map) {
          sections.add(
            LuongSectionModel.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          );
        }
      }
    }

    return LuongThangModel(
      manv: (
        json['manv'] ??
        json['Manv'] ??
        ''
      ).toString(),

      thang: _parseInt(
        json['thang'] ??
        json['Thang'],
      ),

      nam: _parseInt(
        json['nam'] ??
        json['Nam'],
      ),

      nhomLuong: sections,
    );
  }

  static int _parseInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  LuongFieldModel? getField(
    String fieldName,
  ) {
    for (final LuongSectionModel section
        in nhomLuong) {
      final LuongFieldModel? field =
          section.getField(
        fieldName,
      );

      if (field != null) {
        return field;
      }
    }

    return null;
  }
}
class LuongThucLinhThangModel {
  final int thang;
  final int nam;
  final double? thuclinh;
  final bool coDuLieu;

  const LuongThucLinhThangModel({
    required this.thang,
    required this.nam,
    required this.thuclinh,
    required this.coDuLieu,
  });

  factory LuongThucLinhThangModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return LuongThucLinhThangModel(
      thang: int.tryParse(
            (
              json['thang'] ??
              json['Thang'] ??
              0
            ).toString(),
          ) ??
          0,

      nam: int.tryParse(
            (
              json['nam'] ??
              json['Nam'] ??
              0
            ).toString(),
          ) ??
          0,

      thuclinh: _parseDouble(
        json['thuclinh'] ??
        json['Thuclinh'],
      ),

      coDuLieu:
          json['coDuLieu'] == true ||
          json['CoDuLieu'] == true,
    );
  }

  static double? _parseDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }
}