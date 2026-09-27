import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/nuocthai_model.dart';
import '../providers/auth_provider.dart';
import '../services/nuocthai_service.dart';
import 'nuocthai_form_screen.dart';

class NuocThaiListScreen extends StatefulWidget {
  const NuocThaiListScreen({super.key});

  @override
  State<NuocThaiListScreen> createState() => _NuocThaiListScreenState();
}

class _NuocThaiListScreenState extends State<NuocThaiListScreen> {
  final NuocThaiService _service = NuocThaiService();
  final ScrollController _scrollController = ScrollController();
  
  List<NuocThai> _danhSach = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  String? _selectedChiNhanh; 
  DateTimeRange? _selectedDateRange;

  final List<Map<String, String>> _tatCaChiNhanh = [
    {'id': '', 'name': 'Tất cả'},
    {'id': 'BVHUNGVUONG', 'name': 'BV Hùng Vương'},
    {'id': 'KIMXUYEN', 'name': 'Kim Xuyên'},
    {'id': 'CHANMONG', 'name': 'Chân Mộng'},
    {'id': 'SONDUONG', 'name': 'Sơn Dương'},
    {'id': 'THANHBA', 'name': 'Thanh Ba'},
  ];

  String _getChiNhanhName(String id) {
    return _tatCaChiNhanh.firstWhere((cn) => cn['id'] == id, orElse: () => {'name': id})['name']!;
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({bool isLoadMore = false}) async {
    if (_isLoading) return;
    if (!isLoadMore) { setState(() { _currentPage = 1; _hasMore = true; _danhSach.clear(); }); }

    setState(() => _isLoading = true);
    try {
      final data = await _service.getDanhSachNuocThai(
        page: _currentPage, pageSize: _pageSize, chiNhanh: _selectedChiNhanh,
        fromDate: _selectedDateRange != null ? DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start) : null,
        toDate: _selectedDateRange != null ? DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end) : null,
      );
      setState(() {
        if (data.length < _pageSize) _hasMore = false;
        _danhSach.addAll(data);
        if (data.isNotEmpty) _currentPage++;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi tải dữ liệu!'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(NuocThai item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn muốn xóa bản ghi này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _service.deleteNuocThai(item.id!);
      if (success) { _fetchData(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa!'))); }
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final String myManv = auth.currentManv ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Quản lý Nước thải', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1274BC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter ngang
          Container(height: 60, color: Colors.white, child: ListView.separated(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _tatCaChiNhanh.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cn = _tatCaChiNhanh[index];
              return Center(child: FilterChip(label: Text(cn['name']!), selected: _selectedChiNhanh == cn['id'], onSelected: (val) { setState(() => _selectedChiNhanh = cn['id']); _fetchData(); }));
            },
          )),
          
          // Bộ lọc ngày
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFF1274BC), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDateRange == null 
                        ? "Chọn khoảng ngày" 
                        : "${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}",
                    ),
                    const Spacer(),
                    if (_selectedDateRange != null) IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () { setState(() => _selectedDateRange = null); _fetchData(); })
                  ],
                ),
              ),
            ),
          ),

          Expanded(child: RefreshIndicator(
            onRefresh: () => _fetchData(),
            child: _danhSach.isEmpty && !_isLoading
                ? ListView(children: const [SizedBox(height: 100), Center(child: Text('Không có dữ liệu'))])
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _danhSach.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _danhSach.length) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                
                final item = _danhSach[index];
                bool isOwner = item.maNhanVien == myManv;
                bool isAbnormal = item.batThuong == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: isAbnormal ? Colors.red.shade50 : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isAbnormal ? Colors.red.shade200 : Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isAbnormal ? Colors.red.shade100 : Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Text(_getChiNhanhName(item.chiNhanh ?? ''), style: TextStyle(fontWeight: FontWeight.bold, color: isAbnormal ? Colors.red.shade700 : Colors.blue.shade700))),
                          const Spacer(),
                          Text(item.ngay != null ? DateFormat('dd/MM/yyyy').format(item.ngay!) : '', style: TextStyle(color: Colors.grey.shade600)),
                          if (isAbnormal) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.error_outline, color: Colors.red, size: 18)),
                        ]),
                        const SizedBox(height: 12),
                        
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          _buildDataColumn("Cũ", "${item.chiSoCu ?? 0}"),
                          _buildDataColumn("Mới", "${item.chiSoMoi ?? 0}"),
                          _buildDataColumn("Lưu lượng", "${item.tong ?? 0}", isHighlighted: true),
                        ]),
                        
                        // ===== HIỂN THỊ GHI CHÚ TẠI ĐÂY =====
                        if (item.ghiChu != null && item.ghiChu!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isAbnormal ? Colors.red.shade100.withOpacity(0.5) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isAbnormal ? Colors.red.shade100 : Colors.grey.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.notes, size: 16, color: isAbnormal ? Colors.red.shade400 : Colors.grey.shade500),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.ghiChu!,
                                    style: TextStyle(fontSize: 13, color: isAbnormal ? Colors.red.shade800 : Colors.grey.shade700, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // ====================================

                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade200),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${item.maNhanVien ?? ''} - ${item.tennv ?? 'Admin'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            if (isOwner)
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () async { final r = await Navigator.push(context, MaterialPageRoute(builder: (c) => NuocThaiFormScreen(nuocThai: item))); if (r == true) _fetchData(); }),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(item)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF1274BC), child: const Icon(Icons.add, color: Colors.white), onPressed: () async { final r = await Navigator.push(context, MaterialPageRoute(builder: (c) => const NuocThaiFormScreen())); if (r == true) _fetchData(); }),
    );
  }
  
  Widget _buildDataColumn(String label, String value, {bool isHighlighted = false}) => Column(children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isHighlighted ? const Color(0xFF1274BC) : Colors.black87))]);
}