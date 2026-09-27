import 'package:flutter/foundation.dart';

import '../models/cme_model.dart';
import '../services/cme_service.dart';

class CmeProvider with ChangeNotifier {
  final CmeService _service;

  CmeProvider({CmeService? service}) : _service = service ?? CmeService();

  List<CmeTrainingType> _trainingTypes = const <CmeTrainingType>[];
  List<CmeDepartment> _departments = const <CmeDepartment>[];
  CmePagedResult _myResult = const CmePagedResult();
  CmePagedResult _approvalResult = const CmePagedResult();
  CmeDashboardSummary _dashboardSummary = const CmeDashboardSummary();
  CmeQuery _myQuery = const CmeQuery();
  CmeQuery _approvalQuery = const CmeQuery(trangThai: CmeStatus.choDuyet);
  int _dashboardExpirationDays = 60;
  int _dashboardLimit = 5;
  bool _hasRequestedDashboard = false;

  bool _canApprove = false;
  bool _isLoadingMy = false;
  bool _isLoadingApproval = false;
  bool _isLoadingDashboard = false;
  bool _isLoadingCatalog = false;
  bool _isLoadingDepartments = false;
  bool _isSubmitting = false;
  bool _isProcessing = false;

  String? _myError;
  String? _approvalError;
  String? _dashboardError;
  String? _catalogError;
  String? _departmentError;
  String? _submitError;
  String? _processingError;

  int _catalogRequestVersion = 0;
  int _departmentRequestVersion = 0;
  int _myRequestVersion = 0;
  int _approvalRequestVersion = 0;
  int _dashboardRequestVersion = 0;

  List<CmeTrainingType> get trainingTypes => _trainingTypes;
  List<CmeDepartment> get departments => _departments;
  CmePagedResult get myResult => _myResult;
  CmePagedResult get approvalResult => _approvalResult;
  CmeDashboardSummary get dashboardSummary => _dashboardSummary;
  CmeQuery get myQuery => _myQuery;
  CmeQuery get approvalQuery => _approvalQuery;
  bool get canApprove => _canApprove;

  bool get isLoadingMy => _isLoadingMy;
  bool get isLoadingApproval => _isLoadingApproval;
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoadingCatalog => _isLoadingCatalog;
  bool get isLoadingDepartments => _isLoadingDepartments;
  bool get isSubmitting => _isSubmitting;
  bool get isProcessing => _isProcessing;

  String? get myError => _myError;
  String? get approvalError => _approvalError;
  String? get dashboardError => _dashboardError;
  String? get catalogError => _catalogError;
  String? get departmentError => _departmentError;
  String? get submitError => _submitError;
  String? get processingError => _processingError;

  String? get errorMessage =>
      _submitError ??
      _processingError ??
      _myError ??
      _approvalError ??
      _dashboardError ??
      _departmentError ??
      _catalogError;

  Future<void> initialize(bool canApprove) async {
    _catalogRequestVersion++;
    _departmentRequestVersion++;
    _myRequestVersion++;
    _approvalRequestVersion++;

    _canApprove = canApprove;
    if (!_canApprove) {
      _dashboardRequestVersion++;
      _dashboardSummary = const CmeDashboardSummary();
      _dashboardError = null;
      _isLoadingDashboard = false;
      _hasRequestedDashboard = false;
    }
    _trainingTypes = const <CmeTrainingType>[];
    _departments = const <CmeDepartment>[];
    _myQuery = const CmeQuery();
    _approvalQuery = const CmeQuery(trangThai: CmeStatus.choDuyet);
    _myResult = CmePagedResult(pageSize: _myQuery.pageSize);
    _approvalResult = CmePagedResult(pageSize: _approvalQuery.pageSize);
    _myError = null;
    _approvalError = null;
    _catalogError = null;
    _departmentError = null;
    _submitError = null;
    _processingError = null;
    _isLoadingMy = false;
    _isLoadingApproval = false;
    _isLoadingCatalog = false;
    _isLoadingDepartments = false;
    _isSubmitting = false;
    _isProcessing = false;
    notifyListeners();

    await Future.wait<void>(<Future<void>>[
      loadTrainingTypes(),
      if (_canApprove) loadDepartments(),
      loadMy(),
      if (_canApprove) loadApproval(),
      if (_canApprove) loadDashboard(),
    ]);
  }

