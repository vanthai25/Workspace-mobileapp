import 'package:flutter/foundation.dart';
import '../models/thuc_hanh_models.dart';
import '../services/thuc_hanh_service.dart';

class ThucHanhProvider extends ChangeNotifier {
  final ThucHanhService service;
  ThucHanhProvider(this.service);
  ThucHanhPage<NguoiThucHanhModel> people = const ThucHanhPage();
  ThucHanhPage<DotThucHanhModel> batches = const ThucHanhPage();
  ThucHanhPage<DangKyThucHanhModel> registrations = const ThucHanhPage();
  bool loadingPeople = false,
      loadingBatches = false,
      loadingRegistrations = false,
      saving = false;
  String? error;
  String keywordPeople = '', keywordBatches = '', keywordRegistrations = '';
  int? peopleBatchId;
  int? batchRegistrationState;
  DateTime? batchFromDate, batchToDate;
  int? registrationBatchId, registrationPracticeState, registrationSource;
  int _peopleRequest = 0, _batchRequest = 0, _registrationRequest = 0;

  Future<void> initialize() => loadBatches();

  Future<void> selectBatch(int id) {
    registrationBatchId = id;
    keywordRegistrations = '';
    registrationPracticeState = null;
    registrationSource = null;
    registrations = const ThucHanhPage();
    return loadRegistrations();
  }

  Future<void> loadPeople({int page = 1}) async {
    final request = ++_peopleRequest;
    loadingPeople = true;
    error = null;
    notifyListeners();
    try {
      final result = await service.getPeople(
        keyword: keywordPeople,
        batchId: peopleBatchId,
        page: page,
      );
      if (request == _peopleRequest) people = result;
    } catch (e) {
      if (request == _peopleRequest) error = _msg(e);
    } finally {
      if (request == _peopleRequest) {
        loadingPeople = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadBatches({int page = 1}) async {
    final request = ++_batchRequest;
    loadingBatches = true;
    error = null;
    notifyListeners();
    try {
      final result = await service.getBatches(
        keyword: keywordBatches,
        registrationState: batchRegistrationState,
        fromDate: batchFromDate,
        toDate: batchToDate,
        page: page,
      );
      if (request == _batchRequest) batches = result;
    } catch (e) {
      if (request == _batchRequest) error = _msg(e);
    } finally {
      if (request == _batchRequest) {
        loadingBatches = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadRegistrations({int page = 1}) async {
    final request = ++_registrationRequest;
    loadingRegistrations = true;
    error = null;
    notifyListeners();
    try {
      final result = await service.getRegistrations(
        keyword: keywordRegistrations,
        batchId: registrationBatchId,
        practiceState: registrationPracticeState,
        source: registrationSource,
        page: page,
      );
      if (request == _registrationRequest) registrations = result;
    } catch (e) {
      if (request == _registrationRequest) error = _msg(e);
    } finally {
      if (request == _registrationRequest) {
        loadingRegistrations = false;
        notifyListeners();
      }
    }
  }

  Future<bool> mutate(
    Future<void> Function() action, {
    bool reloadPeople = false,
    bool reloadBatches = false,
    bool reloadRegistrations = false,
  }) async {
    if (saving) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await action();
      if (reloadPeople) await loadPeople(page: people.page);
      if (reloadBatches) await loadBatches(page: batches.page);
      if (reloadRegistrations) {
        await loadRegistrations(page: registrations.page);
      }
      return true;
    } catch (e) {
      error = _msg(e);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');
}
