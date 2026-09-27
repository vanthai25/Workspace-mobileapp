import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';

import '../models/cap_cchn_models.dart';
import '../services/cap_cchn_service.dart';

class CapCchnProvider extends ChangeNotifier {
  final CapCchnService service;

  CapCchnProvider({required this.service});

  CapCchnPageResult result = const CapCchnPageResult();
  String keyword = '';
  String status = '';
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> initialize() => load(page: 1);

  Future<void> load({int? page}) async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      result = await service.getDanhSach(
        keyword: keyword,
        status: status,
        page: page ?? result.currentPage,
        pageSize: result.pageSize,
      );
    } catch (error) {
      errorMessage = _message(error);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String value) async {
    keyword = value.trim();
    await load(page: 1);
  }

  Future<void> changeStatus(String value) async {
    if (status == value) return;
    status = value;
    await load(page: 1);
  }

  Future<CapCchnModel?> getDetail(int id) async {
    errorMessage = null;
    try {
      return await service.getById(id);
    } catch (error) {
      errorMessage = _message(error);
      notifyListeners();
      return null;
    }
  }

  Future<bool> save({
    int? id,
    required Map<String, dynamic> payload,
    fp.PlatformFile? fileHopDong,
    fp.PlatformFile? fileQuyetDinh,
    fp.PlatformFile? fileXacNhanTH,
    fp.PlatformFile? fileThongBaoTiepNhan,
    fp.PlatformFile? anhDaiDien,
    fp.PlatformFile? fileHocPhi,
  }) async {
    if (isSaving) return false;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (id == null) {
        await service.create(
          payload,
          fileHopDong: fileHopDong,
          fileQuyetDinh: fileQuyetDinh,
          fileXacNhanTH: fileXacNhanTH,
          fileThongBaoTiepNhan: fileThongBaoTiepNhan,
          anhDaiDien: anhDaiDien,
          fileHocPhi: fileHocPhi,
        );
      } else {
        await service.update(
          id,
          payload,
          fileHopDong: fileHopDong,
          fileQuyetDinh: fileQuyetDinh,
          fileXacNhanTH: fileXacNhanTH,
          fileThongBaoTiepNhan: fileThongBaoTiepNhan,
          anhDaiDien: anhDaiDien,
          fileHocPhi: fileHocPhi,
        );
      }
      await load(page: id == null ? 1 : result.currentPage);
      return true;
    } catch (error) {
      errorMessage = _message(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> remove(int id) async {
    if (isSaving) return false;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await service.delete(id);
      final int targetPage = result.items.length == 1 && result.currentPage > 1
          ? result.currentPage - 1
          : result.currentPage;
      await load(page: targetPage);
      return true;
    } catch (error) {
      errorMessage = _message(error);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<Uint8List> download(int id, String type) {
    return service.downloadFile(id, type);
  }

  Future<CapCchnCatalog> getCatalog() => service.getCatalog();

  Future<List<CapCchnMentorOption>> getMentorOptions({
    required int idKhoaPhong,
    required int loaiNhanVien,
    required DateTime ngayBatDau,
    required DateTime ngayKetThuc,
    int? excludeCapCchnId,
    String? keyword,
  }) => service.getMentorOptions(
    idKhoaPhong: idKhoaPhong,
    loaiNhanVien: loaiNhanVien,
    ngayBatDau: ngayBatDau,
    ngayKetThuc: ngayKetThuc,
    excludeCapCchnId: excludeCapCchnId,
    keyword: keyword,
  );

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
