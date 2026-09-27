import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/thuc_hanh_models.dart';
import '../../services/api_client.dart';
import '../../services/thuc_hanh_service.dart';

class ThucHanhLookupScreen extends StatefulWidget {
  final String lookupCode;

  const ThucHanhLookupScreen({super.key, required this.lookupCode});

  @override
  State<ThucHanhLookupScreen> createState() => _ThucHanhLookupScreenState();
}

class _ThucHanhLookupScreenState extends State<ThucHanhLookupScreen> {
  late final ThucHanhService _service;
  TraCuuThucHanhModel? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ThucHanhService(ApiClient().dio);
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await _service.lookupRegistration(widget.lookupCode);
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F7FA),
    appBar: AppBar(
      foregroundColor: Colors.white,
      title: const Text(
        'Tra cứu thực hành',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF075E91), Color(0xFF0796C5)],
          ),
        ),
      ),
    ),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7F4F9), Color(0xFFF7FAFC)],
        ),
      ),
      child: _error != null
          ? _errorView()
          : _data == null
          ? const Center(child: CircularProgressIndicator())
          : _content(_data!),
    ),
  );

  Widget _errorView() => Center(
    child: Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(26),
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE9EF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 54, color: Color(0xFFC64B43)),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );

  Widget _content(TraCuuThucHanhModel data) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF075E91), Color(0xFF19A2C9)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33075E91),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.hoVaTen,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.tenDot,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                _status(data.tinhTrangThucHanh),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _section(
            'Thông tin hồ sơ',
            Icons.badge_outlined,
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _info('Ngày đăng ký', _dateTime(data.ngayDangKy)),
                _info('Ngày sinh', _date(data.ngaySinh)),
                _info(
                  'Giới tính',
                  data.gioiTinh == null
                      ? 'Chưa cập nhật'
                      : (data.gioiTinh! ? 'Nam' : 'Nữ'),
                ),
                _info('CCCD', data.soCCCD),
                _info('Điện thoại', data.soDienThoai),
                _info('Email', data.email),
                _info('Trường/đơn vị', data.truongDonVi),
                _info('Chuyên ngành', data.chuyenNganh),
                _info('Trình độ', data.trinhDoChuyenMon),
              ],
            ),
          ),
          const SizedBox(height: 15),
          _section(
            'Lịch thực hành',
            Icons.calendar_month_outlined,
            data.phanCongs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text('Hồ sơ chưa được phân công thực hành.'),
                    ),
                  )
                : Column(
                    children: data.phanCongs
                        .map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFDCE9EF),
                              ),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFE0F2F8),
                                  child: Icon(
                                    Icons.local_hospital_outlined,
                                    color: Color(0xFF087DBA),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.tenKhoaPhong ?? 'Khoa/phòng',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        'Người hướng dẫn: ${item.hoVaTenNguoiHuongDan ?? item.maSoNguoiHuongDan}',
                                      ),
                                      Text(
                                        '${_date(item.ngayBatDau)} - ${_date(item.ngayKetThuc)}',
                                        style: const TextStyle(
                                          color: Color(0xFF587180),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mã tra cứu: ${data.maTraCuu}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6F8794)),
          ),
        ],
      ),
    ),
  );

  Widget _section(String title, IconData icon, Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDCE9EF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF087DBA)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const Divider(height: 26),
        child,
      ],
    ),
  );

  Widget _info(String label, String? value) => Container(
    width: 270,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF7FAFC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6C8492)),
        ),
        const SizedBox(height: 3),
        Text(
          value == null || value.isEmpty ? 'Chưa cập nhật' : value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _status(int value) {
    const names = [
      'Chưa phân công',
      'Sắp thực hành',
      'Đang thực hành',
      'Đã kết thúc',
    ];
    final index = value.clamp(0, 3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        names[index],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _date(DateTime? value) =>
      value == null ? 'Chưa cập nhật' : DateFormat('dd/MM/yyyy').format(value);

  String _dateTime(DateTime value) =>
      DateFormat('dd/MM/yyyy HH:mm').format(value);
}
