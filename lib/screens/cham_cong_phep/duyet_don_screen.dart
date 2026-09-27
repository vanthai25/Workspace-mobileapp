import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async'; 
import '../../providers/cham_cong_phep_provider.dart';

class DuyetDonScreen extends StatefulWidget {
  const DuyetDonScreen({Key? key}) : super(key: key);

  @override
  State<DuyetDonScreen> createState() => _DuyetDonScreenState();
}

class _DuyetDonScreenState extends State<DuyetDonScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  late DateTime _fromDate;
  late DateTime _toDate;
  int _selectedStatus = 0; 

  @override
  void initState() {
    super.initState();
    // Khởi tạo ngày đầu tháng và cuối tháng
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Hủy timer khi đóng màn hình
    _searchController.dispose();
    super.dispose();
  }

  void _fetchData() {
    context.read<ChamCongPhepProvider>().fetchDanhSachChoDuyet(
      fromDate: _fromDate.toIso8601String(),
      toDate: _toDate.toIso8601String(),
      trangThai: _selectedStatus,
      searchKeyword: _searchController.text,
    );
  }

  // Hàm gọi API khi gõ tìm kiếm (có độ trễ 0.5s để chống giật/lag)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchData();
    });
  }

  void _showCupertinoDatePicker(BuildContext context, DateTime initialDate, Function(DateTime) onConfirm) {
    DateTime tempDate = initialDate;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)), onPressed: () => Navigator.pop(context)),
                  CupertinoButton(
                    child: const Text('Xong', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), 
                    onPressed: () {
                      onConfirm(tempDate);
                      Navigator.pop(context);
                    }
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                onDateTimeChanged: (DateTime newDate) => tempDate = newDate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionDialog(BuildContext context, String ngayLap, String manvXin, int trangThai) {
    bool isApprove = trangThai == 1;
    final controller = TextEditingController(text: isApprove ? "Đồng ý" : ""); 

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isApprove ? 'Nội dung duyệt' : 'Lý do từ chối', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width, 
          child: TextField(
            controller: controller, 
            maxLines: 4, 
            minLines: 3, 
            keyboardType: TextInputType.multiline, 
            decoration: InputDecoration(
              hintText: isApprove ? "Nhập nội dung duyệt..." : "Nhập lý do từ chối (bắt buộc)...",
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: BorderSide.none
              )
            )
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.redAccent, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            ),
            onPressed: () async {
              if (!isApprove && controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do từ chối!')));
                return;
              }

              Navigator.pop(context);
              bool success = await context.read<ChamCongPhepProvider>().xuLyDuyetDon(
                ngayLap, manvXin, trangThai, controller.text
              );
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isApprove ? 'Đã duyệt đơn thành công!' : 'Đã từ chối đơn!')
                ));
                _fetchData();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Thao tác thất bại! Vui lòng kiểm tra Backend.'),
                  backgroundColor: Colors.redAccent,
                ));
              }
            }, 
            child: Text(isApprove ? 'Duyệt ngay' : 'Từ chối', style: const TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
  void _confirmHuyDuyet(BuildContext context, String ngayLap, String manvXin) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hủy duyệt', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc muốn hủy duyệt đơn này? Đơn sẽ quay về trạng thái Chờ xử lý.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              // Gọi API Hủy duyệt
              bool success = await context.read<ChamCongPhepProvider>().huyDuyetDon(ngayLap, manvXin);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy duyệt thành công!')));
                _fetchData();
              }
            }, 
            child: const Text('Xác nhận')
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Column(
        children: [
          // 1. THANH TÌM KIẾM AUTO-LOAD (Đã bỏ nút mũi tên)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged, // Gõ đến đâu tự chạy hàm debounce đến đó
                decoration: InputDecoration(
                  hintText: 'Tìm Mã NV hoặc Tên...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),

          // 2. BỘ LỌC NGÀY (Mặc định đầu tháng - cuối tháng)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _buildDateButton(_fromDate, true)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                ),
                Expanded(child: _buildDateButton(_toDate, false)),
              ],
            ),
          ),

          // 3. THANH LỌC TRẠNG THÁI
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildModernChip('Chờ duyệt', 0, Colors.orange),
                const SizedBox(width: 10),
                _buildModernChip('Đã duyệt', 1, Colors.green),
                const SizedBox(width: 10),
                _buildModernChip('Từ chối', 2, Colors.red),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 4. DANH SÁCH ĐƠN
          Expanded(
            child: Consumer<ChamCongPhepProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return const Center(child: CupertinoActivityIndicator(radius: 16));
                
                if (provider.choDuyetList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Không có đơn nào', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: provider.choDuyetList.length,
                  itemBuilder: (context, index) {
                    final phieu = provider.choDuyetList[index];
                    return _buildModernCard(phieu, provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- CÁC WIDGET CUSTOM ---

  Widget _buildDateButton(DateTime date, bool isFrom) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showCupertinoDatePicker(context, date, (newDate) {
        setState(() => isFrom ? _fromDate = newDate : _toDate = newDate);
        _fetchData();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded, size: 16, color: Colors.indigo.shade300),
            const SizedBox(width: 8),
            Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernChip(String label, int statusValue, MaterialColor color) {
    bool isSelected = _selectedStatus == statusValue;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatus = statusValue);
        _fetchData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard(dynamic phieu, ChamCongPhepProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                  child: const Center(child: Icon(Icons.person_rounded, color: Colors.indigo)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phieu.tenNhanVien ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text('Mã NV: ${phieu.manvXin} • ${DateFormat('dd/MM').format(phieu.ngayLap)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: phieu.trangThai == 0 ? Colors.orange.shade50 : (phieu.trangThai == 1 ? Colors.green.shade50 : Colors.red.shade50),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Text(
                    phieu.trangThai == 0 ? 'Chờ duyệt' : (phieu.trangThai == 1 ? 'Đã duyệt' : 'Từ chối'),
                    style: TextStyle(
                      color: phieu.trangThai == 0 ? Colors.orange.shade700 : (phieu.trangThai == 1 ? Colors.green.shade700 : Colors.red.shade700),
                      fontSize: 11, fontWeight: FontWeight.bold
                    )
                  ),
                )
              ],
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF0F0F0))),
            Text('Lý do: ${phieu.lyDoNghiPhep ?? "Không có"}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                text: 'Tổng số ngày: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                children: [
                  TextSpan(text: '${phieu.tongSoNgay} ngày', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 14))
                ]
              )
            ),
            
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: phieu.chiTietDanhSachNgay.map<Widget>((ct) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.grey.shade400),
                      const SizedBox(width: 10),
                      Text(DateFormat('dd/MM/yyyy').format(ct.ngayNghi), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(ct.tenKyHieu ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                )).toList(),
              ),
            ),
            
            if (phieu.trangThai == 0) ...[
              // ĐANG CHỜ DUYỆT -> Hiện: TỪ CHỐI | DUYỆT NGAY
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showActionDialog(context, phieu.ngayLap.toIso8601String(), phieu.manvXin ?? '', 2),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent, side: BorderSide(color: Colors.redAccent.shade100),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                      child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showActionDialog(context, phieu.ngayLap.toIso8601String(), phieu.manvXin ?? '', 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                      child: const Text('Duyệt ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ] else if (phieu.trangThai == 1) ...[
              // ĐÃ DUYỆT -> Hiện: HỦY DUYỆT | TỪ CHỐI
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmHuyDuyet(context, phieu.ngayLap.toIso8601String(), phieu.manvXin ?? ''), 
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700, side: BorderSide(color: Colors.orange.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                      child: const Text('Hủy duyệt', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showActionDialog(context, phieu.ngayLap.toIso8601String(), phieu.manvXin ?? '', 2), // Gọi Hộp thoại từ chối
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)
                      ),
                      child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ] else if (phieu.trangThai == 2) ...[
              // TỪ CHỐI -> Hiện: DUYỆT LẠI
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showActionDialog(context, phieu.ngayLap.toIso8601String(), phieu.manvXin ?? '', 1), // Đổi sang Duyệt
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Duyệt lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}