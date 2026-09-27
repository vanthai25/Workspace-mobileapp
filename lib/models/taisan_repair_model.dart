class RepairLogDetail {
  final int? id;
  final String? manv;
  final String? tenNhanVien;
  final int? stepStatus;
  final String? sysdate;
  final String? noidung;

  RepairLogDetail({
    this.id,
    this.manv,
    this.tenNhanVien,
    this.stepStatus,
    this.sysdate,
    this.noidung,
  });

  factory RepairLogDetail.fromJson(Map<String, dynamic> json) {
    String? date = json['sysdate']?.toString() 
                ?? json['sysDate']?.toString() 
                ?? json['createdAt']?.toString()  
                ?? json['ngayCapNhat']?.toString(); 

    return RepairLogDetail(
      id: json['id'],
      manv: json['manv']?.toString(),
      // Hứng thêm tên nhân viên xử lý bước log từ Backend
      tenNhanVien: json['tenNhanVien']?.toString() ?? json['tennhanvien']?.toString(),
      // Hứng mã số trạng thái int để sau này lọc điều kiện
      stepStatus: json['stepStatus'] != null ? int.tryParse(json['stepStatus'].toString()) : null,
      sysdate: date,
      noidung: json['noidung']?.toString() ?? json['noiDung']?.toString(),
    );
  }
}

class TaiSanRepair {
  final int? id;
  final String? ngaylap;
  final String? maTaiSanId;
  final String? tentaisan;
  final String? vitrisudung;
  final String? noidung;
  final String? nguoilap;
  final String? khoalap;
  final String? khoanhan;
  final String? nguoinhan;
  final String? ngaynhan;
  final int? trangthaiphieu;
  final int? mucuutien;
  final String? ldkhoa;
  final String? ngayLdkhoa;
  final String? ghichu;
  final String? maqlts;
  final String? nguoixutri;
  final String? ngayxutri;
  final String? noidungxutri;
  final double? chiphi;
  final String? noidungchuyendi;
  final String? tenKhoaLap;
  final String? tenKhoaNhan;
  final String? tenNguoiLap;
  final String? tenNguoiNhan;
  final String? tenNguoiXutri;
  final String? tenNguoiQuanLy; //maqlts
  final String? tenLdkhoa;
  final List<int>? fileIds;
  final List<String>? sdtNguoiLap;
  final List<RepairLogDetail>? logs;

  TaiSanRepair({
    this.id, this.ngaylap, this.maTaiSanId, this.tentaisan, this.vitrisudung, 
    this.noidung, this.nguoilap, this.khoalap, this.khoanhan, this.nguoinhan,
    this.ngaynhan, this.trangthaiphieu, this.mucuutien, this.ldkhoa, 
    this.ngayLdkhoa, this.ghichu, this.maqlts, this.nguoixutri, 
    this.ngayxutri, this.noidungxutri, this.chiphi, this.noidungchuyendi,
    this.tenKhoaLap, this.tenKhoaNhan, this.tenNguoiLap, this.tenNguoiNhan,
    this.tenNguoiXutri,this.tenNguoiQuanLy,this.tenLdkhoa,this.fileIds,this.sdtNguoiLap,
    this.logs,
  });

  factory TaiSanRepair.fromJson(Map<String, dynamic> json) {
    List<String> getPhoneNumbers(Map<String, dynamic>? nav) {
      if (nav == null) return [];
      List<String> phones = [];
      final p1 = nav['dienthoai1']?.toString().trim();
      if (p1 != null && p1.isNotEmpty) phones.add(p1);
      final p2 = nav['dienthoai2']?.toString().trim();
      if (p2 != null && p2.isNotEmpty) phones.add(p2);
      return phones;
    }

    var rawLogs = json['taiSanRepairCts'] ?? json['taiSanRepairCt'] ?? json['TaiSanRepairCts'] ?? json['logs'];

    return TaiSanRepair(
      id: json['id'],
      ngaylap: json['ngaylap']?.toString(),
      maTaiSanId: json['maTaiSanId']?.toString(),
      tentaisan: json['tentaisan']?.toString(),
      vitrisudung: json['vitrisudung']?.toString(),
      noidung: json['noidung']?.toString(),
      nguoilap: json['nguoilap']?.toString(),
      khoalap: json['khoalap']?.toString(),
      khoanhan: json['khoanhan']?.toString(),
      nguoinhan: json['nguoinhan']?.toString(),
      ngaynhan: json['ngaynhan']?.toString(),
      trangthaiphieu: json['trangthaiphieu'] != null ? int.tryParse(json['trangthaiphieu'].toString()) : null,
      mucuutien: json['mucuutien'] != null ? int.tryParse(json['mucuutien'].toString()) : null,
      ldkhoa: json['ldkhoa']?.toString(),
      ngayLdkhoa: json['ngayLdkhoa']?.toString(),
      ghichu: json['ghichu']?.toString(),
      maqlts: json['maqlts']?.toString(),
      nguoixutri: json['nguoixutri']?.toString(),
      ngayxutri: json['ngayxutri']?.toString(),
      noidungxutri: json['noidungxutri']?.toString(),
      chiphi: json['chiphi'] != null ? double.tryParse(json['chiphi'].toString()) : null,
      noidungchuyendi: json['noidungchuyendi']?.toString(),
      tenKhoaLap: json['khoalapNavigation']?['tenkhoa']?.toString(),
      tenKhoaNhan: json['khoanhanNavigation']?['tenkhoa']?.toString(),
      tenNguoiLap: json['nguoilapNavigation']?['tennv']?.toString() ?? json['tenNguoiLap']?.toString(),
      tenNguoiNhan: json['nguoinhanNavigation']?['tennv']?.toString() ?? json['tenNguoiNhan']?.toString(),
      tenLdkhoa: json['ldkhoaNavigation']?['tennv']?.toString() ?? json['ldkhoa']?.toString(),
      tenNguoiXutri: json['nguoixutriNavigation']?['tennv']?.toString() ?? json['tenNguoiXutri']?.toString(),
      tenNguoiQuanLy: json['maqltsNavigation']?['tennv']?.toString() ?? json['tenNguoiQuanLy']?.toString(),
      sdtNguoiLap: getPhoneNumbers(json['nguoilapNavigation']),
      fileIds: json['taiSanRepairImages'] != null 
      ? (json['taiSanRepairImages'] as List)
          .map((img) => int.tryParse(img['fileId']?.toString() ?? ''))
          .where((id) => id != null)
          .cast<int>()
          .toList()
      : (json['fileIds'] != null ? List<int>.from(json['fileIds']) : null),
      logs: rawLogs != null
          ? (rawLogs as List).map((x) => RepairLogDetail.fromJson(x)).toList()
          : [],
    );
  }
}