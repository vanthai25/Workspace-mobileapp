import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';

import '../models/nhan_vien_v2_models.dart';
import '../models/khen_thuong_ky_luat_models.dart';
import '../services/nhan_vien_v2_service.dart';

class NhanVienV2Provider extends ChangeNotifier {
  final NhanVienV2Service service;

  NhanVienV2Provider({required this.service});

  bool isLoading = false;
  bool isPageLoading = false;
  bool isLoadingProfile = false;
  bool isLockingAccount = false;

  String? errorMessage;

  List<NhanVienV2Model> danhSach = [];
  List<KhoaPhongV2Model> khoaPhongs = [];
  List<NhanVienTaiLieuKhacV2Model> taiLieuKhac = [];

  bool isLoadingTaiLieuKhac = false;

  bool isUploadingTaiLieuKhac = false;

  final Set<int> downloadingTaiLieuKhacIds = {};
  bool isDownloadingTaiLieuKhac(int idTaiLieu) {
    return downloadingTaiLieuKhacIds.contains(idTaiLieu);
  }

  String? taiLieuKhacError;
  NhanVienProfileV2Model? profile;
  NhanVienKhenThuongKyLuatModel khenThuongKyLuat =
      const NhanVienKhenThuongKyLuatModel();
  bool isLoadingKhenThuongKyLuat = false;
  bool _loadKhenThuongKyLuatForSelection = false;

  String keyword = '';
  int? selectedKhoaPhong;

  bool includeNghiViec = false;

  int currentPage = 1;
  int pageSize = 50;

  int totalCount = 0;
  int totalPages = 0;
  String sortBy = 'maSo';
  String sortOrder = 'asc';

  NhanVienTongQuanV2Model? tongQuan;

  int _listRequestId = 0;
  String? selectedMaSo;
  NhanVienDanhMucV2Model? danhMuc;

  bool isSaving = false;
  Future<void> initialize() async {
    await Future.wait([loadKhoaPhong(), loadTongQuan(), loadDanhSach()]);
  }

  Future<void> ensureDanhMuc() async {
    if (danhMuc != null) {
      return;
    }

    danhMuc = await service.getDanhMuc();

    notifyListeners();
  }

  Future<void> loadKhoaPhong() async {
    try {
      khoaPhongs = await service.getKhoaPhong();

      notifyListeners();
    } catch (e) {
      debugPrint('NhanVienV2 loadKhoaPhong: $e');
    }
  }

  Future<void> loadTongQuan() async {
    try {
      tongQuan = await service.getTongQuan();

      notifyListeners();
    } catch (e) {
      debugPrint('NhanVienV2 loadTongQuan: $e');
    }
  }

  Future<void> loadDanhSach({bool resetPage = false}) async {
    if (resetPage) {
      currentPage = 1;
    }

    final int requestId = ++_listRequestId;

    final bool firstLoad = danhSach.isEmpty;

    if (firstLoad) {
      isLoading = true;
    } else {
      isPageLoading = true;
    }

    errorMessage = null;

    notifyListeners();

    try {
      debugPrint('Provider: bắt đầu load nhân viên...');

      final result = await service.getDanhSach(
        keyword: keyword,

        idKhoaPhong: selectedKhoaPhong,

        includeNghiViec: includeNghiViec,

        page: currentPage,

        pageSize: pageSize,

        sortBy: sortBy,

        sortOrder: sortOrder,
      );
      if (requestId != _listRequestId) {
        return;
      }

      danhSach = result.items;

      currentPage = result.currentPage;

      totalCount = result.totalCount;

      totalPages = result.totalPages;

      debugPrint('Provider: page = $currentPage');

      debugPrint('Provider: danhSach = ${danhSach.length}');

      debugPrint('Provider: totalCount = $totalCount');

      debugPrint('Provider: totalPages = $totalPages');
    } catch (e, stackTrace) {
      if (requestId != _listRequestId) {
        return;
      }
      errorMessage = e.toString();

      debugPrint('Provider loadDanhSach ERROR = $e');

      debugPrint(stackTrace.toString());
    } finally {
      if (requestId == _listRequestId) {
        isLoading = false;
        isPageLoading = false;

        notifyListeners();
      }
    }
  }

