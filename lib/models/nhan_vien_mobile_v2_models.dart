class NhanVienMobileKhoaPhongV2Model {
  final int idKhoaPhong;
  final String? tenKhoaPhong;
  final int? stt;
  final int soNhanVien;
  final List<NhanVienMobileItemV2Model> nhanViens;

  const NhanVienMobileKhoaPhongV2Model({
    required this.idKhoaPhong,
    this.tenKhoaPhong,
    this.stt,
    required this.soNhanVien,
    required this.nhanViens,
  });

  factory NhanVienMobileKhoaPhongV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    final list =
        json['nhanViens'] ??
        json['NhanViens'];

    return NhanVienMobileKhoaPhongV2Model(
      idKhoaPhong: _toInt(
            json['idKhoaPhong'] ??
                json['IdKhoaPhong'],
          ) ??
          0,
      tenKhoaPhong:
          (json['tenKhoaPhong'] ??
                  json['TenKhoaPhong'])
              ?.toString(),
      stt: _toInt(
        json['stt'] ??
            json['STT'] ??
            json['Stt'],
      ),
      soNhanVien: _toInt(
            json['soNhanVien'] ??
                json['SoNhanVien'],
          ) ??
          0,
      nhanViens: list is List
          ? list
                .whereType<Map>()
                .map(
                  (e) =>
                      NhanVienMobileItemV2Model.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : <NhanVienMobileItemV2Model>[],
    );
  }
}

class NhanVienMobileItemV2Model {
  final String maSo;
  final String? hoVaTen;
  final String? soDienThoai;
  final int? anhDaiDien;
  final DateTime? namSinh;

  final bool? gioiTinh;
  final int? idKhoaPhongCongTac;
  final String? tenKhoaPhongCongTac;

  final int? idToDoi;
  final String? tenToDoi;

  final int? idChucDanh;
  final String? tenChucDanh;

  final int? idChucVu;
  final String? tenChucVu;

  final int? sttChucVu;

  final int idKhoaPhongHienThi;
  final String? tenKhoaPhongHienThi;

  final int? kieuHienThi;
  final int? sttHienThi;

  const NhanVienMobileItemV2Model({
    required this.maSo,
    this.hoVaTen,
    this.soDienThoai,
    this.anhDaiDien,
    this.idKhoaPhongCongTac,
    this.tenKhoaPhongCongTac,
    this.idToDoi,
    this.tenToDoi,
    this.idChucDanh,
    this.tenChucDanh,
    this.idChucVu,
    this.tenChucVu,
    this.sttChucVu,
    required this.idKhoaPhongHienThi,
    this.tenKhoaPhongHienThi,
    this.kieuHienThi,
    this.sttHienThi,
    this.namSinh,
this.gioiTinh,
  });

  factory NhanVienMobileItemV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return NhanVienMobileItemV2Model(
      maSo:
          (json['maSo'] ??
                  json['MaSo'] ??
                  '')
              .toString(),
      hoVaTen:
          (json['hoVaTen'] ??
                  json['HoVaTen'])
              ?.toString(),
      soDienThoai:
          (json['soDienThoai'] ??
                  json['SoDienThoai'])
              ?.toString(),
      anhDaiDien: _toInt(
        json['anhDaiDien'] ??
            json['AnhDaiDien'],
      ),
      idKhoaPhongCongTac: _toInt(
        json['idKhoaPhongCongTac'] ??
            json['IdKhoaPhongCongTac'],
      ),
      tenKhoaPhongCongTac:
          (json['tenKhoaPhongCongTac'] ??
                  json['TenKhoaPhongCongTac'])
              ?.toString(),
      idToDoi: _toInt(
        json['idToDoi'] ??
            json['IdToDoi'],
      ),
      namSinh: _toDateTime(
        json['namSinh'] ??
            json['NamSinh'],
      ),

      gioiTinh: _toBool(
        json['gioiTinh'] ??
            json['GioiTinh'],
      ),
      tenToDoi:
          (json['tenToDoi'] ??
                  json['TenToDoi'])
              ?.toString(),
      idChucDanh: _toInt(
        json['idChucDanh'] ??
            json['IdChucDanh'],
      ),
      tenChucDanh:
          (json['tenChucDanh'] ??
                  json['TenChucDanh'])
              ?.toString(),
      idChucVu: _toInt(
        json['idChucVu'] ??
            json['IdChucVu'],
      ),
      tenChucVu:
          (json['tenChucVu'] ??
                  json['TenChucVu'])
              ?.toString(),
      sttChucVu: _toInt(
        json['sttChucVu'] ??
            json['STTChucVu'] ??
            json['SttChucVu'],
      ),
      idKhoaPhongHienThi: _toInt(
            json['idKhoaPhongHienThi'] ??
                json['IdKhoaPhongHienThi'],
          ) ??
          0,
      tenKhoaPhongHienThi:
          (json['tenKhoaPhongHienThi'] ??
                  json['TenKhoaPhongHienThi'])
              ?.toString(),
      kieuHienThi: _toInt(
        json['kieuHienThi'] ??
            json['KieuHienThi'],
      ),
      sttHienThi: _toInt(
        json['sttHienThi'] ??
            json['STTHienThi'] ??
            json['SttHienThi'],
      ),
    );
  }
}

