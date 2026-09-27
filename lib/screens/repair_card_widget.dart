import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/taisan_repair_model.dart';
import '../providers/auth_provider.dart';
import 'repair_detail_screen.dart';

class RepairCardWidget extends StatelessWidget {
  final TaiSanRepair repair;
  final Map<String, dynamic> statusObj;
  final Map<String, dynamic> priorityObj;
  final VoidCallback onRefresh;
  final Function(TaiSanRepair) onEdit;
  final Function(int) onDelete;
  final Function(TaiSanRepair, int) onChangeStatus;

  const RepairCardWidget({
    super.key,
    required this.repair,
    required this.statusObj,
    required this.priorityObj,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) { return dateStr; }
  }

  String _formatEmployee(String? id, String? name) {
    if (id == null || id.isEmpty) return 'Chưa cập nhật';
    if (name != null && name.isNotEmpty) return '$id - $name';
    return id; 
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1274BC);
    final authProvider = context.read<AuthProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RepairDetailScreen(repairId: repair.id!))
            );
            if (result == true) onRefresh();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(border: Border(left: BorderSide(color: statusObj['color'], width: 5))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER CARD
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mã phiếu: #${repair.id ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 13)),
                        Row(
                          children: [
                            if (repair.mucuutien == 2 || repair.mucuutien == 3)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: priorityObj['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(priorityObj['text'], style: TextStyle(color: priorityObj['color'], fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusObj['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                children: [
                                  Icon(statusObj['icon'], size: 12, color: statusObj['color']),
                                  const SizedBox(width: 4),
                                  Text(statusObj['text'], style: TextStyle(color: statusObj['color'], fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  // BODY CARD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(repair.tentaisan ?? 'Chưa cập nhật tên', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50), height: 1.3)),
                        const SizedBox(height: 6),
                        _buildIconTextRow(Icons.qr_code_rounded, "Mã TS: ", repair.maTaiSanId),
                        _buildIconTextRow(Icons.account_balance_wallet_rounded, "Mã QLTS: ", repair.maqlts),
                        _buildIconTextRow(Icons.location_on_rounded, "Vị trí: ", repair.vitrisudung),
                        
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Nội dung báo hỏng:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                              const SizedBox(height: 4),
                              Text(repair.noidung ?? 'Không có mô tả', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                            ],
                          ),
                        ),
                        if (repair.ghichu != null && repair.ghichu!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text("Ghi chú: ${repair.ghichu}", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ),

                  // FOOTER CARD - VÙNG CHỨA CÁC NÚT ĐỘNG
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFooterRow(Icons.person_rounded, Colors.blue.shade600, "Người lập:", _formatEmployee(repair.nguoilap, repair.tenNguoiLap)),
                        _buildFooterRow(Icons.outbound_rounded, Colors.orange.shade700, "Nơi nhận:", repair.tenKhoaNhan ?? repair.khoanhan ?? "Chưa rõ"),
                        _buildFooterRow(Icons.access_time_rounded, Colors.grey.shade600, "Ngày lập:", _formatDate(repair.ngaylap)),
                        
                        const Divider(height: 24, thickness: 1),
                        
                        // LOGIC PHÂN QUYỀN HIỂN THỊ NÚT BẤM (STATE MACHINE)
                        Builder(
                          builder: (context) {
                            final currentManv = authProvider.currentManv;
                            
                            // Các biến phân quyền (Giống 100% detail)
                            bool isCreator = repair.nguoilap == currentManv;
                            bool hasRole23 = authProvider.currentRoleIds.contains(23);
                            bool hasRole25 = authProvider.currentRoleIds.contains(25);
                            bool isHandler = repair.nguoixutri == currentManv; // Đã thêm biến này
                            bool isKhoHandler = repair.maqlts == currentManv;
                            
                            int status = repair.trangthaiphieu ?? 0;
                            List<Widget> actionButtons = [];

                            // Nút Sửa/Xóa (Chỉ hiện trạng thái 0 và đúng người lập)
                            if (status == 0 && isCreator) {
                              actionButtons.add(IconButton(onPressed: () => onDelete(repair.id!), icon: const Icon(Icons.delete_outline_rounded, color: Colors.red)));
                              actionButtons.add(IconButton(onPressed: () => onEdit(repair), icon: Icon(Icons.edit_outlined, color: primaryColor)));
                            }

                            // 1. Trạng thái 0 -> 2 (Quyền 23)
                            if (status == 0 && hasRole23) {
                              actionButtons.add(_buildActionBtn("TIẾP NHẬN", Icons.engineering, Colors.blue.shade600, () => onChangeStatus(repair, 2)));
                            }
                            
                            // 2. Trạng thái 2 -> Các luồng khác (Quyền 23)
                            if (status == 2 && hasRole23) {
                              if (repair.nguoinhan == currentManv) {
                                actionButtons.add(_buildActionBtn("HỦY TIẾP NHẬN", Icons.cancel, Colors.red, () => onChangeStatus(repair, 0)));
                              }
                              
                              if (isHandler) {
                                actionButtons.add(_buildActionBtn("GỬI VẬT TƯ", Icons.inventory, Colors.orange.shade700, () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Vui lòng vào chi tiết phiếu để nhập nội dung gửi vật tư!'),
                                    backgroundColor: Colors.orange,
                                  ));
                                }));
                                
                                actionButtons.add(_buildActionBtn("HOÀN THÀNH", Icons.check_circle, Colors.green, () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('Vui lòng vào chi tiết phiếu để nhập Kết quả xử lý!'),
                                    backgroundColor: Colors.orange,
                                  ));
                                }));
                              }
                            }

                            // 3. Trạng thái 4 (Quyền 23 & 25)
                            if (status == 4) {
                              if (hasRole23 && isHandler) {
                                actionButtons.add(_buildActionBtn("HỦY GỬI VT", Icons.cancel, Colors.red, () => onChangeStatus(repair, 2)));
                              }
                              if (hasRole25) {
                                actionButtons.add(_buildActionBtn("VT TIẾP NHẬN", Icons.move_to_inbox, Colors.teal, () => onChangeStatus(repair, 5)));
                              }
                            }

                            // 4. Trạng thái 5 (Quyền 25)
                            if (status == 5 && hasRole25 && isKhoHandler) {
                              actionButtons.add(_buildActionBtn("HỦY TIẾP NHẬN", Icons.cancel, Colors.red, () => onChangeStatus(repair, 4)));
                              actionButtons.add(_buildActionBtn("VT CHUYỂN ĐI", Icons.local_shipping, Colors.purple, () => onChangeStatus(repair, 6)));
                            }

                            // 5. Trạng thái 6 (Quyền 25)
                            if (status == 6 && hasRole25 && isKhoHandler) {
                              actionButtons.add(_buildActionBtn("HỦY CHUYỂN ĐI", Icons.cancel, Colors.red, () => onChangeStatus(repair, 5)));
                              actionButtons.add(_buildActionBtn("BÁO HÀNG VỀ", Icons.system_update_alt, Colors.amber.shade700, () => onChangeStatus(repair, 7)));
                            }

                            // 6. Trạng thái 7 (Quyền 25)
                            if (status == 7 && hasRole25 && isKhoHandler) {
                              actionButtons.add(_buildActionBtn("HỦY HÀNG VỀ", Icons.cancel, Colors.red, () => onChangeStatus(repair, 6)));
                            }

                            // 7. Trạng thái 9 (Quyền 23 được phép Hủy Hoàn Thành)
                            if (status == 9 && hasRole23 && isHandler) { // Đã bổ sung check isHandler
                              actionButtons.add(_buildActionBtn("HỦY HOÀN THÀNH", Icons.cancel, Colors.red, () => onChangeStatus(repair, 2)));
                            }

                            return Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                spacing: 8, runSpacing: 8,
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: actionButtons,
                              ),
                            );
                          }
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, 
          padding: const EdgeInsets.symmetric(horizontal: 10), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Widget _buildIconTextRow(IconData icon, String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildFooterRow(IconData icon, Color iconColor, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          SizedBox(width: 75, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}