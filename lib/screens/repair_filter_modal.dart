import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/khoa_model.dart'; 

class RepairFilterModal extends StatefulWidget {
  final DateTime? initFromDate;
  final DateTime? initToDate;
  final String? initKhoaLap;
  final String? initKhoaNhan;
  final List<Khoa> listKhoa;
  final Function(DateTime?, DateTime?, String?, String?) onApplyFilter;

  const RepairFilterModal({
    super.key,
    this.initFromDate,
    this.initToDate,
    this.initKhoaLap,
    this.initKhoaNhan,
    required this.listKhoa,
    required this.onApplyFilter,
  });

  @override
  State<RepairFilterModal> createState() => _RepairFilterModalState();
}

class _RepairFilterModalState extends State<RepairFilterModal> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _khoaLapSelected;
  String? _khoaNhanSelected;
  final Color primaryColor = const Color(0xFF1274BC);

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initFromDate;
    _toDate = widget.initToDate;
    _khoaLapSelected = widget.initKhoaLap;
    _khoaNhanSelected = widget.initKhoaNhan;
  }

  Future<void> _selectDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        isFromDate ? _fromDate = picked : _toDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lọc nâng cao', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildDatePickerUI(label: 'Từ ngày', date: _fromDate, onTap: () => _selectDate(true))),
                const SizedBox(width: 16),
                Expanded(child: _buildDatePickerUI(label: 'Đến ngày', date: _toDate, onTap: () => _selectDate(false))),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Khoa/Phòng báo hỏng', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: widget.listKhoa.any((k) => k.makhoa == _khoaLapSelected) ? _khoaLapSelected : null,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              hint: const Text("Tất cả khoa phòng"),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả')),
                ...widget.listKhoa.map((khoa) {
                  return DropdownMenuItem<String>(
                    value: khoa.makhoa,
                    child: Text(khoa.tenkhoa ?? khoa.makhoa ?? '', overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (val) => setState(() => _khoaLapSelected = val),
            ),
            const SizedBox(height: 20),
            const Text('Bộ phận tiếp nhận', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _khoaNhanSelected,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tất cả')),
                DropdownMenuItem(value: 'CNTT', child: Text('Phòng Công nghệ thông tin')),
                DropdownMenuItem(value: 'CN', child: Text('Phòng Kỹ thuật - Hạ tầng')),
              ],
              onChanged: (val) => setState(() => _khoaNhanSelected = val),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      setState(() { _fromDate = null; _toDate = null; _khoaNhanSelected = null; _khoaLapSelected = null; });
                    },
                    child: const Text('Xóa lọc', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      widget.onApplyFilter(_fromDate, _toDate, _khoaLapSelected, _khoaNhanSelected);
                      Navigator.pop(context);
                    },
                    child: const Text('ÁP DỤNG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerUI({required String label, required DateTime? date, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Chọn ngày', style: TextStyle(color: date != null ? Colors.black87 : Colors.grey.shade500, fontSize: 14)),
                const Icon(Icons.calendar_month_rounded, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}