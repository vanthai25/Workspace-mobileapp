import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/chamcong_bosung_model.dart';
import '../../services/chamcong_bosung_service.dart';
import '../../utils/helpers.dart';
import 'cham_cong_bo_sung_web_design.dart';

class DuyetBoSungScreen extends StatefulWidget {
  final bool isRole6;
  final bool isRole7;

  const DuyetBoSungScreen({
    super.key,
    required this.isRole6,
    required this.isRole7,
  });

  @override
  State<DuyetBoSungScreen> createState() => _DuyetBoSungScreenState();
}

class _DuyetBoSungScreenState extends State<DuyetBoSungScreen> {
  final ChamCongBoSungService _apiService = ChamCongBoSungService();
  final Color primaryColor = const Color(0xFF1274BC);

  bool _isLoading = true;
  List<PhieuBoSungModel> _phieuList = [];

  DateTime _selectedMonth = DateTime.now();
  int _currentTabIndex = 0;
  String _searchQuery = '';

  int countPending = 0;
  int countApproved = 0;
  int countRejected = 0;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  Set<int> _selectedIds = {};

  List<Map<String, String>> _danhSachKhoa = [];
  String _selectedMakhoa = '';
  String _selectedTenKhoa = 'Tất cả Khoa/Phòng';

  @override
  void initState() {
    super.initState();
    if (widget.isRole7) {
      _loadDanhSachKhoa();
    }
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 🔥 LẤY DANH SÁCH KHOA TỪ API
  Future<void> _loadDanhSachKhoa() async {
    final list = await _apiService.getDanhSachKhoa();
    if (mounted) {
      setState(() {
        _danhSachKhoa = list;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    _selectedIds.clear();

    final data = await _apiService.getDashboardDuyet(
      month: _selectedMonth.month,
      year: _selectedMonth.year,
      tabIndex: _currentTabIndex,
      keyword: _searchQuery,
      isRole6: widget.isRole6,
      isRole7: widget.isRole7,
      makhoa: _selectedMakhoa, // 🔥 Truyền mã khoa lên
    );

    if (mounted) {
      setState(() {
        if (data != null) {
          countPending = data['countPending'] ?? 0;
          countApproved = data['countApproved'] ?? 0;
          countRejected = data['countRejected'] ?? 0;
          var listRaw = data['data'] as List? ?? [];
          _phieuList = listRaw
              .map((x) => PhieuBoSungModel.fromJson(x))
              .toList();
        } else {
          _phieuList = [];
        }
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
      1,
    );
    _fetchData();
  }

  void _changeTab(int index) {
    if (_currentTabIndex == index) return;
    _currentTabIndex = index;
    _fetchData();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      _fetchData();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id))
        _selectedIds.remove(id);
      else
        _selectedIds.add(id);
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds = _phieuList
            .where((p) {
              bool isRole6AndKtProcessed =
                  widget.isRole6 &&
                  (p.trangThaiDuyet == 4 || p.trangThaiDuyet == 5);
              return !isRole6AndKtProcessed;
            })
            .map((e) => e.id)
            .toSet();
      } else {
        _selectedIds.clear();
      }
    });
  }

  Future<void> _processDuyetPhieu({
    required List<int> ids,
    required int newStatus,
    bool isReject = false,
  }) async {
    String ghiChu = '';
    if (isReject) {
      final txtController = TextEditingController();
      bool confirm =
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(
                'Lý do từ chối',
                style: TextStyle(color: Colors.red),
              ),
              content: TextField(
                controller: txtController,
                decoration: const InputDecoration(
                  hintText: 'Nhập lý do...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    if (txtController.text.trim().isEmpty) {
                      AppHelpers.showSnackBar(
                        'Vui lòng nhập lý do từ chối',
                        isError: true,
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirm) return;
      ghiChu = txtController.text.trim();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    int successCount = 0;
    for (int id in ids) {
      bool isOk = await _apiService.duyetPhieu(
        id,
        newStatus,
        ghiChuTuChoi: ghiChu,
      );
      if (isOk) successCount++;
    }
    Navigator.of(context, rootNavigator: true).pop();

    if (successCount > 0) {
      AppHelpers.showSnackBar(
        'Đã xử lý thành công $successCount phiếu',
        isError: false,
      );
      _fetchData();
    }
  }

  // 🔥 HIỂN THỊ GIAO DIỆN LỌC KHOA Ở BOTTOM SHEET
  void _showKhoaFilterBottomSheet() {
    String searchKhoaQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            List<Map<String, String>> filteredKhoa = _danhSachKhoa.where((k) {
              String search = searchKhoaQuery.toLowerCase();
              return k['tenkhoa']!.toLowerCase().contains(search) ||
                  k['makhoa']!.toLowerCase().contains(search);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
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
                    'Chọn Khoa/Phòng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (val) {
                        setModalState(() {
                          searchKhoaQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc mã...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildKhoaItem(
                          makhoa: '',
                          tenkhoa: 'Tất cả Khoa/Phòng',
                          isAll: true,
                          onTap: () {
                            setState(() {
                              _selectedMakhoa = '';
                              _selectedTenKhoa = 'Tất cả Khoa/Phòng';
                            });
                            Navigator.pop(ctx);
                            _fetchData();
                          },
                        ),
                        ...filteredKhoa.map(
                          (k) => _buildKhoaItem(
                            makhoa: k['makhoa']!,
                            tenkhoa: k['tenkhoa']!,
                            onTap: () {
                              setState(() {
                                _selectedMakhoa = k['makhoa']!;
                                _selectedTenKhoa = k['tenkhoa']!;
                              });
                              Navigator.pop(ctx);
                              _fetchData();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKhoaItem({
    required String makhoa,
    required String tenkhoa,
    bool isAll = false,
    required VoidCallback onTap,
  }) {
    bool isSelected = _selectedMakhoa == makhoa;
    String firstLetter = isAll
        ? ''
        : (tenkhoa.isNotEmpty ? tenkhoa.substring(0, 1).toUpperCase() : 'K');
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 2,
          ),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: isAll ? Colors.grey.shade100 : Colors.blue.shade50,
            child: isAll
                ? Icon(Icons.apartment, color: Colors.grey.shade600, size: 20)
                : Text(
                    firstLetter,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
          title: Text(
            tenkhoa,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey.shade800,
              fontSize: 15,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Color(0xFF1274BC))
              : null,
          onTap: onTap,
        ),
        Divider(
          height: 1,
          color: Colors.grey.shade200,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                // 🔥 HIỂN THỊ TÊN KHOA ĐANG LỌC BÊN DƯỚI THÁNG
                if (widget.isRole7 && _selectedMakhoa.isNotEmpty)
                  Text(
                    _selectedTenKhoa,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.blue,
                ),
                onPressed: () => _changeMonth(-1),
                splashRadius: 20,
              ),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.blue,
                ),
                onPressed: () => _changeMonth(1),
                splashRadius: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            _buildTabItem(0, 'Chờ xử lý', countPending, Colors.amber.shade600),
            _buildTabItem(1, 'Đã duyệt', countApproved, Colors.green),
            _buildTabItem(2, 'Từ chối', countRejected, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String title, int count, Color activeColor) {
    bool isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndSelectAll() {
    Color activeColor = _currentTabIndex == 0
        ? Colors.amber.shade600
        : _currentTabIndex == 1
        ? Colors.green
        : Colors.red;
    bool isAllSelected =
        _phieuList.isNotEmpty &&
        _selectedIds.length ==
            _phieuList
                .where(
                  (p) =>
                      !(widget.isRole6 &&
                          (p.trangThaiDuyet == 4 || p.trangThaiDuyet == 5)),
                )
                .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Tìm theo Mã, Tên NV...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _toggleSelectAll(!isAllSelected),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 42,
              padding: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAllSelected ? activeColor : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isAllSelected,
                    activeColor: activeColor,
                    visualDensity: VisualDensity.compact,
                    onChanged: _toggleSelectAll,
                  ),
                  Text(
                    'Chọn tất cả',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isAllSelected ? activeColor : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhieuCard(PhieuBoSungModel phieu) {
    Color borderColor = _currentTabIndex == 0
        ? Colors.amber.shade600
        : _currentTabIndex == 1
        ? Colors.green
        : Colors.red;
    String ngayHienThi = "";
    if (phieu.ngayThieu != null && phieu.ngayThieu!.length >= 10) {
      String date = phieu.ngayThieu!.substring(0, 10);
      List<String> parts = date.split('-');
      if (parts.length == 3)
        ngayHienThi = "${parts[2]}/${parts[1]}/${parts[0]}";
    }

    bool isRole6AndKtProcessed =
        widget.isRole6 &&
        (phieu.trangThaiDuyet == 4 || phieu.trangThaiDuyet == 5);

    return Card(
      margin: useChamCongDesktopWeb(context)
          ? const EdgeInsets.all(6)
          : const EdgeInsets.only(bottom: 10, left: 16, right: 16),
      elevation: useChamCongDesktopWeb(context) ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          useChamCongDesktopWeb(context) ? 15 : 8,
        ),
        side: useChamCongDesktopWeb(context)
            ? const BorderSide(color: ChamCongWebColors.border)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            useChamCongDesktopWeb(context) ? 15 : 8,
          ),
          color: Colors.white,
          border: Border(left: BorderSide(color: borderColor, width: 5)),
        ),
        padding: const EdgeInsets.only(left: 14, top: 10, bottom: 12, right: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${phieu.manv} - ${phieu.tenNV}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            ngayHienThi,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${phieu.tongCong ?? 1} công',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isRole6AndKtProcessed)
                  Checkbox(
                    value: _selectedIds.contains(phieu.id),
                    activeColor: borderColor,
                    visualDensity: VisualDensity.compact,
                    onChanged: (val) => _toggleSelection(phieu.id),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 8),
            if (phieu.noiDung != null && phieu.noiDung!.isNotEmpty)
              Text(
                '"${phieu.noiDung}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            if (phieu.lyDo != null && phieu.lyDo!.isNotEmpty)
              Text(
                '"${phieu.lyDo}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),

            Builder(
              builder: (context) {
                bool showApprovers =
                    (_currentTabIndex == 1 || _currentTabIndex == 2) ||
                    (_currentTabIndex == 0 && widget.isRole7);
                if (showApprovers &&
                    ((phieu.tenLdDuyet != null &&
                            phieu.tenLdDuyet!.isNotEmpty) ||
                        (phieu.tenKtDuyet != null &&
                            phieu.tenKtDuyet!.isNotEmpty))) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (phieu.tenLdDuyet != null &&
                                phieu.tenLdDuyet!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.blueGrey,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'LĐ Duyệt: ${phieu.tenLdDuyet}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (phieu.tenLdDuyet != null &&
                                phieu.tenLdDuyet!.isNotEmpty &&
                                phieu.tenKtDuyet != null &&
                                phieu.tenKtDuyet!.isNotEmpty)
                              const SizedBox(height: 4),
                            if (phieu.tenKtDuyet != null &&
                                phieu.tenKtDuyet!.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.manage_accounts,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'KT Duyệt: ${phieu.tenKtDuyet}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            if (_currentTabIndex == 2 &&
                phieu.ghiChu != null &&
                phieu.ghiChu!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Từ chối: ${phieu.ghiChu}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentTabIndex == 0) ...[
                  _buildActionBtn(
                    'Duyệt',
                    Icons.check,
                    Colors.green,
                    () => _processDuyetPhieu(
                      ids: [phieu.id],
                      newStatus: widget.isRole6 ? 2 : 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildActionBtn(
                    'Từ chối',
                    Icons.close,
                    Colors.red,
                    () => _processDuyetPhieu(
                      ids: [phieu.id],
                      newStatus: widget.isRole6 ? 3 : 5,
                      isReject: true,
                    ),
                  ),
                ],
                if (_currentTabIndex == 1) ...[
                  if (isRole6AndKtProcessed)
                    const Text(
                      'Kế toán đã duyệt, không thể thay đổi',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    )
                  else ...[
                    _buildActionBtn(
                      'Hủy',
                      Icons.undo_rounded,
                      Colors.orange.shade700,
                      () => _processDuyetPhieu(
                        ids: [phieu.id],
                        newStatus: widget.isRole6 ? 1 : 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionBtn(
                      'Từ chối',
                      Icons.close,
                      Colors.red,
                      () => _processDuyetPhieu(
                        ids: [phieu.id],
                        newStatus: widget.isRole6 ? 3 : 5,
                        isReject: true,
                      ),
                    ),
                  ],
                ],
                if (_currentTabIndex == 2) ...[
                  if (isRole6AndKtProcessed)
                    const Text(
                      'Kế toán đã từ chối, không thể thay đổi',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    )
                  else
                    _buildActionBtn(
                      'Duyệt lại',
                      Icons.replay_circle_filled_rounded,
                      Colors.green,
                      () => _processDuyetPhieu(
                        ids: [phieu.id],
                        newStatus: widget.isRole6 ? 2 : 4,
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 32),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget? _buildBatchActionBar() {
    if (_selectedIds.isEmpty) return null;
    List<Widget> buttons = [];
    if (_currentTabIndex == 0) {
      buttons.add(
        Expanded(
          child: _buildBatchBtn(
            'Duyệt Tất Cả',
            Colors.green,
            () => _processDuyetPhieu(
              ids: _selectedIds.toList(),
              newStatus: widget.isRole6 ? 2 : 4,
            ),
          ),
        ),
      );
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: _buildBatchBtn(
            'Từ Chối Tất Cả',
            Colors.red,
            () => _processDuyetPhieu(
              ids: _selectedIds.toList(),
              newStatus: widget.isRole6 ? 3 : 5,
              isReject: true,
            ),
          ),
        ),
      );
    } else if (_currentTabIndex == 1) {
      buttons.add(
        Expanded(
          child: _buildBatchBtn(
            'Hủy Duyệt',
            Colors.orange.shade700,
            () => _processDuyetPhieu(
              ids: _selectedIds.toList(),
              newStatus: widget.isRole6 ? 1 : 2,
            ),
          ),
        ),
      );
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: _buildBatchBtn(
            'Từ Chối',
            Colors.red,
            () => _processDuyetPhieu(
              ids: _selectedIds.toList(),
              newStatus: widget.isRole6 ? 3 : 5,
              isReject: true,
            ),
          ),
        ),
      );
    } else if (_currentTabIndex == 2) {
      buttons.add(
        Expanded(
          child: _buildBatchBtn(
            'Duyệt Lại Tất Cả',
            Colors.green,
            () => _processDuyetPhieu(
              ids: _selectedIds.toList(),
              newStatus: widget.isRole6 ? 2 : 4,
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(child: Row(children: buttons)),
    );
  }

  Widget _buildBatchBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (useChamCongDesktopWeb(context)) {
      return _buildWeb(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Duyệt Phiếu Bổ Sung',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          // 🔥 NÚT LỌC KHOA (Chỉ hiển thị cho Kế toán)
          if (widget.isRole7)
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined),
              tooltip: 'Lọc Khoa/Phòng',
              onPressed: _showKhoaFilterBottomSheet,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildCustomTabs(),
          _buildSearchAndSelectAll(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _phieuList.isEmpty
                ? Center(
                    child: Text(
                      'Không có phiếu nào',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 0, bottom: 20),
                      itemCount: _phieuList.length,
                      itemBuilder: (context, index) =>
                          _buildPhieuCard(_phieuList[index]),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBatchActionBar(),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return ChamCongWebPage(
      title: 'Duyệt phiếu bổ sung',
      subtitle: widget.isRole7
          ? 'Nghiệm thu phiếu bổ sung công toàn bệnh viện'
          : 'Xử lý phiếu bổ sung công trong đơn vị',
      icon: Icons.fact_check_rounded,
      maxWidth: 1420,
      actions: [
        IconButton.filledTonal(
          tooltip: 'Làm mới dữ liệu',
          onPressed: _isLoading ? null : _fetchData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: Stack(
        children: [
          Column(
            children: [
              ChamCongWebCard(
                margin: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton.outlined(
                          tooltip: 'Tháng trước',
                          onPressed: _isLoading ? null : () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 165),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          child: Text(
                            'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
                            style: const TextStyle(
                              color: ChamCongWebColors.text,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: 'Tháng sau',
                          onPressed: _isLoading ? null : () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Tìm theo mã hoặc tên nhân viên...',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                        ),
                        if (widget.isRole7) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 300,
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(_selectedMakhoa),
                              initialValue: _selectedMakhoa,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Khoa / Phòng',
                                prefixIcon: Icon(Icons.apartment_rounded),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('Tất cả Khoa/Phòng'),
                                ),
                                ..._danhSachKhoa.map(
                                  (khoa) => DropdownMenuItem(
                                    value: khoa['makhoa'] ?? '',
                                    child: Text(
                                      khoa['tenkhoa'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: _isLoading
                                  ? null
                                  : (value) {
                                      final maKhoa = value ?? '';
                                      final selected = _danhSachKhoa
                                          .where(
                                            (item) => item['makhoa'] == maKhoa,
                                          )
                                          .firstOrNull;
                                      setState(() {
                                        _selectedMakhoa = maKhoa;
                                        _selectedTenKhoa = selected == null
                                            ? 'Tất cả Khoa/Phòng'
                                            : selected['tenkhoa'] ?? '';
                                      });
                                      _fetchData();
                                    },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildWebStatusTab(
                          index: 0,
                          title: 'Chờ xử lý',
                          count: countPending,
                          color: ChamCongWebColors.warning,
                        ),
                        const SizedBox(width: 10),
                        _buildWebStatusTab(
                          index: 1,
                          title: 'Đã duyệt',
                          count: countApproved,
                          color: ChamCongWebColors.success,
                        ),
                        const SizedBox(width: 10),
                        _buildWebStatusTab(
                          index: 2,
                          title: 'Từ chối',
                          count: countRejected,
                          color: ChamCongWebColors.danger,
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _phieuList.isEmpty
                              ? null
                              : () => _toggleSelectAll(_selectedIds.isEmpty),
                          icon: const Icon(Icons.select_all_rounded),
                          label: Text(
                            _selectedIds.isEmpty
                                ? 'Chọn tất cả'
                                : 'Bỏ chọn (${_selectedIds.length})',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: ChamCongWebColors.primary,
                        ),
                      )
                    : _phieuList.isEmpty
                    ? const ChamCongWebEmpty(
                        title: 'Không có phiếu cần xử lý',
                        message:
                            'Không có dữ liệu phù hợp với bộ lọc hiện tại.',
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth >= 1050
                              ? (constraints.maxWidth - 52) / 2
                              : constraints.maxWidth - 40;

                          return SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              4,
                              0,
                              4,
                              _selectedIds.isEmpty ? 24 : 90,
                            ),
                            child: Wrap(
                              runSpacing: 2,
                              children: _phieuList
                                  .map(
                                    (item) => SizedBox(
                                      width: width,
                                      child: _buildPhieuCard(item),
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_selectedIds.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildBatchActionBar()!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebStatusTab({
    required int index,
    required String title,
    required int count,
    required Color color,
  }) {
    final selected = _currentTabIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: _isLoading ? null : () => _changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .1) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: .35)
                : ChamCongWebColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? color : ChamCongWebColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
