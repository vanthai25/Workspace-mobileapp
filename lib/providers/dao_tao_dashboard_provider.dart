import 'package:flutter/foundation.dart';

import '../models/dao_tao_dashboard_models.dart';
import '../services/dao_tao_dashboard_service.dart';

class DaoTaoDashboardProvider extends ChangeNotifier {
  final DaoTaoDashboardService service;

  DaoTaoDashboardProvider(this.service);

  DaoTaoDashboardModel? dashboard;
  bool loading = false;
  bool exporting = false;
  String? error;

  Future<void> load() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      dashboard = await service.getDashboard();
    } catch (exception) {
      error = _message(exception);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<DaoTaoDashboardDownload?> exportExcel() async {
    if (exporting) return null;
    exporting = true;
    error = null;
    notifyListeners();
    try {
      return await service.exportExcel();
    } catch (exception) {
      error = _message(exception);
      return null;
    } finally {
      exporting = false;
      notifyListeners();
    }
  }

  String _message(Object exception) {
    final value = exception.toString().replaceFirst('Exception: ', '').trim();
    return value.isEmpty ? 'Không thể tải dashboard đào tạo.' : value;
  }
}
