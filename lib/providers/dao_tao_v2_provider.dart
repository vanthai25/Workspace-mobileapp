import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../models/dao_tao_v2_models.dart';
import '../services/dao_tao_v2_service.dart';

class DaoTaoV2Provider extends ChangeNotifier {
  final DaoTaoV2Service service;
  final Map<int, List<LopDaoTaoFileV2Model>> taiLieuTheoLop = {};

  final Set<int> loadingTaiLieuIds = {};

  final Map<int, String?> taiLieuErrorTheoLop = {};
  final Map<int, DaoTaoThongTinOnlineV2Model> thongTinOnlineTheoLop = {};

  final Set<int> loadingThongTinOnlineIds = {};

  bool isLoadingNhanVienChuaDangKy = false;

  bool isBoSungNguoiDangKy = false;

  List<DaoTaoNhanVienChuaDangKyV2Model> nhanVienChuaDangKy = [];
  final Set<int> downloadingFileIds = {};
  DaoTaoV2Provider({required this.service});

  // ==========================================================
  // STATE
  // ==========================================================

  bool isLoading = false;

  bool isLoadingMyClasses = false;

  bool isSaving = false;

  String? errorMessage;
  bool isLoadingDashboard = false;
  bool isLoadingChamCong = false;

  bool isLoadingNguoiDangKy = false;

  bool isCapChungChi = false;

  bool isExportingExcel = false;
  bool isLoadingXacNhanHocVien = false;

  bool isSavingXacNhanHocVien = false;
  bool isPreparingPrint = false;
  List<DaoTaoXacNhanHocVienV2Model> xacNhanHocVien = [];
  DaoTaoChamCongBaoCaoV2Model? baoCaoChamCong;

  List<DaoTaoNguoiDangKyV2Model> nguoiDangKy = [];
  DaoTaoDashboardV2Model? dashboard;
  List<LopDaoTaoV2Model> danhSach = [];

  List<LopDaoTaoV2Model> lopCuaToi = [];

  DaoTaoDanhMucV2Model? danhMuc;

  String keyword = '';

  bool? dangMoDangKy;
  bool isLoadingTaiLieu(int idLopDaoTao) {
    return loadingTaiLieuIds.contains(idLopDaoTao);
  }

  bool isDownloadingFile(int idFile) {
    return downloadingFileIds.contains(idFile);
  }

  Future<void> initialize() async {
    await loadDanhSach();
  }

