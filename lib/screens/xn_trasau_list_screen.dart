import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Để dùng chức năng gọi điện
import '../models/xn_trasau_model.dart';
import '../services/xn_trasau_service.dart';
import '../services/api_client.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'pdf_viewer_screen.dart';
import 'xn_trasau_ket_qua_screen.dart';
import '../utils/xn_pdf_save.dart';

// Model mô tả chi tiết từng file PDF kết quả
class PdfFileItem {
  final int id;
  final String? tenfile;
  final String? loai;
  final String? ngay;

  PdfFileItem({required this.id, this.tenfile, this.loai, this.ngay});

  factory PdfFileItem.fromJson(Map<String, dynamic> json) {
    return PdfFileItem(
      id: json['id'],
      tenfile: json['tenfile'],
      loai: json['loai'],
      ngay: json['ngay']?.toString(),
    );
  }
}

class XNTraSauListScreen extends StatefulWidget {
  const XNTraSauListScreen({super.key});

  @override
  State<XNTraSauListScreen> createState() => _XNTraSauListScreenState();
}

class _XNTraSauListScreenState extends State<XNTraSauListScreen> {
  final XNTraSauService _apiService = XNTraSauService();
  final Color primaryColor = const Color(0xFF1274BC);

  List<XNTraSau> _list = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  // Biến bộ lọc
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _selectedState; // null = Tất cả, 0 = Chưa trả, 2 = Đã trả
  Timer? _debounce;
  bool _showFilters = false;
  int _viewMode = 0;
  String? _selectedKhoa;
  String? _selectedPhong;
  String? _selectedNguoiCd;
  List<String> _khoaList = [];
  List<dynamic> _phongList = [];
  List<dynamic> _nguoiCdList = [];

