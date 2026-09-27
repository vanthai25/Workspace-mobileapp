class BaoCom {
  final int? id;
  final String? manv;
  final String? ngaybaocom;
  final bool? ansang;
  final bool? anchieu;
  final String? anvo;
  final String? ghichu;
  final String? makhoa;
  final String? tennv;
  final int? mamaubaocom;
  final String? nguoibao;

  BaoCom({
    this.id,
    this.manv,
    this.ngaybaocom,
    this.ansang,
    this.anchieu,
    this.anvo,
    this.ghichu,
    this.makhoa,
    this.tennv,
    this.mamaubaocom,
    this.nguoibao,
  });

  factory BaoCom.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1; 
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return BaoCom(
      // Ép kiểu an toàn cho ID
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      manv: json['manv']?.toString(),
      ngaybaocom: json['ngaybaocom']?.toString(),
      ansang: parseBool(json['ansang']),
      anchieu: parseBool(json['anchieu']),
      anvo: json['anvo']?.toString(),
      ghichu: json['ghichu']?.toString(),
      makhoa: json['makhoa']?.toString(),
      tennv: json['tennv']?.toString(),
      mamaubaocom: int.tryParse(json['mamaubaocom']?.toString() ?? '0'),
      nguoibao: json['nguoibao']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'manv': manv,
      'ngaybaocom': ngaybaocom,
      'ansang': ansang,
      'anchieu': anchieu,
      'ghichu': ghichu,
      'makhoa': makhoa,
      'tennv': tennv,
      'nguoibao': nguoibao,
      'mamaubaocom': mamaubaocom ?? 0,
    };
  }
}