import 'package:flutter/material.dart';
import '../models/diennuoc_model.dart';
import '../services/diennuoc_service.dart';

class DienNuocFormScreen extends StatefulWidget {
  final DienNuoc? dienNuoc;
  final int? prefillIdHoGiaDinh;
  final String? prefillSearchText; 

  const DienNuocFormScreen({super.key, this.dienNuoc, this.prefillIdHoGiaDinh, this.prefillSearchText});

  @override
  State<DienNuocFormScreen> createState() => _DienNuocFormScreenState();
}

class _DienNuocFormScreenState extends State<DienNuocFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DienNuocService _service = DienNuocService();

  late TextEditingController _dienCuCtrl;
  late TextEditingController _dienMoiCtrl;
  late TextEditingController _nuocCuCtrl;
  late TextEditingController _nuocMoiCtrl;

  int? _selectedHoGiaDinh;
  late int _selectedThang;
  late int _selectedNam;
  
  bool _isLoading = false;
  bool _isFetchingLatest = false;
  List<Map<String, dynamic>> _danhMucHoGiaDinh = [];

  @override
  void initState() {
    super.initState();
    _dienCuCtrl = TextEditingController(text: widget.dienNuoc?.csdienCu?.toString() ?? '');
    _dienMoiCtrl = TextEditingController(text: widget.dienNuoc?.csdienMoi?.toString() ?? '');
    _nuocCuCtrl = TextEditingController(text: widget.dienNuoc?.csnuocCu?.toString() ?? '');
    _nuocMoiCtrl = TextEditingController(text: widget.dienNuoc?.csnuocMoi?.toString() ?? '');

    DateTime now = DateTime.now();
    int defaultThang = now.month == 1 ? 12 : now.month - 1;
    int defaultNam = now.month == 1 ? now.year - 1 : now.year;

    _selectedHoGiaDinh = widget.dienNuoc?.idHoGiaDinh ?? widget.prefillIdHoGiaDinh;
    _selectedThang = widget.dienNuoc?.thang ?? defaultThang;
    _selectedNam = widget.dienNuoc?.nam ?? defaultNam;

    _loadDanhMuc().then((_) {
      if (widget.prefillIdHoGiaDinh != null && widget.dienNuoc == null) {
        _fetchLatestData(widget.prefillIdHoGiaDinh!);
      }
    });
  }

  Future<void> _loadDanhMuc() async {
    final list = await _service.getDanhMucHoGiaDinh();
    if (mounted) setState(() => _danhMucHoGiaDinh = list);
  }

  @override
  void dispose() {
    _dienCuCtrl.dispose(); _dienMoiCtrl.dispose();
    _nuocCuCtrl.dispose(); _nuocMoiCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLatestData(int id) async {
    if (widget.dienNuoc != null) return; 
    setState(() => _isFetchingLatest = true);
    final data = await _service.getLatestChiSo(id);
    if (mounted) {
      setState(() {
        _dienCuCtrl.text = data['dien'] == 0 ? '' : data['dien'].toString();
        _nuocCuCtrl.text = data['nuoc'] == 0 ? '' : data['nuoc'].toString();
        _isFetchingLatest = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHoGiaDinh == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng tìm và chọn Hộ gia đình hợp lệ'), backgroundColor: Colors.orange));
      return;
    }

    // 🟢 KIỂM TRA RÀNG BUỘC PHẢI NHẬP ÍT NHẤT ĐIỆN HOẶC NƯỚC
    bool hasDien = _dienCuCtrl.text.isNotEmpty || _dienMoiCtrl.text.isNotEmpty;
    bool hasNuoc = _nuocCuCtrl.text.isNotEmpty || _nuocMoiCtrl.text.isNotEmpty;

    if (!hasDien && !hasNuoc) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập chỉ số Điện hoặc Nước!'), backgroundColor: Colors.orange));
      return;
    }

    // Nếu nhập số mới thì phải có số cũ tương ứng
    if (_dienMoiCtrl.text.isNotEmpty && _dienCuCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền Chỉ số Điện cũ'), backgroundColor: Colors.orange));
      return;
    }
    if (_nuocMoiCtrl.text.isNotEmpty && _nuocCuCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền Chỉ số Nước cũ'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    final dto = DienNuoc(
      id: widget.dienNuoc?.id,
      idHoGiaDinh: _selectedHoGiaDinh,
      thang: _selectedThang,
      nam: _selectedNam,
      // Chấp nhận gửi null lên server nếu để trống trường đó
      csdienCu: _dienCuCtrl.text.isEmpty ? null : int.tryParse(_dienCuCtrl.text),
      csdienMoi: _dienMoiCtrl.text.isEmpty ? null : int.tryParse(_dienMoiCtrl.text),
      csnuocCu: _nuocCuCtrl.text.isEmpty ? null : int.tryParse(_nuocCuCtrl.text),
      csnuocMoi: _nuocMoiCtrl.text.isEmpty ? null : int.tryParse(_nuocMoiCtrl.text),
    );

    bool isSuccess;
    if (widget.dienNuoc == null) {
      String? err = await _service.createDienNuoc(dto);
      isSuccess = (err == null);
      if (!isSuccess && mounted) {
        showDialog(context: context, builder: (c) => AlertDialog(title: const Text('Lỗi', style: TextStyle(color: Colors.red)), content: Text(err!), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('ĐÓNG'))]));
      }
    } else {
      isSuccess = await _service.updateDienNuoc(widget.dienNuoc!.id!, dto);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thành công!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.dienNuoc != null;
    final isPrefilled = widget.prefillIdHoGiaDinh != null; 
    
    String initialSearchText = '';
    if (isEditMode) {
      initialSearchText = 'Phòng ${widget.dienNuoc!.soPhong} - ${widget.dienNuoc!.hoGiaDinh}';
    } else if (widget.prefillSearchText != null) {
      initialSearchText = widget.prefillSearchText!;
    }

    return GestureDetector( 
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditMode ? 'Cập nhật Điện Nước' : 'Thêm mới Điện Nước', style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1274BC),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Tìm Hộ gia đình (Gõ để tìm kiếm)'),
                    Autocomplete<Map<String, dynamic>>(
                      initialValue: TextEditingValue(text: initialSearchText),
                      displayStringForOption: (option) => option['name'],
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) return _danhMucHoGiaDinh;
                        return _danhMucHoGiaDinh.where((opt) => opt['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (selection) {
                        setState(() => _selectedHoGiaDinh = selection['id']);
                        _fetchLatestData(selection['id']);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        bool isLocked = isEditMode || isPrefilled; 
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          readOnly: isLocked,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            hintText: 'Nhập số phòng hoặc tên...',
                            suffixIcon: const Icon(Icons.search),
                            filled: isLocked,
                            fillColor: isLocked ? Colors.grey.shade200 : Colors.white,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Bắt buộc';
                            if (_selectedHoGiaDinh == null) return 'Vui lòng chọn từ danh sách gợi ý';
                            return null;
                          }
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Tháng'),
                              DropdownButtonFormField<int>(
                                value: _selectedThang,
                                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
                                items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('Tháng ${i + 1}'))),
                                onChanged: (val) => setState(() => _selectedThang = val!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Năm'),
                              DropdownButtonFormField<int>(
                                value: _selectedNam,
                                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 16)),
                                items: [DateTime.now().year - 2, DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1]
                                    .map((y) => DropdownMenuItem(value: y, child: Text('Năm $y'))).toList(),
                                onChanged: (val) => setState(() => _selectedNam = val!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 🟢 GROUP ĐIỆN (Shadow 1)
                    _buildShadowContainer(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('⚡ CHỈ SỐ ĐIỆN', Colors.orange),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Điện cũ', _dienCuCtrl, isFetching: _isFetchingLatest)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField('Điện mới', _dienMoiCtrl)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🟢 GROUP NƯỚC (Shadow 2)
                    _buildShadowContainer(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('💧 CHỈ SỐ NƯỚC', Colors.blue),
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Nước cũ', _nuocCuCtrl, isFetching: _isFetchingLatest)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField('Nước mới', _nuocMoiCtrl)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1274BC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        onPressed: _submit,
                        child: const Text('LƯU DỮ LIỆU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)));

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isFetching = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: isFetching ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null,
          ),
          // 🟢 ĐÃ FIX: Cho phép bỏ trống để nhận giá trị NULL
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            if (int.tryParse(v) == null) return 'Phải là số';
            return null;
          },
        ),
      ],
    );
  }
  Widget _buildShadowContainer(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}