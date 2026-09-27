class ChamCongBoSung {
  final int? id;
  final String? manv;
  final String? noidung;
  final String? lydo;
  final int? trangthaiduyet;
  final String? ghichu;
  final String? ngaylap;
  final double? tongcong;
  final String? ngaythieu;
  final String? ldkhoaduyet;
  final String? ngayldkhoaduyet;
  final String? ketoanduyet;
  final String? ngayketoanduyet;
  final String? tenLdDuyet;
  final String? tenKtDuyet;

  // Cơ sở lưu trong CHAMCONG_BOSUNG
  final String? coso;

  ChamCongBoSung({
    this.id,
    this.manv,
    this.noidung,
    this.lydo,
    this.trangthaiduyet,
    this.ghichu,
    this.ngaylap,
    this.tongcong,
    this.ngaythieu,
    this.ldkhoaduyet,
    this.ngayldkhoaduyet,
    this.ketoanduyet,
    this.ngayketoanduyet,
    this.tenLdDuyet,
    this.tenKtDuyet,
    this.coso,
  });

  factory ChamCongBoSung.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawTongCong =
        json['Tongcong'] ??
        json['tongcong'] ??
        json['TongCong'] ??
        0.0;

    return ChamCongBoSung(
      id: int.tryParse(
        (json['Id'] ?? json['id'])?.toString() ?? '',
      ),
      manv: (json['Manv'] ?? json['manv'])?.toString(),
      noidung:
          (json['Noidung'] ?? json['noidung'])?.toString(),
      lydo: (json['Lydo'] ?? json['lydo'])?.toString(),
      trangthaiduyet: int.tryParse(
        (json['Trangthaiduyet'] ??
                    json['trangthaiduyet'])
                ?.toString() ??
            '',
      ),
      ghichu:
          (json['Ghichu'] ?? json['ghichu'])?.toString(),
      ngaylap:
          (json['Ngaylap'] ?? json['ngaylap'])?.toString(),
      tongcong:
          double.tryParse(rawTongCong.toString()) ?? 0.0,
      ngaythieu:
          (json['Ngaythieu'] ?? json['ngaythieu'])
              ?.toString(),
      ldkhoaduyet:
          (json['Ldkhoaduyet'] ?? json['ldkhoaduyet'])
              ?.toString(),
      ngayldkhoaduyet:
          (json['Ngayldkhoaduyet'] ??
                  json['ngayldkhoaduyet'])
              ?.toString(),
      ketoanduyet:
          (json['Ketoanduyet'] ?? json['ketoanduyet'])
              ?.toString(),
      ngayketoanduyet:
          (json['Ngayketoanduyet'] ??
                  json['ngayketoanduyet'])
              ?.toString(),
      tenLdDuyet:
          (json['TenLdDuyet'] ?? json['tenLdDuyet'])
              ?.toString(),
      tenKtDuyet:
          (json['TenKtDuyet'] ?? json['tenKtDuyet'])
              ?.toString(),
      coso: (json['Coso'] ?? json['coso'])?.toString(),
    );
  }
}

class BaoCaoChamCongLechV2 {
  final int chamCongCTId;
  final String maNV;
  final DateTime? ngay;
  final String thu;

  final String? vao1;
  final String? ra1;
  final String? vao2;
  final String? ra2;

  final double gio;
  final double cong;

  final String? kh;
  final int tre;
  final int som;
  final int isBoSung;
  final String trangThai;

  const BaoCaoChamCongLechV2({
    required this.chamCongCTId,
    required this.maNV,
    required this.ngay,
    required this.thu,
    required this.vao1,
    required this.ra1,
    required this.vao2,
    required this.ra2,
    required this.gio,
    required this.cong,
    required this.kh,
    required this.tre,
    required this.som,
    required this.isBoSung,
    required this.trangThai,
  });

  factory BaoCaoChamCongLechV2.fromJson(
    Map<String, dynamic> json,
  ) {
    dynamic getValue(String key) {
      for (final entry in json.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase()) {
          return entry.value;
        }
      }
      return null;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;

      final String raw = value.toString().trim();
      if (raw.isEmpty) return null;

      return DateTime.tryParse(raw);
    }

    return BaoCaoChamCongLechV2(
      chamCongCTId: int.tryParse(
            getValue('chamCongCTId')?.toString() ?? '',
          ) ??
          0,
      maNV: getValue('maNV')?.toString() ?? '',
      ngay: parseDate(getValue('ngay')),
      thu: getValue('thu')?.toString() ?? '',
      vao1: getValue('vao1')?.toString(),
      ra1: getValue('ra1')?.toString(),
      vao2: getValue('vao2')?.toString(),
      ra2: getValue('ra2')?.toString(),
      gio: double.tryParse(
            getValue('gio')?.toString() ?? '',
          ) ??
          0,
      cong: double.tryParse(
            getValue('cong')?.toString() ?? '',
          ) ??
          0,
      kh: getValue('kh')?.toString(),
      tre: int.tryParse(
            getValue('tre')?.toString() ?? '',
          ) ??
          0,
      som: int.tryParse(
            getValue('som')?.toString() ?? '',
          ) ??
          0,
      isBoSung: int.tryParse(
            getValue('isBoSung')?.toString() ?? '',
          ) ??
          0,
      trangThai:
          getValue('trangThai')?.toString() ?? '',
    );
  }
}
class ChamCongCoSoOption {
  final String ma;
  final String ten;
  final String cosoLuu;

