import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobileapp_bvhv/services/nhanvien_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/baocom_model.dart';
import '../models/nhanvien_model.dart';
import '../services/baocom_service.dart';

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
  int _soNgayDat = 1; // BIẾN MỚI: Số lượng ngày muốn đặt liên tiếp

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
      _soNgayDat = 1; // Mặc định tạo 1 ngày
    } else {
      _manvCtrl.text = widget.existingData?.manv ?? '';
      _tennvCtrl.text = widget.existingData?.tennv ?? '';
      _soNgayDat = 1; // Đang sửa thì chỉ sửa 1 ngày
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
    str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
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
        _soNgayDat = 1; // Chọn ngày mới thì reset về 1 ngày
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
      backgroundColor: const Color(0xFF1274BC).withOpacity(0.1),
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

  // --- HÀM TẠO NÚT BẤM CHỌN NHANH NGÀY ---
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

  // --- LOGIC LƯU HÀNG LOẠT (BATCH INSERT) ---
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

    // Lưu lại bộ Messenger trước khi gọi onSuccess (vì onSuccess sẽ đóng Form)
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Chạy vòng lặp tạo phiếu cho N ngày
      for (int i = 0; i < _soNgayDat; i++) {
        DateTime currentDate = _selectedDate.add(Duration(days: i));
        
        // 1. Kiểm tra trùng lặp cho từng ngày
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
          continue; // Bỏ qua ngày này, chạy tiếp ngày hôm sau
        }

        // 2. Định dạng ngày để gửi API
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
          mamaubaocom: 0,
        );
        
        bool success = isUpdate 
          ? await widget.apiService.updateBaoCom(submitData)
          : await widget.apiService.createBaoCom(submitData);

        if (success) successCount++;
      }

      if (successCount > 0) {
        widget.onSuccess(); // Đóng Form và Refresh màn hình
        
        // Hiện thông báo Thành công MÀU XANH cực rõ ràng
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
    
    // Tạo chuỗi hiển thị khoảng thời gian nếu đặt > 1 ngày
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
                    Expanded(child: Text("Đã quá 8h00 sáng hoặc ngày trong quá khứ. Không thể thao tác.", style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            
            if (!isDisabled) const SizedBox(height: 16),
            
            // --- GIAO DIỆN CHỌN NGÀY ---
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
            
            // --- NÚT BẤM CHỌN NHANH (Chỉ hiện khi Thêm mới) ---
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
                        _selectedDate = DateTime.now().add(const Duration(days: 1)); // Bắt đầu từ ngày mai
                        _soNgayDat = 3;
                      });
                    }, _soNgayDat == 3),
                    const SizedBox(width: 8),
                    _buildQuickDateBtn("7 ngày", () {
                      setState(() {
                        _selectedDate = DateTime.now().add(const Duration(days: 1)); // Bắt đầu từ ngày mai
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
                  shadowColor: const Color(0xFF1274BC).withOpacity(0.4),
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