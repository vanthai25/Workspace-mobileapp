import 'package:flutter/material.dart';
import '../models/cham_cong_tang_ca_model.dart';
import '../services/cham_cong_tang_ca_service.dart';

class ChamCongTangCaProvider with ChangeNotifier {
  final ChamCongTangCaService _service = ChamCongTangCaService();
  
  List<ChamCongTangCaModel> _danhSachPhieu = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<ChamCongTangCaModel> get danhSachPhieu => _danhSachPhieu;
  bool get isLoading => _isLoading;
  bool _chiCaNhanHienTai = false;
  int? _trangThaiHienTai;
  String get errorMessage => _errorMessage;

  Future<void> fetchDanhSach({
    int? trangThai,
    bool chiCaNhan = false,
  }) async {
    _isLoading = true;
    _errorMessage = '';

    _trangThaiHienTai = trangThai;
    _chiCaNhanHienTai = chiCaNhan;

    notifyListeners();

    try {
      _danhSachPhieu = await _service.getDanhSachPhieu(
        trangThai: trangThai,
        chiCaNhan: chiCaNhan,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _danhSachPhieu = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> refreshDanhSach() async {
    await fetchDanhSach(
      trangThai: _trangThaiHienTai,
      chiCaNhan: _chiCaNhanHienTai,
    );
  }
  // Thêm mới phiếu
  Future<bool> createPhieu(DateTime batDau, DateTime ketThuc, int soPhut, String lyDo) async {
    try {
      // Đã sửa thành createPhieu và truyền param dạng named (required)
      bool success = await _service.createPhieu(
        batDau: batDau,
        ketThuc: ketThuc,
        soPhut: soPhut,
        lyDoTangCa: lyDo,
      );
      if (success) {
        await refreshDanhSach(); // Tải lại danh sách sau khi tạo thành công
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Cập nhật phiếu
  Future<bool> updatePhieu(int id, DateTime batDau, DateTime ketThuc, int soPhut, String lyDo) async {
    try {
      bool success = await _service.updatePhieu(
        id,
        batDau: batDau,
        ketThuc: ketThuc,
        soPhut: soPhut,
        lyDoTangCa: lyDo,
      );
      if (success) {
        await refreshDanhSach(); 
      }
      return success;
    } catch (e) {
      return false;
    }
  }
  
  // Xoá phiếu
  Future<bool> deletePhieu(int id) async {
     try {
       // Đã sửa thành deletePhieu
       bool success = await _service.deletePhieu(id);
       if(success){
         // Xoá trực tiếp khỏi list dưới local để UI update nhanh, không cần gọi lại API
         _danhSachPhieu.removeWhere((element) => element.id == id);
         notifyListeners();
       }
       return success;
     } catch (e) {
       return false;
     }
  }

  Future<bool> duyetPhieu(
    int id,
    int newStatus, {
    required String capDuyet,
    String lyDoTuChoi = '',
  }) async {
  final success = await _service.duyetPhieu(
    id,
    newStatus,
    capDuyet: capDuyet,
    lyDoTuChoi: lyDoTuChoi,
  );

  if (success) {
    await refreshDanhSach();
  }

  return success;
}
Future<bool> duyetNhieu({
  required Set<int> ids,
  required int newStatus,
  required String capDuyet,
  String lyDoTuChoi = '',
}) async {
  final success = await _service.duyetNhieu(
    ids: ids,
    newStatus: newStatus,
    capDuyet: capDuyet,
    lyDoTuChoi: lyDoTuChoi,
  );

  if (success) {
    await refreshDanhSach();
  }

  return success;
}
}