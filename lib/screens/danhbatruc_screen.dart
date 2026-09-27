import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class DanhBaTrucScreen extends StatefulWidget {
  const DanhBaTrucScreen({super.key});

  static List<dynamic>? cachedDanhBaList;
  static Future<void> preloadData() async {
    if (cachedDanhBaList != null) return; 
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.baseUrl}/DanhBaTruc');
      if (response.statusCode == 200 && response.data['success'] == true) {
        List<dynamic> data = response.data['data'] ?? [];
        
        data.sort((a, b) {
          int idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          int idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return idA.compareTo(idB);
        });

        cachedDanhBaList = data;
      }
    } catch (e) {
      debugPrint("Lỗi pre-load danh bạ: $e");
    }
  }

  @override
  State<DanhBaTrucScreen> createState() => _DanhBaTrucScreenState();
}

class _DanhBaTrucScreenState extends State<DanhBaTrucScreen> {
  final Color primaryColor = const Color(0xFF1274BC);
  
  List<dynamic> _filteredList = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (DanhBaTrucScreen.cachedDanhBaList != null) {
      setState(() {
        _filteredList = DanhBaTrucScreen.cachedDanhBaList!;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final response = await dio.get('${AppConstants.baseUrl}/DanhBaTruc');
      if (response.statusCode == 200 && response.data['success'] == true) {
        List<dynamic> data = response.data['data'] ?? [];
        
        // Sắp xếp ID theo dạng ASC
        data.sort((a, b) {
          int idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          int idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          return idA.compareTo(idB);
        });

        DanhBaTrucScreen.cachedDanhBaList = data;
        
        if (mounted) {
          setState(() {
            _filteredList = DanhBaTrucScreen.cachedDanhBaList!;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _errorMessage = "Không thể lấy dữ liệu"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = "Lỗi kết nối máy chủ"; _isLoading = false; });
    }
  }

  void _filterDanhBa(String query) {
    if (DanhBaTrucScreen.cachedDanhBaList == null) return;
    
    if (query.isEmpty) {
      setState(() => _filteredList = DanhBaTrucScreen.cachedDanhBaList!);
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredList = DanhBaTrucScreen.cachedDanhBaList!.where((item) {
        final tenGoi = (item['tenGoi'] ?? '').toString().toLowerCase();
        final soDienThoai = (item['soDienThoai'] ?? '').toString().toLowerCase();
        return tenGoi.contains(lowerQuery) || soDienThoai.contains(lowerQuery);
      }).toList();
    });
  }

  void _makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có số điện thoại!')));
      return;
    }
    
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    
    try {
      // Ép gọi luôn, bỏ qua check canLaunchUrl để tránh bị Android/iOS block quyền
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint("Không thể gọi: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở ứng dụng gọi điện. Vui lòng kiểm tra lại thiết bị.')));
      }
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
        title: const Text('Số trực toàn hệ thống', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: TextField(
              onChanged: _filterDanhBa,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Nhập tên hoặc số điện thoại...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1274BC)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)))
                : _filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("Không tìm thấy kết quả", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: _filteredList.length,
                      itemBuilder: (context, index) {
                        final item = _filteredList[index];
                        final String tenGoi = item['tenGoi'] ?? 'Chưa cập nhật tên';
                        final String soDienThoai = item['soDienThoai'] ?? 'N/A';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _makePhoneCall(soDienThoai),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.08), shape: BoxShape.circle),
                                      child: Icon(Icons.support_agent_rounded, color: primaryColor, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tenGoi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                                          const SizedBox(height: 4),
                                          Text(soDienThoai, style: TextStyle(color: primaryColor, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                                      child: const Icon(Icons.phone_in_talk, color: Colors.green, size: 22),
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
        ],
      ),

      ),
    );
  }
}