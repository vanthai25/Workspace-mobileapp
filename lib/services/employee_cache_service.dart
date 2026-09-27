import '../models/nhanvien_model.dart';

class EmployeeCacheService {
  // Static instance để dùng chung trong toàn app
  static final EmployeeCacheService instance = EmployeeCacheService._internal();
  EmployeeCacheService._internal();

  // Cache dữ liệu
  Map<String, List<NhanVien>> _deptEmployees = {};
  List<NhanVien>? _allEmployees;

  void saveDeptEmployees(String maKhoa, List<NhanVien> emps) => _deptEmployees[maKhoa] = emps;
  List<NhanVien>? getDeptEmployees(String maKhoa) => _deptEmployees[maKhoa];
  
  bool isDeptLoaded(String maKhoa) => _deptEmployees.containsKey(maKhoa);
}