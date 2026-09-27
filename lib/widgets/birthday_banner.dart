import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/nhanvien_model.dart';
import '../services/nhanvien_service.dart';
import 'employee_card.dart';

class BirthdayBanner extends StatefulWidget {
  const BirthdayBanner({super.key});

  @override
  State<BirthdayBanner> createState() => _BirthdayBannerState();
}

class _BirthdayBannerState extends State<BirthdayBanner> {
  final NhanvienService _apiService = NhanvienService();
  List<NhanVien> _birthdays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBirthdays();
  }

  Future<void> _fetchBirthdays() async {
    final results = await _apiService.getBirthdaysToday();
    if (mounted) {
      setState(() {
        _birthdays = results;
        _isLoading = false;
      });
    }
  }

  void _showBirthdayList() {
    if (kIsWeb) {
      _showWebBirthdayDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F7F9), // Màu nền ngoài của Bottom Sheet
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                // Thêm padding 2 bên để chữ không bị sát lề màn hình
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: const BoxDecoration(
                  color: Color(
                    0xFFF4F7F9,
                  ), // 🔥 ĐÃ SỬA: Cùng màu nền với nền ngoài
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Hãy gửi những lời chúc mừng tốt đẹp tới quý đồng nghiệp của bạn nhé 🎂",
                      textAlign: TextAlign.center, // Căn giữa vì câu khá dài
                      style: TextStyle(
                        fontSize: 15, // Giảm nhẹ font để vừa vặn
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1274BC),
                        height:
                            1.3, // Giãn dòng nhẹ cho dễ đọc nếu rớt xuống 2 dòng
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 40),
                  itemCount: _birthdays.length,
                  itemBuilder: (context, index) {
                    final nv = _birthdays[index];
                    return EmployeeCard(
                      employee: nv,
                      tenKhoa: nv.tenkhoa ?? nv.makhoa ?? 'Chưa rõ khoa',
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showWebBirthdayDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final double dialogHeight =
            MediaQuery.sizeOf(dialogContext).height * 0.76;

        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: SizedBox(
            width: 720,
            height: dialogHeight,
            child: Material(
              color: const Color(0xFFF7F8FC),
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7455C5), Color(0xFF9A65C8)],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.cake_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sinh nhật hôm nay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_birthdays.length} đồng nghiệp đang đón tuổi mới',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Đóng',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                      itemCount: _birthdays.length,
                      itemBuilder: (context, index) {
                        final NhanVien employee = _birthdays[index];
                        return EmployeeCard(
                          employee: employee,
                          tenKhoa:
                              employee.tenkhoa ??
                              employee.makhoa ??
                              'Chưa rõ khoa',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebBanner() {
    final List<String> names = _birthdays
        .map((employee) => employee.tennv?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .take(3)
        .toList();
    final int remaining = _birthdays.length - names.length;
    final String peopleLabel = names.isEmpty
        ? 'Cùng gửi những lời chúc tốt đẹp đến các đồng nghiệp.'
        : '${names.join(', ')}${remaining > 0 ? ' và $remaining đồng nghiệp khác' : ''}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 680;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF6DF), Color(0xFFF5EEFF)],
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE9D7AE)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD39A42).withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _showBirthdayList,
              hoverColor: const Color(0xFF8B63C5).withValues(alpha: 0.035),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 20,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE7A23B), Color(0xFF9A65C8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.cake_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hôm nay có ${_birthdays.length} đồng nghiệp sinh nhật',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF49375E),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            peopleLabel,
                            maxLines: compact ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF78698B),
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!compact)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: const Color(0xFFDCC9EA)),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Xem danh sách',
                              style: TextStyle(
                                color: Color(0xFF7252A4),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 7),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF7252A4),
                              size: 17,
                            ),
                          ],
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF8B72AA),
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox();
    if (_birthdays.isEmpty) return const SizedBox();

    if (kIsWeb) return _buildWebBanner();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 30, 67, 233).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 221, 219, 255),
                Color.fromARGB(255, 215, 221, 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: InkWell(
            onTap: _showBirthdayList,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Text("🎉", style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Hôm nay có ${_birthdays.length} quý đồng nghiệp sinh nhật!",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Hệ thống y tế Hùng Vương kính chúc quý đồng nghiệp Sinh nhật vui vẻ 🎂",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color.fromARGB(255, 14, 13, 13),
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF900C3F),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