  Future<void> setKeyword(String value) async {
    keyword = value;

    await loadDanhSach(resetPage: true);
  }

  Future<void> setKhoaPhong(int? value) async {
    selectedKhoaPhong = value;

    await loadDanhSach(resetPage: true);
  }

  Future<void> setIncludeNghiViec(bool value) async {
    includeNghiViec = value;

    await loadDanhSach(resetPage: true);
  }

  // ===========================================================
  // PAGE
  // ===========================================================

  Future<void> goToPage(int page) async {
    if (isLoading || isPageLoading) {
      return;
    }

    final int maxPage = totalPages <= 0 ? 1 : totalPages;

    final int target = page.clamp(1, maxPage);

    if (target == currentPage) {
      return;
    }

    currentPage = target;

    await loadDanhSach();
  }

  Future<void> firstPage() async {
    await goToPage(1);
  }

  Future<void> lastPage() async {
    if (totalPages <= 0) {
      return;
    }

    await goToPage(totalPages);
  }

  Future<void> nextPage() async {
    await goToPage(currentPage + 1);
  }

  Future<void> previousPage() async {
    await goToPage(currentPage - 1);
  }

  Future<void> setSort({required String by, required String order}) async {
    if (sortBy == by && sortOrder == order) {
      return;
    }

    sortBy = by;
    sortOrder = order;

    await Future.wait([loadTongQuan(), loadDanhSach(resetPage: true)]);
  }
  // ===========================================================
  // PROFILE
  // ===========================================================

