// 1. DTO Chi tiết ngày nghỉ
class ChamCongPhepChiTietDto {
  final DateTime ngayNghi;
  final String? kyHieuId;
  final String? tenKyHieu;

  ChamCongPhepChiTietDto({
    required this.ngayNghi,
    this.kyHieuId,
    this.tenKyHieu,
  });

  factory ChamCongPhepChiTietDto.fromJson(Map<String, dynamic> json) =>
      ChamCongPhepChiTietDto(
        ngayNghi: DateTime.parse(json["ngayNghi"]),
        kyHieuId: json["kyHieuId"],
        tenKyHieu: json["tenKyHieu"],
      );

  Map<String, dynamic> toJson() => {
        "ngayNghi": ngayNghi.toIso8601String(),
        "kyHieuId": kyHieuId,
        "tenKyHieu": tenKyHieu,
      };
}

// 2. DTO Tạo mới đơn xin nghỉ
class ChamCongPhepCreateRequestDto {
  final DateTime ngayNghi;
  final String? kyHieuId;
  final String? lyDoNghiPhep;
  final String? nguoiDuyet;
  final List<ChamCongPhepChiTietDto> danhSachNgay;

  ChamCongPhepCreateRequestDto({
    required this.ngayNghi,
    this.kyHieuId,
    this.lyDoNghiPhep,
    this.nguoiDuyet,
    required this.danhSachNgay,
  });

  Map<String, dynamic> toJson() => {
        "ngayNghi": ngayNghi.toIso8601String(),
        "kyHieuId": kyHieuId,
        "lyDoNghiPhep": lyDoNghiPhep,
        "nguoiDuyet": nguoiDuyet,
        "danhSachNgay": List<dynamic>.from(danhSachNgay.map((x) => x.toJson())),
      };
}

// 3. DTO Danh sách ký hiệu
class ChamCongPhepKyHieuResponseDto {
  final String? kyHieu;
  final String? tenLoaiCong;
  final int? phanLoai;

  ChamCongPhepKyHieuResponseDto({
    this.kyHieu,
    this.tenLoaiCong,
    this.phanLoai,
  });

  factory ChamCongPhepKyHieuResponseDto.fromJson(Map<String, dynamic> json) =>
      ChamCongPhepKyHieuResponseDto(
        kyHieu: json["kyHieu"],
        tenLoaiCong: json["tenLoaiCong"],
        phanLoai: json["phanLoai"],
      );
}

// 4. DTO Danh sách người duyệt
class ChamCongPhepNguoiDuyetResponseDto {
  final String? manv;
  final String? tenNhanVien;

  ChamCongPhepNguoiDuyetResponseDto({
    this.manv,
    this.tenNhanVien,
  });

  factory ChamCongPhepNguoiDuyetResponseDto.fromJson(Map<String, dynamic> json) =>
      ChamCongPhepNguoiDuyetResponseDto(
        manv: json["manv"],
        tenNhanVien: json["tenNhanVien"],
      );
}

// 5. DTO Phiếu xin nghỉ (Hiển thị Lịch sử / Danh sách chờ duyệt)
// 5. DTO Phiếu xin nghỉ
// Hiển thị Lịch sử / Danh sách chờ duyệt
class ChamCongPhepPhieuNghiResponseDto {
  final String? manvXin;
  final String? tenNhanVien;

  final DateTime ngayLap;

  final String? lyDoNghiPhep;

  final int trangThai;

  final double tongSoNgay;

  final List<ChamCongPhepChiTietDto>
      chiTietDanhSachNgay;

  ChamCongPhepPhieuNghiResponseDto({
    this.manvXin,
    this.tenNhanVien,
    required this.ngayLap,
    this.lyDoNghiPhep,
    required this.trangThai,
    required this.tongSoNgay,
    required this.chiTietDanhSachNgay,
  });

  // =========================================================
  // TÍNH SỐ NGÀY NGHỈ THEO KÝ HIỆU
  // =========================================================

  static double _tinhTongSoNgay(
    List<ChamCongPhepChiTietDto> chiTiet,
    double tongBackend,
  ) {
    /*
     * Nếu API không trả chi tiết,
     * giữ nguyên tổng backend để tránh
     * làm mất dữ liệu.
     */
    if (chiTiet.isEmpty) {
      return tongBackend;
    }

    double tong = 0;

    for (final item in chiTiet) {
      final String kyHieu =
          (item.kyHieuId ?? '')
              .trim()
              .toLowerCase();

      /*
       * xs = Đi làm buổi sáng
       *      => nghỉ 1/2 ngày
       *
       * xc = Đi làm buổi chiều
       *      => nghỉ 1/2 ngày
       */
      if (kyHieu == 'xs' ||
          kyHieu == 'xc') {
        tong += 0.5;
      } else {
        /*
         * Các ký hiệu nghỉ nguyên ngày.
         */
        tong += 1.0;
      }
    }

    return tong;
  }

  factory ChamCongPhepPhieuNghiResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    // =======================================================
    // 1. PARSE CHI TIẾT TRƯỚC
    // =======================================================

    final List<ChamCongPhepChiTietDto>
        chiTiet =
        json["chiTietDanhSachNgay"] != null
            ? List<ChamCongPhepChiTietDto>.from(
                json["chiTietDanhSachNgay"].map(
                  (x) =>
                      ChamCongPhepChiTietDto
                          .fromJson(x),
                ),
              )
            : [];

    // =======================================================
    // 2. TỔNG BACKEND
    // =======================================================

    final double tongBackend =
        (json["tongSoNgay"] ?? 0)
            .toDouble();

    // =======================================================
    // 3. TÍNH LẠI THEO xs / xc
    // =======================================================

    final double tongThucTe =
        _tinhTongSoNgay(
      chiTiet,
      tongBackend,
    );

    return ChamCongPhepPhieuNghiResponseDto(
      manvXin:
          json["manvXin"],

      tenNhanVien:
          json["tenNhanVien"],

      ngayLap:
          DateTime.parse(
        json["ngayLap"],
      ),

      lyDoNghiPhep:
          json["lyDoNghiPhep"],

      trangThai:
          json["trangThai"],

      /*
       * Không dùng trực tiếp
       * tongSoNgay backend nữa.
       */
      tongSoNgay:
          tongThucTe,

      chiTietDanhSachNgay:
          chiTiet,
    );
  }
}

class ChamCongPhepRequestDto {
  final DateTime ngayLap;
  final String? manvXin;
  final int trangThai;
  final String? noiDungDuyet;

  ChamCongPhepRequestDto({
    required this.ngayLap,
    this.manvXin,
    required this.trangThai,
    this.noiDungDuyet,
  });

  Map<String, dynamic> toJson() => {
        "ngayLap": ngayLap.toIso8601String(),
        "manvXin": manvXin,
        "trangThai": trangThai,
        "noiDungDuyet": noiDungDuyet,
      };
}