  const ChamCongCoSoOption({
    required this.ma,
    required this.ten,
    required this.cosoLuu,
  });

  factory ChamCongCoSoOption.fromJson(
    Map<String, dynamic> json,
  ) {
    return ChamCongCoSoOption(
      ma: (json['ma'] ?? json['Ma'])?.toString() ?? '',
      ten: (json['ten'] ?? json['Ten'])?.toString() ?? '',
      cosoLuu:
          (json['cosoLuu'] ?? json['CosoLuu'])
                  ?.toString() ??
              '',
    );
  }
}
class BaoCaoChamCongLechV2Result {
  final List<BaoCaoChamCongLechV2> data;

  final String? maKhoa;
  final String? coSoMacDinh;
  final String? coSoDangXem;
  final String? cosoLuuBoSung;

  final List<ChamCongCoSoOption> danhSachCoSo;

  const BaoCaoChamCongLechV2Result({
    required this.data,
    required this.maKhoa,
    required this.coSoMacDinh,
    required this.coSoDangXem,
    required this.cosoLuuBoSung,
    required this.danhSachCoSo,
  });

  factory BaoCaoChamCongLechV2Result.fromResponse(
    Map<String, dynamic> response,
  ) {
    final List<dynamic> rawData =
        response['data'] is List
            ? response['data'] as List<dynamic>
            : <dynamic>[];

    final Map<String, dynamic> metadata =
        response['metadata'] is Map
            ? Map<String, dynamic>.from(
                response['metadata'] as Map,
              )
            : <String, dynamic>{};

    final List<dynamic> rawCoSo =
        metadata['danhSachCoSo'] is List
            ? metadata['danhSachCoSo'] as List<dynamic>
            : <dynamic>[];

    return BaoCaoChamCongLechV2Result(
      data: rawData
          .whereType<Map>()
          .map(
            (item) => BaoCaoChamCongLechV2.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      maKhoa: metadata['maKhoa']?.toString(),
      coSoMacDinh:
          metadata['coSoMacDinh']?.toString(),
      coSoDangXem:
          metadata['coSoDangXem']?.toString(),
      cosoLuuBoSung:
          metadata['cosoLuuBoSung']?.toString(),
      danhSachCoSo: rawCoSo
          .whereType<Map>()
          .map(
            (item) => ChamCongCoSoOption.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}
class PhieuBoSungModel {
  final int id;
  final String? manv;
  final String? tenNV;
  final String? tenKhoa;
  final String? tenLdDuyet;
  final String? tenKtDuyet;
  final String? noiDung;
  final String? lyDo;
  final String? ngayThieu;
  final double? tongCong;
  final int? trangThaiDuyet;
  final String? ghiChu; 

  PhieuBoSungModel({
    required this.id, this.manv, this.tenNV, this.tenKhoa, 
    this.tenLdDuyet, this.tenKtDuyet, this.noiDung, this.lyDo,
    this.ngayThieu, this.tongCong, this.trangThaiDuyet, this.ghiChu
  });

  factory PhieuBoSungModel.fromJson(Map<String, dynamic> json) {
    dynamic getVal(String key) {
      if (json.containsKey(key)) return json[key];
      for (var k in json.keys) {
        if (k.toLowerCase() == key.toLowerCase()) return json[k];
      }
      return null;
    }

    return PhieuBoSungModel(
      id: int.tryParse(getVal('id')?.toString() ?? '0') ?? 0,
      manv: getVal('manv')?.toString(),
      tenNV: getVal('tennv')?.toString() ?? 'Chưa rõ tên',
      tenKhoa: getVal('tenkhoa')?.toString(),
      tenLdDuyet: getVal('tenldduyet')?.toString(),
      tenKtDuyet: getVal('tenktduyet')?.toString(),
      noiDung: getVal('noidung')?.toString(),
      lyDo: getVal('lydo')?.toString(),
      ngayThieu: getVal('ngaythieu')?.toString(),
      tongCong: double.tryParse(getVal('tongcong')?.toString() ?? ''),
      
      trangThaiDuyet: int.tryParse(getVal('trangthaiduyet')?.toString() ?? ''),
      ghiChu: getVal('ghichu')?.toString(),
    );
  }
}