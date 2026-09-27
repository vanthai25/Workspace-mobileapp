import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cham_cong_phep_provider.dart';
import 'tao_don_nghi_screen.dart';

class LichSuNghiScreen extends StatefulWidget {
  const LichSuNghiScreen({Key? key}) : super(key: key);
  
  @override
  State<LichSuNghiScreen> createState() => _LichSuNghiScreenState();
}

class _LichSuNghiScreenState extends State<LichSuNghiScreen> {
  // DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  // DateTime _toDate = DateTime.now().add(const Duration(days: 30));
  late DateTime _fromDate;
  late DateTime _toDate;
  int _selectedStatus = -1; // -1 là Tất cả

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    context.read<ChamCongPhepProvider>().fetchLichSu(
      fromDate: _fromDate.toIso8601String(),
      toDate: _toDate.toIso8601String(),
    );
  }

  void _confirmDelete(BuildContext context, String ngayLap) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa phiếu xin nghỉ này không?', style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              bool success = await context.read<ChamCongPhepProvider>().xoaDon(ngayLap);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phiếu thành công!')));
                _fetchData();
              }
            },
            child: const Text('Xóa phiếu'),
          ),
        ],
      ),
    );
  }

  void _showCupertinoDatePicker(BuildContext context, DateTime initialDate, Function(DateTime) onConfirm) {
    DateTime tempDate = initialDate;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
        ),
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
                    child: const Text('Xong', style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF1274BC))), 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Đồng bộ nền xám lạnh hiện đại
      
      // Nút Tạo đơn mới (Dấu +) bo tròn lơ lửng
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TaoDonNghiScreen())).then((_) {
            _fetchData(); 
          });
        },
        backgroundColor: const Color(0xFF1274BC),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      
      body: Column(
        children: [
          // 1. BỘ LỌC NGÀY (Phẳng, tối giản)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

          // 2. THANH LỌC TRẠNG THÁI (Pill Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildModernChip('Tất cả', -1, const Color(0xFF1274BC)),
                const SizedBox(width: 10),
                _buildModernChip('Chờ duyệt', 0, Colors.orange),
                const SizedBox(width: 10),
                _buildModernChip('Đã duyệt', 1, Colors.green),
                const SizedBox(width: 10),
                _buildModernChip('Từ chối', 2, Colors.red),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. DANH SÁCH DỮ LIỆU (Thẻ mượt mà)
          Expanded(
            child: Consumer<ChamCongPhepProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CupertinoActivityIndicator(radius: 16));
                }
                
                // Lọc Frontend theo trạng thái
                var filteredList = provider.lichSuList;
                if (_selectedStatus != -1) {
                  filteredList = filteredList.where((p) => p.trangThai == _selectedStatus).toList();
                }

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Không có phiếu nghỉ phép nào', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 80), // Cách đáy cho nút (+) không đè chữ
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    return _buildModernCard(filteredList[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- CÁC WIDGET CUSTOM HIỆN ĐẠI ---

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

  Widget _buildModernChip(String label, int statusValue, Color color) {
    bool isSelected = _selectedStatus == statusValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = statusValue),
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

  Widget _buildModernCard(dynamic phieu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
        ]
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Row(
              children: [
                Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                  child: const Center(child: Icon(Icons.receipt_long_rounded, color: Colors.indigo)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Phiếu xin nghỉ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text('Nộp: ${DateFormat('dd/MM/yyyy HH:mm').format(phieu.ngayLap)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                // Badge trạng thái
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
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF0F0F0)),
            ),

            // Body Card
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
            // Hộp chứa chi tiết ngày nghỉ
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
            
            // Nút Xóa phiếu (chỉ hiện khi phiếu đang Chờ duyệt)
            if (phieu.trangThai == 0) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, phieu.ngayLap.toIso8601String()),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Xóa phiếu', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.shade100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
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