  Future<void> loadDepartments() async {
    if (!_canApprove) {
      _departments = const <CmeDepartment>[];
      _departmentError = null;
      _isLoadingDepartments = false;
      notifyListeners();
      return;
    }

    final int requestId = ++_departmentRequestVersion;
    _isLoadingDepartments = true;
    _departmentError = null;
    notifyListeners();

    try {
      final List<CmeDepartment> result = await _service.getDepartments();
      if (requestId != _departmentRequestVersion) {
        return;
      }

      _departments = result;
    } catch (error) {
      if (requestId != _departmentRequestVersion) {
        return;
      }

      _departments = const <CmeDepartment>[];
      _departmentError = _errorText(
        error,
        'Không thể tải danh mục khoa/phòng.',
      );
    } finally {
      if (requestId == _departmentRequestVersion) {
        _isLoadingDepartments = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadTrainingTypes() async {
    final int requestId = ++_catalogRequestVersion;
    _isLoadingCatalog = true;
    _catalogError = null;
    notifyListeners();

    try {
      final List<CmeTrainingType> result = await _service.getTrainingTypes();
      if (requestId != _catalogRequestVersion) {
        return;
      }

      _trainingTypes = result;
    } catch (error) {
      if (requestId != _catalogRequestVersion) {
        return;
      }

      _trainingTypes = const <CmeTrainingType>[];
      _catalogError = _errorText(
        error,
        'Không thể tải danh mục hình thức đào tạo.',
      );
    } finally {
      if (requestId == _catalogRequestVersion) {
        _isLoadingCatalog = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMy({CmeQuery? query}) async {
    final CmeQuery requestedQuery = query ?? _myQuery;
    final int requestId = ++_myRequestVersion;
    _myQuery = requestedQuery;
    _isLoadingMy = true;
    _myError = null;
    notifyListeners();

    try {
      final CmePagedResult result = await _service.getMyRequests(
        requestedQuery,
      );
      if (requestId != _myRequestVersion) {
        return;
      }

      _myResult = result;
    } catch (error) {
      if (requestId != _myRequestVersion) {
        return;
      }

      _myError = _errorText(error, 'Không thể tải yêu cầu CME của bạn.');
    } finally {
      if (requestId == _myRequestVersion) {
        _isLoadingMy = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadApproval({CmeQuery? query}) async {
    if (!_canApprove) {
      _approvalResult = const CmePagedResult();
      _approvalError = null;
      _isLoadingApproval = false;
      notifyListeners();
      return;
    }

    final CmeQuery requestedQuery = query ?? _approvalQuery;
    final int requestId = ++_approvalRequestVersion;
    _approvalQuery = requestedQuery;
    _isLoadingApproval = true;
    _approvalError = null;
    notifyListeners();

    try {
      final CmePagedResult result = await _service.getApprovalRequests(
        requestedQuery,
      );
      if (requestId != _approvalRequestVersion) {
        return;
      }

      _approvalResult = result;
    } catch (error) {
      if (requestId != _approvalRequestVersion) {
        return;
      }

      _approvalError = _errorText(
        error,
        'Không thể tải danh sách yêu cầu CME cần duyệt.',
      );
    } finally {
      if (requestId == _approvalRequestVersion) {
        _isLoadingApproval = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadDashboard({
    bool? canApprove,
    int soNgaySapHetHan = 60,
    int gioiHan = 5,
  }) async {
    if (canApprove != null) {
      _canApprove = canApprove;
    }

    if (!_canApprove) {
      _dashboardRequestVersion++;
      _dashboardSummary = const CmeDashboardSummary();
      _dashboardError = null;
      _isLoadingDashboard = false;
      _hasRequestedDashboard = false;
      notifyListeners();
      return;
    }

    final int requestId = ++_dashboardRequestVersion;
    _dashboardExpirationDays = soNgaySapHetHan.clamp(1, 365);
    _dashboardLimit = gioiHan.clamp(1, 50);
    _hasRequestedDashboard = true;
    _isLoadingDashboard = true;
    _dashboardError = null;
    notifyListeners();

    try {
      final CmeDashboardSummary result = await _service.getDashboard(
        soNgaySapHetHan: _dashboardExpirationDays,
        gioiHan: _dashboardLimit,
      );
      if (requestId != _dashboardRequestVersion) {
        return;
      }

      _dashboardSummary = result;
    } catch (error) {
      if (requestId != _dashboardRequestVersion) {
        return;
      }

      _dashboardError = _errorText(error, 'Không thể tải thông báo CME.');
    } finally {
      if (requestId == _dashboardRequestVersion) {
        _isLoadingDashboard = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshDashboard() {
    return loadDashboard(
      soNgaySapHetHan: _dashboardExpirationDays,
      gioiHan: _dashboardLimit,
    );
  }

  Future<CmeRequestModel> create(CmeCreateInput input) async {
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();

    try {
      final CmeRequestModel created = await _service.create(input);
      await Future.wait<void>(<Future<void>>[
        loadMy(query: _myQuery.copyWith(page: 1)),
        if (_shouldRefreshDashboard) refreshDashboard(),
      ]);
      return created;
    } catch (error) {
      _submitError = _errorText(error, 'Không thể gửi yêu cầu CME.');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<CmeRequestModel> getById(int id) {
    return _service.getById(id);
  }

  Future<CmeAttachment> downloadAttachment(int id) {
    return _service.downloadAttachment(id);
  }

  Future<void> deleteRequest(int id) async {
    _isProcessing = true;
    _processingError = null;
    notifyListeners();

    try {
      await _service.deleteRequest(id);
      await Future.wait<void>(<Future<void>>[
        loadMy(query: _pageAfterRemovingItem(_myQuery, _myResult, id)),
        if (_canApprove)
          loadApproval(
            query: _pageAfterRemovingItem(_approvalQuery, _approvalResult, id),
          ),
        if (_shouldRefreshDashboard) refreshDashboard(),
      ]);
    } catch (error) {
      _processingError = _errorText(error, 'Không thể xóa yêu cầu CME.');
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<CmeRequestModel> approve(int id) {
    return _processDecision(() => _service.approve(id));
  }

  Future<CmeRequestModel> cancelApproval(int id) {
    return _processDecision(() => _service.cancelApproval(id));
  }

  Future<CmeRequestModel> reject(int id, String reason) {
    return _processDecision(() => _service.reject(id, reason));
  }

  Future<CmeRequestModel> _processDecision(
    Future<CmeRequestModel> Function() action,
  ) async {
    _isProcessing = true;
    _processingError = null;
    notifyListeners();

    try {
      final CmeRequestModel result = await action();
      await Future.wait<void>(<Future<void>>[
        loadMy(),
        if (_canApprove) loadApproval(),
        if (_shouldRefreshDashboard) refreshDashboard(),
      ]);
      return result;
    } catch (error) {
      _processingError = _errorText(error, 'Không thể xử lý yêu cầu CME.');
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearErrors() {
    _myError = null;
    _approvalError = null;
    _dashboardError = null;
    _catalogError = null;
    _departmentError = null;
    _submitError = null;
    _processingError = null;
    notifyListeners();
  }

  void clear() {
    _catalogRequestVersion++;
    _departmentRequestVersion++;
    _myRequestVersion++;
    _approvalRequestVersion++;
    _dashboardRequestVersion++;
    _canApprove = false;
    _trainingTypes = const <CmeTrainingType>[];
    _departments = const <CmeDepartment>[];
    _myQuery = const CmeQuery();
    _approvalQuery = const CmeQuery(trangThai: CmeStatus.choDuyet);
    _myResult = const CmePagedResult();
    _approvalResult = const CmePagedResult();
    _dashboardSummary = const CmeDashboardSummary();
    _dashboardExpirationDays = 60;
    _dashboardLimit = 5;
    _hasRequestedDashboard = false;
    _isLoadingMy = false;
    _isLoadingApproval = false;
    _isLoadingDashboard = false;
    _isLoadingCatalog = false;
    _isLoadingDepartments = false;
    _isSubmitting = false;
    _isProcessing = false;
    _myError = null;
    _approvalError = null;
    _dashboardError = null;
    _catalogError = null;
    _departmentError = null;
    _submitError = null;
    _processingError = null;
    notifyListeners();
  }

  bool get _shouldRefreshDashboard => _canApprove && _hasRequestedDashboard;

  CmeQuery _pageAfterRemovingItem(
    CmeQuery query,
    CmePagedResult result,
    int removedId,
  ) {
    final bool currentPageWillBeEmpty =
        result.page > 1 &&
        result.items.length == 1 &&
        result.items.single.id == removedId;
    return currentPageWillBeEmpty
        ? query.copyWith(page: result.page - 1)
        : query;
  }

  String _errorText(Object error, String fallback) {
    if (error is CmeApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return fallback;
  }
}
