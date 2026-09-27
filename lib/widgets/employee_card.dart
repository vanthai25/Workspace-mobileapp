import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/nhanvien_model.dart';

class EmployeeCard extends StatelessWidget {
  final NhanVien employee;
  final String tenKhoa;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.tenKhoa,
  });

  @override
  Widget build(BuildContext context) {
    String chucVu = employee.tencv?.trim() ?? '';
    String chucDanh = employee.tenchucdanh?.trim() ?? '';
    String ngaySinh = employee.ngaysinh?.trim() ?? '';

    bool hideChucVu = (chucVu.toLowerCase() == 'k' ||
        chucVu.toLowerCase() == 'không' ||
        chucVu.isEmpty);

    List<String> positionParts = [];
    if (chucDanh.isNotEmpty) positionParts.add(chucDanh);
    if (!hideChucVu) positionParts.add(chucVu);
    String positionText = positionParts.join(' - ');

    final Color primaryColor = const Color(0xFF1274BC);

    return InkWell(
      onTap: () => _showEmployeeDetails(context, primaryColor, positionText, ngaySinh),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 145, // 🔥 Nới nhẹ lên 145 để không bao giờ bị tràn viền
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            // CỘT TRÁI: ẢNH ĐẠI DIỆN
            SizedBox(
              width: 105, // Cố định chiều rộng ảnh
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), bottomLeft: Radius.circular(11)),
                child: _buildImage(),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Text(
                      employee.tennv?.trim() ?? 'N/A',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mã NV: ${employee.manv?.trim() ?? "N/A"}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6), // Giảm khoảng cách này xuống
                    
                    if (ngaySinh.isNotEmpty) _buildSmallInfoRow(Icons.cake_outlined, ngaySinh),
                    _buildSmallInfoRow(Icons.apartment_outlined, tenKhoa),
                    
                    if (positionText.isNotEmpty)
                      _buildSmallInfoRow(
                        Icons.work_outline, 
                        positionText, 
                        textColor: primaryColor, 
                        isBold: true
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, Color primaryColor, String positionText, String ngaySinh) {
    List<String> phones = [];
    if ((employee.dienthoai1 ?? "").trim().isNotEmpty) phones.add(employee.dienthoai1!.trim());
    if ((employee.dienthoai2 ?? "").trim().isNotEmpty) phones.add(employee.dienthoai2!.trim());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),

              SizedBox(
                width: 90, height: 90,
                child: ClipRRect(borderRadius: BorderRadius.circular(45), child: _buildImage()),
              ),
              const SizedBox(height: 12),

              Text(
                employee.tennv?.trim() ?? 'N/A',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                child: Text(employee.tenchucdanh?.isNotEmpty == true ? employee.tenchucdanh! : 'Nhân viên', 
                       style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: _buildInfoBox(Icons.badge_outlined, "MÃ NHÂN VIÊN", employee.manv?.trim() ?? "N/A", primaryColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoBox(Icons.cake_outlined, "NGÀY SINH", ngaySinh.isEmpty ? "N/A" : ngaySinh, primaryColor)),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoBox(Icons.apartment_outlined, "KHOA / PHÒNG", tenKhoa, primaryColor, isFullWidth: true),
              
              if (positionText.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoBox(Icons.work_outline, "CHỨC VỤ & CHỨC DANH", positionText, primaryColor, isFullWidth: true),
              ],
              
              if (employee.tentd?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _buildInfoBox(Icons.school_outlined, "TRÌNH ĐỘ", employee.tentd!.trim(), primaryColor, isFullWidth: true),
              ],

              const SizedBox(height: 24),

              if (phones.isNotEmpty) ...[
                if (phones.length == 1)
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: _buildCallButton(phones[0]),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(child: _buildCallButton(phones[0])),
                      const SizedBox(width: 12),
                      Expanded(child: _buildCallButton(phones[1])),
                    ],
                  )
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoBox(IconData icon, String title, String value, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCallButton(String phone) {
    return ElevatedButton.icon(
      onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.call, color: Colors.white, size: 18),
      label: Text("Gọi $phone", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2ECA6A),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  Widget _buildSmallInfoRow(IconData icon, String text, {Color? textColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0), // Ép khoảng cách các dòng nhỏ lại
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: textColor ?? Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13, 
                color: textColor ?? Colors.grey.shade700,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    bool hasImage = employee.anh != null && employee.anh!.length > 100;
    if (hasImage) {
      try {
        String base64String = employee.anh!.contains(',') ? employee.anh!.split(',').last : employee.anh!;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => _buildFallbackAvatar());
      } catch (e) {
        return _buildFallbackAvatar();
      }
    } else {
      return _buildFallbackAvatar();
    }
  }

  Widget _buildFallbackAvatar() {
    String initial = employee.tennv?.isNotEmpty == true ? employee.tennv![0].toUpperCase() : '?';
    return Container(
      color: Colors.grey.shade100,
      width: double.infinity, height: double.infinity,
      child: Center(child: Text(initial, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1274BC).withOpacity(0.4)))),
    );
  }
}