  Future<void> loadDanhSach({DateTime? tuNgay, DateTime? denNgay}) async {
    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      danhSach = await service.getDanhSach(
        keyword: keyword,

        dangMoDangKy: dangMoDangKy,

        tuNgay: tuNgay,

        denNgay: denNgay,
      );
    } catch (e) {
      errorMessage = _getErrorMessage(e);
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  Future<void> setKeyword(
    String value, {
    DateTime? tuNgay,
    DateTime? denNgay,
  }) async {
    keyword = value.trim();

    await loadDanhSach(tuNgay: tuNgay, denNgay: denNgay);
  }

  Future<void> setDangMoDangKy(
    bool? value, {
    DateTime? tuNgay,
    DateTime? denNgay,
  }) async {
    dangMoDangKy = value;

    await loadDanhSach(tuNgay: tuNgay, denNgay: denNgay);
  }

  Future<void> loadLopCuaToi() async {
    isLoadingMyClasses = true;

    errorMessage = null;

    notifyListeners();

    try {
      lopCuaToi = await service.getLopCuaToi();
    } catch (e) {
      errorMessage = _getErrorMessage(e);
    } finally {
      isLoadingMyClasses = false;

      notifyListeners();
    }
  }

  // ==========================================================
  // DANH MỤC
  // ==========================================================

  Future<bool> ensureDanhMuc() async {
    if (danhMuc != null) {
      return true;
    }

    try {
      danhMuc = await service.getDanhMuc();

      notifyListeners();

      return true;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      notifyListeners();

      return false;
    }
  }

  Future<bool> createLop(
    Map<String, dynamic> data, {
    required List<fp.PlatformFile> files,
  }) async {
    if (isSaving) {
      return false;
    }

    isSaving = true;
    errorMessage = null;

    notifyListeners();

    try {
      await service.createLop(data, files: files);

      await loadDanhSach();

      return true;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      isSaving = false;

      notifyListeners();
    }
  }

  Future<bool> updateLop(
    int id,
    Map<String, dynamic> data, {
    required List<fp.PlatformFile> files,
    required List<int> fileIdsToDelete,
  }) async {
    if (isSaving) {
      return false;
    }

    isSaving = true;
    errorMessage = null;

    notifyListeners();

    try {
      await service.updateLop(
        id,
        data,
        files: files,
        fileIdsToDelete: fileIdsToDelete,
      );

      // File đã thay đổi => bỏ cache cũ.
      taiLieuTheoLop.remove(id);

      taiLieuErrorTheoLop.remove(id);

      await loadDanhSach();

      await loadLopCuaToi();

      return true;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      isSaving = false;

      notifyListeners();
    }
  }

  Future<bool> deleteLop(int id) async {
    if (isSaving) {
      return false;
    }

    isSaving = true;
    errorMessage = null;

    notifyListeners();

    try {
      await service.deleteLop(id);

      danhSach.removeWhere((e) => e.idLopDaoTao == id);

      lopCuaToi.removeWhere((e) => e.idLopDaoTao == id);

      notifyListeners();

      return true;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      isSaving = false;

      notifyListeners();
    }
  }

  Future<bool> dangKy(int id, {bool isDangKyOnline = false}) async {
    if (isSaving) {
      return false;
    }

    isSaving = true;
    errorMessage = null;

    notifyListeners();

    try {
      await service.dangKy(id, isDangKyOnline: isDangKyOnline);

      await Future.wait([loadDanhSach(), loadLopCuaToi()]);

      await loadTaiLieu(id, force: true);

      if (isDangKyOnline) {
        await loadThongTinOnline(id, force: true);
      }

      return true;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      isSaving = false;

      notifyListeners();
    }
  }

  bool isLoadingThongTinOnline(int idLopDaoTao) {
    return loadingThongTinOnlineIds.contains(idLopDaoTao);
  }

  Future<DaoTaoThongTinOnlineV2Model?> loadThongTinOnline(
    int idLopDaoTao, {
    bool force = false,
  }) async {
    if (!force && thongTinOnlineTheoLop.containsKey(idLopDaoTao)) {
      return thongTinOnlineTheoLop[idLopDaoTao];
    }

    if (loadingThongTinOnlineIds.contains(idLopDaoTao)) {
      return null;
    }

    loadingThongTinOnlineIds.add(idLopDaoTao);

    errorMessage = null;

    notifyListeners();

    try {
      final result = await service.getThongTinOnline(idLopDaoTao);

      thongTinOnlineTheoLop[idLopDaoTao] = result;

      return result;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return null;
    } finally {
      loadingThongTinOnlineIds.remove(idLopDaoTao);

      notifyListeners();
    }
  }

  // ==========================================================
  // TÌM NGƯỜI CHƯA ĐĂNG KÝ
  // ==========================================================

  Future<List<DaoTaoNhanVienChuaDangKyV2Model>> loadNhanVienChuaDangKy(
    int idLopDaoTao, {
    String? keyword,
  }) async {
    isLoadingNhanVienChuaDangKy = true;

    errorMessage = null;

    notifyListeners();

    try {
      nhanVienChuaDangKy = await service.getNhanVienChuaDangKy(
        idLopDaoTao,
        keyword: keyword,
      );

      return nhanVienChuaDangKy;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      nhanVienChuaDangKy = [];

      return [];
    } finally {
      isLoadingNhanVienChuaDangKy = false;

      notifyListeners();
    }
  }

  // ==========================================================
  // BỔ SUNG NGƯỜI VÀO LỚP
  // ==========================================================

  Future<BoSungNguoiDangKyResultV2Model?> boSungNguoiDangKy({
    required int idLopDaoTao,
    required Map<String, bool> nhanViens,
  }) async {
    if (isBoSungNguoiDangKy) {
      return null;
    }

    isBoSungNguoiDangKy = true;

    errorMessage = null;

    notifyListeners();

    try {
      final result = await service.boSungNguoiDangKy(
        idLopDaoTao: idLopDaoTao,

        nhanViens: nhanViens,
      );

      // cập nhật số người đăng ký
      await loadDanhSach();

      await Future.wait([
        loadNhanVienChuaDangKy(idLopDaoTao),

        loadXacNhanHocVien(idLopDaoTao),
      ]);

      return result;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return null;
    } finally {
      isBoSungNguoiDangKy = false;

      notifyListeners();
    }
  }
  // ==========================================================
  // HỦY ĐĂNG KÝ
  // ==========================================================

  Future<bool> huyDangKy(int id) async {
    if (isSaving) {
      return false;
    }

    isSaving = true;
    errorMessage = null;

    notifyListeners();

    try {
      await service.huyDangKy(id);

      await Future.wait([loadDanhSach(), loadLopCuaToi()]);

      return true;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      isSaving = false;

      notifyListeners();
    }
  }

  Future<DaoTaoChamCongBaoCaoV2Model?> loadBaoCaoChamCong(
    int idLopDaoTao,
  ) async {
    isLoadingChamCong = true;
    errorMessage = null;
    baoCaoChamCong = null;

    notifyListeners();

    try {
      final result = await service.getBaoCaoChamCong(idLopDaoTao);

      baoCaoChamCong = result;

      return result;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return null;
    } finally {
      isLoadingChamCong = false;

      notifyListeners();
    }
  }

  Future<DaoTaoInDiemDanhV2Model?> prepareInDiemDanh({
    required int idLopDaoTao,
    required String loaiIn,
    required DateTime ngayInDiemDanh,
  }) async {
    if (isPreparingPrint) {
      return null;
    }

    isPreparingPrint = true;

    errorMessage = null;

    notifyListeners();

    try {
      final result = await service.getDuLieuInDiemDanh(
        idLopDaoTao: idLopDaoTao,

        loaiIn: loaiIn,

        ngayInDiemDanh: ngayInDiemDanh,
      );

      // NgayInDiemDanh đã được update ở backend.
      await loadDanhSach();

      return result;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return null;
    } finally {
      isPreparingPrint = false;

      notifyListeners();
    }
  }

  Future<List<DaoTaoXacNhanHocVienV2Model>> loadXacNhanHocVien(
    int idLopDaoTao,
  ) async {
    isLoadingXacNhanHocVien = true;

    errorMessage = null;

    notifyListeners();

    try {
      xacNhanHocVien = await service.getXacNhanHocVien(idLopDaoTao);

      return xacNhanHocVien;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      xacNhanHocVien = [];

      return [];
    } finally {
      isLoadingXacNhanHocVien = false;

      notifyListeners();
    }
  }

  // ==========================================================
  // LƯU IsHopLeDaoTao
  // ==========================================================

  Future<bool> saveXacNhanHocVien({
    required int idLopDaoTao,
    required Map<String, bool> nhanViens,
  }) async {
    if (isSavingXacNhanHocVien) {
      return false;
    }

    if (nhanViens.isEmpty) {
      return false;
    }

    isSavingXacNhanHocVien = true;

    errorMessage = null;

    notifyListeners();

    try {
      await service.xacNhanHocVien(
        idLopDaoTao: idLopDaoTao,

        nhanViens: nhanViens,
      );

      await loadXacNhanHocVien(idLopDaoTao);

      return true;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return false;
    } finally {
      isSavingXacNhanHocVien = false;

      notifyListeners();
    }
  }
  // ==========================================================
  // NGƯỜI ĐĂNG KÝ
  // ==========================================================

  Future<List<DaoTaoNguoiDangKyV2Model>> loadNguoiDangKy(
    int idLopDaoTao,
  ) async {
    isLoadingNguoiDangKy = true;
    errorMessage = null;
    nguoiDangKy = [];

    notifyListeners();

    try {
      nguoiDangKy = await service.getNguoiDangKy(idLopDaoTao);

      return nguoiDangKy;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return [];
    } finally {
      isLoadingNguoiDangKy = false;

      notifyListeners();
    }
  }

  // ==========================================================
  // CẤP CME / CHỨNG CHỈ
  // ==========================================================

  Future<CapChungChiDaoTaoResultV2Model?> capChungChi({
    required int idLopDaoTao,
    required List<String> maSos,
    required bool cme,
    DateTime? ngayHetHan,
    String? soChungChi,
  }) async {
    if (isCapChungChi) {
      return null;
    }

    isCapChungChi = true;
    errorMessage = null;

    notifyListeners();

    try {
      final result = await service.capChungChi(
        idLopDaoTao: idLopDaoTao,

        maSos: maSos,

        cme: cme,

        ngayHetHan: ngayHetHan,

        soChungChi: soChungChi,
      );

      // Reload để cập nhật DaCapCme / DaCapChungChi
      await loadNguoiDangKy(idLopDaoTao);

      return result;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return null;
    } finally {
      isCapChungChi = false;

      notifyListeners();
    }
  }

  // ==========================================================
  // EXCEL
  // ==========================================================

  Future<Uint8List?> exportChamCongExcel(int idLopDaoTao) async {
    if (isExportingExcel) {
      return null;
    }

    isExportingExcel = true;
    errorMessage = null;

    notifyListeners();

    try {
      return await service.exportChamCongExcel(idLopDaoTao);
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return null;
    } finally {
      isExportingExcel = false;

      notifyListeners();
    }
  }
  // ==========================================================
  // UPLOAD FILE
  // ==========================================================

  Future<DaoTaoUploadedFileV2Model> uploadFile({
    required Uint8List bytes,
    required String fileName,
  }) {
    return service.uploadFile(bytes: bytes, fileName: fileName);
  }

  Future<DaoTaoDashboardV2Model?> loadDashboard(int idLopDaoTao) async {
    if (isLoadingDashboard) {
      return null;
    }

    isLoadingDashboard = true;
    errorMessage = null;
    dashboard = null;

    notifyListeners();

    try {
      final result = await service.getDashboard(idLopDaoTao);

      dashboard = result;

      return result;
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return null;
    } finally {
      isLoadingDashboard = false;

      notifyListeners();
    }
  }

  void clearDashboard() {
    dashboard = null;
    notifyListeners();
  }

  Future<List<LopDaoTaoFileV2Model>> loadTaiLieu(
    int idLopDaoTao, {
    bool force = false,
  }) async {
    if (!force && taiLieuTheoLop.containsKey(idLopDaoTao)) {
      return taiLieuTheoLop[idLopDaoTao] ?? [];
    }

    if (loadingTaiLieuIds.contains(idLopDaoTao)) {
      return taiLieuTheoLop[idLopDaoTao] ?? [];
    }

    loadingTaiLieuIds.add(idLopDaoTao);

    taiLieuErrorTheoLop[idLopDaoTao] = null;

    notifyListeners();

    try {
      final result = await service.getTaiLieu(idLopDaoTao);

      taiLieuTheoLop[idLopDaoTao] = result;

      return result;
    } catch (e) {
      taiLieuErrorTheoLop[idLopDaoTao] = _getErrorMessage(e);

      return [];
    } finally {
      loadingTaiLieuIds.remove(idLopDaoTao);

      notifyListeners();
    }
  }

  Future<Uint8List?> downloadTaiLieu({
    required int idLopDaoTao,
    required int idFile,
  }) async {
    if (downloadingFileIds.contains(idFile)) {
      return null;
    }

    downloadingFileIds.add(idFile);

    errorMessage = null;

    notifyListeners();

    try {
      return await service.downloadTaiLieu(
        idLopDaoTao: idLopDaoTao,

        idFile: idFile,
      );
    } catch (e) {
      errorMessage = _getErrorMessage(e);

      return null;
    } finally {
      downloadingFileIds.remove(idFile);

      notifyListeners();
    }
  }

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'Không kết nối được máy chủ. Vui lòng kiểm tra API hoặc đường truyền rồi thử lại.';
      }

      if (error.type == DioExceptionType.receiveTimeout) {
        return 'Máy chủ xử lý dữ liệu quá lâu. Vui lòng thử lại sau ít phút.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra API hoặc đường truyền.';
      }

      final body = error.response?.data;

      if (body is Map) {
        final message = body['message'] ?? body['Message'];

        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    return error.toString();
  }
}
