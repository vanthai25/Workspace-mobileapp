import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../models/khoa_model.dart';
import '../models/taisan_dutru_model.dart';
import '../providers/auth_provider.dart';
import '../services/taisan_dutru_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'dutru_detail_screen.dart'; 

// =========================================================
// 1. MÀN HÌNH DANH SÁCH CHÍNH
// =========================================================
class DuTruListScreen extends StatefulWidget {
  const DuTruListScreen({super.key});

  @override
  State<DuTruListScreen> createState() => _DuTruListScreenState();
}

class _DuTruListScreenState extends State<DuTruListScreen> {
  final TaisanDutruService _apiService = TaisanDutruService();
  final Color primaryColor = const Color(0xFF1274BC);

  List<TaiSanDuTru> _list = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  final ScrollController _scrollCtrl = ScrollController();
  
  // --- CÁC BIẾN STATE BỘ LỌC ---
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _selectedStatus; 
  String? _selectedKhoa; 
  bool _onlyPriority = false;
  Timer? _debounce;
  bool _showFilters = false;

  List<Khoa> _listKhoa = [];

  @override
  void initState() {
    super.initState();
    _fetchKhoaList(); 
    
    // 🔥 ĐÃ CẬP NHẬT: Đợi cây Widget dựng xong để lấy Quyền, set mặc định Tab Của Tôi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roles = context.read<AuthProvider>().currentRoleIds;
      if (roles.contains(29)) {
        setState(() {
          _selectedStatus = -1; // -1 là ID quy ước cho tab "Của tôi"
        });
      }
      _fetchData(); // Bắt đầu tải dữ liệu sau khi set mặc định xong
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_isLoading && !_isFetchingMore && _hasMore) {
        _fetchMoreData();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchKhoaList() async {
    try {
      final response = await ApiClient().dio.get('${AppConstants.baseUrl}/Khoa'); 

      if (response.statusCode == 200) {
        var responseData = response.data['data'] ?? response.data; 
        
        if (responseData is List) {
          setState(() {
            _listKhoa = responseData.map((e) => Khoa.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi lấy danh sách khoa: $e');
    }
  }

  void _clearFilters() {
    final roles =
        context.read<AuthProvider>().currentRoleIds;

    setState(() {
      _searchQuery = '';
      _fromDate = null;
      _toDate = null;
      _selectedKhoa = null;
      _onlyPriority = false;

      _selectedStatus =
          roles.contains(29) ? -1 : null;
    });

    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; _currentPage = 1; _hasMore = true; });

    final myManv = context.read<AuthProvider>().currentManv;

    // 🔥 XỬ LÝ LOGIC TAB "CỦA TÔI"
    int? apiStatus = _selectedStatus == -1 ? null : _selectedStatus;
    String? apiMaHDTV = _selectedStatus == -1 ? myManv : null;

    final data = await _apiService.getTaiSanDuTrus(
      maPhieuDuTru: _searchQuery, 
      page: _currentPage, 
      pageSize: _pageSize,
      fromDate: _fromDate?.toIso8601String(),
      toDate: _toDate?.toIso8601String(),
      trangThaiPhieu: apiStatus,
      maKhoaDeNghi: _selectedKhoa, 
      maHDTVPhuTrach: apiMaHDTV, 
      mucUuTien: _onlyPriority ? 1 : null,
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
    
    final myManv = context.read<AuthProvider>().currentManv;

    // 🔥 XỬ LÝ LOGIC TAB "CỦA TÔI"
    int? apiStatus = _selectedStatus == -1 ? null : _selectedStatus;
    String? apiMaHDTV = _selectedStatus == -1 ? myManv : null;

    final newData = await _apiService.getTaiSanDuTrus(
      maPhieuDuTru: _searchQuery, 
      page: _currentPage, 
      pageSize: _pageSize,
      fromDate: _fromDate?.toIso8601String(),
      toDate: _toDate?.toIso8601String(),
      trangThaiPhieu: apiStatus,
      maKhoaDeNghi: _selectedKhoa,
      maHDTVPhuTrach: apiMaHDTV, 
      mucUuTien: _onlyPriority ? 1 : null,
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
      _searchQuery = val;
      _fetchData();
    });
  }

  // --- POPUP CHỌN NGÀY DẠNG IOS CUỘN ---
  void _showCupertinoDatePicker(BuildContext context, bool isFromDate) {
    DateTime initialDate = isFromDate ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now());
    DateTime tempPickedDate = initialDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (isFromDate) _fromDate = tempPickedDate;
                          else _toDate = tempPickedDate;
                        });
                        _fetchData();
                        Navigator.pop(context);
                      },
                      child: const Text('Xong', style: TextStyle(color: Color(0xFF1274BC), fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime(2030),
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- POPUP CHỌN KHOA / PHÒNG CÓ TÌM KIẾM ---
  void _showKhoaPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String localSearch = '';
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            var filteredList = _listKhoa.where((k) {
              final searchLower = localSearch.toLowerCase();
              return (k.tenkhoa ?? '').toLowerCase().contains(searchLower) ||
                     (k.makhoa ?? '').toLowerCase().contains(searchLower);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chọn Khoa/Phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc mã...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) => setModalState(() => localSearch = val),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (localSearch.isEmpty)
                          ListTile(
                            leading: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                              child: const Icon(Icons.home_work_outlined, size: 18, color: Colors.grey),
                            ),
                            title: Text('Tất cả Khoa/Phòng', style: TextStyle(fontWeight: _selectedKhoa == null ? FontWeight.bold : FontWeight.normal)),
                            trailing: _selectedKhoa == null ? const Icon(Icons.check_circle, color: Color(0xFF1274BC)) : null,
                            onTap: () {
                              setState(() => _selectedKhoa = null);
                              _fetchData();
                              Navigator.pop(context);
                            },
                          ),
                        ...filteredList.map((k) {
                          bool isSelected = _selectedKhoa == k.makhoa;
                          return Column(
                            children: [
                              const Divider(height: 1, indent: 60),
                              ListTile(
                                leading: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                  child: Text(k.makhoa?.substring(0, 1).toUpperCase() ?? 'K', style: const TextStyle(color: Color(0xFF1274BC), fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                                  alignment: Alignment.center,
                                ),
                                title: Text(k.tenkhoa ?? k.makhoa ?? '', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF1274BC)) : null,
                                onTap: () {
                                  setState(() => _selectedKhoa = k.makhoa);
                                  _fetchData();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  // 🔥 ĐÃ CẬP NHẬT: Thêm tab "Của tôi" (id: -1) cho quyền HĐTV
  List<Map<String, dynamic>> _getAvailableStatuses() {
    final roles = context.read<AuthProvider>().currentRoleIds;
    if (roles.contains(30)) { 
      return [
        {'id': null, 'name': 'Tất cả'},
        {'id': 5, 'name': 'Chờ TTMS nhận'},
        {'id': 6, 'name': 'TTMS đã nhận'},
      ];
    } else if (roles.contains(29)) { 
      return [
        {'id': -1, 'name': 'Của tôi'}, // Thêm tab này ở đầu
        {'id': null, 'name': 'Tất cả'},
        {'id': 4, 'name': 'Chờ HĐTV duyệt'},
        {'id': 5, 'name': 'HĐTV đã duyệt'},
        {'id': 8, 'name': 'HĐTV Từ chối'},
      ];
    } else { 
      return [
        {'id': null, 'name': 'Tất cả'},
        {'id': 0, 'name': 'Mới tạo'},
        {'id': 1, 'name': 'Chờ LĐ đơn vị duyệt'},
        {'id': 2, 'name': 'LĐ đơn vị Duyệt'},
        {'id': 3, 'name': 'QLTS Duyệt'},
        {'id': 4, 'name': 'Trình HĐTV'},
        {'id': 5, 'name': 'HĐTV Duyệt'},
        {'id': 6, 'name': 'TTMS Nhận'},
        {'id': 8, 'name': 'Bị từ chối'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.read<AuthProvider>().currentRoleIds;
    bool canFilterKhoa = roles.any((r) => [28, 29, 30].contains(r));
    var statuses = _getAvailableStatuses();
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF4FA5E5), Color(0xFF1274BC)]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
                          const Text('Phiếu Dự Trù', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      IconButton(
                        icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt, color: Colors.white),
                        onPressed: () => setState(() => _showFilters = !_showFilters),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: TextEditingController.fromValue(TextEditingValue(text: _searchQuery, selection: TextSelection.collapsed(offset: _searchQuery.length))),
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: "Tìm mã phiếu dự trù...",
                        prefixIcon: Icon(Icons.search, color: Colors.blue),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  if (_showFilters) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showCupertinoDatePicker(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_fromDate == null ? 'Từ ngày' : DateFormat('dd/MM/yyyy').format(_fromDate!), style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showCupertinoDatePicker(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_toDate == null ? 'Đến ngày' : DateFormat('dd/MM/yyyy').format(_toDate!), style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (canFilterKhoa) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showKhoaPicker,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedKhoa == null 
                                    ? "Tất cả Khoa/Phòng" 
                                    : (_listKhoa.firstWhere((k) => k.makhoa == _selectedKhoa, orElse: () => Khoa(makhoa: _selectedKhoa, tenkhoa: _selectedKhoa)).tenkhoa ?? _selectedKhoa!),
                                  style: TextStyle(color: _selectedKhoa == null ? Colors.black54 : Colors.black87, fontSize: 14, fontWeight: _selectedKhoa == null ? FontWeight.normal : FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Color(0xFF1274BC)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                        label: const Text('Xóa bộ lọc', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),

            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),

                  FilterChip(
                    selected: _onlyPriority,
                    showCheckmark: true,
                    checkmarkColor: Colors.white,
                    selectedColor: Colors.red,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _onlyPriority
                          ? Colors.red
                          : Colors.red.shade200,
                    ),
                    avatar: Icon(
                      Icons.priority_high_rounded,
                      size: 17,
                      color: _onlyPriority
                          ? Colors.white
                          : Colors.red,
                    ),
                    label: Text(
                      'Ưu tiên',
                      style: TextStyle(
                        color: _onlyPriority
                            ? Colors.white
                            : Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    onSelected: (bool selected) {
                      setState(() {
                        _onlyPriority = selected;
                      });

                      _fetchData();
                    },
                  ),

                  const SizedBox(width: 8),

                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.grey.shade300,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.only(right: 16),
                      itemCount: statuses.length,
                      itemBuilder: (context, index) {
                        final status = statuses[index];

                        final bool isSelected =
                            _selectedStatus == status['id'];

                        return Padding(
                          padding:
                              const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status['name']),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            visualDensity:
                                VisualDensity.compact,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedStatus = selected
                                    ? status['id']
                                    : null;
                              });

                              _fetchData();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _list.isEmpty
                      ? const Center(child: Text("Không có phiếu nào", style: TextStyle(fontSize: 16, color: Colors.grey)))
                      : RefreshIndicator(
                          onRefresh: _fetchData,
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            itemCount: _list.length + (_isFetchingMore ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == _list.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                              return DuTruCardWidget(phieu: _list[i], onRefresh: _fetchData);
                            },
                          ),
                        ),
            )
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 2. COMPONENT WIDGET THẺ HIỂN THỊ CÁ NHÂN
// =========================================================
class DuTruCardWidget extends StatefulWidget {
  final TaiSanDuTru phieu;
  final VoidCallback onRefresh;

  const DuTruCardWidget({super.key, required this.phieu, required this.onRefresh});

  @override
  State<DuTruCardWidget> createState() => _DuTruCardWidgetState();
}

class _DuTruCardWidgetState extends State<DuTruCardWidget> {
  final TaisanDutruService _apiService = TaisanDutruService();
  bool _isProcessing = false;

  // --- POPUP CHỌN HĐTV DUYỆT ---
  Future<String?> _showSelectHDTVDialog() async {
    String? selectedValue;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Chọn Lãnh đạo duyệt', style: TextStyle(fontSize: 18, color: Color(0xFF1274BC), fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Tổng GĐ Phạm Văn Học', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: '00001',
                  groupValue: selectedValue,
                  activeColor: const Color(0xFF1274BC),
                  onChanged: (val) => setStateSB(() => selectedValue = val),
                ),
                RadioListTile<String>(
                  title: const Text('Phó Tổng GĐ Trần Liên Việt', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: '00002',
                  groupValue: selectedValue,
                  activeColor: const Color(0xFF1274BC),
                  onChanged: (val) => setStateSB(() => selectedValue = val),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1274BC)),
                onPressed: selectedValue == null ? null : () => Navigator.pop(ctx, selectedValue),
                child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
              )
            ],
          );
        }
      )
    );
  }

  // --- POPUP NHẬP LÝ DO TỪ CHỐI ---
  Future<String?> _showRejectReasonDialog() async {
    TextEditingController reasonCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Từ chối duyệt', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập lý do từ chối...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                AppHelpers.showSnackBar('Vui lòng nhập lý do!', isError: true);
                return;
              }
              Navigator.pop(ctx, reasonCtrl.text.trim());
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- POPUP NHẬP GHI CHÚ KHI DUYỆT (HĐTV) ---
  Future<String?> _showApproveNoteDialog(String msgTitle) async {
    TextEditingController noteCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xác nhận $msgTitle', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn chắc chắn muốn $msgTitle phiếu này?', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú duyệt (không bắt buộc)...',
                hintStyle: const TextStyle(fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<Map<String, String>?> _showChuyenHDTVDialog({String? currentManvHdqt}) async {
    String? selectedValue;
    TextEditingController reasonCtrl = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Chuyển Lãnh đạo duyệt', style: TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn HĐTV nhận phiếu:', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (currentManvHdqt != '00001')
                    RadioListTile<String>(
                      title: const Text('Tổng GĐ Phạm Văn Học', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      value: '00001',
                      groupValue: selectedValue,
                      activeColor: Colors.orange,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setStateSB(() => selectedValue = val),
                    ),
                  if (currentManvHdqt != '00002')
                    RadioListTile<String>(
                      title: const Text('Phó Tổng GĐ Trần Liên Việt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      value: '00002',
                      groupValue: selectedValue,
                      activeColor: Colors.orange,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setStateSB(() => selectedValue = val),
                    ),
                  const SizedBox(height: 12),
                  const Text('Lý do chuyển:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Nhập lý do chuyển (không bắt buộc)...',
                      hintStyle: const TextStyle(fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: selectedValue == null ? null : () {
                  Navigator.pop(ctx, {
                    'mahdtv': selectedValue!,
                    'lydo': reasonCtrl.text.trim(),
                  });
                },
                child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
              )
            ],
          );
        }
      )
    );
  }

  Future<void> _xacNhanHanhDong(String actionEndpoint, String msgTitle, {bool isCancel = false}) async {
    String? mahdtvSelected;
    String? lydoThamSo; 
    String? ghichuThamSo;

    String? currentManv = widget.phieu.manvHdqt; 

    if (actionEndpoint == 'v2/trinhhdtv') {
      mahdtvSelected = await _showSelectHDTVDialog();
      if (mahdtvSelected == null) return;
    } 
    else if (actionEndpoint == 'chuyen-hdtv') {
      var result = await _showChuyenHDTVDialog(currentManvHdqt: currentManv);
      if (result == null) return;
      mahdtvSelected = result['mahdtv'];
      lydoThamSo = result['lydo'];
    } 
    else if (actionEndpoint == 'hdtv-tuchoi') {
      lydoThamSo = await _showRejectReasonDialog();
      if (lydoThamSo == null) return; 
    } 
    else if (actionEndpoint == 'hdtv-confirm') {
      ghichuThamSo = await _showApproveNoteDialog(msgTitle);
      if (ghichuThamSo == null) return; 
    } 
    else {
      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isCancel ? 'Xác nhận Hủy' : 'Xác nhận Duyệt', style: TextStyle(color: isCancel ? Colors.red : Colors.blue)),
          content: Text('Bạn chắc chắn muốn $msgTitle phiếu này?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Đóng', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isCancel ? Colors.red : Colors.blue),
              onPressed: () => Navigator.pop(ctx, true), 
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (actionEndpoint == 'hdtv-confirm' || actionEndpoint == 'hdtv-tuchoi' || actionEndpoint == 'huy-hdtv-confirm' || actionEndpoint == 'chuyen-hdtv') {
      final authProvider = context.read<AuthProvider>();
      bool processWithPassword = false;
      
      if (await authProvider.isBiometricSupported()) {
        final LocalAuthentication localAuth = LocalAuthentication();
        try {
          final bool didAuthenticate = await localAuth.authenticate(
            localizedReason: 'Vui lòng xác thực sinh trắc học để ${isCancel ? "từ chối/hủy" : "thao tác"} phiếu (Quyền HĐTV)',
            biometricOnly: true, 
          );
          if (!didAuthenticate) processWithPassword = true;
        } catch (e) {
          processWithPassword = true;
        }
      } else {
        processWithPassword = true;
      }

      if (processWithPassword) {
        String? password = await _yeuCauNhapMatKhauThayThe();
        if (password == null || password.isEmpty) {
          if (mounted) AppHelpers.showSnackBar('Đã hủy thao tác!', isError: true);
          return; 
        }

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF1274BC))),
          );
        }

        try {
          final manv = authProvider.currentManv ?? '';
          bool isPassCorrect = await authProvider.login(manv, password);
          if (mounted) Navigator.pop(context); 

          if (!isPassCorrect) {
            if (mounted) AppHelpers.showSnackBar('Mật khẩu xác thực không đúng!', isError: true);
            return; 
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); 
            AppHelpers.showSnackBar('Mật khẩu không chính xác hoặc lỗi kết nối!', isError: true);
          }
          return;
        }
      }
    }

    setState(() => _isProcessing = true);
    
    Map<String, dynamic> apiParams = {};
    if (mahdtvSelected != null) apiParams['mahdtv'] = mahdtvSelected;
    if (lydoThamSo != null && lydoThamSo.isNotEmpty) apiParams['lydo'] = lydoThamSo;
    if (ghichuThamSo != null && ghichuThamSo.isNotEmpty) apiParams['ghichu'] = ghichuThamSo;

    bool ok = await _apiService.updateTrangThaiDuTru(
      widget.phieu.maPhieuDuTru, 
      actionEndpoint,
      queryParams: apiParams.isNotEmpty ? apiParams : null,
    );
    
    if (ok) {
      if (mounted) {
        AppHelpers.showSnackBar('Thao tác thành công!', isError: false);
        widget.onRefresh(); 
      }
    } else {
      if (mounted) AppHelpers.showSnackBar('Lỗi hệ thống, thao tác thất bại!', isError: true);
    }
    
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<String?> _yeuCauNhapMatKhauThayThe() {
    final pwdController = TextEditingController();
    bool isVisible = false;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Xác thực mật khẩu', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sinh trắc học thất bại hoặc bị hủy. Vui lòng nhập mật khẩu tài khoản để tiếp tục thao tác!', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                TextField(
                  controller: pwdController,
                  obscureText: !isVisible,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setStateSB(() => isVisible = !isVisible),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () => Navigator.pop(context, pwdController.text),
                child: const Text('XÁC NHẬN', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildMiniButton(String title, Color color, String endpoint, {bool isCancel = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: _isProcessing ? null : () => _xacNhanHanhDong(endpoint, title, isCancel: isCancel),
          child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final int status = widget.phieu.trangThaiPhieu ?? 0;
    final String phieuMaKhoa = widget.phieu.maKhoaDeNghi ?? '';
    
    final auth = context.read<AuthProvider>();
    final roles = auth.currentRoleIds;
    final myKhoa = auth.currentMaKhoa ?? '';
    final myManv = auth.currentManv ?? '';

    List<Widget> buttons = [];

    if (status == 0 && phieuMaKhoa == myKhoa) {
      buttons.add(_buildMiniButton('TRÌNH LĐ ĐƠN VỊ', Colors.blue, 'trinhldkhoa'));
    } 
    else if (status == 1) {
      if (widget.phieu.maNguoiYeuCau == myManv) buttons.add(_buildMiniButton('HỦY TRÌNH', Colors.red, 'huy-trinhldkhoa', isCancel: true));
      if (roles.contains(27) && phieuMaKhoa == myKhoa) buttons.add(_buildMiniButton('LĐ ĐƠN VỊ DUYỆT', Colors.orange, 'ldkhoa-confirm'));
    } 
    else if (status == 2) {
      if (widget.phieu.nguoiDuyetDuTru == myManv) buttons.add(_buildMiniButton('LĐ ĐƠN VỊ HỦY', Colors.red, 'huy-ldkhoa-confirm', isCancel: true));
      if (roles.contains(28) && widget.phieu.duyetKho != true) buttons.add(_buildMiniButton('QLTS XÁC NHẬN', Colors.purple, 'kho-confirm'));
      
      if (roles.contains(27) && phieuMaKhoa == myKhoa && widget.phieu.duyetKho == true) buttons.add(_buildMiniButton('TRÌNH HĐTV', Colors.indigo, 'v2/trinhhdtv'));
    } 
    else if (status == 3) {
      if (widget.phieu.maNguoiTiepNhan == myManv) buttons.add(_buildMiniButton('QLTS HỦY', Colors.red, 'huy-kho-confirm', isCancel: true));
      
      if (roles.contains(28) && widget.phieu.maNguoiTiepNhan == myManv) buttons.add(_buildMiniButton('TRÌNH HĐTV', Colors.indigo, 'v2/trinhhdtv'));
    } 
    else if (status == 4) {
      if (widget.phieu.maNguoiTiepNhan == myManv || (widget.phieu.duyetKho == true && widget.phieu.nguoiDuyetDuTru == myManv)) {
        buttons.add(_buildMiniButton('HỦY TRÌNH HĐTV', Colors.red, 'huy-trinhhdtv', isCancel: true));
      }
      if (roles.contains(29) && widget.phieu.manvHdqt == myManv) {
        buttons.add(_buildMiniButton('TỪ CHỐI', Colors.red, 'hdtv-tuchoi', isCancel: true));
        buttons.add(_buildMiniButton('HĐTV DUYỆT', Colors.teal, 'hdtv-confirm'));
      }
    } 
    else if (status == 5) {
      if (widget.phieu.manvHdqt == myManv) {
        buttons.add(_buildMiniButton('HỦY DUYỆT', Colors.orange, 'huy-hdtv-confirm', isCancel: true));
        buttons.add(_buildMiniButton('TỪ CHỐI', Colors.red, 'hdtv-tuchoi', isCancel: true));
      }
      if (roles.contains(30)) buttons.add(_buildMiniButton('TTMS NHẬN', Colors.green, 'ttms-confirm'));
    } 
    else if (status == 6) {
      if (widget.phieu.manvTtms == myManv) buttons.add(_buildMiniButton('TTMS HỦY', Colors.red, 'huy-ttms-confirm', isCancel: true));
    }
    else if (status == 8) {
      if (roles.contains(29) && (widget.phieu.manvHdqt == myManv || widget.phieu.manvHdqt == null)) {
        buttons.add(_buildMiniButton('DUYỆT LẠI', Colors.teal, 'hdtv-confirm'));
      }
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: buttons,
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.grey;
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.purple;
      case 4: return Colors.indigo;
      case 5: return Colors.teal;
      case 6: return Colors.green;
      case 8: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Mới tạo';
      case 1: return 'Chờ LĐ Khoa';
      case 2: return 'LĐ Khoa Duyệt';
      case 3: return 'QLTS Duyệt';
      case 4: return 'Trình HĐTV';
      case 5: return 'HĐTV Duyệt';
      case 6: return 'TTMS Nhận';
      case 8: return 'HĐTV Từ chối';
      default: return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
      _getStatusColor(
    widget.phieu.trangThaiPhieu ?? 0,
  );

  final bool isPriority =
      widget.phieu.mucUuTien == 1;

    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, 
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: statusColor, width: 6)), 
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => DuTruDetailScreen(maPhieu: widget.phieu.maPhieuDuTru),
            )).then((_) => widget.onRefresh()); 
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.phieu.maPhieuDuTru,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Nhãn ưu tiên nằm bên trái trạng thái
                    if (isPriority) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade300,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.priority_high_rounded,
                              size: 13,
                              color: Colors.red,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'ƯU TIÊN',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Trạng thái phiếu
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(
                          widget.phieu.trangThaiPhieu ?? 0,
                        ),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.business, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Khoa: ${widget.phieu.tenKhoaDeNghi ?? "N/A"}', style: const TextStyle(fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(widget.phieu.ngayDuTru != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.phieu.ngayDuTru!)) : 'N/A', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  ],
                ),
                
                // HIỂN THỊ GHI CHÚ
                if (widget.phieu.ghiChuDuTru != null && widget.phieu.ghiChuDuTru!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Ghi chú: ${widget.phieu.ghiChuDuTru}', style: const TextStyle(fontSize: 14, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                
                if (_isProcessing) 
                  const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))))
                else 
                  _buildActionButtons()
              ],
            ),
          ),
        ),
      ),
    );
  }
}