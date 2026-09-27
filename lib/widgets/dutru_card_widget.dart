import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/taisan_dutru_model.dart';
import '../screens/dutru_detail_screen.dart';

class DuTruCardWidget extends StatelessWidget {
  final TaiSanDuTru phieu;
  final VoidCallback onRefresh;

  const DuTruCardWidget({super.key, required this.phieu, required this.onRefresh});

  Map<String, dynamic> _getStatus(int? status) {
    switch (status) {
      case 0: return {'text': 'Mới tạo', 'color': Colors.blue};
      case 1: return {'text': 'Chờ LĐ Khoa duyệt', 'color': Colors.orange};
      case 2: return {'text': 'Chờ Tài sản duyệt', 'color': Colors.purple};
      case 3: return {'text': 'Chờ trình HĐTV', 'color': Colors.indigo};
      case 4: return {'text': 'Chờ HĐTV duyệt', 'color': Colors.teal};
      case 5: return {'text': 'Chờ TTMS duyệt', 'color': Colors.green};
      case 6: return {'text': 'TTMS đã duyệt', 'color': Colors.blueGrey};
      case 20: return {'text': 'HĐTV Từ chối', 'color': Colors.red};
      default: return {'text': 'Trạng thái: $status', 'color': Colors.grey};
    }
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(d));
    } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    final stMap = _getStatus(phieu.trangThaiPhieu);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => DuTruDetailScreen(maPhieu: phieu.maPhieuDuTru)));
            if (res == true) onRefresh();
          },
          child: Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: stMap['color'], width: 5)), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${phieu.maPhieuDuTru}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: stMap['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(stMap['text'], style: TextStyle(color: stMap['color'], fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(phieu.tenKhoaDeNghi ?? 'Khoa đề nghị: N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                const SizedBox(height: 8),
                _buildRow(Icons.person, "Người lập:", phieu.tenNguoiYeuCau ?? phieu.maNguoiYeuCau ?? 'N/A'),
                _buildRow(Icons.access_time_filled, "Ngày lập:", _formatDate(phieu.ngayDuTru)),
                if (phieu.ghiChuDuTru != null && phieu.ghiChuDuTru!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text("Ghi chú: ${phieu.ghiChuDuTru}", style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(width: 6),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}