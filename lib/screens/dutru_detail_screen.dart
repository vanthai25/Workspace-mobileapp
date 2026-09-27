import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../models/taisan_dutru_model.dart';
import '../services/taisan_dutru_service.dart';
import '../providers/auth_provider.dart';
import '../utils/helpers.dart';

class DuTruDetailScreen extends StatefulWidget {
  final String maPhieu;
  const DuTruDetailScreen({super.key, required this.maPhieu});

  @override
  State<DuTruDetailScreen> createState() => _DuTruDetailScreenState();
}

class _DuTruDetailScreenState extends State<DuTruDetailScreen> {
  final TaisanDutruService _apiService = TaisanDutruService();
  TaiSanDuTru? _phieu;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final data = await _apiService.getTaiSanDuTruDetail(widget.maPhieu);
    if (mounted) {
      setState(() { 
        _phieu = data; 
        _isLoading = false; 
      });
    }
  }

  // --- POPUP CHỌN HĐTV DUYỆT (Đã cập nhật để tự ẩn người đang được giao) ---
  Future<String?> _showSelectHDTVDialog({String? currentManvHdqt}) async {
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
                // Chỉ hiện TGD Học nếu người đang giữ phiếu không phải là TGD Học
                if (currentManvHdqt != '00001')
                  RadioListTile<String>(
                    title: const Text('Chủ tịch - Tổng GĐ Phạm Văn Học', style: TextStyle(fontWeight: FontWeight.bold)),
                    value: '00001',
                    groupValue: selectedValue,
                    activeColor: const Color(0xFF1274BC),
                    onChanged: (val) => setStateSB(() => selectedValue = val),
                  ),
                
                // Chỉ hiện PTGD Việt nếu người đang giữ phiếu không phải là PTGD Việt
                if (currentManvHdqt != '00002')
                  RadioListTile<String>(
                    title: const Text('Phó Tổng GĐ - Trần Liên Việt', style: TextStyle(fontWeight: FontWeight.bold)),
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

    String? currentManv = _phieu?.manvHdqt; // Gọi trực tiếp từ biến _phieu

    if (actionEndpoint == 'v2/trinhhdtv') {
      mahdtvSelected = await _showSelectHDTVDialog(currentManvHdqt: currentManv);
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
      widget.maPhieu, 
      actionEndpoint,
      queryParams: apiParams.isNotEmpty ? apiParams : null,
    );
    
    if (ok) {
      if (mounted) {
        AppHelpers.showSnackBar('Thao tác thành công!', isError: false);
        await _fetchDetail(); 
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

  Widget _buildActionButton(String title, Color color, String endpoint, {bool isCancel = false}) {
    return Expanded(
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: EdgeInsets.zero, // Ép lề bằng 0 để chữ có thể tự dãn
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          onPressed: _isProcessing ? null : () => _xacNhanHanhDong(endpoint, title, isCancel: isCancel),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ẩn icon nếu chữ quá dài, tiết kiệm không gian
              if (title.length < 8) Icon(isCancel ? Icons.cancel_rounded : Icons.check_circle_rounded, color: Colors.white, size: 18),
              if (title.length < 8) const SizedBox(width: 4),
              Flexible(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_phieu == null || _isProcessing) return null;
    
    final int status = _phieu!.trangThaiPhieu ?? 0;
    final String phieuMaKhoa = _phieu!.maKhoaDeNghi ?? '';
    final auth = context.read<AuthProvider>();
    final roles = auth.currentRoleIds;
    final myKhoa = auth.currentMaKhoa ?? '';
    final myManv = auth.currentManv ?? '';

    List<Widget> buttons = [];

    if (status == 0 && phieuMaKhoa == myKhoa) {
      buttons.add(_buildActionButton('TRÌNH LĐ ĐƠN VỊ', Colors.blue, 'trinhldkhoa'));
    } else if (status == 1) {
      if (_phieu!.maNguoiYeuCau == myManv) {
        buttons.add(_buildActionButton('HỦY TRÌNH', Colors.red, 'huy-trinhldkhoa', isCancel: true));
        buttons.add(const SizedBox(width: 12));
      }
      if (roles.contains(27) && phieuMaKhoa == myKhoa) {
        buttons.add(_buildActionButton('LĐ ĐƠN VỊ DUYỆT', Colors.orange, 'ldkhoa-confirm'));
      }
    } else if (status == 2) {
      if (_phieu!.nguoiDuyetDuTru == myManv) {
        buttons.add(_buildActionButton('LĐ ĐƠN VỊ HỦY', Colors.red, 'huy-ldkhoa-confirm', isCancel: true));
        buttons.add(const SizedBox(width: 12));
      }
      if (roles.contains(28) && _phieu!.duyetKho != true) {
        buttons.add(_buildActionButton('QLTS XÁC NHẬN', Colors.purple, 'kho-confirm'));
      }
      if (roles.contains(27) && phieuMaKhoa == myKhoa && _phieu!.duyetKho == true) { 
        buttons.add(_buildActionButton('TRÌNH HĐTV', Colors.indigo, 'v2/trinhhdtv')); 
      }
    } else if (status == 3) {
      if (_phieu!.maNguoiTiepNhan == myManv) {
        buttons.add(_buildActionButton('QLTS HỦY', Colors.red, 'huy-kho-confirm', isCancel: true));
        buttons.add(const SizedBox(width: 12));
      }
      if (roles.contains(28) && _phieu!.maNguoiTiepNhan == myManv) {
        buttons.add(_buildActionButton('TRÌNH HĐTV', Colors.indigo, 'v2/trinhhdtv'));
      }
    } else if (status == 4) {
      if (_phieu!.maNguoiTiepNhan == myManv || (_phieu!.duyetKho == true && _phieu!.nguoiDuyetDuTru == myManv)) {
        buttons.add(_buildActionButton('HỦY TRÌNH', Colors.red, 'huy-trinhhdtv', isCancel: true));
        buttons.add(const SizedBox(width: 12));
      }
      if (roles.contains(29) && _phieu!.manvHdqt == myManv) {
        buttons.add(_buildActionButton('CHUYỂN', Colors.orange, 'chuyen-hdtv'));
        buttons.add(const SizedBox(width: 6));
        buttons.add(_buildActionButton('TỪ CHỐI', Colors.red, 'hdtv-tuchoi', isCancel: true)); 
        buttons.add(const SizedBox(width: 6));
        buttons.add(_buildActionButton('DUYỆT', Colors.teal, 'hdtv-confirm'));
      }
    } else if (status == 5) {
      if (_phieu!.manvHdqt == myManv) {
        buttons.add(_buildActionButton('HỦY DUYỆT', Colors.orange, 'huy-hdtv-confirm', isCancel: true));
        buttons.add(const SizedBox(width: 12));
        buttons.add(_buildActionButton('TỪ CHỐI', Colors.red, 'hdtv-tuchoi', isCancel: true));
        buttons.add(const SizedBox(width: 12));
      }
      if (roles.contains(30)) {
        buttons.add(_buildActionButton('TTMS TIẾP NHẬN', Colors.green, 'ttms-confirm'));
      }
    } else if (status == 6) {
      if (_phieu!.manvTtms == myManv) {
        buttons.add(_buildActionButton('TTMS HỦY', Colors.red, 'huy-ttms-confirm', isCancel: true));
      }
    } 
    else if (status == 8) {
      if (roles.contains(29) && (_phieu!.manvHdqt == myManv || _phieu!.manvHdqt == null)) {
        buttons.add(_buildActionButton('DUYỆT LẠI', Colors.teal, 'hdtv-confirm'));
      }
    }

    if (buttons.isEmpty) return null;
    if (buttons.last is SizedBox) buttons.removeLast(); 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(child: Row(children: buttons)),
    );
  }

  String _formatEmp(String? manv, String? tennv) {
    if (manv != null && manv.isNotEmpty && tennv != null && tennv.isNotEmpty) {
      return '$manv - $tennv';
    }
    return tennv ?? manv ?? '';
  }

  Widget _buildTimelineItem(
    String stepName, 
    String? personName, 
    String? dateStr, 
    bool isDone, 
    {
      bool isFirst = false, 
      bool isLast = false, 
      bool isRejected = false, 
      String? noteText,     
      Color? noteColor,     
      IconData? noteIcon    
    }
  ) {
    String dateFormatted = dateStr != null ? DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.parse(dateStr)) : '';
    Color dotColor = isRejected ? Colors.red : (isDone ? Colors.blue : Colors.grey.shade200);
    Color lineColor = isDone || isRejected ? (isRejected ? Colors.red : Colors.blue) : Colors.grey.shade300;

    // Thiết lập màu sắc và icon mặc định nếu có ghi chú
    Color finalNoteColor = noteColor ?? Colors.grey.shade600;
    IconData finalNoteIcon = noteIcon ?? Icons.info_outline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst) Container(width: 2, height: 16, color: lineColor),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              child: isRejected 
                  ? const Icon(Icons.close, color: Colors.white, size: 16)
                  : (isDone ? const Icon(Icons.check, color: Colors.white, size: 16) : null),
            ),
            // Tăng chiều dài của đường kẻ dọc nếu bước này có hiển thị khối Ghi chú/Lý do
            if (!isLast) Container(width: 2, height: (noteText != null && noteText.isNotEmpty) ? 80 : 36, color: lineColor),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: isFirst ? 0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stepName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isRejected ? Colors.red : (isDone ? Colors.black87 : Colors.grey))),
                
                // Hiển thị tên người xử lý (Đặc cách cho bước "Trình HĐTV" vẫn hiện tên dù chưa Done)
                if ((isDone || isRejected || stepName.contains("Đã trình HĐTV")) && personName != null && personName.isNotEmpty)
                  Text(personName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                
                if ((isDone || isRejected) && dateFormatted.isNotEmpty)
                  Text(dateFormatted, style: TextStyle(fontSize: 12, color: isRejected ? Colors.red : Colors.blue)),
                
                // 🔥 KHỐI HIỂN THỊ LÝ DO / GHI CHÚ
                if (noteText != null && noteText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: finalNoteColor.withOpacity(0.08), 
                      borderRadius: BorderRadius.circular(8), 
                      border: Border.all(color: finalNoteColor.withOpacity(0.3))
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(finalNoteIcon, size: 16, color: finalNoteColor),
                        const SizedBox(width: 6),
                        Expanded(child: Text(noteText, style: TextStyle(fontSize: 13, color: finalNoteColor))),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTimeline() {
    int s = _phieu!.trangThaiPhieu ?? 0;
    bool skipKho = _phieu!.duyetKho == true;

    List<Widget> timelineSteps = [];
    int step = 1; 
    
    // 1. Khởi tạo
    timelineSteps.add(_buildTimelineItem("${step++}. Khởi tạo phiếu", _formatEmp(_phieu!.maNguoiYeuCau, _phieu!.tenNguoiYeuCau), _phieu!.ngayDuTru, true, isFirst: true));
    
    // 2. LĐ đơn vị duyệt
    timelineSteps.add(_buildTimelineItem("${step++}. LĐ đơn vị duyệt", _formatEmp(_phieu!.nguoiDuyetDuTru, _phieu!.tenNguoiDuyetDuTru), _phieu!.ngayLdkhoaDuyet, s >= 2 || s == 8));

    // 3. QLTS Xác nhận (Nếu có)
    if (!skipKho) {
      timelineSteps.add(_buildTimelineItem("${step++}. QLTS Xác nhận", _formatEmp(_phieu!.maNguoiTiepNhan, _phieu!.tenNguoiTiepNhan), _phieu!.ngayDuyetDuTru, s >= 3 || s == 8));
    }

    bool daTrinhHDTV = s >= 4 || s == 8;
    String? tenNguoiDangGiu = daTrinhHDTV ? _formatEmp(_phieu!.manvHdqt, _phieu!.tenHDQT) : null;
    
    String? noteChuyen;
    if (daTrinhHDTV && _phieu!.lydoHDTVchuyen != null && _phieu!.lydoHDTVchuyen!.isNotEmpty) {
      noteChuyen = "Lý do chuyển: ${_phieu!.lydoHDTVchuyen}";
    }

    timelineSteps.add(_buildTimelineItem(
      "${step++}. Đã trình HĐTV", 
      tenNguoiDangGiu, 
      null, 
      daTrinhHDTV,
      noteText: noteChuyen,
      noteColor: Colors.orange.shade800,
      noteIcon: Icons.swap_horiz_rounded
    ));
    
    // 5. Kết quả HĐTV
    if (s == 8) {
       // Nếu BỊ TỪ CHỐI
       timelineSteps.add(_buildTimelineItem(
          "${step++}. HĐTV Từ chối", 
          tenNguoiDangGiu, 
          _phieu!.ngayHdqtduyet, 
          false, 
          isLast: true, 
          isRejected: true, 
          noteText: "Lý do: ${_phieu!.lydoHDTVtuchoi ?? 'Không có lý do'}",
          noteColor: Colors.red,
          noteIcon: Icons.warning_amber_rounded
       ));
    } else {
       // Nếu DUYỆT (Kèm GHI CHÚ DUYỆT nếu có)
       String? noteDuyet;
       if (_phieu!.ghichuHDTVduyet != null && _phieu!.ghichuHDTVduyet!.isNotEmpty) {
         noteDuyet = "Ghi chú: ${_phieu!.ghichuHDTVduyet}";
       }
       
       timelineSteps.add(_buildTimelineItem(
          "${step++}. HĐTV Duyệt", 
          tenNguoiDangGiu, 
          _phieu!.ngayHdqtduyet, 
          s >= 5,
          noteText: noteDuyet,
          noteColor: Colors.teal,
          noteIcon: Icons.check_circle_outline
       ));

       // 6. TTMS Tiếp nhận
       timelineSteps.add(_buildTimelineItem(
          "${step++}. TTMS Tiếp nhận", 
          _formatEmp(_phieu!.manvTtms, _phieu!.tennvTtms), 
          _phieu!.ngayTtmsnhan, 
          s >= 6, 
          isLast: true
       ));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TIẾN ĐỘ XỬ LÝ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
          if (skipKho) 
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text("(Dự trù không qua QLTS, LĐ đơn vị trình HĐTV)", style: TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic)),
            ),
          const SizedBox(height: 16),
          ...timelineSteps, 
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      final bool isPriority =
      _phieu?.mucUuTien == 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(title: Text('Chi tiết #${widget.maPhieu}'), backgroundColor: const Color(0xFF1274BC), foregroundColor: Colors.white, elevation: 0),
      body: _isLoading || _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : _phieu == null
              ? const Center(child: Text("Không tìm thấy dữ liệu"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    _phieu!.tenKhoaDeNghi ??
                                        'Khoa: N/A',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1274BC),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                if (isPriority) ...[
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
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
                                          size: 14,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'ƯU TIÊN',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const Divider(height: 24),
                            Text('Người yêu cầu: ${_phieu!.tenNguoiYeuCau}', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('Ngày dự trù: ${_phieu!.ngayDuTru != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_phieu!.ngayDuTru!)) : ''}', style: const TextStyle(fontSize: 14)),
                            if (_phieu!.ghiChuDuTru != null) ...[
                              const SizedBox(height: 8),
                              Text('Ghi chú: ${_phieu!.ghiChuDuTru}', style: const TextStyle(fontSize: 14)),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "DANH SÁCH CHI TIẾT TÀI SẢN",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _phieu!.chiTiets.length,
                        itemBuilder: (ctx, i) {
                          final item = _phieu!.chiTiets[i];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tên tài sản
                                  Text(
                                    item.tenTaiSan ?? 'N/A',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Model & Số lượng
                                  if (item.model != null && item.model!.isNotEmpty) ...[
                                    Text(
                                      'Model: ${item.model}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    'Số lượng: ${item.soLuong} (${item.donViTinh})',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  
                                  // 🔥 Ghi chú chi tiết (nếu có)
                                  if (item.ghiChuDuTruChiTiet != null && item.ghiChuDuTruChiTiet!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blueGrey.shade100)
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.edit_note_rounded, size: 16, color: Colors.blueGrey.shade600),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item.ghiChuDuTruChiTiet!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.blueGrey.shade800,
                                                fontStyle: FontStyle.normal
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildProgressTimeline(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}