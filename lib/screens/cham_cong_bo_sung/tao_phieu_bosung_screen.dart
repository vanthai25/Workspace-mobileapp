import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/chamcong_bosung_service.dart';
import '../../utils/helpers.dart';
import 'cham_cong_bo_sung_web_design.dart';

class TaoPhieuBoSungScreen extends StatefulWidget {
  final String ngayThieu;

  /// Mã cơ sở dùng cho API V2:
  /// BVHV, PKCM, PKKX, PKSD, PKTB
  final String coSo;

  final int? editId;
  final String? oldNoiDung;
  final String? oldLyDo;
  final double? oldTongCong;

  const TaoPhieuBoSungScreen({
    super.key,
    required this.ngayThieu,
    required this.coSo,
    this.editId,
    this.oldNoiDung,
    this.oldLyDo,
    this.oldTongCong,
  });

  @override
  State<TaoPhieuBoSungScreen> createState() => _TaoPhieuBoSungScreenState();
}

class _TaoPhieuBoSungScreenState extends State<TaoPhieuBoSungScreen> {
  final ChamCongBoSungService _apiService = ChamCongBoSungService();

  final Color primaryColor = const Color(0xFF1274BC);

  final TextEditingController _lyDoController = TextEditingController();

  final TextEditingController _noiDungKhacController = TextEditingController();

  bool _isLoading = false;

  String _noiDungSelected = 'Quên quét vân tay Sáng';

  double _tongCongSelected = 1.0;

  final List<String> _listNoiDung = [
    'Quên quét vân tay Sáng',
    'Quên quét vân tay Chiều',
    'Quên quét vân tay cả ngày',
    'Đi công tác / Làm việc bên ngoài',
    'Lý do khác',
  ];

  bool get _isEdit => widget.editId != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      final String oldNoiDung = widget.oldNoiDung?.trim() ?? '';

      if (_listNoiDung.contains(oldNoiDung)) {
        _noiDungSelected = oldNoiDung;
      } else {
        _noiDungSelected = 'Lý do khác';
        _noiDungKhacController.text = oldNoiDung;
      }

      _lyDoController.text = widget.oldLyDo ?? '';

      final double oldTongCong = widget.oldTongCong ?? 1.0;

