import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart'; 
import 'package:dio/dio.dart';
import '../models/baocom_model.dart';
import '../models/baocom_menu.dart'; 
import '../models/nhanvien_model.dart';
import '../providers/auth_provider.dart';
import '../services/baocom_service.dart';
import '../services/nhanvien_service.dart';
import '../services/khoa_service.dart';
import '../utils/constants.dart';

class BaoComForm extends StatefulWidget {
  final BaoCom? existingData;
  final DateTime initialDate; 
  final String currentUserMaNV;
  final String currentUserTenNV;
  final String currentUserMaKhoa;
  final String currentUserTenKhoa;
  final List<BaoCom> allMeals; 
  final BaoComService apiService;
  final NhanvienService nhanvienService;
  final VoidCallback onSuccess;

  const BaoComForm({
    super.key,
    this.existingData,
    required this.initialDate,
    required this.currentUserMaNV,
    required this.currentUserTenNV,
    required this.currentUserMaKhoa,
    required this.currentUserTenKhoa,
    required this.allMeals, 
    required this.apiService,
    required this.nhanvienService,
    required this.onSuccess,
  });

  @override
  State<BaoComForm> createState() => _BaoComFormState();
}

class _BaoComFormState extends State<BaoComForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _manvCtrl = TextEditingController();
  final TextEditingController _tennvCtrl = TextEditingController();
  final TextEditingController _displayEmployeeCtrl = TextEditingController();
  
  late DateTime _selectedDate; 
  int _soNgayDat = 1; 

  bool _isTrua = false;
  bool _isToi = false;  
  bool _isSaving = false;
  
  String? _formErrorMessage;
  List<NhanVien> _khoaEmployees = [];
  bool _isLoadingEmployees = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate; 

    if (widget.existingData == null) {
      _manvCtrl.text = widget.currentUserMaNV;
      _tennvCtrl.text = widget.currentUserTenNV;
      _soNgayDat = 1; 
    } else {
      _manvCtrl.text = widget.existingData?.manv ?? '';
      _tennvCtrl.text = widget.existingData?.tennv ?? '';
      _soNgayDat = 1; 
      if (widget.existingData!.ngaybaocom != null) {
        _selectedDate = DateTime.tryParse(widget.existingData!.ngaybaocom!) ?? widget.initialDate;
      }
    }
    
    if (_manvCtrl.text.isNotEmpty) {
      _displayEmployeeCtrl.text = "${_manvCtrl.text} - ${_tennvCtrl.text}";
    }
    
    _isTrua = widget.existingData?.ansang ?? false;
    _isToi = widget.existingData?.anchieu ?? false;

    _loadEmployeesInKhoa(); 
  }

  @override
  void dispose() {
    _manvCtrl.dispose();
    _tennvCtrl.dispose();
    _displayEmployeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeesInKhoa() async {
    try {
      final emps = await widget.nhanvienService.getNhanVienByKhoa(widget.currentUserMaKhoa);
      if (mounted) {
        setState(() {
          _khoaEmployees = emps;
          _isLoadingEmployees = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingEmployees = false);
    }
  }

  String _removeVietnameseTones(String str) {
    str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợợỡ]'), 'o');
    str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    str = str.replaceAll(RegExp(r'[đ]'), 'd');
    str = str.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
    str = str.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
    str = str.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
    str = str.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
    str = str.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
    str = str.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
    str = str.replaceAll(RegExp(r'[Đ]'), 'D');
    return str.toLowerCase();
  }

  bool _isButtonDisabled() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (target.isBefore(today)) return true;
    if (target.isAtSameMomentAs(today) && now.hour >= 8) return true;
    return false;
  }

  Future<void> _pickDate() async {
    if (_isButtonDisabled() && widget.existingData != null) return;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), 
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF1274BC))),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _soNgayDat = 1; 
        _formErrorMessage = null; 
      });
    }
  }

  Widget _buildEmployeeAvatar(NhanVien nv) {
    if (nv.anh != null && nv.anh!.isNotEmpty) {
      try {
        String cleanBase64 = nv.anh!.contains(',') ? nv.anh!.split(',').last : nv.anh!;
        Uint8List imageBytes = base64Decode(cleanBase64);
        return CircleAvatar(backgroundColor: Colors.white, backgroundImage: MemoryImage(imageBytes));
      } catch (e) {
        debugPrint('Lỗi giải mã ảnh mini: $e');
      }
    }
    return CircleAvatar(
      backgroundColor: const Color(0xFF1274BC).withValues(alpha:0.1),
      child: Text(nv.tennv != null && nv.tennv!.isNotEmpty ? nv.tennv![0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF1274BC), fontWeight: FontWeight.bold)),
    );
  }

  void _openEmployeePicker() {
    if (_isButtonDisabled()) return; 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = ''; 
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            List<NhanVien> filtered = _khoaEmployees;
            if (query.isNotEmpty) {
              String searchQ = _removeVietnameseTones(query);
              filtered = _khoaEmployees.where((nv) {
                String tenUnsigned = _removeVietnameseTones(nv.tennv ?? '');
                String maUnsigned = _removeVietnameseTones(nv.manv ?? '');
                return tenUnsigned.contains(searchQ) || maUnsigned.contains(searchQ);
              }).toList();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Chọn nhân viên (Khoa hiện tại)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      onChanged: (val) => setModalState(() => query = val),
                      decoration: InputDecoration(
                        hintText: 'Nhập mã hoặc tên...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isLoadingEmployees 
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? Center(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off_rounded, size: 50, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                const Text('Không tìm thấy nhân viên.', style: TextStyle(color: Colors.grey)),
                              ],
                            ))
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final nv = filtered[index];
                                return ListTile(
                                  leading: _buildEmployeeAvatar(nv),
                                  title: Text('${nv.tennv}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  subtitle: Text('Mã NV: ${nv.manv}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  onTap: () {
                                    setState(() {
                                      _manvCtrl.text = nv.manv ?? '';
                                      _tennvCtrl.text = nv.tennv ?? '';
                                      _displayEmployeeCtrl.text = '${nv.manv} - ${nv.tennv}';
                                      _formErrorMessage = null; 
                                    });
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  String _generateGhiChu(bool isUpdate) {
    String action = isUpdate ? "Update" : "Insert";
    String currentActionTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    String truaStr = _isTrua ? "Có" : "Không";
    String toiStr = _isToi ? "Có" : "Không";
    return "${widget.currentUserMaNV} - ${widget.currentUserTenNV} |$action| $currentActionTime | Trưa: $truaStr, Tối: $toiStr";
  }

  Widget _buildQuickDateBtn(String label, VoidCallback onTap, bool isSelected) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1274BC) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700, 
            fontWeight: FontWeight.bold,
            fontSize: 13
          )
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _formErrorMessage = null);
    if (_isButtonDisabled()) return; 
    if (!_formKey.currentState!.validate()) return;
    if (_manvCtrl.text.isEmpty) {
      setState(() => _formErrorMessage = 'Vui lòng chọn nhân viên cần báo cơm!');
      return;
    }
    if (!_isTrua && !_isToi) {
      setState(() => _formErrorMessage = 'Bạn chưa chọn suất ăn nào (Trưa / Tối)!');
      return;
    }

    setState(() => _isSaving = true);
    int successCount = 0;
    int dupCount = 0;
    bool isUpdate = widget.existingData != null;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      for (int i = 0; i < _soNgayDat; i++) {
        DateTime currentDate = _selectedDate.add(Duration(days: i));
        
        bool isDuplicate = widget.allMeals.any((meal) {
          if (isUpdate && meal.id == widget.existingData!.id) return false;
          if (meal.manv == _manvCtrl.text.trim() && meal.ngaybaocom != null) {
            DateTime mealDate = DateTime.tryParse(meal.ngaybaocom!) ?? DateTime.now();
            return (mealDate.year == currentDate.year && mealDate.month == currentDate.month && mealDate.day == currentDate.day);
          }
          return false;
        });

        if (isDuplicate && !isUpdate) {
          dupCount++;
          continue; 
        }

        DateTime cleanDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
        String dateISO = cleanDate.toIso8601String(); 
        String generatedGhiChu = _generateGhiChu(isUpdate);

        BaoCom submitData = BaoCom(
          id: widget.existingData?.id,
          manv: _manvCtrl.text.trim(),
          tennv: _tennvCtrl.text.trim(),
          makhoa: widget.currentUserMaKhoa, 
          nguoibao: widget.currentUserMaNV,
          ngaybaocom: dateISO,
          ansang: _isTrua,
          anchieu: _isToi,
          ghichu: generatedGhiChu,
        );

        bool success = isUpdate 
          ? await widget.apiService.updateBaoCom(submitData)
          : await widget.apiService.createBaoCom(submitData);

        if (success) successCount++;
      }

      if (successCount > 0) {
        widget.onSuccess(); 
        
        String msg = isUpdate ? 'Cập nhật thành công!' : 'Đã báo cơm thành công $successCount ngày!';
        if (dupCount > 0) msg += ' (Bỏ qua $dupCount ngày bị trùng)';
        
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)), 
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        setState(() => _formErrorMessage = dupCount > 0 
          ? 'Các ngày bạn chọn ĐỀU ĐÃ ĐƯỢC báo cơm rồi!' 
          : 'Lưu thất bại, máy chủ từ chối yêu cầu.');
      }
    } catch (e) {
      setState(() => _formErrorMessage = 'Không thể kết nối máy chủ, vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isUpdate = widget.existingData != null;
    bool isDisabled = _isButtonDisabled(); 
    
    String dateDisplayText = DateFormat('dd/MM/yyyy').format(_selectedDate);
    if (_soNgayDat > 1) {
      DateTime endDate = _selectedDate.add(Duration(days: _soNgayDat - 1));
      dateDisplayText += '  Đến  ${DateFormat('dd/MM/yyyy').format(endDate)}';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
        left: 20, right: 20, top: 12,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isUpdate ? "Cập nhật Phiếu" : "Thêm Phiếu Báo Cơm", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 20, color: Colors.grey)
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            if (isDisabled)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, border: Border.all(color: Colors.orange.shade200), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(child: Text("Đã qua 8h00 sáng hoặc ngày trong quá khứ. Không thể thao tác.", style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            
            if (!isDisabled) const SizedBox(height: 16),
            
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDisabled ? Colors.grey.shade100 : Colors.white,
                  border: Border.all(color: Colors.grey.shade300), 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ngày báo cơm", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(dateDisplayText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDisabled ? Colors.grey : const Color(0xFF1274BC))),
                      ],
                    ),
                    Icon(Icons.calendar_month_rounded, color: isDisabled ? Colors.grey : const Color(0xFF1274BC), size: 28),
                  ],
                ),
              ),
            ),
            
            if (!isUpdate && !isDisabled) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickDateBtn("Hôm nay", () {
                      setState(() {
                        _selectedDate = DateTime.now();
                        _soNgayDat = 1;
                      });
                    }, _soNgayDat == 1 && _selectedDate.day == DateTime.now().day),
                    const SizedBox(width: 8),
                    _buildQuickDateBtn("Ngày mai", () {
                      setState(() {
                        _selectedDate = DateTime.now().add(const Duration(days: 1));
                        _soNgayDat = 1;
                      });
                    }, _soNgayDat == 1 && _selectedDate.day == DateTime.now().add(const Duration(days: 1)).day),
                    const SizedBox(width: 8),
                    _buildQuickDateBtn("3 ngày", () {
                      setState(() {
                        _selectedDate = DateTime.now().add(const Duration(days: 1)); 
                        _soNgayDat = 3;
                      });
                    }, _soNgayDat == 3),
                    const SizedBox(width: 8),
                    _buildQuickDateBtn("7 ngày", () {
                      setState(() {
                        _selectedDate = DateTime.now().add(const Duration(days: 1)); 
                        _soNgayDat = 7;
                      });
                    }, _soNgayDat == 7),
                  ],
                ),
              )
            ],
            
            const SizedBox(height: 16),
            TextFormField(
              controller: _displayEmployeeCtrl,
              readOnly: true, 
              onTap: _openEmployeePicker, 
              style: TextStyle(fontWeight: FontWeight.bold, color: isDisabled ? Colors.grey : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Người ăn (Chọn từ danh sách)',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                filled: isDisabled,
                fillColor: Colors.grey.shade100,
                prefixIcon: Icon(Icons.person_pin_rounded, color: isDisabled ? Colors.grey : const Color(0xFF1274BC)),
                suffixIcon: Icon(Icons.arrow_drop_down_circle_rounded, color: isDisabled ? Colors.grey : Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 16),
            
            const Text("Chọn suất ăn:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50), fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isDisabled ? null : () => setState(() { _isTrua = !_isTrua; _formErrorMessage = null; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isTrua ? Colors.orange.shade50 : (isDisabled ? Colors.grey.shade100 : Colors.white),
                        border: Border.all(color: _isTrua ? Colors.orange : Colors.grey.shade300, width: _isTrua ? 2 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wb_sunny_rounded, size: 20, color: _isTrua ? Colors.orange : Colors.grey),
                          const SizedBox(width: 8),
                          Text("Ăn Trưa", style: TextStyle(color: _isTrua ? Colors.orange.shade800 : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: isDisabled ? null : () => setState(() { _isToi = !_isToi; _formErrorMessage = null; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isToi ? Colors.indigo.shade50 : (isDisabled ? Colors.grey.shade100 : Colors.white),
                        border: Border.all(color: _isToi ? Colors.indigo : Colors.grey.shade300, width: _isToi ? 2 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.nights_stay_rounded, size: 20, color: _isToi ? Colors.indigo : Colors.grey),
                          const SizedBox(width: 8),
                          Text("Ăn Tối", style: TextStyle(color: _isToi ? Colors.indigo.shade800 : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_formErrorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_formErrorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDisabled ? Colors.grey.shade400 : const Color(0xFF1274BC),
                  elevation: isDisabled ? 0 : 4,
                  shadowColor: const Color(0xFF1274BC).withValues(alpha:0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: (_isSaving || isDisabled) ? null : _submit,
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isUpdate ? Icons.save_rounded : Icons.check_circle_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(isUpdate ? 'CẬP NHẬT PHIẾU' : 'XÁC NHẬN TẠO PHIẾU', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class BaoComScreen extends StatefulWidget {
  const BaoComScreen({super.key});

  @override
  State<BaoComScreen> createState() => _BaoComScreenState();
}

class _BaoComScreenState extends State<BaoComScreen> {
  final BaoComService _apiService = BaoComService();
  final KhoaService _khoaService = KhoaService();        
  final NhanvienService _nhanVienService = NhanvienService();
  final Color primaryColor = const Color(0xFF1274BC);
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  List<BaoCom> _allMeals = []; 
  Map<DateTime, List<BaoCom>> _groupedBaoCom = {}; 
  
  static String? _cachedTenKhoa; 
  String _tenKhoaHienTai = ''; 
  static List<BaoComMenu>? _cachedMenuList;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData(); 
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    
    try {
      final auth = context.read<AuthProvider>();
      final String currentMaNV = auth.currentManv ?? '';
      final String currentMaKhoa = auth.currentMaKhoa ?? '';

      List<BaoCom> list;

      if (_cachedTenKhoa == null) {
        final results = await Future.wait([
          _apiService.getBaoCom(nguoibao: currentMaNV, pageSize: 200),
          _khoaService.getTenKhoa(currentMaKhoa), 
        ]);
        list = results[0] as List<BaoCom>;
        _cachedTenKhoa = results[1] as String;
      } else {
        list = await _apiService.getBaoCom(nguoibao: currentMaNV, pageSize: 200);
      }

      _tenKhoaHienTai = _cachedTenKhoa!;
      _allMeals = list;

      Map<DateTime, List<BaoCom>> newGrouped = {};
      for (var item in list) {
        if (item.ngaybaocom != null) {
          DateTime parsedDate = DateTime.tryParse(item.ngaybaocom!) ?? DateTime.now();
          DateTime dateOnly = _normalizeDate(parsedDate); 
          if (newGrouped[dateOnly] == null) newGrouped[dateOnly] = [];
          newGrouped[dateOnly]!.add(item);
        }
      }
      
      if (mounted) {
        setState(() {
          _groupedBaoCom = newGrouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', ''); 
        });
      }
    }
  }

  // --- HÀM GỌI API & HIỂN THỊ THỰC ĐƠN MỚI ---
  Future<void> _showMenuDialog(DateTime date) async {
    // 1. Chỉ gọi API nếu Cache trống (Lần bấm đầu tiên)
    if (_cachedMenuList == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      try {
        final dio = Dio();
        final response = await dio.get('${AppConstants.baseUrl}/BaoComMenu');
        if (!mounted) return;
        Navigator.pop(context); 

        if (response.statusCode == 200 && response.data['success'] == true) {
          List data = response.data['data'];
          // Lưu dữ liệu vào Cache
          _cachedMenuList = data.map((item) => BaoComMenu.fromJson(item)).toList();
        } else {
          _cachedMenuList = [];
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); 
        _showSnackBar("Không thể tải dữ liệu thực đơn, vui lòng thử lại sau.", isError: true);
        return;
      }
    }

    if (!mounted) return;
    BaoComMenu? menuToday;
    if (_cachedMenuList != null) {
      for (var menu in _cachedMenuList!) {
        DateTime menuDate = DateTime.parse(menu.ngay).toLocal();
        if (menuDate.year == date.year && menuDate.month == date.month && menuDate.day == date.day) {
          menuToday = menu;
          break;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildMenuSheet(menuToday, date),
    );
  }

  // --- GIAO DIỆN BOTTOM SHEET THỰC ĐƠN ĐẸP MẮT ---
  Widget _buildMenuSheet(BaoComMenu? menu, DateTime date) {
    String dateStr = DateFormat('dd/MM/yyyy').format(date);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu_rounded, color: primaryColor, size: 28),
                const SizedBox(width: 10),
                Text("Thực Đơn Ngày $dateStr", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
            const SizedBox(height: 24),
            
            if (menu == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.no_meals_rounded, size: 50, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text("Chưa cập nhật thực đơn cho ngày này.", style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
                  ],
                ),
              )
            else ...[
              _buildMenuSection("Bữa Trưa", Icons.wb_sunny_rounded, Colors.orange, menu.menuTrua ?? "Chưa có dữ liệu bữa trưa"),
              const SizedBox(height: 16),
              _buildMenuSection("Bữa Tối", Icons.nights_stay_rounded, Colors.indigo, menu.menuToi ?? "Chưa có dữ liệu bữa tối"),
            ],
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              )
            )
          ]
        ),
      )
    );
  }

  Widget _buildMenuSection(String title, IconData icon, Color color, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.05),
        border: Border.all(color: color.withValues(alpha:0.2)),
        borderRadius: BorderRadius.circular(16)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }

  List<BaoCom> _getMealsForDay(DateTime day) {
    return _groupedBaoCom[
            _normalizeDate(day)] ??
        [];
  }
  List<BaoCom> _getCalendarEventsForDay(
    DateTime day,
  ) {
    final List<BaoCom> meals =
        _groupedBaoCom[
                _normalizeDate(day)] ??
            [];

    return meals.where(
      (BaoCom item) {
        return item.ansang == true ||
            item.anchieu == true;
      },
    ).toList();
  }

  bool _checkTimeRule(DateTime targetDate, {bool showMessage = true}) {
    final now = DateTime.now();
    final today = _normalizeDate(now);
    final target = _normalizeDate(targetDate);

    if (target.isBefore(today)) {
      if (showMessage) _showSnackBar("Không thể can thiệp dữ liệu của ngày trong quá khứ!", isError: true);
      return false;
    }
    if (target.isAtSameMomentAs(today) && now.hour >= 8) {
      if (showMessage) _showSnackBar("Đã qua 8h00 sáng. Không thể thao tác phiếu hôm nay nữa!", isError: true);
      return false;
    }
    return true;
  }

  Future<void> _deleteBaoCom(BaoCom item) async {
    DateTime recordDate = DateTime.tryParse(item.ngaybaocom ?? '') ?? DateTime.now();
    if (!_checkTimeRule(recordDate)) return;

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa phiếu báo cơm này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      bool success = await _apiService.deleteBaoCom(item.id!);
      if (success) {
        _showSnackBar("Xóa thành công!");
        _fetchData(); 
      }
    } catch (e) {
      _showSnackBar("Lỗi khi xóa phiếu!", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  void _showFormDialog({BaoCom? existingData, DateTime? defaultDate}) {
    if (existingData != null) {
      DateTime recordDate = DateTime.tryParse(existingData.ngaybaocom ?? '') ?? DateTime.now();
      if (!_checkTimeRule(recordDate)) return;
    }

    final auth = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BaoComForm(
          existingData: existingData,
          initialDate: defaultDate ?? _selectedDay,
          currentUserMaNV: auth.currentManv ?? '',
          currentUserTenNV: auth.currentTenNV ?? '',
          currentUserMaKhoa: auth.currentMaKhoa ?? '',       
          currentUserTenKhoa: _tenKhoaHienTai,    
          allMeals: _allMeals,
          apiService: _apiService,
          nhanvienService: _nhanVienService,
          onSuccess: () {
            Navigator.pop(context);
            _fetchData(); 
          },
        );
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    final List<BaoCom> selectedDayMeals =
        _getMealsForDay(
      _selectedDay,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Quản lý Báo Cơm', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Xem thực đơn',
            icon: const Icon(Icons.restaurant_menu_rounded),
            onPressed: () => _showMenuDialog(_selectedDay),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(defaultDate: _selectedDay),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Báo cơm",
          style: TextStyle(
            color: Colors.white,         
            fontSize: 16,                
            fontWeight: FontWeight.bold, 
          ),
        ),
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  TextButton(onPressed: _fetchData, child: const Text("Thử lại"))
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  ),
                  child: TableCalendar<BaoCom>(
                    firstDay: DateTime(2023, 1, 1),
                    lastDay: DateTime(2030, 12, 31),

                    focusedDay: _focusedDay,

                    selectedDayPredicate:
                        (day) =>
                            isSameDay(
                              _selectedDay,
                              day,
                            ),

                    onDaySelected:
                        (
                      selectedDay,
                      focusedDay,
                    ) {
                      setState(() {
                        _selectedDay =
                            selectedDay;

                        _focusedDay =
                            focusedDay;
                      });
                    },

                    // Chỉ tạo marker khi thực sự
                    // có suất Trưa hoặc Tối.
                    eventLoader:
                        _getCalendarEventsForDay,

                    calendarFormat:
                        CalendarFormat.month,

                    availableCalendarFormats:
                        const {
                      CalendarFormat.month:
                          'Tháng',
                    },

                    headerStyle:
                        HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,

                      titleTextStyle:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(
                          0xFF2C3E50,
                        ),
                      ),

                      leftChevronIcon:
                          Icon(
                        Icons.chevron_left,
                        color:
                            primaryColor,
                      ),

                      rightChevronIcon:
                          Icon(
                        Icons.chevron_right,
                        color:
                            primaryColor,
                      ),
                    ),

                    calendarStyle:
                        CalendarStyle(
                      todayDecoration:
                          BoxDecoration(
                        color:
                            primaryColor.withValues(
                          alpha: 0.3,
                        ),
                        shape:
                            BoxShape.circle,
                      ),

                      selectedDecoration:
                          BoxDecoration(
                        color:
                            primaryColor,
                        shape:
                            BoxShape.circle,
                      ),

                      markerDecoration:
                          const BoxDecoration(
                        color:
                            Color.fromARGB(
                          255,
                          39,
                          209,
                          5,
                        ),
                        shape:
                            BoxShape.circle,
                      ),

                      markersMaxCount: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: selectedDayMeals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text("Không có phiếu báo cơm\nngày ${DateFormat('dd/MM/yyyy').format(_selectedDay)}", 
                              textAlign: TextAlign.center, 
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80), 
                        itemCount: selectedDayMeals.length,
                        itemBuilder: (context, index) {
                          return _buildBaoComCard(selectedDayMeals[index]);
                        },
                      ),
                ),
              ],
            ),
    );
  }

  Widget _buildBaoComCard(BaoCom item) {
    DateTime recordDate = DateTime.tryParse(item.ngaybaocom ?? '') ?? DateTime.now();
    bool canEdit = _checkTimeRule(recordDate, showMessage: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${item.manv} - ${item.tennv ?? 'Chưa có tên'}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                ),
                Row(
                  children: canEdit 
                  ? [
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.orange),
                        onPressed: () => _showFormDialog(existingData: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteBaoCom(item), 
                      ),
                    ]
                  : [
                      Tooltip(
                        message: "Phiếu đã khóa",
                        child: Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 22),
                      ),
                      const SizedBox(width: 16),
                    ],
                )
              ],
            ),
            const Divider(),
            _buildInfoRow(Icons.apartment, "Khoa:", _tenKhoaHienTai.isNotEmpty ? _tenKhoaHienTai : item.makhoa ?? 'N/A'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text("Suất ăn: ", style: TextStyle(color: Colors.grey)),
                if (item.ansang == true) _buildTag("Trưa", Colors.orange),
                if (item.ansang == true && item.anchieu == true) const SizedBox(width: 4),
                if (item.anchieu == true) _buildTag("Tối", Colors.indigo),
                if (item.ansang != true && item.anchieu != true) const Text("Không đặt", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.notes, "Ghi chú:", item.ghichu ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label ", style: const TextStyle(color: Colors.grey)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
    );
  }
}