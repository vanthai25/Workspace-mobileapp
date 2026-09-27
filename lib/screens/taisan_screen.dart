import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
// import 'package:barcode_scan2/barcode_scan2.dart'; 
import '../models/tai_san_model.dart';
import '../services/taisan_service.dart';
import '../providers/auth_provider.dart';
// import '../utils/helpers.dart'; 
import 'create_repair_ticket_screen.dart';
import 'scanner_screen.dart';

class TaiSanScreen extends StatefulWidget {
  const TaiSanScreen({super.key});

  @override
  State<TaiSanScreen> createState() => _TaiSanScreenState();
}

class _TaiSanScreenState extends State<TaiSanScreen> {
  final TaiSanService _taiSanService = TaiSanService();
  final Color primaryColor = const Color(0xFF1274BC);

  List<TaiSan> _danhSachTaiSan = [];
  bool _isLoading = true;
  bool _isFetchingMore = false; 
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
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

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isFetchingMore && _hasMore) {
        _fetchMoreData();
      }
    }
  }

  Future<List<TaiSan>> _getSmartData(int page) async {
    List<TaiSan> results = [];
    final myKhoa = context.read<AuthProvider>().currentMaKhoa?.toUpperCase().trim() ?? '';
    
    // 1. TÌM KIẾM
    if (_searchQuery.isNotEmpty) {
      final responses = await Future.wait([
        _taiSanService.getDanhSachTaiSan(tentaisan: _searchQuery, page: page, pageSize: _pageSize),
        _taiSanService.getDanhSachTaiSan(maTaiSan: _searchQuery, page: page, pageSize: _pageSize),
      ]);

      final Map<String, TaiSan> uniqueMap = {};
      for (var item in responses[0]) uniqueMap[item.maTaiSan ?? ''] = item;
      for (var item in responses[1]) uniqueMap[item.maTaiSan ?? ''] = item;
      
      results = uniqueMap.values.toList();
    } 
    // 2. MẶC ĐỊNH
    else {
      if (page == 1 && myKhoa.isNotEmpty) {
        final responses = await Future.wait([
          _taiSanService.getDanhSachTaiSan(makhoa: myKhoa, page: 1, pageSize: 200), 
          _taiSanService.getDanhSachTaiSan(page: page, pageSize: _pageSize), 
        ]);

        results = [...responses[0]];
        results.addAll(responses[1].where((item) => item.makhoa?.toUpperCase().trim() != myKhoa));
      } else {
        final generalAssets = await _taiSanService.getDanhSachTaiSan(page: page, pageSize: _pageSize);
        results = generalAssets.where((item) => item.makhoa?.toUpperCase().trim() != myKhoa).toList();
      }
    }

    if (mounted) {
      results.sort((a, b) {
        bool aIsMyKhoa = a.makhoa?.toUpperCase().trim() == myKhoa || a.makhoaNavigation?.makhoa?.toUpperCase().trim() == myKhoa;
        bool bIsMyKhoa = b.makhoa?.toUpperCase().trim() == myKhoa || b.makhoaNavigation?.makhoa?.toUpperCase().trim() == myKhoa;
        if (aIsMyKhoa && !bIsMyKhoa) return -1;
        if (!aIsMyKhoa && bIsMyKhoa) return 1; 
        return 0; 
      });
    }

    return results;
  }

  Future<void> _fetchData({bool isRefresh = false}) async {
    if (!isRefresh) setState(() => _isLoading = true);
    
    _currentPage = 1;
    _hasMore = true;

    final data = await _getSmartData(_currentPage);

    if (mounted) {
      setState(() {
        _danhSachTaiSan = data; 
        _isLoading = false;
        if (data.length < _pageSize && _searchQuery.isEmpty) _hasMore = false; 
      });
    }
  }

  Future<void> _fetchMoreData() async {
    setState(() => _isFetchingMore = true);
    _currentPage++;

    final newData = await _getSmartData(_currentPage);

    if (mounted) {
      setState(() {
        _isFetchingMore = false;
        if (newData.isNotEmpty) {
          final existingIds = _danhSachTaiSan.map((e) => e.maTaiSan).toSet();
          final filteredNewData = newData.where((e) => !existingIds.contains(e.maTaiSan)).toList();
          _danhSachTaiSan.addAll(filteredNewData);
        }
        if (newData.length < _pageSize) _hasMore = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        _searchQuery = query;
        _fetchData(); 
      }
    });
  }

  // --- HÀM QUÉT QR ĐƯỢC THÊM VÀO ---
  Future<void> _scanQRCode() async {
    // Mở màn hình quét mới và chờ kết quả
    final String? maTaiSan = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    // Nếu quét thành công, cập nhật ô tìm kiếm và load lại data
    if (maTaiSan != null && maTaiSan.isNotEmpty) {
      setState(() {
        _searchController.text = maTaiSan;
        _searchQuery = maTaiSan;
      });
      
      // Gọi lại API tìm kiếm với mã vừa quét được
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
    onTap: () {
      FocusScope.of(context).unfocus();
    },
    child: Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Danh sách Tài sản', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          
          if (_isLoading && _danhSachTaiSan.isNotEmpty)
            LinearProgressIndicator(
              backgroundColor: Colors.blue.shade50,
              color: primaryColor,
              minHeight: 3,
            ),

          Expanded(
            child: _isLoading && _danhSachTaiSan.isEmpty
                ? Center(child: CircularProgressIndicator(color: primaryColor)) 
                : _danhSachTaiSan.isEmpty
                    ? _buildEmptyState()
                    : AnimatedOpacity(
                        opacity: _isLoading ? 0.4 : 1.0, 
                        duration: const Duration(milliseconds: 250),
                        child: RefreshIndicator(
                            onRefresh: () => _fetchData(isRefresh: true),
                            color: primaryColor,
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _danhSachTaiSan.length + (_isFetchingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _danhSachTaiSan.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(child: CircularProgressIndicator(color: primaryColor)),
                                  );
                                }
                                return _buildTaiSanCard(_danhSachTaiSan[index]);
                              },
                            ),
                          ),
                      ),
          ),
        ],
      ),
    ),
  );
  }

  // --- THANH TÌM KIẾM ĐƯỢC CẬP NHẬT ---
  Widget _buildSearchBar() {
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Tìm theo tên hoặc mã tài sản...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min, // Giữ cho Row nhỏ gọn theo chiều ngang
            children: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                  iconSize: 20,
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
              // Nút quét mã QR
              IconButton(
                icon: Icon(Icons.qr_code_scanner_rounded, color: primaryColor, size: 24),
                onPressed: () {
                  FocusScope.of(context).unfocus(); // Đóng bàn phím khi mở camera
                  _scanQRCode();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildTaiSanCard(TaiSan taiSan) {
    final myKhoa = context.read<AuthProvider>().currentMaKhoa?.toUpperCase().trim() ?? '';
    final isMyKhoa = taiSan.makhoa?.toUpperCase().trim() == myKhoa;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isMyKhoa ? 3 : 1, 
      color: isMyKhoa ? Colors.blue.shade50 : Colors.white, 
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: isMyKhoa ? primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.inventory_2_rounded, color: isMyKhoa ? primaryColor : Colors.grey.shade600, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(taiSan.tentaisan ?? 'Chưa có tên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isMyKhoa ? primaryColor : const Color(0xFF2C3E50)), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                          if (isMyKhoa) const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.qr_code_rounded, 'Mã:', taiSan.maTaiSan ?? 'N/A'),
                      _buildInfoRow(Icons.apartment_rounded, 'Khoa:', taiSan.makhoaNavigation?.tenkhoa ?? taiSan.makhoa ?? 'N/A'),
                      if (taiSan.model != null && taiSan.model!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildInfoRow(Icons.memory_rounded, 'Model:', taiSan.model!),
                      ],
                      
                      if (taiSan.seri != null && taiSan.seri!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildInfoRow(Icons.confirmation_number_rounded, 'Seri:', taiSan.seri!),
                      ],

                      if (taiSan.viTriSuDung != null && taiSan.viTriSuDung!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildInfoRow(Icons.location_on_rounded, 'Vị trí:', taiSan.viTriSuDung!),
                      ]
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // 🟢 NÚT BÁO SỬA CHỮA
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.build_rounded, size: 18),
                label: const Text("BÁO SỬA CHỮA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateRepairTicketScreen(
                        initialTaiSan: taiSan, 
                      ),
                    ),
                  ).then((value) {

                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text('$label ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_rounded, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text("Không tìm thấy tài sản nào", style: TextStyle(color: Color(0xFF2C3E50), fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}