      // Dropdown hiện chỉ có 0.5 và 1.0.
      _tongCongSelected = oldTongCong <= 0.5 ? 0.5 : 1.0;
    }
  }

  @override
  void dispose() {
    _lyDoController.dispose();
    _noiDungKhacController.dispose();
    super.dispose();
  }

  String get _tenCoSo {
    switch (widget.coSo.trim().toUpperCase()) {
      case 'PKCM':
      case 'CHANMONG':
        return 'Phòng khám Chấn Mộng';

      case 'PKKX':
      case 'KIMXUYEN':
        return 'Phòng khám Kim Xuyên';

      case 'PKSD':
      case 'SONDUONG':
        return 'Phòng khám Sơn Dương';

      case 'PKTB':
      case 'THANHBA':
        return 'Phòng khám Thanh Ba';

      case 'BVHV':
      case 'BVHUNGVUONG':
      default:
        return 'Bệnh viện Hùng Vương';
    }
  }

  String get _maCoSoApi {
    final String value = widget.coSo.trim().toUpperCase();

    switch (value) {
      case 'PKCM':
      case 'CHANMONG':
        return 'PKCM';

      case 'PKKX':
      case 'KIMXUYEN':
        return 'PKKX';

      case 'PKSD':
      case 'SONDUONG':
        return 'PKSD';

      case 'PKTB':
      case 'THANHBA':
        return 'PKTB';

      case 'BVHV':
      case 'BVHUNGVUONG':
      default:
        return 'BVHV';
    }
  }

  DateTime? _parseNgay(String value) {
    final String raw = value.trim();

    if (raw.isEmpty) {
      return null;
    }

    // Dạng API ISO:
    // 2026-08-01 hoặc 2026-08-01T00:00:00
    final DateTime? isoDate = DateTime.tryParse(raw);

    if (isoDate != null) {
      return isoDate;
    }

    // Dạng đang hiển thị trên Flutter:
    // 01/08/2026
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(raw);
    } catch (_) {
      return null;
    }
  }

  String get _ngayHienThi {
    final DateTime? parsedDate = _parseNgay(widget.ngayThieu);

    if (parsedDate == null) {
      return widget.ngayThieu;
    }

    return DateFormat('dd/MM/yyyy').format(parsedDate);
  }

  String? get _ngayGuiApi {
    final DateTime? parsedDate = _parseNgay(widget.ngayThieu);

    if (parsedDate == null) {
      return null;
    }

    return DateFormat('yyyy-MM-dd').format(parsedDate);
  }

  Future<void> _submitForm() async {
    if (_isLoading) {
      return;
    }

    String noiDungFinal = _noiDungSelected.trim();

    if (_noiDungSelected == 'Lý do khác') {
      noiDungFinal = _noiDungKhacController.text.trim();

      if (noiDungFinal.isEmpty) {
        AppHelpers.showSnackBar(
          'Vui lòng nhập nội dung bổ sung!',
          isError: true,
        );
        return;
      }
    }

    final String lyDo = _lyDoController.text.trim();

    if (lyDo.isEmpty) {
      AppHelpers.showSnackBar(
        'Vui lòng nhập lý do hoặc diễn giải chi tiết!',
        isError: true,
      );
      return;
    }

    final String? ngayThieuApi = _ngayGuiApi;

    if (ngayThieuApi == null) {
      AppHelpers.showSnackBar('Ngày thiếu công không hợp lệ!', isError: true);
      return;
    }

    if (widget.coSo.trim().isEmpty) {
      AppHelpers.showSnackBar(
        'Không xác định được cơ sở chấm công!',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool isSuccess;

    if (_isEdit) {
      isSuccess = await _apiService.updatePhieuV2(
        widget.editId!,
        noiDung: noiDungFinal,
        lyDo: lyDo,
        ngayThieu: ngayThieuApi,
        tongCong: _tongCongSelected,
        coSo: _maCoSoApi,
      );
    } else {
      isSuccess = await _apiService.createPhieuV2(
        noiDung: noiDungFinal,
        lyDo: lyDo,
        ngayThieu: ngayThieuApi,
        tongCong: _tongCongSelected,
        coSo: _maCoSoApi,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!isSuccess) {
      return;
    }

    AppHelpers.showSnackBar(
      _isEdit ? 'Đã cập nhật phiếu thành công!' : 'Đã gửi phiếu thành công!',
      isError: false,
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (useChamCongDesktopWeb(context)) {
      return _buildWeb(context);
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          title: Text(
            _isEdit ? 'Sửa phiếu bổ sung' : 'Tạo phiếu bổ sung',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThongTinNgayVaCoSo(),

                    const SizedBox(height: 16),

                    _buildNoiDungYeuCau(),

                    const SizedBox(height: 30),

                    _buildSubmitButton(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return ChamCongWebPage(
      title: _isEdit ? 'Cập nhật phiếu bổ sung' : 'Tạo phiếu bổ sung',
      subtitle: _isEdit
          ? 'Điều chỉnh nội dung phiếu trước khi gửi lại'
          : 'Bổ sung công cho ngày ghi nhận thiếu dữ liệu',
      icon: _isEdit ? Icons.edit_note_rounded : Icons.note_add_rounded,
      maxWidth: 1180,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: ChamCongWebColors.primary,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final information = _buildThongTinNgayVaCoSo();
                      final request = _buildNoiDungYeuCau();

                      if (constraints.maxWidth < 880) {
                        return Column(
                          children: [
                            information,
                            const SizedBox(height: 16),
                            request,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 360, child: information),
                          const SizedBox(width: 16),
                          Expanded(child: request),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  ChamCongWebCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Kiểm tra kỹ ngày, cơ sở và số công trước khi gửi.',
                            style: TextStyle(
                              color: ChamCongWebColors.muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        SizedBox(width: 220, child: _buildSubmitButton()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildThongTinNgayVaCoSo() {
    return _buildSectionCard(
      title: 'Thông tin bổ sung',
      icon: Icons.calendar_today_rounded,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy_rounded, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ngày ghi nhận thiếu công',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _ngayHienThi,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: Colors.orange.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cơ sở chấm công',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tenCoSo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _maCoSoApi,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoiDungYeuCau() {
    return _buildSectionCard(
      title: 'Nội dung yêu cầu',
      icon: Icons.edit_document,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _noiDungSelected,
            decoration: _inputDecoration(
              'Loại bổ sung *',
              Icons.category_rounded,
            ),
            isExpanded: true,
            items: _listNoiDung.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value == null) {
                return;
              }

              setState(() {
                _noiDungSelected = value;
              });
            },
          ),

          if (_noiDungSelected == 'Lý do khác') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _noiDungKhacController,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                'Nhập nội dung khác *',
                Icons.short_text_rounded,
                hint: 'VD: Quên quét vân tay khi đi công tác...',
              ),
            ),
          ],

          const SizedBox(height: 16),

          DropdownButtonFormField<double>(
            value: _tongCongSelected,
            decoration: _inputDecoration(
              'Số công đề nghị tính *',
              Icons.calculate_rounded,
            ),
            isExpanded: true,
            items: const [
              DropdownMenuItem<double>(
                value: 0.5,
                child: Text(
                  '0.5 công (Nửa ngày)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DropdownMenuItem<double>(
                value: 1.0,
                child: Text(
                  '1.0 công (Cả ngày)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            onChanged: (double? value) {
              if (value == null) {
                return;
              }

              setState(() {
                _tongCongSelected = value;
              });
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _lyDoController,
            maxLines: 4,
            minLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: _inputDecoration(
              'Lý do / Diễn giải chi tiết *',
              Icons.description_rounded,
              hint: 'VD: Do đi công tác đột xuất, quên quẹt thẻ lúc về...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitForm,
        icon: Icon(
          _isEdit ? Icons.save_rounded : Icons.send_rounded,
          color: Colors.white,
        ),
        label: Text(
          _isEdit ? 'CẬP NHẬT PHIẾU' : 'GỬI PHIẾU BỔ SUNG',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1),
          ),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }
}
