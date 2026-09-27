import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:provider/provider.dart';
import '../models/diennuoc_model.dart';
import '../providers/auth_provider.dart';
import '../services/diennuoc_service.dart';
import 'diennuoc_form_screen.dart';

class DienNuocListScreen extends StatefulWidget {
  const DienNuocListScreen({super.key});

  @override
  State<DienNuocListScreen> createState() => _DienNuocListScreenState();
}

class _DienNuocListScreenState extends State<DienNuocListScreen> {
  final DienNuocService _service = DienNuocService();
  final ScrollController _scrollController = ScrollController();
  
  List<DienNuoc> _danhSach = [];
  List<Map<String, dynamic>> _danhMucHoGiaDinh = []; 

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  int? _filterThang; 
  int? _filterNam;
  int? _filterIdHoGiaDinh;

  @override
  void initState() {
    super.initState();
    _loadDanhMuc();
    _fetchData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50 && !_isLoading && _hasMore) {
        _fetchData(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDanhMuc() async {
    final list = await _service.getDanhMucHoGiaDinh();
    if (mounted) setState(() => _danhMucHoGiaDinh = list);
  }

  Future<void> _fetchData({bool isLoadMore = false}) async {
    if (_isLoading) return;
    if (!isLoadMore) { setState(() { _currentPage = 1; _hasMore = true; _danhSach.clear(); }); }

    setState(() => _isLoading = true);
    
    final data = await _service.getDanhSach(
        page: _currentPage, 
        pageSize: _pageSize,
        thang: _filterThang,
        nam: _filterNam,
        idHoGiaDinh: _filterIdHoGiaDinh,
    );
    
    if (mounted) {
      setState(() {
        if (data.length < _pageSize) _hasMore = false;
        _danhSach.addAll(data);
        if (data.isNotEmpty) _currentPage++;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(DienNuoc item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn muốn xóa bản ghi này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _service.deleteDienNuoc(item.id!);
      if (success && mounted) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa thành công!')));
      }
    }
  }

  void _showMonthYearPicker() {
    int tempThang = _filterThang ?? DateTime.now().month;
    int tempNam = _filterNam ?? DateTime.now().year;
    List<int> years = [DateTime.now().year - 2, DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1];

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() { _filterThang = null; _filterNam = null; });
                      Navigator.pop(context);
                    },
                    child: const Text('BỎ LỌC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() { _filterThang = tempThang; _filterNam = tempNam; });
                      Navigator.pop(context);
                    },
                    child: const Text('XONG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1274BC))),
                  )
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: tempThang - 1),
                        itemExtent: 40,
                        onSelectedItemChanged: (idx) => tempThang = idx + 1,
                        children: List.generate(12, (index) => Center(child: Text('Tháng ${index + 1}', style: const TextStyle(fontSize: 18)))),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: years.indexOf(tempNam) != -1 ? years.indexOf(tempNam) : 2),
                        itemExtent: 40,
                        onSelectedItemChanged: (idx) => tempNam = years[idx],
                        children: years.map((y) => Center(child: Text('Năm $y', style: const TextStyle(fontSize: 18)))).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => _fetchData());
  }

  void _nhapTiep(DienNuoc item) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => DienNuocFormScreen(
      prefillIdHoGiaDinh: item.idHoGiaDinh,
      prefillSearchText: 'Phòng ${item.soPhong ?? ''} - ${item.hoGiaDinh ?? ''}', 
    )));
    if (result == true) _fetchData();
  }

  Widget _buildFilterBar() {
    String filterText = (_filterThang != null && _filterNam != null) 
        ? 'Tháng $_filterThang/$_filterNam' 
        : 'Tháng/Năm';

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: _showMonthYearPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Expanded(
                      child: Text(
                        filterText, 
                        style: TextStyle(
                          fontWeight: FontWeight.w600, 
                          color: _filterThang != null ? const Color(0xFF1274BC) : Colors.black87
                        ),
                        overflow: TextOverflow.ellipsis, 
                      ),
                    ),
                    const SizedBox(width: 4), 
                    Icon(Icons.calendar_month, color: _filterThang != null ? const Color(0xFF1274BC) : Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Autocomplete<Map<String, dynamic>>(
              displayStringForOption: (option) => option['name'],
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                return _danhMucHoGiaDinh.where((opt) => opt['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (selection) {
                setState(() => _filterIdHoGiaDinh = selection['id']);
                _fetchData(); 
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Tìm phòng...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    suffixIcon: _filterIdHoGiaDinh != null 
                      ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () { controller.clear(); setState(() => _filterIdHoGiaDinh = null); _fetchData(); })
                      : const Icon(Icons.search, size: 20),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final String myManv = auth.currentManv ?? '';
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Quản lý Điện Nước', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1274BC),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
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
                    bool isOwner = item.manv == myManv;
                    bool isLatest = item.isLatest ?? false; 

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text('Phòng ${item.soPhong ?? ''}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                                    ),
                                    const SizedBox(width: 8),
                                    if (item.khuVuc != null && item.khuVuc!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                                        child: Text(item.khuVuc!, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700, fontSize: 12)),
                                      ),
                                  ],
                                ),
                                Text('Tháng ${item.thang}/${item.nam}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            Text(item.hoGiaDinh ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: const [Icon(Icons.bolt, size: 16, color: Colors.orange), SizedBox(width: 4), Text('Điện', style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.bold))]),
                                        const SizedBox(height: 8),
                                        Text('Cũ: ${item.csdienCu ?? 0}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                        const SizedBox(height: 4),
                                        Text('Mới: ${item.csdienMoi ?? 0}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: const [Icon(Icons.water_drop, size: 16, color: Colors.blue), SizedBox(width: 4), Text('Nước', style: TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold))]),
                                        const SizedBox(height: 8),
                                        Text('Cũ: ${item.csnuocCu ?? 0}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                        const SizedBox(height: 4),
                                        Text('Mới: ${item.csnuocMoi ?? 0}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade200),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${item.manv ?? ''} - ${item.tennv ?? 'Admin'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                Row(
                                  children: [
                                    if (isLatest) 
                                      IconButton(icon: const Icon(Icons.add_chart, color: Colors.green, size: 24), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _nhapTiep(item)),
                                      
                                    // 🟢 ĐỒNG BỘ: CHỈ HIỂN THỊ SỬA XÓA KHI LÀ CHÍNH CHỦ VÀ LÀ BẢN GHI MỚI NHẤT
                                    if (isOwner && isLatest) ...[
                                      const SizedBox(width: 16),
                                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () async { final r = await Navigator.push(context, MaterialPageRoute(builder: (c) => DienNuocFormScreen(dienNuoc: item))); if (r == true) _fetchData(); }),
                                      const SizedBox(width: 16),
                                      IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _confirmDelete(item)),
                                    ]
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1274BC),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const DienNuocFormScreen()));
          if (result == true) _fetchData();
        },
      ),
    );
  }
}