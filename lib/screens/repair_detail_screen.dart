import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/taisan_repair_model.dart';
import '../models/nhanvien_model.dart';
import '../services/taisan_repair_service.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import 'create_repair_ticket_screen.dart';
import '../services/nhanvien_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RepairDetailScreen extends StatefulWidget {
  final int repairId;

  const RepairDetailScreen({super.key, required this.repairId});

  @override
  State<RepairDetailScreen> createState() => _RepairDetailScreenState();
}

class _RepairDetailScreenState extends State<RepairDetailScreen> {
  final TaiSanRepairService _apiService = TaiSanRepairService();
  final NhanvienService _nhanVienService = NhanvienService();
  final Color primaryColor = const Color(0xFF1274BC);

  // Controller quản lý ô nhập text kết quả trực tiếp ở màn hình
  final TextEditingController _noteController = TextEditingController();

  TaiSanRepair? _repair;
  bool _isLoading = true;
  bool _isForwarding = false; 

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    final data = await _apiService.getTaiSanRepairById(widget.repairId);
    if (mounted) {
      setState(() {
        _repair = data;
        _isLoading = false;
        _isForwarding = false;
        _noteController.clear(); 
      });
    }
  }

  RepairLogDetail? _getLogByStatus(int statusToFind) {
    if (_repair == null || _repair!.logs == null) return null;
    try {
      return _repair!.logs!.lastWhere((log) => log.stepStatus == statusToFind);
    } catch (_) {
      return null; 
    }
  }

  Future<void> _changeStatusFlow(int newStatus) async {
    if (_repair == null) return;

    bool isNoteValid() {
      if (_noteController.text.trim().isNotEmpty) return true;
      if (_repair!.noidungxutri != null && _repair!.noidungxutri!.trim().isNotEmpty) return true;
      return false;
    }
    if (newStatus == 2 && _repair!.trangthaiphieu == 0) {
      if (_repair!.khoanhan == null) {
        AppHelpers.showSnackBar('Phiếu này chưa cấu hình bộ phận tiếp nhận!', isError: true);
        return;
      }

      setState(() => _isForwarding = true); 
      final employees = await _nhanVienService.getNhanVienByKhoa(_repair!.khoanhan!); 
      final currentManv = context.read<AuthProvider>().currentManv;
      String? selectedNguoiXuTri = currentManv;
      if(mounted) setState(() => _isForwarding = false); 

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
        builder: (ctx) => AlertDialog(
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
              Text('Bộ phận tiếp nhận: ${_repair!.tenKhoaNhan ?? _repair!.khoanhan}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedNguoiXuTri,
                isExpanded: true,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                hint: const Text("Chọn người xử lý"),
                items: dropdownItems,
                onChanged: (val) => setState(() => selectedNguoiXuTri = val),
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
        ),
      );

      if (confirm == true && selectedNguoiXuTri != null) {
        setState(() => _isForwarding = true);
        try {
          final success = await _apiService.changeRepairStatus(_repair!.id!, 2, nguoixutri: selectedNguoiXuTri);
          if (success) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tiếp nhận sửa chữa thành công!'), backgroundColor: Colors.green));
            await _fetchDetail(); 
          }
        } finally {
          if (mounted) setState(() => _isForwarding = false);
        }
      }
    } 
    else if (newStatus == 9 || (newStatus == 4 && _repair!.trangthaiphieu == 2)) {
      
      bool isFromStep2 = (_repair!.trangthaiphieu == 2);
      bool hasContent = _noteController.text.trim().isNotEmpty || (_repair!.noidungxutri != null && _repair!.noidungxutri!.trim().isNotEmpty);

      if (isFromStep2 && !hasContent) {
        AppHelpers.showSnackBar(
          newStatus == 9 ? 'Vui lòng nhập Kết quả xử lý ở ô phía trên!' : 'Vui lòng nhập nội dung trước khi gửi vật tư!', 
          isError: true
        );
        return;
      }

      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(newStatus == 9 ? 'Hoàn thành phiếu' : 'Gửi vật tư', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Xác nhận ${newStatus == 9 ? 'Nghiệm thu hoàn tất' : 'Gửi vật tư đi'} với nội dung đã nhập?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: newStatus == 9 ? Colors.green : Colors.orange.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isForwarding = true);
        try {
          bool success = false;
          if (newStatus == 9) {
            success = await _apiService.changeRepairStatus(_repair!.id!, 9, noidungxutri: _noteController.text.trim());
          } else {
            // Trường hợp này là từ Status 2 -> 4
            success = await _apiService.changeRepairStatus(_repair!.id!, 4, noidungxutri: _noteController.text.trim());
          }

          if (success) {
            await _fetchDetail();
            if (mounted) AppHelpers.showSnackBar(newStatus == 9 ? 'Đã hoàn thành phiếu!' : 'Đã gửi vật tư!');
          }
        } finally {
          if (mounted) setState(() => _isForwarding = false);
        }
      }
    }
    else if (newStatus == 9) {
      bool isFromStep2 = (_repair!.trangthaiphieu == 2);
      bool hasContent = _noteController.text.trim().isNotEmpty || 
                       (_repair!.noidungxutri != null && _repair!.noidungxutri!.trim().isNotEmpty);

      if (isFromStep2 && !hasContent) {
        AppHelpers.showSnackBar('Vui lòng nhập Kết quả xử lý!', isError: true);
        return;
      }

      // 2. HỎI XÁC NHẬN
      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hoàn thành phiếu'),
          content: const Text('Xác nhận hoàn tất phiếu sửa chữa này?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isForwarding = true);
        try {
          String finalContent = _noteController.text.trim().isNotEmpty 
                                ? _noteController.text.trim() 
                                : (_repair!.noidungxutri ?? "");

          bool success = await _apiService.changeRepairStatus(_repair!.id!, 9, noidungxutri: finalContent);
          if (success) {
            await _fetchDetail();
            if (mounted) AppHelpers.showSnackBar('Đã hoàn thành phiếu!');
          }
        } finally {
          if (mounted) setState(() => _isForwarding = false);
        }
      }
    }
    // 3. KỊCH BẢN VT CHUYỂN ĐI (5 -> 6): HIỂN THỊ POPUP NHƯ CŨ (Vì ô text rỗng chỉ hiện ở bước Đang xử lý)
    else if (newStatus == 6 && _repair!.trangthaiphieu == 5) {
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
        setState(() => _isForwarding = true); 
        try {
          final success = await _apiService.changeRepairStatus(
            _repair!.id!, 
            6, 
            noidungchuyendi: noidungChuyenController.text.trim()
          );
          if (success) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật chuyển vật tư thành công!'), backgroundColor: Colors.green));
            await _fetchDetail(); 
          }
        } finally {
          if (mounted) setState(() => _isForwarding = false);
        }
      }
    }
    // 4. CÁC TRẠNG THÁI KHÁC: CHỈ HỎI XÁC NHẬN NHANH
    else {
      String actionName = "";
      if (newStatus == 0) actionName = "Hủy tiếp nhận";
      else if (newStatus == 4) actionName = _repair!.trangthaiphieu == 5 ? "Hủy VT tiếp nhận" : "Gửi vật tư";
      else if (newStatus == 5) actionName = _repair!.trangthaiphieu == 6 ? "Hủy VT chuyển đi" : "Vật tư tiếp nhận";
      else if (newStatus == 6 && _repair!.trangthaiphieu == 7) actionName = "Hủy hàng về";
      else if (newStatus == 7) actionName = "Báo hàng về";
      else if (newStatus == 2) {
        if (_repair!.trangthaiphieu == 4) actionName = "Hủy gửi vật tư";
        if (_repair!.trangthaiphieu == 9) actionName = "Hủy hoàn thành";
      }

      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(actionName, style: TextStyle(color: newStatus < _repair!.trangthaiphieu! ? Colors.red : Colors.blue.shade700, fontWeight: FontWeight.bold)),
          content: const Text('Bạn có chắc chắn muốn thực hiện thao tác này?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Đóng', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: newStatus < _repair!.trangthaiphieu! ? Colors.red : Colors.blue.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isForwarding = true);
        try {
          final success = await _apiService.changeRepairStatus(_repair!.id!, newStatus);
          if (success) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật trạng thái thành công!'), backgroundColor: Colors.green));
            await _fetchDetail();
          }
        } finally {
          if (mounted) setState(() => _isForwarding = false);
        }
      }
    }
  }

  Future<void> _deleteTicket() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cảnh báo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa phiếu #${_repair!.id} không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Xóa phiếu', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _apiService.deleteTaiSanRepair(_repair!.id!);
      if (success && mounted) {
        AppHelpers.showSnackBar('Đã xóa phiếu thành công!');
        Navigator.pop(context, true); 
      }
    }
  }

  Future<void> _editTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRepairTicketScreen(editTicket: _repair))
    );
    if (result == true) {
      setState(() => _isLoading = true);
      _fetchDetail(); 
    }
  }

  void _viewFullImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer( 
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url, fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber.replaceAll(RegExp(r'\s+'), ''));
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  String _formatEmployee(String? id, String? name) {
    if (id == null || id.isEmpty) return 'Chưa cập nhật';
    if (name != null && name.isNotEmpty) return '$id - $name';
    return id; 
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) { return dateStr; }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    int status = _repair?.trangthaiphieu ?? -1;
    bool isHandler = _repair?.nguoixutri == authProvider.currentManv;
    bool hasRole23 = authProvider.currentRoleIds.contains(23);
    
    bool canEditNote = (status == 2 && hasRole23 && isHandler);
    
    return GestureDetector( 
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          title: Text('Chi tiết phiếu #${widget.repairId}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          actions: [
            if (_repair != null && _repair!.trangthaiphieu == 0 && _repair!.nguoilap == authProvider.currentManv)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _editTicket();
                  if (value == 'delete') _deleteTicket();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, color: Colors.blue, size: 20), SizedBox(width: 12), Text('Sửa phiếu')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, color: Colors.red, size: 20), SizedBox(width: 12), Text('Xóa phiếu')])),
                ],
              ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : _repair == null
                ? const Center(child: Text('Không tìm thấy dữ liệu phiếu'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- THÔNG TIN CHUNG ---
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_repair!.tentaisan ?? 'Chưa cập nhật tên', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                              const SizedBox(height: 12),
                              _buildDetailRow(Icons.qr_code_rounded, 'Mã tài sản:', _repair!.maTaiSanId ?? 'Trống'),
                              _buildDetailRow(Icons.location_on_rounded, 'Vị trí:', _repair!.vitrisudung ?? 'Trống'),
                              _buildDetailRow(Icons.apartment_rounded, 'Khoa báo:', '${_repair!.tenKhoaLap ?? _repair!.khoalap}'),
                              _buildDetailRow(Icons.person_rounded, 'Người lập:', _formatEmployee(_repair!.nguoilap, _repair!.tenNguoiLap)),

                              if (_repair!.sdtNguoiLap != null && _repair!.sdtNguoiLap!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 24, bottom: 12, top: 2), 
                                  child: Wrap(
                                    spacing: 8, runSpacing: 6, 
                                    children: _repair!.sdtNguoiLap!.map<Widget>((phone) {
                                      return InkWell(
                                        onTap: () => _makePhoneCall(phone.toString()),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1274BC).withOpacity(0.08), 
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF1274BC).withOpacity(0.2)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.phone_in_talk_rounded, size: 14, color: Color(0xFF1274BC)),
                                              const SizedBox(width: 6),
                                              Text(phone.toString(), style: const TextStyle(color: Color(0xFF1274BC), fontSize: 13, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                              _buildDetailRow(Icons.move_to_inbox_rounded, 'Nơi nhận:', '${_repair!.tenKhoaNhan ?? _repair!.khoanhan}'),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                              
                              const Text("Mô tả lỗi:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                              const SizedBox(height: 6),
                              Text(_repair!.noidung ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4)),
                              
                              const SizedBox(height: 12),
                              const Text("Ghi chú:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                              const SizedBox(height: 6),
                              Text(_repair!.ghichu ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_repair!.fileIds != null && _repair!.fileIds!.isNotEmpty) ...[
                            _buildSectionCard(
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _repair!.fileIds!.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemBuilder: (context, index) {
                                  final fileId = _repair!.fileIds![index];
                                  final imageUrl = '${AppConstants.baseUrl}/FileStorage/$fileId';
                                  return InkWell(
                                    onTap: () => _viewFullImage(imageUrl), 
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(imageUrl, fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],

                        if (canEditNote) ...[
                          _buildSectionCard(
                            title: "Nội dung xử lý / Kết quả",
                            icon: Icons.edit_note_rounded,
                            child: TextField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Nhập tình trạng tài sản ...",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1274BC), width: 1.5)),
                                contentPadding: const EdgeInsets.all(16),
                                filled: true, fillColor: Colors.grey.shade50,
                              ),
                            )
                          ),
                          const SizedBox(height: 16),
                        ],

                        // --- TIẾN ĐỘ XỬ LÝ (TIMELINE) ---
                        Builder(
                          builder: (context) {
                            int status = _repair!.trangthaiphieu ?? 0;
                            bool daQuaVatTu = _repair!.maqlts != null || _repair!.noidungchuyendi != null;

                            final log2 = _getLogByStatus(2); 
                            final log4 = _getLogByStatus(4);
                            final log5 = _getLogByStatus(5);
                            final log6 = _getLogByStatus(6);
                            final log7 = _getLogByStatus(7);

                            // Build subtitle cho bước Đang Xử lý (Nơi sẽ gánh chuỗi noidungxutri)
                            String dangXuLySubtitle = _formatEmployee(_repair!.nguoixutri, _repair!.tenNguoiXutri);
                            if (_repair!.noidungxutri != null && _repair!.noidungxutri!.isNotEmpty) {
                              dangXuLySubtitle += "\n👉 Kết quả xử lý: ${_repair!.noidungxutri}";
                            }

                            return _buildSectionCard(
                              title: 'Tiến độ xử lý',
                              icon: Icons.timeline_rounded,
                              child: Column(
                                children: [
                                  _buildTimelineItem(
                                    "Người lập phiếu",
                                    _formatEmployee(_repair!.nguoilap, _repair!.tenNguoiLap),
                                    _formatDate(_repair!.ngaylap),
                                    isDone: true, color: Colors.blue.shade600,
                                    icon: Icons.person_add_alt_1_rounded, isLast: status == 0,
                                  ),

                                  if (status >= 2)
                                    _buildTimelineItem(
                                      "Tiếp nhận phiếu",
                                      _formatEmployee(_repair!.nguoinhan, _repair!.tenNguoiNhan),
                                      _formatDate(_repair!.ngaynhan),
                                      isDone: true, color: Colors.teal.shade600,
                                      icon: Icons.assignment_turned_in_rounded, isLast: false,
                                    ),

                                  if (status >= 2)
                                    _buildTimelineItem(
                                      "Đang xử lý",
                                      dangXuLySubtitle, 
                                      log2 != null ? _formatDate(log2.sysdate) : '', 
                                      isDone: true, color: Colors.purple.shade500,
                                      icon: Icons.autorenew_rounded, isLast: status == 2,
                                    ),                 

                                  if (log4 != null || status == 4 || status == 5 || status == 6 || status == 7 || (status == 9 && daQuaVatTu))
                                    _buildTimelineItem(
                                      "Gửi vật tư",
                                      log4 != null ? _formatEmployee(log4.manv, log4.tenNhanVien) : (status == 4 ? "Chờ phòng vật tư điều phối thiết bị" : "Đã gửi vật tư thành công"),
                                      log4 != null ? _formatDate(log4.sysdate) : '',
                                      isDone: true, color: Colors.orange.shade700,
                                      icon: Icons.inventory_rounded, isLast: status == 4
                                    ),

                                  if (log5 != null || status == 5 || status == 6 || status == 7 || (status == 9 && _repair!.maqlts != null))
                                    _buildTimelineItem(
                                      "Vật tư tiếp nhận",
                                      log5 != null ? _formatEmployee(log5.manv, log5.tenNhanVien) : (status == 5 ? "Đang chờ thông tin sửa ngoài" : _formatEmployee(_repair!.maqlts, _repair!.tenNguoiQuanLy)),
                                      log5 != null ? _formatDate(log5.sysdate) : '',
                                      isDone: true, color: Colors.cyan.shade700,
                                      icon: Icons.move_to_inbox_rounded, isLast: status == 5,
                                    ),

                                  if (log6 != null || status == 6 || status == 7 || (status == 9 && _repair!.noidungchuyendi != null))
                                    _buildTimelineItem(
                                      "Vật tư chuyển đi",
                                      log6 != null 
                                        ? "${_formatEmployee(log6.manv, log6.tenNhanVien)}${_repair!.noidungchuyendi != null ? '\n(${_repair!.noidungchuyendi})' : ''}" 
                                        : (_repair!.noidungchuyendi ?? "Đang chuyển đi bảo hành / sửa ngoài"),
                                      log6 != null ? _formatDate(log6.sysdate) : '',
                                      isDone: true, color: Colors.indigo,
                                      icon: Icons.local_shipping_rounded, isLast: status == 6
                                    ),

                                  if (log7 != null || status == 7 || (status == 9 && daQuaVatTu))
                                    _buildTimelineItem(
                                      "Hàng về",
                                      log7 != null ? _formatEmployee(log7.manv, log7.tenNhanVien) : (status == 7 ? "Vật tư đã về viện, chờ kỹ thuật nghiệm thu" : "Thiết bị đã về viện"),
                                      log7 != null ? _formatDate(log7.sysdate) : '',
                                      isDone: true, color: Colors.amber.shade800,
                                      icon: Icons.system_update_alt_rounded, isLast: status == 7
                                    ),

                                  if (status == 9)
                                    _buildTimelineItem(
                                      "Hoàn thành",
                                      "${_formatEmployee(_repair!.nguoixutri, _repair!.tenNguoiXutri)}\nHoàn tất", 
                                      _formatDate(_repair!.ngayxutri),
                                      isDone: true, color: Colors.green.shade600,
                                      icon: Icons.check_circle_rounded, isLast: true
                                    ),
                                ],
                              ),
                            );
                          }
                        ),
                        const SizedBox(height: 40), 
                      ],
                    ),
                  ),
        bottomNavigationBar: _buildDynamicBottomBar(),
      ),
    );
  }

  Widget? _buildDynamicBottomBar() {
    if (_repair == null) return null;
    int status = _repair!.trangthaiphieu ?? -1;

    final authProvider = context.read<AuthProvider>();
    bool hasRole23 = authProvider.currentRoleIds.contains(23);
    bool hasRole25 = authProvider.currentRoleIds.contains(25);
    bool isHandler = _repair!.nguoixutri == authProvider.currentManv;

    List<Widget> actionButtons = [];

    if (status == 0 && hasRole23) {
      actionButtons.add(Expanded(child: _buildActionButton("TIẾP NHẬN", Icons.engineering, Colors.blue.shade600, () => _changeStatusFlow(2))));
    }

    if (status == 2 && hasRole23) {
      if (_repair!.nguoinhan == authProvider.currentManv) {
        actionButtons.add(Expanded(child: _buildActionButton("HỦY", Icons.cancel, Colors.red, () => _changeStatusFlow(0))));
        actionButtons.add(const SizedBox(width: 8));
      }
      if (isHandler) {
        actionButtons.add(Expanded(child: _buildActionButton("GỬI VT", Icons.inventory, Colors.orange.shade700, () => _changeStatusFlow(4))));
        actionButtons.add(const SizedBox(width: 8));
        actionButtons.add(Expanded(child: _buildActionButton("HOÀN THÀNH", Icons.check_circle, Colors.green, () => _changeStatusFlow(9))));
      }
    }

    if (status == 4) {
      if (hasRole23 && isHandler) {
        actionButtons.add(Expanded(child: _buildActionButton("HỦY GỬI VT", Icons.cancel, Colors.red, () => _changeStatusFlow(2))));
        actionButtons.add(const SizedBox(width: 8));
      }
      if (hasRole25) {
        actionButtons.add(Expanded(child: _buildActionButton("VT TIẾP NHẬN", Icons.move_to_inbox, Colors.teal, () => _changeStatusFlow(5))));
      }
    }

    if (status == 5 && hasRole25) {
      actionButtons.add(Expanded(child: _buildActionButton("HỦY", Icons.cancel, Colors.red, () => _changeStatusFlow(4))));
      actionButtons.add(const SizedBox(width: 8));
      actionButtons.add(Expanded(child: _buildActionButton("VT CHUYỂN ĐI", Icons.local_shipping, Colors.purple, () => _changeStatusFlow(6))));
    }

    if (status == 6 && hasRole25) {
      actionButtons.add(Expanded(child: _buildActionButton("HỦY", Icons.cancel, Colors.red, () => _changeStatusFlow(5))));
      actionButtons.add(const SizedBox(width: 8));
      actionButtons.add(Expanded(child: _buildActionButton("BÁO HÀNG VỀ", Icons.system_update_alt, Colors.amber.shade700, () => _changeStatusFlow(7))));
    }

    if (status == 7 && hasRole25) {
      actionButtons.add(Expanded(child: _buildActionButton("HỦY HÀNG VỀ", Icons.cancel, Colors.red, () => _changeStatusFlow(6))));
      actionButtons.add(const SizedBox(width: 8));
    }
    
    if (status == 7 && hasRole23 && isHandler) {
      actionButtons.add(Expanded(child: _buildActionButton("HOÀN THÀNH", Icons.check_circle, Colors.green, () => _changeStatusFlow(9))));
    }

    if (status == 9 && hasRole23 && isHandler) { 
        actionButtons.add(Expanded(child: _buildActionButton("HỦY HOÀN THÀNH", Icons.cancel, Colors.red, () => _changeStatusFlow(2))));
    }

    if (actionButtons.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
      ),
      child: SafeArea(child: Row(children: actionButtons)),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback action) {
    return SizedBox(
      height: 45,
      child: ElevatedButton.icon(
        onPressed: _isForwarding ? null : action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
        ),
        icon: _isForwarding 
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, color: Colors.white, size: 16),
        label: Text(
          _isForwarding ? 'ĐANG XỬ LÝ...' : label, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSectionCard({String? title, IconData? icon, required Widget child}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && icon != null) ...[
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          ],
          child, 
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, String time, {bool isDone = false, bool isLast = false, Color color = Colors.green, IconData icon = Icons.check}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24, height: 24, 
                decoration: BoxDecoration(color: isDone ? color : Colors.grey.shade300, shape: BoxShape.circle),
                child: isDone ? Icon(icon, size: 14, color: Colors.white) : null,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: isDone ? color.withOpacity(0.4) : Colors.grey.shade300)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDone ? color : Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w500)),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}