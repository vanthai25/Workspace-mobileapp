import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cham_cong_tang_ca_provider.dart';
import '../../utils/helpers.dart';
import 'cham_cong_tang_ca_form_screen.dart';

class ChamCongTangCaScreen extends StatefulWidget {
  const ChamCongTangCaScreen({Key? key}) : super(key: key);

  @override
  State<ChamCongTangCaScreen> createState() =>
      _ChamCongTangCaScreenState();
}

class _ChamCongTangCaScreenState
    extends State<ChamCongTangCaScreen> {
  DateTime _selectedMonth = DateTime.now();

  /// null: Tất cả
  /// 0: Chờ Khoa duyệt
  /// 1: Khoa đã duyệt
  /// 2: BV đã duyệt
  /// 3: Từ chối
  int? _selectedStatus;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChamCongTangCaProvider>().fetchDanhSach(
            chiCaNhan: true,
          );
    });
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
  }

  Widget _buildMonthFilter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month,
            color: Colors.blueGrey,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2C3E50),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: Colors.blue,
            ),
            onPressed: _previousMonth,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.blue,
            ),
            onPressed: _nextMonth,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        children: [
          _buildFilterChip('Tất cả', null),
          _buildFilterChip('Chờ Khoa duyệt', 0),
          _buildFilterChip('Khoa duyệt', 1),
          _buildFilterChip('BV duyệt', 2),
          _buildFilterChip('Từ chối', 3),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    int? statusValue,
  ) {
    final bool isSelected =
        _selectedStatus == statusValue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.blue.withOpacity(0.2),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(
          color: isSelected
              ? Colors.blue
              : Colors.transparent,
        ),
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.blue.shade800
              : Colors.black87,
          fontWeight: isSelected
              ? FontWeight.bold
              : FontWeight.normal,
        ),
        onSelected: (_) {
          setState(() {
            _selectedStatus = statusValue;
          });
        },
      ),
    );
  }
  Widget _buildThongTinNguoiDuyet(phieu) {
    final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    final String tenLDKhoa =
        phieu.tenLDKhoaDuyet?.toString().trim() ?? '';

    final String tenLDBV =
        phieu.tenLDBVDuyet?.toString().trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tenLDKhoa.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_outline,
                size: 17,
                color: Colors.blue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'LĐ Khoa: $tenLDKhoa',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (phieu.ngayLDKhoaDuyet != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 23,
                top: 2,
              ),
              child: Text(
                'Duyệt lúc: '
                '${dateTimeFormat.format(phieu.ngayLDKhoaDuyet!)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
        ],

        if (tenLDBV.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 17,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'LĐ Bệnh viện: $tenLDBV',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (phieu.ngayLDBVDuyet != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 23,
                top: 2,
              ),
              child: Text(
                'Duyệt lúc: '
                '${dateTimeFormat.format(phieu.ngayLDBVDuyet!)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ],
    );
  }
  Widget _buildTrangThai(int status) {
    late Color color;
    late String text;

    switch (status) {
      case 0:
        color = Colors.orange;
        text = 'Chờ Khoa duyệt';
        break;

      case 1:
        color = Colors.blue;
        text = 'Khoa đã duyệt';
        break;

      case 2:
        color = Colors.green;
        text = 'BV đã duyệt';
        break;

      case 3:
        color = Colors.red;
        text = 'Từ chối';
        break;

      default:
        color = Colors.grey;
        text = 'Không xác định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa phiếu tăng ca này không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Xóa',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final bool success = await context
        .read<ChamCongTangCaProvider>()
        .deletePhieu(id);

    if (success) {
      AppHelpers.showSnackBar('Xóa thành công');
    }
  }

  bool _isCurrentEmployee(
    String phieuManv,
    String currentManv,
  ) {
    return phieuManv.trim().toLowerCase() ==
        currentManv.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    // Dùng watch để màn hình cập nhật nếu AuthProvider
    // nạp mã nhân viên sau khi màn hình đã build.
    final AuthProvider authProvider =
        context.watch<AuthProvider>();

    final String currentManv =
        authProvider.currentManv?.trim() ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Danh Sách Tăng Ca'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildMonthFilter(),
          _buildStatusFilters(),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<ChamCongTangCaProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (provider.errorMessage.isNotEmpty) {
                  return Center(
                    child: Text(
                      'Lỗi: ${provider.errorMessage}',
                    ),
                  );
                }

                /*
                 * Lọc bảo vệ ở Frontend:
                 *
                 * Dù API có vô tình trả phiếu của người khác,
                 * màn hình cá nhân vẫn chỉ hiển thị phiếu có
                 * manv trùng với người đang đăng nhập.
                 */
                final filteredList =
                    provider.danhSachPhieu.where((phieu) {
                  if (currentManv.isEmpty) {
                    return false;
                  }

                  if (!_isCurrentEmployee(
                    phieu.manv,
                    currentManv,
                  )) {
                    return false;
                  }

                  if (_selectedStatus != null &&
                      phieu.trangThaiDuyet !=
                          _selectedStatus) {
                    return false;
                  }

                  if (phieu.batDau.year !=
                          _selectedMonth.year ||
                      phieu.batDau.month !=
                          _selectedMonth.month) {
                    return false;
                  }

                  return true;
                }).toList()
                      ..sort(
                        (a, b) =>
                            b.ngayLap.compareTo(a.ngayLap),
                      );

                if (currentManv.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không xác định được mã nhân viên.',
                    ),
                  );
                }

                if (filteredList.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () {
                      return provider.fetchDanhSach(
                        chiCaNhan: true,
                      );
                    },
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 150),
                        Icon(
                          Icons.inbox_outlined,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Không có dữ liệu trong '
                            'thời gian hoặc trạng thái này.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () {
                    return provider.fetchDanhSach(
                      chiCaNhan: true,
                    );
                  },
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final phieu = filteredList[index];

                      final bool canEditOrDelete =
                          phieu.trangThaiDuyet == 0 &&
                              _isCurrentEmployee(
                                phieu.manv,
                                currentManv,
                              );

                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      phieu.tenNV,
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTrangThai(
                                    phieu.trangThaiDuyet,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                phieu.tenKhoa,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${DateFormat('dd/MM/yyyy HH:mm').format(phieu.batDau)}'
                                      ' - ${DateFormat('HH:mm').format(phieu.ketThuc)}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.hourglass_bottom,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tổng: ${phieu.soPhut} phút',
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.edit_note,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Lý do: '
                                      '${phieu.lyDoTangCa}',
                                    ),
                                  ),
                                ],
                              ),
                              _buildThongTinNguoiDuyet(phieu),
                              if (phieu.trangThaiDuyet == 3 &&
                                  phieu.lyDoTuChoi
                                          ?.trim()
                                          .isNotEmpty ==
                                      true)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    top: 8,
                                  ),
                                  child: Text(
                                    '❌ Lý do từ chối: '
                                    '${phieu.lyDoTuChoi}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontStyle:
                                          FontStyle.italic,
                                    ),
                                  ),
                                ),
                              if (canEditOrDelete) ...[
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 16,
                                      ),
                                      label:
                                          const Text('Sửa'),
                                      style: OutlinedButton
                                          .styleFrom(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 12,
                                          vertical: 0,
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(8),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChamCongTangCaFormScreen(
                                              phieuToEdit:
                                                  phieu,
                                            ),
                                          ),
                                        );

                                        if (!mounted) {
                                          return;
                                        }

                                        await context
                                            .read<
                                                ChamCongTangCaProvider>()
                                            .fetchDanhSach(
                                              chiCaNhan:
                                                  true,
                                            );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Xóa',
                                        style: TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                      style: OutlinedButton
                                          .styleFrom(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal: 12,
                                          vertical: 0,
                                        ),
                                        side:
                                            const BorderSide(
                                          color: Colors.red,
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        _confirmDelete(
                                          phieu.id,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ],
                            
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const ChamCongTangCaFormScreen(),
            ),
          );

          if (!mounted) {
            return;
          }

          await context
              .read<ChamCongTangCaProvider>()
              .fetchDanhSach(
                chiCaNhan: true,
              );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}