  Future<void> selectNhanVien(
    String maSo, {
    bool loadKhenThuongKyLuat = false,
  }) async {
    selectedMaSo = maSo;
    _loadKhenThuongKyLuatForSelection = loadKhenThuongKyLuat;

    isLoadingProfile = true;
    isLoadingKhenThuongKyLuat = loadKhenThuongKyLuat;
    errorMessage = null;

    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        service.getHoSo(maSo),
        service.getTaiLieuKhac(maSo),
      ]);

      profile = results[0] as NhanVienProfileV2Model;
      taiLieuKhac = results[1] as List<NhanVienTaiLieuKhacV2Model>;
      if (loadKhenThuongKyLuat) {
        try {
          khenThuongKyLuat = await service.getKhenThuongKyLuat(maSo);
        } catch (e) {
          errorMessage = e.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          );
          khenThuongKyLuat = const NhanVienKhenThuongKyLuatModel();
        }
      } else {
        khenThuongKyLuat = const NhanVienKhenThuongKyLuatModel();
      }
    } catch (e) {
      errorMessage = e.toString();
      profile = null;
      taiLieuKhac = [];
      khenThuongKyLuat = const NhanVienKhenThuongKyLuatModel();
    } finally {
      isLoadingProfile = false;
      isLoadingKhenThuongKyLuat = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    final maSo = selectedMaSo;

    if (maSo == null) {
      return;
    }

    await selectNhanVien(
      maSo,
      loadKhenThuongKyLuat: _loadKhenThuongKyLuatForSelection,
    );
  }

  Future<void> loadKhenThuongKyLuat(String maSo) async {
    isLoadingKhenThuongKyLuat = true;
    errorMessage = null;
    notifyListeners();
    try {
      khenThuongKyLuat = await service.getKhenThuongKyLuat(maSo);
    } catch (e) {
      errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      khenThuongKyLuat = const NhanVienKhenThuongKyLuatModel();
    } finally {
      isLoadingKhenThuongKyLuat = false;
      notifyListeners();
    }
  }

  Future<bool> saveKhenThuong({
    required String maSo,
    required Map<String, dynamic> data,
    String? maKhenThuong,
    fp.PlatformFile? file,
  }) async {
    if (isSaving) return false;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await service.saveKhenThuong(
        maSo: maSo,
        payload: data,
        maKhenThuong: maKhenThuong,
        fileBytes: file?.bytes,
        fileName: file?.name,
      );
      await loadKhenThuongKyLuat(maSo);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> saveKyLuat({
    required String maSo,
    required Map<String, dynamic> data,
    String? maKyLuat,
    fp.PlatformFile? file,
  }) async {
    if (isSaving) return false;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await service.saveKyLuat(
        maSo: maSo,
        payload: data,
        maKyLuat: maKyLuat,
        fileBytes: file?.bytes,
        fileName: file?.name,
      );
      await loadKhenThuongKyLuat(maSo);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteKhenThuong(String maSo, String maKhenThuong) async {
    return _deleteKhenThuongKyLuat(
      maSo,
      () => service.deleteKhenThuong(maSo, maKhenThuong),
    );
  }

  Future<bool> deleteKyLuat(String maSo, String maKyLuat) async {
    return _deleteKhenThuongKyLuat(
      maSo,
      () => service.deleteKyLuat(maSo, maKyLuat),
    );
  }

  Future<bool> _deleteKhenThuongKyLuat(
    String maSo,
    Future<void> Function() action,
  ) async {
    if (isSaving) return false;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      await loadKhenThuongKyLuat(maSo);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> downloadKhenThuongKyLuatFile({
    required String maSo,
    required String loai,
    required String ma,
  }) async {
    try {
      return await service.downloadKhenThuongKyLuatFile(
        maSo: maSo,
        loai: loai,
        ma: ma,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> createNhanVien(Map<String, dynamic> data) async {
    if (isSaving) return false;

    isSaving = true;
    errorMessage = null;

    notifyListeners();

    try {
      await service.createNhanVien(data);

      await loadDanhSach(resetPage: true);

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateNhanVien(String maSo, Map<String, dynamic> data) async {
    if (isSaving) return false;

    isSaving = true;
    errorMessage = null;

    notifyListeners();

    try {
      await service.updateNhanVien(maSo, data);

      await Future.wait([loadDanhSach(), loadTongQuan()]);

      if (selectedMaSo == maSo) {
        await refreshProfile();
      }

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<KhoaTaiKhoanNhanVienV2Model?> lockNhanVienAccounts(String maSo) async {
    if (isLockingAccount) {
      return null;
    }

    isLockingAccount = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await service.lockNhanVienAccounts(maSo);

      await Future.wait<void>([
        loadDanhSach(),
        if (selectedMaSo == maSo) refreshProfile(),
      ]);

      return result;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      isLockingAccount = false;
      notifyListeners();
    }
  }

  Future<bool> createViTriCongTac(
    String maSo,
    Map<String, dynamic> data,
  ) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.createViTriCongTac(maSo, data);

      await refreshProfile();
      await loadDanhSach();

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<UploadedFileV2Model> uploadFile({
    required Uint8List bytes,
    required String fileName,
  }) {
    return service.uploadFile(bytes: bytes, fileName: fileName);
  }

  Future<Uint8List?> downloadNhanVienFile({
    required String maSo,
    required int idFile,
  }) async {
    try {
      errorMessage = null;
      return await service.downloadNhanVienFile(maSo: maSo, idFile: idFile);
    } catch (e) {
      errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> createChungChi(String maSo, Map<String, dynamic> data) async {
    if (isSaving) return false;

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await service.createChungChi(maSo, data);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateChungChi(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    if (isSaving) return false;

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await service.updateChungChi(maSo, id, data);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteChungChi(String maSo, int id) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.deleteChungChi(maSo, id);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> createBangCap(String maSo, Map<String, dynamic> data) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.createBangCap(maSo, data);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateBangCap(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.updateBangCap(maSo, id, data);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBangCap(String maSo, int id) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.deleteBangCap(maSo, id);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> createCchn(String maSo, Map<String, dynamic> data) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.createCchn(maSo, data);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateCchn(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.updateCchn(maSo, id, data);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCchn(String maSo, int id) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.deleteCchn(maSo, id);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> createHopDong(String maSo, Map<String, dynamic> data) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.createHopDong(maSo, data);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateHopDong(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.updateHopDong(maSo, id, data);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteHopDong(String maSo, int id) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.deleteHopDong(maSo, id);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> createThanNhan(String maSo, Map<String, dynamic> data) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.createThanNhan(maSo, data);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateThanNhan(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.updateThanNhan(maSo, id, data);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteThanNhan(String maSo, int id) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.deleteThanNhan(maSo, id);

      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateViTriCongTac(
    String maSo,
    int id,
    Map<String, dynamic> data,
  ) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.updateViTriCongTac(maSo, id, data);

      await refreshProfile();
      await loadDanhSach();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDaoTaoNoiVien(String maSo, int idDangKyDaoTao) async {
    if (isSaving) {
      return false;
    }

    isSaving = true;

    errorMessage = null;

    notifyListeners();

    try {
      await service.deleteDaoTaoNoiVien(maSo, idDangKyDaoTao);
      await refreshProfile();

      return true;
    } catch (e) {
      errorMessage = e.toString();

      return false;
    } finally {
      isSaving = false;

      notifyListeners();
    }
  }

  Future<bool> deleteViTriCongTac(String maSo, int id) async {
    if (isSaving) return false;

    isSaving = true;
    notifyListeners();

    try {
      await service.deleteViTriCongTac(maSo, id);

      await refreshProfile();
      await loadDanhSach();

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<List<NhanVienTaiLieuKhacV2Model>> loadTaiLieuKhac(String maSo) async {
    isLoadingTaiLieuKhac = true;

    taiLieuKhacError = null;

    notifyListeners();

    try {
      taiLieuKhac = await service.getTaiLieuKhac(maSo);

      return taiLieuKhac;
    } catch (e) {
      taiLieuKhacError = _getErrorMessage(e);

      taiLieuKhac = [];

      return [];
    } finally {
      isLoadingTaiLieuKhac = false;

      notifyListeners();
    }
  }

  Future<bool> uploadTaiLieuKhac({
    required String maSo,
    required List<fp.PlatformFile> files,
    DateTime? ngayTaiLieu,
    String? ghiChu,
  }) async {
    if (isUploadingTaiLieuKhac) {
      return false;
    }

    isUploadingTaiLieuKhac = true;

    taiLieuKhacError = null;

    notifyListeners();

    try {
      await service.uploadTaiLieuKhac(
        maSo: maSo,

        files: files,

        ngayTaiLieu: ngayTaiLieu,

        ghiChu: ghiChu,
      );

      await loadTaiLieuKhac(maSo);

      return true;
    } catch (e) {
      taiLieuKhacError = _getErrorMessage(e);

      return false;
    } finally {
      isUploadingTaiLieuKhac = false;

      notifyListeners();
    }
  }

  Future<bool> updateTaiLieuKhac({
    required String maSo,
    required int idTaiLieu,
    String? tenTaiLieu,
    DateTime? ngayTaiLieu,
    String? ghiChu,
    int? stt,
  }) async {
    try {
      await service.updateTaiLieuKhac(
        maSo: maSo,

        idTaiLieu: idTaiLieu,

        tenTaiLieu: tenTaiLieu,

        ngayTaiLieu: ngayTaiLieu,

        ghiChu: ghiChu,

        stt: stt,
      );

      await loadTaiLieuKhac(maSo);

      return true;
    } catch (e) {
      taiLieuKhacError = _getErrorMessage(e);

      notifyListeners();

      return false;
    }
  }

  Future<bool> deleteTaiLieuKhac({
    required String maSo,
    required int idTaiLieu,
  }) async {
    try {
      await service.deleteTaiLieuKhac(maSo: maSo, idTaiLieu: idTaiLieu);

      taiLieuKhac.removeWhere((x) => x.idTaiLieuNhanVien == idTaiLieu);

      notifyListeners();

      return true;
    } catch (e) {
      taiLieuKhacError = _getErrorMessage(e);

      notifyListeners();

      return false;
    }
  }

  Future<Uint8List?> downloadTaiLieuKhac({
    required String maSo,
    required int idTaiLieu,
  }) async {
    if (downloadingTaiLieuKhacIds.contains(idTaiLieu)) {
      return null;
    }

    downloadingTaiLieuKhacIds.add(idTaiLieu);

    notifyListeners();

    try {
      return await service.downloadTaiLieuKhac(
        maSo: maSo,

        idTaiLieu: idTaiLieu,
      );
    } catch (e) {
      taiLieuKhacError = _getErrorMessage(e);

      return null;
    } finally {
      downloadingTaiLieuKhacIds.remove(idTaiLieu);

      notifyListeners();
    }
  }

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      final body = error.response?.data;

      if (body is Map) {
        final message = body['message'] ?? body['Message'];

        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }

      if (body is String && body.trim().isNotEmpty) {
        return body.trim();
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    return error.toString();
  }
}
