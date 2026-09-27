import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cham_cong_phep_model.dart';

class PhieuNghiCard extends StatelessWidget {
  final ChamCongPhepPhieuNghiResponseDto phieu;
  final bool showActions; // Cờ để hiện nút Duyệt/Từ chối hoặc Xóa
  final Function(int status, String? reason)? onAction; // Callback khi bấm nút

  const PhieuNghiCard({
    Key? key, 
    required this.phieu, 
    this.showActions = false, 
    this.onAction
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text("NV: ${phieu.tenNhanVien ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold))),
                Text("Ngày nộp: ${DateFormat('dd/MM/yy').format(phieu.ngayLap)}"),
              ],
            ),
            const SizedBox(height: 8),
            Text('Lý do: ${phieu.lyDoNghiPhep ?? "Không có"}'),
            Text('Tổng: ${phieu.tongSoNgay} ngày', style: const TextStyle(color: Colors.blue)),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade200, 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _showRejectDialog(context),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red
                    ),
                    child: const Text('Từ chối'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => onAction?.call(1, null),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Đổi màu khác để dễ nhìn
                        foregroundColor: Colors.white
                    ),
                    child: const Text('Duyệt'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lý do từ chối'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Nhập lý do...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(onPressed: () {
            onAction?.call(2, controller.text); // 2 là trạng thái Từ chối
            Navigator.pop(context);
          }, child: const Text('Gửi')),
        ],
      ),
    );
  }
}