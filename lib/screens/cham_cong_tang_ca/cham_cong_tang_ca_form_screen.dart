import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import thư viện để dùng thanh cuộn
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/cham_cong_tang_ca_model.dart';
import '../../providers/cham_cong_tang_ca_provider.dart';
import '../../utils/helpers.dart';

class ChamCongTangCaFormScreen extends StatefulWidget {
  final ChamCongTangCaModel? phieuToEdit;

  const ChamCongTangCaFormScreen({Key? key, this.phieuToEdit}) : super(key: key);

  @override
  State<ChamCongTangCaFormScreen> createState() => _ChamCongTangCaFormScreenState();
}

class _ChamCongTangCaFormScreenState extends State<ChamCongTangCaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lyDoController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  int _soPhut = 180;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.phieuToEdit != null) {
      final phieu = widget.phieuToEdit!;
      _selectedDate = phieu.batDau;
      _startTime = TimeOfDay(hour: phieu.batDau.hour, minute: phieu.batDau.minute);
      _endTime = TimeOfDay(hour: phieu.ketThuc.hour, minute: phieu.ketThuc.minute);
      _soPhut = phieu.soPhut;
      _lyDoController.text = phieu.lyDoTangCa;
    } else {
      _calculateMinutes();
    }
  }

  void _calculateMinutes() {
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);
    
    setState(() {
      _soPhut = end.difference(start).inMinutes;
    });
  }

  // HÀM CHỌN NGÀY VỚI THANH CUỘN (CUPERTINO)
  Future<void> _selectDateCupertino(BuildContext context) async {
    DateTime tempDate = _selectedDate;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300, // Chiều cao của bảng chọn
          child: Column(
            children: [
              // Thanh công cụ Hủy / Xong
              Container(
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: const Text('Hủy', style: TextStyle(color: Colors.red, fontSize: 16))
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedDate = tempDate);
                        _calculateMinutes();
                        Navigator.pop(context);
                      },
                      child: const Text('Xong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                    ),
                  ],
                ),
              ),
              // Vòng xoay chọn Ngày
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  minimumYear: 2020,
                  maximumYear: 2100,
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // HÀM CHỌN GIỜ VỚI THANH CUỘN (CUPERTINO)
  Future<void> _selectTimeCupertino(BuildContext context, bool isStart) async {
    TimeOfDay initialTime = isStart ? _startTime : _endTime;
    DateTime tempDateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day, 
      initialTime.hour, initialTime.minute
    );

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              // Thanh công cụ Hủy / Xong
              Container(
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: const Text('Hủy', style: TextStyle(color: Colors.red, fontSize: 16))
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (isStart) {
                            _startTime = TimeOfDay(hour: tempDateTime.hour, minute: tempDateTime.minute);
                          } else {
                            _endTime = TimeOfDay(hour: tempDateTime.hour, minute: tempDateTime.minute);
                          }
                        });
                        _calculateMinutes();
                        Navigator.pop(context);
                      },
                      child: const Text('Xong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                    ),
                  ],
                ),
              ),
              // Vòng xoay chọn Giờ (Tiếng Việt dùng 24h là chuẩn nhất)
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true, 
                  initialDateTime: tempDateTime,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDateTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_soPhut <= 0) {
      AppHelpers.showSnackBar("Giờ kết thúc phải lớn hơn giờ bắt đầu!", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);
    
    final provider = Provider.of<ChamCongTangCaProvider>(context, listen: false);
    bool success;

    if (widget.phieuToEdit == null) {
      success = await provider.createPhieu(start, end, _soPhut, _lyDoController.text.trim());
    } else {
      success = await provider.updatePhieu(widget.phieuToEdit!.id, start, end, _soPhut, _lyDoController.text.trim());
    }

    setState(() => _isSubmitting = false);

    if (success) {
      AppHelpers.showSnackBar(widget.phieuToEdit == null ? "Thêm mới thành công" : "Cập nhật thành công");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.phieuToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa Phiếu Tăng Ca' : 'Thêm Phiếu Tăng Ca'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nút Chọn Ngày (Gọi hàm Cupertino mới)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Ngày tăng ca", style: TextStyle(color: Colors.grey)),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDateCupertino(context),
              ),
              const Divider(),
              
              // Nút Chọn Giờ Bắt Đầu - Kết Thúc (Gọi hàm Cupertino mới)
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Bắt đầu", style: TextStyle(color: Colors.grey)),
                      subtitle: Text('${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 16)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTimeCupertino(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Kết thúc", style: TextStyle(color: Colors.grey)),
                      subtitle: Text('${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 16)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTimeCupertino(context, false),
                    ),
                  ),
                ],
              ),
              const Divider(),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Tổng thời gian: $_soPhut phút (${(_soPhut/60).toStringAsFixed(1)} giờ)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _soPhut > 0 ? Colors.green : Colors.red),
                ),
              ),

              TextFormField(
                controller: _lyDoController,
                decoration: const InputDecoration(
                  labelText: 'Lý do tăng ca',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập lý do' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(isEdit ? 'Cập Nhật' : 'Lưu Phiếu', style: const TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}