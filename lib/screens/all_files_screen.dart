import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
// import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/taptin_model.dart';
import '../services/taptin_service.dart';
import '../utils/constants.dart';
// import '../providers/auth_provider.dart';

class AllFilesScreen extends StatefulWidget {
  const AllFilesScreen({super.key});

  @override
  State<AllFilesScreen> createState() => _AllFilesScreenState();
}

class _AllFilesScreenState extends State<AllFilesScreen> {
  final TaptinService _apiService = TaptinService();
  List<TapTin> _files = [];
  
  bool _isLoading = true; 
  bool _isLoadMore = false; 
  bool _hasMore = true; 
  int _currentPage = 1;
  final int _pageSize = 15; 
  final ScrollController _scrollController = ScrollController();

  // Bộ lọc
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _selectedLoaiId;
  Timer? _debounce;
  
  // Biến theo dõi ID file đang tải để hiển thị loading
  int? _downloadingFileId;

  final Color primaryColor = const Color(0xFF1274BC);

  final List<Map<String, dynamic>> _categories = [
    {'id': null, 'name': 'Tất cả'},
    {'id': 1, 'name': 'Chính sách miễn giảm'},
    {'id': 11, 'name': 'Quyết định - Công văn'},
    {'id': 2, 'name': 'Khen thưởng - Kỷ luật'},
    {'id': 3, 'name': 'Lịch trực'},
    {'id': 4, 'name': 'Thông tin thuốc'},
    {'id': 5, 'name': 'Thực đơn dinh dưỡng'},
    {'id': 6, 'name': 'Thông báo'},
    {'id': 7, 'name': 'Quy chế - Kế hoạch'},
    {'id': 8, 'name': 'Điều động nhân sự'},
    {'id': 9, 'name': 'Lịch đào tạo - Lịch làm việc'},
    {'id': 10, 'name': 'Khác'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchFiles(); // Load trang 1
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadMore && _hasMore) {
        _fetchFiles(isLoadMore: true); 
      }
    }
  }

  Future<void> _fetchFiles({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() {
        _isLoadMore = true;
        _currentPage++; 
      });
    } else {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
        _files.clear();
      });
    }
    
    String? fromDateStr = _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null;
    String? toDateStr = _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null;

    try {
      final results = await _apiService.searchTapTin(
        keyword: _searchQuery,
        fromDate: fromDateStr,
        toDate: toDateStr,
        loaiId: _selectedLoaiId,
        page: _currentPage, 
        pageSize: _pageSize, 
      );

      setState(() {
        if (isLoadMore) {
          _files.addAll(results); 
          _isLoadMore = false;
        } else {
          _files = results; 
          _isLoading = false;
        }

        if (results.length < _pageSize) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        if (isLoadMore) _isLoadMore = false;
        else _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchQuery = query;
      _fetchFiles();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)), child: child!),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate != null && _fromDate!.isAfter(_toDate!)) _toDate = null;
        } else {
          _toDate = picked;
        }
      });
      _fetchFiles();
    }
  }

  // --- HÀM TẢI VỀ VÀ MỞ FILE NATIVE ---
  Future<void> _downloadAndOpenFile(TapTin file) async {
    if (file.id == null) return;
    
    // Tự sinh tên file nếu api không trả về đuôi
    String fileName = file.tenTapTin ?? 'vanban_${file.id}';
    if (!fileName.contains('.')) {
      if (file.duongDan != null && file.duongDan!.contains('.')) {
        fileName += '.${file.duongDan!.split('.').last}';
      } else {
        fileName += '.pdf'; // Fallback mặc định
      }
    }

    setState(() => _downloadingFileId = file.id);

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final url = '${AppConstants.baseUrl}/Taptin/download/${file.id}';

      final response = await http.get(
        Uri.parse(url),
        headers: { if (token != null) 'Authorization': 'Bearer $token' },
      );

      if (response.statusCode == 200) {
        // Lưu vào thư mục tạm của điện thoại
        final dir = await getTemporaryDirectory();
        final localFile = File('${dir.path}/$fileName');
        await localFile.writeAsBytes(response.bodyBytes);
        
        // Mở file
        final result = await OpenFile.open(localFile.path);
        
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy ứng dụng đọc loại file này.'), backgroundColor: Colors.orange)
          );
        }
      } else {
        throw Exception("Lỗi tải file (${response.statusCode})");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải file, vui lòng thử lại!'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingFileId = null);
      }
    }
  }

  Future<void> _viewFile(TapTin file) async {
    if (file.id == null) return;
    bool isPdf = (file.duongDan ?? '').toLowerCase().endsWith('.pdf');
    if (!isPdf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ hỗ trợ xem trực tiếp văn bản định dạng PDF. Hãy nhấn "Tải về" để xem file này!'), 
          backgroundColor: Colors.orange,
        )
      );
      return; 
    }
    
    _apiService.recordViewDoc(file.id!);

    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    
    final url = '${AppConstants.baseUrl}/Taptin/download/${file.id}';

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0.5, 
            backgroundColor: Colors.white, 
            centerTitle: true,
            title: Text(
              file.tenTapTin ?? 'Chi tiết văn bản', 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20), 
              onPressed: () => Navigator.of(context).pop()
            ),
          ),
          body: SafeArea(
            child: SfPdfViewer.network(
              url, 
              headers: {'Authorization': 'Bearer $token'}, 
              canShowScrollHead: false,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB), 
      body: Column(
        children: [
          _buildCustomHeader(),
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1274BC)))
              : _files.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController, 
                    padding: const EdgeInsets.only(top: 8, bottom: 100), 
                    itemCount: _files.length + (_isLoadMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      
                      if (i == _files.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF1274BC)),
                          ),
                        );
                      }

                      final file = _files[i];
                      String displayDate = 'Chưa cập nhật';
                      if (file.ngayUp != null && file.ngayUp!.length >= 10) {
                        try { displayDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(file.ngayUp!)); } catch (_) {}
                      }

                      bool isPdf = (file.duongDan ?? '').toLowerCase().endsWith('.pdf');
                      String categoryName = file.tenLoai ?? 'Khác';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [BoxShadow(color: const Color(0xFF1274BC).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 5))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _viewFile(file), // Vẫn giữ ấn vào thẻ để mở chi tiết PDF
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isPdf ? const Color(0xFFFFF0F0) : const Color(0xFFF0F8FF), 
                                      borderRadius: BorderRadius.circular(16)
                                    ),
                                    child: Icon(
                                      isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded, 
                                      color: isPdf ? const Color(0xFFE53935) : primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                              child: Text(categoryName, style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade400),
                                                const SizedBox(width: 4),
                                                Text(displayDate, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          file.tenTapTin ?? 'Văn bản không tên', 
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2C3E50), height: 1.4),
                                          maxLines: 3, overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // 🔥 HÀNG NÚT THAO TÁC MỚI (XEM ONLINE & TẢI VỀ)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (isPdf) ...[
                                              InkWell(
                                                onTap: () => _viewFile(file),
                                                borderRadius: BorderRadius.circular(20),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.visibility, size: 16, color: primaryColor),
                                                      const SizedBox(width: 4),
                                                      Text("Xem online", style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            
                                            if (_downloadingFileId == file.id)
                                              const Padding(
                                                padding: EdgeInsets.only(right: 12, left: 8),
                                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
                                              )
                                            else
                                              InkWell(
                                                onTap: () => _downloadAndOpenFile(file),
                                                borderRadius: BorderRadius.circular(20),
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.download_rounded, size: 16, color: Colors.green),
                                                      SizedBox(width: 4),
                                                      Text("Tải về", style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      // Thu nhỏ padding trên, dưới, trái, phải
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 16, right: 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Văn bản nội bộ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
              if (_fromDate != null || _toDate != null || _searchQuery.isNotEmpty || _selectedLoaiId != null)
                InkWell(
                  onTap: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                      _searchQuery = '';
                      _selectedLoaiId = null;
                    });
                    _fetchFiles();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, color: Colors.red, size: 14),
                        SizedBox(width: 4),
                        Text('Xóa lọc', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(height: 12), 
          
          Container(
            height: 42, 
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "Tìm kiếm văn bản, thông báo...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12), 
                isDense: true, 
              ),
            ),
          ),
          const SizedBox(height: 10), 
          
          // Bộ lọc ngày
          Row(
            children: [
              Expanded(child: _buildDateFilterBtn("Từ ngày", _fromDate, () => _selectDate(context, true))),
              const SizedBox(width: 10),
              Expanded(child: _buildDateFilterBtn("Đến ngày", _toDate, () => _selectDate(context, false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBtn(String hint, DateTime? date, VoidCallback onTap) {
    bool hasDate = date != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        // Giảm padding dọc để nút ngày mỏng hơn
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: hasDate ? primaryColor.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasDate ? primaryColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              hasDate ? DateFormat('dd/MM/yyyy').format(date) : hint,
              style: TextStyle(color: hasDate ? primaryColor : Colors.grey.shade600, fontSize: 13, fontWeight: hasDate ? FontWeight.bold : FontWeight.w500),
            ),
            Icon(Icons.calendar_month_rounded, color: hasDate ? primaryColor : Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: _categories.map((cat) {
            bool isSelected = _selectedLoaiId == cat['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8), 
              child: ChoiceChip(
                label: Text(
                  cat['name'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: primaryColor,
                checkmarkColor: Colors.white, 
                backgroundColor: Colors.grey.shade100,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onSelected: (bool selected) {
                  setState(() => _selectedLoaiId = cat['id']);
                  _fetchFiles(); 
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), shape: BoxShape.circle),
          child: Icon(Icons.folder_off_rounded, size: 64, color: primaryColor.withOpacity(0.5)),
        ),
        const SizedBox(height: 20),
        const Text("Không tìm thấy văn bản", style: TextStyle(color: Color(0xFF2C3E50), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text("Thử thay đổi từ khóa hoặc khoảng thời gian", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      ],
    );
  }
}