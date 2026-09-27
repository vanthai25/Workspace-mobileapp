import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nuocthai_model.dart';
import '../services/nuocthai_service.dart';

class NuocThaiFormScreen extends StatefulWidget {
  final NuocThai? nuocThai;

  const NuocThaiFormScreen({super.key, this.nuocThai});

  @override
  State<NuocThaiFormScreen> createState() => _NuocThaiFormScreenState();
}

class _NuocThaiFormScreenState extends State<NuocThaiFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final NuocThaiService _service = NuocThaiService();
  
  late TextEditingController _chiSoCuCtrl;
  late TextEditingController _chiSoMoiCtrl;
  late TextEditingController _ghiChuCtrl;
  late TextEditingController _tongCtrl; 

  DateTime _selectedDate = DateTime.now();
  String? _selectedChiNhanh;
  bool _isBatThuong = false;
  bool _isLoading = false;
  bool _isFetchingLatest = false;

  final List<Map<String, String>> _chiNhanhDuocPhep = [
    {'id': 'BVHUNGVUONG', 'name': 'BV Hùng Vương'},
    {'id': 'KIMXUYEN', 'name': 'Kim Xuyên'},
    {'id': 'CHANMONG', 'name': 'Chân Mộng'},
    {'id': 'SONDUONG', 'name': 'Sơn Dương'},
    {'id': 'THANHBA', 'name': 'Thanh Ba'},
  ];

  @override
  void initState() {
    super.initState();
    _chiSoCuCtrl = TextEditingController(text: widget.nuocThai?.chiSoCu?.toString() ?? '');
    _chiSoMoiCtrl = TextEditingController(text: widget.nuocThai?.chiSoMoi?.toString() ?? '');
    _ghiChuCtrl = TextEditingController(text: widget.nuocThai?.ghiChu ?? 'Hệ thống hoạt động bình thường');
    _tongCtrl = TextEditingController(text: widget.nuocThai?.tong?.toString() ?? '0');

    if (widget.nuocThai != null) {
      _selectedDate = widget.nuocThai!.ngay ?? DateTime.now();
      _selectedChiNhanh = widget.nuocThai!.chiNhanh;
      _isBatThuong = widget.nuocThai!.batThuong ?? false;
    }

    _chiSoCuCtrl.addListener(_tinhTong);
    _chiSoMoiCtrl.addListener(_tinhTong);
  }

  @override
  void dispose() {
    _chiSoCuCtrl.dispose();
    _chiSoMoiCtrl.dispose();
    _ghiChuCtrl.dispose();
    _tongCtrl.dispose();
    super.dispose();
  }

  void _tinhTong() {
    double cu = double.tryParse(_chiSoCuCtrl.text) ?? 0;
    double moi = double.tryParse(_chiSoMoiCtrl.text) ?? 0;
    
    // Đã bỏ điều kiện check. Cứ nhập là trừ thẳng, chấp nhận cả số âm (khi reset đồng hồ)
    _tongCtrl.text = (moi - cu).toStringAsFixed(2);
  }

  Future<void> _layChiSoCuTuDong(String chiNhanh) async {
    if (widget.nuocThai != null) return; 
    
    setState(() => _isFetchingLatest = true);
    try {
      double latest = await _service.getLatestChiSo(chiNhanh);
      if (mounted) {
        setState(() {
          _chiSoCuCtrl.text = latest.toStringAsFixed(2);
          _isFetchingLatest = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingLatest = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF1274BC))),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChiNhanh == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn chi nhánh'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    final dataToSubmit = NuocThai(
      id: widget.nuocThai?.id,
      ngay: _selectedDate,
      chiSoCu: double.tryParse(_chiSoCuCtrl.text),
      chiSoMoi: double.tryParse(_chiSoMoiCtrl.text),
      chiNhanh: _selectedChiNhanh,
      ghiChu: _ghiChuCtrl.text,
      batThuong: _isBatThuong,
    );

    if (widget.nuocThai == null) {
      String? errorMsg = await _service.createNuocThaiWithMsg(dataToSubmit);
      setState(() => _isLoading = false);
      
      if (errorMsg == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thành công!'), backgroundColor: Colors.green));
          Navigator.pop(context, true); 
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Không thể thêm mới', style: TextStyle(color: Colors.red)),
              content: Text(errorMsg),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ĐÓNG')),
              ],
            )
          );
        }
      }
    } else {
      bool isSuccess = await _service.updateNuocThai(widget.nuocThai!.id!, dataToSubmit);
      setState(() => _isLoading = false);

      if (isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); 
      } else if (!isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại!'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.nuocThai != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Cập nhật Nước thải' : 'Thêm mới Nước thải', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1274BC),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1274BC)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Ngày chốt chỉ số'),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16)),
                            const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Chi nhánh'),
                    DropdownButtonFormField<String>(
                      value: _selectedChiNhanh,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      hint: const Text('Chọn chi nhánh'),
                      items: _chiNhanhDuocPhep.map((cn) => DropdownMenuItem(value: cn['id'], child: Text(cn['name']!))).toList(),
                      onChanged: isEditMode 
                        ? null 
                        : (val) {
                            setState(() => _selectedChiNhanh = val);
                            if (val != null) _layChiSoCuTuDong(val);
                          }, 
                      validator: (val) => val == null ? 'Vui lòng chọn chi nhánh' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Chỉ số cũ'),
                              TextFormField(
                                controller: _chiSoCuCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  suffixIcon: _isFetchingLatest 
                                      ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)) 
                                      : null,
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Chỉ số mới'),
                              TextFormField(
                                controller: _chiSoMoiCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                // Đã xóa validate bắt buộc số mới > số cũ
                                validator: (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null, 
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Lưu lượng sử dụng (Khối)'),
                    TextFormField(
                      controller: _tongCtrl,
                      readOnly: true,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1274BC), fontSize: 18),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Ghi chú'),
                    TextFormField(
                      controller: _ghiChuCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: _isBatThuong ? Colors.red.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _isBatThuong ? Colors.red.shade200 : Colors.grey.shade300)
                      ),
                      child: CheckboxListTile(
                        title: const Text('Đánh dấu chỉ số Bất thường', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Hệ thống sẽ gửi thông báo cảnh báo'),
                        activeColor: Colors.red,
                        value: _isBatThuong,
                        onChanged: (val) => setState(() => _isBatThuong = val ?? false),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1274BC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _submitForm,
                        child: const Text('LƯU DỮ LIỆU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }
}