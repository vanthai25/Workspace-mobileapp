import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/taisan_repair_model.dart';
import '../models/khoa_model.dart'; 
import '../providers/auth_provider.dart';
import '../services/taisan_repair_service.dart';
import '../services/khoa_service.dart';
// import 'package:barcode_scan2/barcode_scan2.dart';
import '../services/nhanvien_service.dart'; 
import '../utils/helpers.dart';
import 'create_repair_ticket_screen.dart';
import 'repair_card_widget.dart';
import 'repair_filter_modal.dart';
import 'scanner_screen.dart';

class RepairListScreen extends StatefulWidget {
  const RepairListScreen({super.key});

  @override
  State<RepairListScreen> createState() => _RepairListScreenState();
}

class _RepairListScreenState extends State<RepairListScreen> {
  final TaiSanRepairService _apiService = TaiSanRepairService();
  final KhoaService _khoaService = KhoaService();
  final NhanvienService _nhanVienService = NhanvienService(); 
  
  final Color primaryColor = const Color(0xFF1274BC);

  List<TaiSanRepair> _repairs = [];
  List<Khoa> _listKhoa = []; 

  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 5;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _khoaNhanSelected;
  String? _khoaLapSelected;
  Timer? _debounce;
  int? _statusSelected;

  final List<Map<String, dynamic>> _statusTabs = [
    {'value': null, 'text': 'Tất cả'},
    {'value': 0, 'text': 'Chờ tiếp nhận'},
    {'value': 2, 'text': 'Đang xử lý'},
    {'value': 4, 'text': 'Gửi vật tư'},
    {'value': 5, 'text': 'VT Tiếp nhận'},
    {'value': 6, 'text': 'VT Chuyển đi'},
    {'value': 7, 'text': 'Hàng về'},
    {'value': 9, 'text': 'Hoàn thành'},
  ];  
  @override
  void initState() {
    super.initState();
    _fetchKhoa();
    _fetchData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchKhoa() async {
    final khoaData = await _khoaService.getAllKhoa(); 
    if (mounted) setState(() => _listKhoa = khoaData);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isFetchingMore && _hasMore) _fetchMoreData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });
    final data = await _getApiData(page: _currentPage);
    if(mounted) {
      setState(() {
        _repairs = data;
        _isLoading = false;
        if (data.length < _pageSize) _hasMore = false;
      });
    }
  }

  Future<void> _fetchMoreData() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;
    final newData = await _getApiData(page: _currentPage);
    if(mounted){
      setState(() {
        _isFetchingMore = false;
        if (newData.isNotEmpty) _repairs.addAll(newData);
        if (newData.length < _pageSize) _hasMore = false;
      });
    }
  }

  Future<List<TaiSanRepair>> _getApiData({required int page}) async {
    String? fromStr = _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null;
    String? toStr = _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null;

    final authProvider = context.read<AuthProvider>();
    bool hasRole23 = authProvider.currentRoleIds.contains(23);
    bool hasRole25 = authProvider.currentRoleIds.contains(25);
    String? myKhoa = authProvider.currentMaKhoa;

    String? finalKhoaLap = _khoaLapSelected;
    String? finalKhoaNhan = _khoaNhanSelected;

    if (hasRole25) {
      // QUYỀN 25 (Vật tư): ĐƯỢC XEM TẤT CẢ
      finalKhoaLap = _khoaLapSelected;
      finalKhoaNhan = _khoaNhanSelected;
    } 
    else if (hasRole23) {
      // QUYỀN 23 (Kỹ thuật/CNTT): XEM PHIẾU KHOA MÌNH TIẾP NHẬN
      finalKhoaNhan = myKhoa;
    } 
    else {
      // NHÂN VIÊN BÌNH THƯỜNG: XEM PHIẾU DO KHOA MÌNH BÁO HỎNG
      finalKhoaLap = myKhoa; 
    }

    return await _apiService.getTaiSanRepairs(
      tentaisan: _searchQuery,
      fromDate: fromStr,
      toDate: toStr,
      khoanhan: finalKhoaNhan,
      khoalap: finalKhoaLap,
      trangthaiphieu: _statusSelected,
      page: page,
      pageSize: _pageSize,
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchQuery = query;
      _fetchData();
    });
  }
  Future<void> _scanQRCode() async {
    final String? maTaiSan = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (maTaiSan != null && maTaiSan.isNotEmpty) {
      setState(() {
        _searchController.text = maTaiSan;
        _searchQuery = maTaiSan;
      });
      
      _fetchData();
    }
  }

  // =======================================================
  // HỆ THỐNG LUÂN CHUYỂN TRẠNG THÁI CHUNG
  // =======================================================
  Future<void> _changeStatusFlow(TaiSanRepair repair, int newStatus) async {
    // 1. KỊCH BẢN TỪ 0 -> 2: CẦN POPUP CHỌN NGƯỜI XỬ LÝ
    if (newStatus == 2 && repair.trangthaiphieu == 0) {
      if (repair.khoanhan == null) {
        AppHelpers.showSnackBar('Phiếu này chưa cấu hình bộ phận tiếp nhận!', isError: true);
        return;
      }

      setState(() => _isLoading = true); 
      final employees = await _nhanVienService.getNhanVienByKhoa(repair.khoanhan!); 
      final currentManv = context.read<AuthProvider>().currentManv;
      String? selectedNguoiXuTri = currentManv;

      if(mounted) setState(() => _isLoading = false); 

      List<DropdownMenuItem<String>> dropdownItems = employees.map((nv) {
        return DropdownMenuItem<String>(
          value: nv.manv,
          child: Text('${nv.manv} - ${nv.tennv ?? ""}', overflow: TextOverflow.ellipsis),
        );
      }).toList();

      if (!employees.any((e) => e.manv == currentManv) && currentManv != null) {
        dropdownItems.insert(0, DropdownMenuItem<String>(
          value: currentManv,
          child: Text('$currentManv - Tôi (Ngoài bộ phận)'),
        ));
      }

      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.engineering_rounded, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Text('Tiếp nhận sửa chữa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bộ phận tiếp nhận: ${repair.tenKhoaNhan ?? repair.khoanhan}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedNguoiXuTri,
                    isExpanded: true,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    hint: const Text("Chọn người xử lý"),
                    items: dropdownItems,
                    onChanged: (val) => setDialogState(() => selectedNguoiXuTri = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Xác nhận nhận', style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        ),
      );

      if (confirm == true && selectedNguoiXuTri != null) {
        setState(() => _isLoading = true);
        try {
          final success = await _apiService.changeRepairStatus(repair.id!, 2, nguoixutri: selectedNguoiXuTri);
          if (success) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiếp nhận sửa chữa thành công!'), backgroundColor: Colors.green));
            _fetchData(); 
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi hệ thống tiếp nhận.'), backgroundColor: Colors.red));
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } 
    // 2. KỊCH BẢN BÁO HOÀN THÀNH (LÊN 9): CẦN POPUP NHẬP NỘI DUNG
    else if (newStatus == 9) {
      final TextEditingController noidungController = TextEditingController();

      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text('Nghiệm thu hoàn thành', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nội dung xử trí / Kết quả:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: noidungController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Nhập tình trạng máy sau khi sửa...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                if (noidungController.text.trim().isEmpty) {
                  AppHelpers.showSnackBar('Vui lòng nhập kết quả xử lý!', isError: true);
                  return;
                }
                Navigator.pop(ctx, true);
              }, 
              child: const Text('Hoàn tất', style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        try {
          final success = await _apiService.changeRepairStatus(repair.id!, 9, noidungxutri: noidungController.text.trim());
          if (success) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hoàn thành phiếu sửa chữa!'), backgroundColor: Colors.green));
            _fetchData();
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi cập nhật hệ thống.'), backgroundColor: Colors.red));
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } else if (newStatus == 6 && repair.trangthaiphieu == 5) {
      final TextEditingController noidungChuyenController = TextEditingController();

      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: Colors.purple.shade600),
              const SizedBox(width: 8),
              const Text('Chuyển vật tư đi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ghi chú chuyển đi:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: noidungChuyenController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "VD: Chuyển hãng bảo hành, gửi lên tuyến trên...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                if (noidungChuyenController.text.trim().isEmpty) {
                  AppHelpers.showSnackBar('Vui lòng nhập nơi chuyển đến!', isError: true);
                  return;
                }
                Navigator.pop(ctx, true);
              }, 
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true); 
        try {
          final success = await _apiService.changeRepairStatus(
            repair.id!, 
            6, 
            noidungchuyendi: noidungChuyenController.text.trim()
          );
          if (success) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật chuyển vật tư thành công!'), backgroundColor: Colors.green));
            await _fetchData(); 
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi cập nhật hệ thống.'), backgroundColor: Colors.red));
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
    // 3. KỊCH BẢN CHUYỂN TRẠNG THÁI KHÁC: CHỈ CẦN HỎI XÁC NHẬN
    else {
      String actionName = "";
      if (newStatus == 0) actionName = "Hủy tiếp nhận";
      else if (newStatus == 4) actionName = repair.trangthaiphieu == 5 ? "Hủy VT tiếp nhận" : "Gửi vật tư";
      else if (newStatus == 5) actionName = repair.trangthaiphieu == 6 ? "Hủy VT chuyển đi" : "Vật tư tiếp nhận";
      else if (newStatus == 6 && repair.trangthaiphieu == 7) actionName = "Hủy hàng về";
      else if (newStatus == 7) actionName = "Báo hàng về";
      else if (newStatus == 2) {
        if (repair.trangthaiphieu == 4) actionName = "Hủy gửi vật tư";
        if (repair.trangthaiphieu == 9) actionName = "Hủy hoàn thành";
      }

      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(actionName, style: TextStyle(color: newStatus < repair.trangthaiphieu! ? Colors.red : Colors.blue.shade700, fontWeight: FontWeight.bold)),
          content: const Text('Bạn có chắc chắn muốn thực hiện thao tác này?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Đóng', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: newStatus < repair.trangthaiphieu! ? Colors.red : Colors.blue.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        try {
          final success = await _apiService.changeRepairStatus(repair.id!, newStatus);
          if (success) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật trạng thái thành công!'), backgroundColor: Colors.green));
            _fetchData();
          } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại, vui lòng kiểm tra lại quyền!'), backgroundColor: Colors.red));
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _deleteTicket(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cảnh báo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa phiếu #$id không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa phiếu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _apiService.deleteTaiSanRepair(id);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phiếu thành công!'), backgroundColor: Colors.green));
        _fetchData();
      } else {
        if(mounted) setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi hệ thống, không thể xóa phiếu.'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _editTicket(TaiSanRepair repair) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRepairTicketScreen(editTicket: repair))
    );
    if (result == true) _fetchData();
  }

  // --- CẬP NHẬT MÀU SẮC ĐỒNG BỘ MÁY TRẠNG THÁI ---
  Map<String, dynamic> _getStatusConfig(int? status) {
    switch (status) {
      case 0: return {'text': 'Chờ tiếp nhận', 'color': Colors.blue, 'icon': Icons.fiber_new_rounded};
      case 2: return {'text': 'Đang xử lý', 'color': Colors.purple, 'icon': Icons.autorenew_rounded};
      case 4: return {'text': 'Đã gửi vật tư', 'color': Colors.orange.shade700, 'icon': Icons.inventory_rounded};
      case 5: return {'text': 'VT Đã tiếp nhận', 'color': Colors.teal, 'icon': Icons.move_to_inbox_rounded};
      case 6: return {'text': 'VT Đã chuyển đi', 'color': Colors.indigo, 'icon': Icons.local_shipping_rounded};
      case 7: return {'text': 'Hàng về', 'color': Colors.amber.shade800, 'icon': Icons.system_update_alt_rounded};
      case 9: return {'text': 'Hoàn thành', 'color': Colors.green, 'icon': Icons.check_circle_rounded};
      default: return {'text': 'Chưa xác định', 'color': Colors.grey, 'icon': Icons.help_outline};
    }
  }

  Map<String, dynamic> _getPriorityConfig(int? priority) {
    switch (priority) {
      case 3: return {'text': 'Gấp', 'color': Colors.red};
      case 2: return {'text': 'Ưu tiên', 'color': Colors.orange};
      default: return {'text': 'Bình thường', 'color': Colors.transparent};
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return RepairFilterModal(
          initFromDate: _fromDate,
          initToDate: _toDate,
          initKhoaLap: _khoaLapSelected,
          initKhoaNhan: _khoaNhanSelected,
          listKhoa: _listKhoa,
          onApplyFilter: (fromDate, toDate, khoaLap, khoaNhan) {
            setState(() {
              _fromDate = fromDate;
              _toDate = toDate;
              _khoaLapSelected = khoaLap;
              _khoaNhanSelected = khoaNhan;
            });
            _fetchData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRepairTicketScreen()));
          if (result == true) _fetchData();
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tạo phiếu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildCustomHeader(),
          _buildHorizontalStatusFilter(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _repairs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        color: primaryColor,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 16, bottom: 80, left: 16, right: 16),
                          itemCount: _repairs.length + (_isFetchingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _repairs.length) {
                              return Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(color: primaryColor)));
                            }
                            final repair = _repairs[index];
                            return RepairCardWidget(
                              repair: repair,
                              statusObj: _getStatusConfig(repair.trangthaiphieu),
                              priorityObj: _getPriorityConfig(repair.mucuutien),
                              onRefresh: _fetchData,
                              onEdit: _editTicket,
                              onDelete: _deleteTicket,
                              onChangeStatus: _changeStatusFlow, // Truyền hàm đa năng
                            );
                          },
                        ),
                      ),
          )
        ],
      ),
      ),
    );
  }
  Widget _buildHorizontalStatusFilter() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusTabs.length,
        itemBuilder: (context, index) {
          final tab = _statusTabs[index];
          final isSelected = _statusSelected == tab['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                tab['text'],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              elevation: isSelected ? 2 : 0,
              pressElevation: 0,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _statusSelected = tab['value'];
                  });
                  _fetchData();
                }
              },
            ),
          );
        },
      ),
    );
  }
  Widget _buildCustomHeader() {
    bool hasActiveFilter = _fromDate != null || _toDate != null || _khoaNhanSelected != null || _khoaLapSelected != null;

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF4FA5E5), Color(0xFF1274BC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 16),
              const Text('Danh sách sửa chữa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Tìm theo tên tài sản...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1274BC)),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1274BC), size: 24),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              _scanQRCode();
                            },
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _showFilterModal,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Stack(
                    children: [
                      const Icon(Icons.filter_list_rounded, color: Colors.white),
                      if (hasActiveFilter)
                        Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: primaryColor, width: 2)))),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text("Không tìm thấy phiếu nào", style: TextStyle(color: Color(0xFF2C3E50), fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}