  @override
  void initState() {
    super.initState();
    _fetchFilterOptions();
    _fetchData();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
              _scrollCtrl.position.maxScrollExtent - 200 &&
          !_isLoading &&
          !_isFetchingMore &&
          _hasMore) {
        _fetchMoreData();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- HÀM XÓA BỘ LỌC ---
  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _fromDate = null;
      _toDate = null;
      _selectedKhoa = null;
      _selectedPhong = null;
      _selectedNguoiCd = null;
      _selectedState = null;
    });
    _fetchData();
  }

  Future<void> _fetchFilterOptions() async {
    final opts = await _apiService.getFilterOptions();
    if (mounted) {
      setState(() {
        _khoaList = List<String>.from(opts['khoas'] ?? []);
        _phongList = opts['phongs'] ?? [];
        _nguoiCdList = opts['nguoicds'] ?? [];
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });
    final myManv = context.read<AuthProvider>().currentManv;
    final data = await _apiService.getXNTraSauList(
      keyword: _searchQuery,
      page: _currentPage,
      pageSize: _pageSize,
      fromDate: _fromDate?.toIso8601String(),
      toDate: _toDate?.toIso8601String(),
      state: _selectedState,
      nguoicd: _viewMode == 0 ? myManv : null,
      khoacd: _selectedKhoa,
      phongcd: _selectedPhong,
      filterNguoicd: _selectedNguoiCd,
    );
    if (mounted) {
      setState(() {
        _list = data;
        _isLoading = false;
        if (data.length < _pageSize) _hasMore = false;
      });
    }
  }

  Future<void> _fetchMoreData() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;
    final newData = await _apiService.getXNTraSauList(
      keyword: _searchQuery,
      page: _currentPage,
      pageSize: _pageSize,
      fromDate: _fromDate?.toIso8601String(),
      toDate: _toDate?.toIso8601String(),
      state: _selectedState,
      khoacd: _selectedKhoa,
      phongcd: _selectedPhong,
      filterNguoicd: _selectedNguoiCd,
    );
    if (mounted) {
      setState(() {
        _list.addAll(newData);
        _isFetchingMore = false;
        if (newData.length < _pageSize) _hasMore = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = val.trim();
      _fetchData();
    });
  }

  // --- CÁC HÀM LẤY TÊN HIỂN THỊ TRÊN FORM LỌC ---
  String _getSelectedKhoaName() => _selectedKhoa ?? 'Tất cả Khoa';
  String _getSelectedPhongName() => _selectedPhong ?? 'Tất cả Phòng';
  String _getSelectedDoctorName() {
    if (_selectedNguoiCd == null) return 'Tất cả Bác sĩ';
    try {
      var doc = _nguoiCdList.firstWhere((e) => e['manv'] == _selectedNguoiCd);
      return '${doc['tennv']}';
    } catch (e) {
      return _selectedNguoiCd!;
    }
  }

  // --- MỞ BOTTOM SHEET CHỌN KHOA ---
  void _showKhoaBottomSheet() {
    String localSearch = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            var filteredList = _khoaList
                .where(
                  (k) => k.toLowerCase().contains(localSearch.toLowerCase()),
                )
                .toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.6,
                maxChildSize: 0.9,
                minChildSize: 0.4,
                expand: false,
                builder: (_, scrollController) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Text(
                        'Chọn Khoa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm khoa...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                          ),
                          onChanged: (val) =>
                              setModalState(() => localSearch = val),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.domain, color: Colors.grey),
                        ),
                        title: const Text(
                          'Tất cả Khoa',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: _selectedKhoa == null
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1274BC),
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedKhoa = null;
                            _selectedPhong = null;
                          });
                          _fetchData();
                          Navigator.pop(ctx);
                        },
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 70),
                          itemBuilder: (context, index) {
                            var khoa = filteredList[index];
                            bool isSelected = _selectedKhoa == khoa;
                            String initial = khoa.isNotEmpty
                                ? khoa.substring(0, 1).toUpperCase()
                                : 'K';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(
                                  0xFF1274BC,
                                ).withOpacity(0.1),
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Color(0xFF1274BC),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                khoa,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF1274BC),
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedKhoa = khoa;
                                  _selectedPhong = null;
                                });
                                _fetchData();
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- MỞ BOTTOM SHEET CHỌN PHÒNG ---
  void _showPhongBottomSheet() {
    String localSearch = '';
    var availablePhongs = _phongList
        .where((p) => _selectedKhoa == null || p['khoacd'] == _selectedKhoa)
        .map((p) => p['phongcd'].toString())
        .toSet()
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            var filteredList = availablePhongs
                .where(
                  (p) => p.toLowerCase().contains(localSearch.toLowerCase()),
                )
                .toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.6,
                maxChildSize: 0.9,
                minChildSize: 0.4,
                expand: false,
                builder: (_, scrollController) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Text(
                        'Chọn Phòng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm phòng...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                          ),
                          onChanged: (val) =>
                              setModalState(() => localSearch = val),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(
                            Icons.meeting_room,
                            color: Colors.grey,
                          ),
                        ),
                        title: const Text(
                          'Tất cả Phòng',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: _selectedPhong == null
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1274BC),
                              )
                            : null,
                        onTap: () {
                          setState(() => _selectedPhong = null);
                          _fetchData();
                          Navigator.pop(ctx);
                        },
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 70),
                          itemBuilder: (context, index) {
                            var phong = filteredList[index];
                            bool isSelected = _selectedPhong == phong;
                            String initial = phong.isNotEmpty
                                ? phong.substring(0, 1).toUpperCase()
                                : 'P';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(
                                  0xFF1274BC,
                                ).withOpacity(0.1),
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Color(0xFF1274BC),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                phong,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF1274BC),
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _selectedPhong = phong);
                                _fetchData();
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- MỞ BOTTOM SHEET CHỌN BÁC SĨ ---
  void _showDoctorBottomSheet() {
    String localSearch = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            var filteredList = _nguoiCdList.where((doc) {
              String manv = (doc['manv'] ?? '').toString().toLowerCase();
              String tennv = (doc['tennv'] ?? '').toString().toLowerCase();
              String search = localSearch.toLowerCase();
              return manv.contains(search) || tennv.contains(search);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.6,
                maxChildSize: 0.9,
                minChildSize: 0.4,
                expand: false,
                builder: (_, scrollController) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Text(
                        'Chọn bác sĩ chỉ định',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên hoặc mã...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                          ),
                          onChanged: (val) =>
                              setModalState(() => localSearch = val),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.group, color: Colors.grey),
                        ),
                        title: const Text(
                          'Tất cả Bác sĩ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: _selectedNguoiCd == null
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1274BC),
                              )
                            : null,
                        onTap: () {
                          setState(() => _selectedNguoiCd = null);
                          _fetchData();
                          Navigator.pop(ctx);
                        },
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 70),
                          itemBuilder: (context, index) {
                            var doc = filteredList[index];
                            bool isSelected = _selectedNguoiCd == doc['manv'];
                            String initial =
                                (doc['tennv'] != null &&
                                    doc['tennv'].toString().isNotEmpty)
                                ? doc['tennv']
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase()
                                : 'BS';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(
                                  0xFF1274BC,
                                ).withOpacity(0.1),
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Color(0xFF1274BC),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                doc['tennv'] ?? 'Chưa rõ tên',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                doc['manv'] ?? '',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF1274BC),
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _selectedNguoiCd = doc['manv']);
                                _fetchData();
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- HÀM CHỌN KHOẢNG NGÀY ---
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _fetchData();
    }
  }

  // --- HÀM XỬ LÝ TRẢ KQ ---
  Future<void> _handleToggleState(XNTraSau item) async {
    bool isChuaTra = (item.state == null || item.state == 0);
    String title = isChuaTra ? "Xác nhận Trả kết quả" : "Hủy trả kết quả";
    String content = isChuaTra
        ? "Bạn có chắc chắn muốn trả kết quả cho bệnh nhân này?"
        : "Hủy bỏ trạng thái đã trả kết quả?";

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            color: isChuaTra ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isChuaTra ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1274BC)),
        ),
      );
    }

    try {
      await _apiService.toggleState(item.id);
      if (mounted) {
        Navigator.pop(context);
        AppHelpers.showSnackBar('Thao tác thành công!', isError: false);
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppHelpers.showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  // --- API GỌI LẤY DANH SÁCH FILE PDF ---
  Future<List<PdfFileItem>> _fetchPdfList(String mathanhtoanct) async {
    final response = await ApiClient().dio.get<dynamic>(
      '${AppConstants.baseUrl}/XNTraSau/list-pdfs',
      queryParameters: {'mathanhtoanct': mathanhtoanct},
    );
    if (response.statusCode == 200) {
      final jsonResponse = response.data;
      if (jsonResponse is Map &&
          jsonResponse['success'] == true &&
          jsonResponse['data'] is List) {
        final List data = jsonResponse['data'];
        return data.map((e) => PdfFileItem.fromJson(e)).toList();
      }
    }
    throw Exception('Không tải được danh sách PDF.');
  }

  // --- HÀM TẢI VỀ VÀ MỞ FILE TRÊN ĐIỆN THOẠI ---
  Future<void> _downloadAndOpenFile(
    BuildContext context,
    int id,
    String fileName,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final loadingRoute = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    unawaited(navigator.push(loadingRoute));
    try {
      final url = '${AppConstants.baseUrl}/XNTraSau/download-pdf?id=$id';

      final response = await ApiClient().dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        await saveXnPdf(Uint8List.fromList(response.data ?? []), fileName);
      } else {
        AppHelpers.showSnackBar('Tải file thất bại!', isError: true);
      }
    } catch (e) {
      if (mounted)
        AppHelpers.showSnackBar(
          'Không tải hoặc mở được file PDF.',
          isError: true,
        );
    } finally {
      if (navigator.mounted && loadingRoute.isActive)
        navigator.removeRoute(loadingRoute);
    }
  }

  void _showDetailBottomSheet(XNTraSau item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Chi tiết chỉ định & Kết quả',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 24),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    children: [
                      // THÔNG TIN BỆNH NHÂN
                      _buildDetailRow(
                        'Bệnh nhân',
                        '${item.hoten ?? "N/A"} (${item.tuoi ?? "N/A"})',
                        isBold: true,
                      ),
                      _buildDetailRow('Mã KCB', item.makcb ?? "N/A"),
                      _buildDetailRow(
                        'Năm sinh',
                        item.namsinh?.toString() ?? "N/A",
                      ),
                      _buildDetailRow('Giới tính', item.gioitinh ?? "N/A"),
                      _buildDetailRow('SĐT', item.dienthoai ?? "Chưa cập nhật"),
                      _buildDetailRow(
                        'Địa chỉ',
                        item.diachi ?? "Chưa cập nhật",
                      ),

                      const Divider(height: 24),

                      // THÔNG TIN CHỈ ĐỊNH
                      _buildDetailRow(
                        'Chỉ định',
                        item.tenhh ?? "N/A",
                        valueColor: primaryColor,
                      ),
                      _buildDetailRow(
                        'Khoa/Phòng',
                        '${item.khoacd ?? "N/A"} - ${item.phongcd ?? "N/A"}',
                      ),
                      _buildDetailRow(
                        'Ngày CĐ',
                        item.ngaycd != null
                            ? DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(DateTime.parse(item.ngaycd!))
                            : "N/A",
                      ),
                      _buildDetailRow(
                        'Bác sĩ CĐ',
                        '${item.tenChucDanh != null && item.tenChucDanh!.isNotEmpty ? item.tenChucDanh! + ". " : ""}${item.tennguoicd ?? item.nguoicd ?? "N/A"}',
                      ),

                      const Divider(height: 24),
                      FilledButton.icon(
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text('Xem kết quả'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => XNTraSauKetQuaScreen(item: item),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'File PDF đính kèm:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1274BC),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 🔥 GỌI API LẤY DANH SÁCH FILE PDF
                      if (item.mathanhtoanct != null)
                        FutureBuilder<List<PdfFileItem>>(
                          future: _fetchPdfList(item.mathanhtoanct.toString()),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Text(
                                'Không tải được danh sách PDF. Vui lòng mở lại chi tiết để thử lại.',
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Chưa có PDF đính kèm. Bạn vẫn có thể chọn “Xem kết quả” ở phía trên.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }

                            final files = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: files.length,
                              itemBuilder: (context, index) {
                                final file = files[index];
                                final fileName =
                                    file.tenfile ?? 'Kết quả_${index + 1}.pdf';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fileName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Loại: ${file.loai ?? "PDF kết quả"}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Nút Xem Online
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: Color(0xFF1274BC),
                                        ),
                                        tooltip: 'Xem trực tuyến',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PdfViewerScreen(
                                                fileId: file.id,
                                                fileName: fileName,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Nút Tải Về Điện Thoại
                                      IconButton(
                                        icon: const Icon(
                                          Icons.download,
                                          color: Colors.green,
                                        ),
                                        tooltip: 'Tải về máy',
                                        onPressed: () => _downloadAndOpenFile(
                                          context,
                                          file.id,
                                          fileName,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        )
                      else
                        const Text(
                          'Chưa có mã thanh toán để tải file.',
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myManv = context.read<AuthProvider>().currentManv ?? '';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: Column(
          children: [
            // HEADER & BỘ LỌC
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4FA5E5), Color(0xFF1274BC)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'XN Trả Sau',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Xóa bộ lọc',
                            icon: const Icon(
                              Icons.filter_alt_off_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _clearFilters,
                          ),
                          IconButton(
                            tooltip: 'Mở rộng bộ lọc',
                            icon: Icon(
                              _showFilters
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.filter_alt_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                setState(() => _showFilters = !_showFilters),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Ô Tìm kiếm
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      maxLength: XNTraSauService.maxKeywordLength,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          XNTraSauService.maxKeywordLength,
                        ),
                        FilteringTextInputFormatter.singleLineFormatter,
                      ],
                      decoration: const InputDecoration(
                        hintText: "Tìm Tên bệnh nhân, Mã KCB...",
                        prefixIcon: Icon(Icons.search, color: Colors.blue),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        counterText: '',
                      ),
                    ),
                  ),

                  // Hiển thị ngày đang lọc
                  if (_fromDate != null && _toDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, left: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.date_range_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Lọc từ: ${DateFormat('dd/MM/yyyy').format(_fromDate!)} đến ${DateFormat('dd/MM/yyyy').format(_toDate!)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Các Form Chọn Nâng Cao
                  if (_showFilters) ...[
                    const SizedBox(height: 12),
                    // HÀNG 1: Chọn Khoa & Phòng
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _showKhoaBottomSheet,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getSelectedKhoaName(),
                                      style: TextStyle(
                                        color: _selectedKhoa == null
                                            ? Colors.grey.shade600
                                            : Colors.black87,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: _selectedKhoa == null
                                ? null
                                : _showPhongBottomSheet,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedKhoa == null
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedKhoa == null
                                          ? 'Chọn khoa trước'
                                          : _getSelectedPhongName(),
                                      style: TextStyle(
                                        color:
                                            _selectedPhong == null ||
                                                _selectedKhoa == null
                                            ? Colors.grey.shade600
                                            : Colors.black87,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // HÀNG 2: Chọn Bác sĩ & Ngày
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _showDoctorBottomSheet,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getSelectedDoctorName(),
                                      style: TextStyle(
                                        color: _selectedNguoiCd == null
                                            ? Colors.grey.shade600
                                            : Colors.black87,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _selectDateRange,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Tab Phân Loại BN
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _viewMode,
                  backgroundColor: Colors.grey.shade200,
                  thumbColor: Colors.white,
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Chỉ định của tôi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _viewMode == 0
                              ? primaryColor
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Tất cả bệnh nhân',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _viewMode == 1
                              ? primaryColor
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) {
                      setState(() => _viewMode = val);
                      _fetchData();
                    }
                  },
                ),
              ),
            ),

            // TABS TRẠNG THÁI
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildChip('Tất cả', null),
                  _buildChip('Chưa trả', 0),
                  _buildChip('Đã trả KQ', 2),
                ],
              ),
            ),

            // DANH SÁCH LISTVIEW
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _list.isEmpty
                  ? const Center(
                      child: Text(
                        "Không có dữ liệu",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 24,
                        ),
                        itemCount: _list.length + (_isFetchingMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _list.length)
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          final item = _list[i];
                          bool isDaTra = item.state == 2;
                          bool isMyPatient = (item.nguoicd == myManv);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () =>
                                    _showDetailBottomSheet(item), // MỞ CHI TIẾT
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // DÒNG 1: Tên - MÃ KCB & Badge
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.hoten?.toUpperCase() ?? "N/A"} - ${item.makcb ?? ""}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black87,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDaTra
                                                  ? Colors.green.shade50
                                                  : const Color(0xFFFEF2E4),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isDaTra ? 'Đã trả' : 'Chưa trả',
                                              style: TextStyle(
                                                color: isDaTra
                                                    ? Colors.green.shade700
                                                    : const Color(0xFFE59C35),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // DÒNG 2: Tên xét nghiệm (Chữ xanh dương)
                                      Text(
                                        item.tenhh ?? "N/A",
                                        style: const TextStyle(
                                          color: Color(0xFF1274BC),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // DÒNG 3: Ngày CĐ
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 16,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Ngày CĐ: ${item.ngaycd != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item.ngaycd!)) : ""}',
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // DÒNG 4: Khoa CĐ
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.domain,
                                            size: 16,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Khoa CĐ: ${item.khoacd ?? "N/A"}',
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // DÒNG 5: Bác sĩ chỉ định
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'BS chỉ định: ${item.tenChucDanh != null && item.tenChucDanh!.isNotEmpty ? item.tenChucDanh! + ". " : ""}${item.tennguoicd ?? item.nguoicd ?? "N/A"}',
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                  255,
                                                  0,
                                                  0,
                                                  0,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // DÒNG 6: CÁC NÚT BẤM
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          // Nút Gọi điện
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                if (item.dienthoai != null &&
                                                    item
                                                        .dienthoai!
                                                        .isNotEmpty) {
                                                  final Uri url = Uri(
                                                    scheme: 'tel',
                                                    path: item.dienthoai,
                                                  );
                                                  if (await canLaunchUrl(url)) {
                                                    await launchUrl(url);
                                                  }
                                                } else {
                                                  AppHelpers.showSnackBar(
                                                    'Bệnh nhân chưa có số điện thoại',
                                                    isError: true,
                                                  );
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.phone,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                              label: Text(
                                                item.dienthoai != null &&
                                                        item
                                                            .dienthoai!
                                                            .isNotEmpty
                                                    ? item.dienthoai!
                                                    : 'Trống SĐT',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                backgroundColor: const Color(
                                                  0xFF1274BC,
                                                ),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Nút Trả KQ
                                          if (isMyPatient) ...[
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () =>
                                                    _handleToggleState(item),
                                                icon: Icon(
                                                  isDaTra
                                                      ? Icons.cancel
                                                      : Icons.check,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                                label: Text(
                                                  isDaTra
                                                      ? 'Hủy trả KQ'
                                                      : 'Trả KQ',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  backgroundColor: isDaTra
                                                      ? Colors.red
                                                      : const Color.fromARGB(
                                                          255,
                                                          0,
                                                          155,
                                                          39,
                                                        ),
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, int? value) {
    bool isSelected = _selectedState == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
        onSelected: (selected) {
          setState(() => _selectedState = selected ? value : null);
          _fetchData();
        },
      ),
    );
  }
}