class NhanVienMobileDetailV2Model {
  final String maSo;
  final String? hoVaTen;
  final DateTime? namSinh;
  final bool? gioiTinh;
  final String? soDienThoai;
  final int? anhDaiDien;

  final String? queQuan;
  final String? noiOHienTai;

  final int? idKhoaPhong;
  final String? tenKhoaPhong;

  final int? idToDoi;
  final String? tenToDoi;

  final int? idChucDanh;
  final String? tenChucDanh;

  final int? idChucVu;
  final String? tenChucVu;

  final int? sttChucVu;

  const NhanVienMobileDetailV2Model({
    required this.maSo,
    this.hoVaTen,
    this.namSinh,
    this.gioiTinh,
    this.soDienThoai,
    this.anhDaiDien,
    this.queQuan,
    this.noiOHienTai,
    this.idKhoaPhong,
    this.tenKhoaPhong,
    this.idToDoi,
    this.tenToDoi,
    this.idChucDanh,
    this.tenChucDanh,
    this.idChucVu,
    this.tenChucVu,
    this.sttChucVu,
  });

  factory NhanVienMobileDetailV2Model.fromJson(
    Map<String, dynamic> json,
  ) {
    return NhanVienMobileDetailV2Model(
      maSo:
          (json['maSo'] ??
                  json['MaSo'] ??
                  '')
              .toString(),
      hoVaTen:
          (json['hoVaTen'] ??
                  json['HoVaTen'])
              ?.toString(),
      namSinh: _toDateTime(
        json['namSinh'] ??
            json['NamSinh'],
      ),
      gioiTinh: _toBool(
        json['gioiTinh'] ??
            json['GioiTinh'],
      ),
      soDienThoai:
          (json['soDienThoai'] ??
                  json['SoDienThoai'])
              ?.toString(),
      anhDaiDien: _toInt(
        json['anhDaiDien'] ??
            json['AnhDaiDien'],
      ),
      queQuan:
          (json['queQuan'] ??
                  json['QueQuan'])
              ?.toString(),
      noiOHienTai:
          (json['noiOHienTai'] ??
                  json['NoiOHienTai'])
              ?.toString(),
      idKhoaPhong: _toInt(
        json['idKhoaPhong'] ??
            json['IdKhoaPhong'],
      ),
      tenKhoaPhong:
          (json['tenKhoaPhong'] ??
                  json['TenKhoaPhong'])
              ?.toString(),
      idToDoi: _toInt(
        json['idToDoi'] ??
            json['IdToDoi'],
      ),
      tenToDoi:
          (json['tenToDoi'] ??
                  json['TenToDoi'])
              ?.toString(),
      idChucDanh: _toInt(
        json['idChucDanh'] ??
            json['IdChucDanh'],
      ),
      tenChucDanh:
          (json['tenChucDanh'] ??
                  json['TenChucDanh'])
              ?.toString(),
      idChucVu: _toInt(
        json['idChucVu'] ??
            json['IdChucVu'],
      ),
      tenChucVu:
          (json['tenChucVu'] ??
                  json['TenChucVu'])
              ?.toString(),
      sttChucVu: _toInt(
        json['sttChucVu'] ??
            json['STTChucVu'] ??
            json['SttChucVu'],
      ),
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

bool? _toBool(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final text =
      value
          .toString()
          .trim()
          .toLowerCase();

  if (text == 'true' ||
      text == '1') {
    return true;
  }

  if (text == 'false' ||
      text == '0') {
    return false;
  }

  return null;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(
    value.toString(),
  );
}
class NhanVienMobileTongQuanV2Model {
  final int tongNhanVien;
  final int tongKhoaPhong;

  const NhanVienMobileTongQuanV2Model({
    required this.tongNhanVien,
    required this.tongKhoaPhong,
  });

  factory NhanVienMobileTongQuanV2Model
      .fromJson(
    Map<String, dynamic> json,
  ) {
    return NhanVienMobileTongQuanV2Model(
      tongNhanVien:
          _toInt(
            json['tongNhanVien'] ??
                json['TongNhanVien'],
          ) ??
          0,

      tongKhoaPhong:
          _toInt(
            json['tongKhoaPhong'] ??
                json['TongKhoaPhong'],
          ) ??
          0,
    );
  }
}