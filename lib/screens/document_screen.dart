import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../models/taptin_model.dart';
import '../services/taptin_service.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final TaptinService _apiService = TaptinService();
  final Color primaryColor = const Color(0xFF1274BC);
  
  List<TapTin> _allFiles = [];
  List<TapTin> _filteredFiles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _downloadingFileId; 

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final list = await _apiService.getAllTapTin();
      
      // Sắp xếp ngày mới nhất lên đầu
      list.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a.ngayUp ?? '') ?? DateTime(1970);
        DateTime dateB = DateTime.tryParse(b.ngayUp ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA); 
      });

      setState(() {
        _allFiles = list;
        _filteredFiles = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _filteredFiles = _allFiles.where((file) {
        final ten = (file.tenTapTin ?? '').toLowerCase();
        final mota = (file.moTa ?? '').toLowerCase();
        final search = query.toLowerCase();
        return ten.contains(search) || mota.contains(search);
      }).toList();
    });
  }

  // --- XỬ LÝ TẢI VÀ MỞ FILE ---
  Future<void> _handleDownloadAndOpen(TapTin file) async {
    if (file.id == null) return;
    
    // Tự sinh tên file nếu api không trả về đuôi file rõ ràng
    String fileName = file.tenTapTin ?? 'document_${file.id}';
    if (!fileName.contains('.')) {
      // Nếu tên file không có đuôi (VD: .pdf), ta nội suy từ đường dẫn
      if (file.duongDan != null && file.duongDan!.contains('.')) {
        fileName += '.${file.duongDan!.split('.').last}';
      } else {
        fileName += '.pdf'; // Fallback mặc định
      }
    }

    setState(() => _downloadingFileId = file.id);

    try {
      // 1. Gọi hàm tải file
      String? localPath = await _apiService.downloadFile(file.id!, fileName);
      
      if (localPath != null) {
        // 2. Mở file bằng ứng dụng mặc định của điện thoại
        final result = await OpenFile.open(localPath);
        
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy ứng dụng để mở loại file này.'), backgroundColor: Colors.orange)
          );
        }
      } else {
        throw Exception("Lỗi tải file");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải file, vui lòng thử lại!'), backgroundColor: Colors.red)
        );
      }
    } finally {
      setState(() => _downloadingFileId = null);
    }
  }

  // Lấy icon tương ứng với loại file
  IconData _getFileIcon(String? path) {
    String p = (path ?? '').toLowerCase();
    if (p.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (p.endsWith('.doc') || p.endsWith('.docx')) return Icons.description;
    if (p.endsWith('.xls') || p.endsWith('.xlsx')) return Icons.table_chart;
    if (p.endsWith('.png') || p.endsWith('.jpg') || p.endsWith('.jpeg')) return Icons.image;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Văn bản & Tài liệu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên văn bản, mô tả...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                        TextButton(onPressed: _fetchFiles, child: const Text("Thử lại"))
                      ],
                    ),
                  )
                : _filteredFiles.isEmpty
                  ? const Center(child: Text('Không tìm thấy tài liệu nào.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredFiles.length,
                      itemBuilder: (context, index) {
                        return _buildFileCard(_filteredFiles[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(TapTin file) {
    String dateDisplay = file.ngayUp ?? '';
    if (dateDisplay.isNotEmpty) {
      try {
        DateTime parsed = DateTime.parse(dateDisplay);
        dateDisplay = DateFormat('dd/MM/yyyy').format(parsed);
      } catch (_) {}
    }

    bool isDownloading = _downloadingFileId == file.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(_getFileIcon(file.duongDan ?? file.tenTapTin), color: primaryColor, size: 28),
        ),
        title: Text(
          file.tenTapTin ?? 'Tài liệu không tên', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50)),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (file.moTa != null && file.moTa!.isNotEmpty)
              Text(file.moTa!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text('Ngày đăng: $dateDisplay', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: isDownloading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.green),
              onPressed: () => _handleDownloadAndOpen(file),
            ),
        onTap: () => _handleDownloadAndOpen(file),
      ),
    );
  }
}