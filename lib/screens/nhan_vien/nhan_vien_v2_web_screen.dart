import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/nhan_vien_v2/screens/dialogs/bang_cap_form_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/cchn_form_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/chung_chi_form_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/file_ca_nhan_form_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/hop_dong_form_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/khen_thuong_ky_luat_form_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/nhan_vien_form_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/than_nhan_form_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/vi_tri_cong_tac_form_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/tuyen_dung_candidate_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/tuyen_dung_preview_dialog.dart';
import '../../features/nhan_vien_v2/screens/dialogs/dao_tao_v2/dialogs/excel_download.dart';
import '../../features/nhan_vien_v2/utils/employee_file_open.dart';
import '../../models/nhan_vien_tuyen_dung_v2_models.dart';
import '../../services/api_client.dart';
import '../../services/nhan_vien_tuyen_dung_service.dart';
import '../../models/nhan_vien_v2_models.dart';
import '../../models/khen_thuong_ky_luat_models.dart';
import '../../providers/nhan_vien_v2_provider.dart';
import 'nhan_vien_web_design.dart';

class NhanVienV2WebScreen extends StatefulWidget {
  final Set<int> roleIds;

  const NhanVienV2WebScreen({super.key, required this.roleIds});

  @override
  State<NhanVienV2WebScreen> createState() => _NhanVienV2WebScreenState();
}

class _NhanVienV2WebScreenState extends State<NhanVienV2WebScreen> {
  static const Color _primary = Color(0xFF1274BC);
  static const Color _primaryDark = Color(0xFF0B426B);
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE3EAF2);
  static const Color _mutedText = Color(0xFF66788A);

  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _cmeSearchController = TextEditingController();

  final TextEditingController _chungChiSearchController =
      TextEditingController();

  final TextEditingController _daoTaoNoiVienSearchController =
      TextEditingController();

  final ScrollController _employeeScrollController = ScrollController();
  final ScrollController _cmeScrollController = ScrollController();
  final ScrollController _chungChiScrollController = ScrollController();
  final ScrollController _daoTaoNoiVienScrollController = ScrollController();

  late final NhanVienTuyenDungService _tuyenDungService;

  Timer? _debounce;
  int _profileTabIndex = 0;
  bool _isExportingReport = false;
  final Set<int> _openingEmployeeFileIds = <int>{};
  final Set<String> _openingKhenThuongKyLuatFiles = <String>{};

  // ===========================================================
  // ROLE
  // ===========================================================

  bool hasRole(int roleId) {
    return widget.roleIds.contains(roleId);
  }

  bool _canAddToProfile({
    required NhanVienProfileV2Model profile,
    required int roleId,
  }) {
    return hasRole(roleId) && profile.isNghiViec != true;
  }

  @override
  void initState() {
    super.initState();

    _tuyenDungService = NhanVienTuyenDungService(ApiClient().dio);
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _searchController.dispose();
    _employeeScrollController.dispose();
    _cmeScrollController.dispose();
    _chungChiScrollController.dispose();
    _daoTaoNoiVienScrollController.dispose();
    _cmeSearchController.dispose();
    _chungChiSearchController.dispose();
    _daoTaoNoiVienSearchController.dispose();

    super.dispose();
  }

  // ===========================================================
  // SEARCH
  // ===========================================================

  void _search(String value) {
    // Để suffix icon cập nhật ngay.
    setState(() {});

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) {
        return;
      }

      context.read<NhanVienV2Provider>().setKeyword(value);
    });
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: nhanVienWebTheme(context),
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 72,
          backgroundColor: _surface,
          surfaceTintColor: _surface,
          automaticallyImplyLeading: false,
          shape: const Border(bottom: BorderSide(color: _border)),
          titleSpacing: 24,
          title: const Row(
            children: [
              _HeaderIcon(),
              SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quản lý nhân sự',
                    style: TextStyle(
                      color: Color(0xFF172B3E),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Hồ sơ và quá trình công tác',
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (hasRole(37))
              Padding(
                padding: EdgeInsets.only(right: hasRole(38) ? 10 : 24),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                    side: const BorderSide(color: Color(0xFFAFD5EA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isExportingReport ? null : _exportNhanSuReport,
                  icon: _isExportingReport
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_outlined),
                  label: Text(
                    _isExportingReport ? 'Đang xuất...' : 'Xuất báo cáo',
                  ),
                ),
              ),

            // ===================================================
            // THÊM NHÂN VIÊN
            //
            // Role 38.
            //
            // Nút này không phụ thuộc nhân viên đang chọn
            // có nghỉ việc hay không vì đây là thêm một
            // nhân viên hoàn toàn mới.
            // ===================================================
            if (hasRole(38)) ...[
              // =================================================
              // TỪ HỒ SƠ TUYỂN DỤNG - LUỒNG MỚI
              // =================================================
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 17,
                  ),
                  side: const BorderSide(color: Color(0xFFAFD5EA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _openCreateNhanVienFromTuyenDung,
                icon: const Icon(Icons.person_search_rounded),
                label: const Text('Từ tuyển dụng'),
              ),

              const SizedBox(width: 10),

              // =================================================
              // THÊM NHÂN VIÊN THỦ CÔNG - GIỮ NGUYÊN
              // =================================================
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 17,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _openCreateNhanVien,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Thêm nhân viên'),
                ),
              ),
            ],
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final double panelWidth = constraints.maxWidth >= 1500
                ? 400
                : constraints.maxWidth >= 1100
                ? 360
                : 320;

            return Row(
              children: [
                SizedBox(width: panelWidth, child: _buildLeftPanel()),
                const VerticalDivider(width: 1, thickness: 1, color: _border),
                Expanded(child: _buildRightPanel()),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===========================================================
  // LEFT PANEL
  // ===========================================================

  Widget _buildLeftPanel() {
    return Consumer<NhanVienV2Provider>(
      builder: (context, provider, child) {
        return Material(
          color: _surface,
          child: Column(
            children: [
              _buildFilters(provider),

              const Divider(height: 1),

              Expanded(child: _buildEmployeeList(provider)),

              const Divider(height: 1),

              _buildPagination(provider),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================
  // FILTERS
  // ===========================================================

  Widget _buildFilters(NhanVienV2Provider provider) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Danh sách nhân viên',
                  style: TextStyle(
                    color: Color(0xFF172B3E),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Container(
                  key: ValueKey<int>(provider.totalCount),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5FC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${provider.totalCount}',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (provider.tongQuan != null) ...[
            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _summaryChip(
                  icon: Icons.numbers_rounded,
                  label: 'Mã lớn nhất',
                  value: provider.tongQuan!.maSoLonNhat ?? '-',
                ),

                _summaryChip(
                  icon: Icons.work_outline_rounded,
                  label: 'Đang làm',
                  value: provider.tongQuan!.dangLamViec.toString(),
                ),

                _summaryChip(
                  icon: Icons.work_off_outlined,
                  label: 'Đã nghỉ',
                  value: provider.tongQuan!.daNghiViec.toString(),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          // ===================================================
          // SEARCH
          // ===================================================
          TextField(
            controller: _searchController,
            onChanged: _search,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tìm tên, mã NV, SĐT hoặc CCCD...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () {
                        _debounce?.cancel();

                        _searchController.clear();

                        setState(() {});

                        provider.setKeyword('');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
              isDense: true,
            ),
          ),

          const SizedBox(height: 12),

          // ===================================================
          // KHOA PHÒNG
          // ===================================================
          DropdownButtonFormField<int?>(
            key: ValueKey<int?>(provider.selectedKhoaPhong),
            initialValue: provider.selectedKhoaPhong,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            decoration: InputDecoration(
              labelText: 'Khoa / Phòng',
              prefixIcon: const Icon(Icons.apartment_rounded, size: 19),
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Tất cả khoa/phòng'),
              ),
              ...provider.khoaPhongs.map((item) {
                return DropdownMenuItem<int?>(
                  value: item.idKhoaPhong,
                  child: Text(
                    item.tenKhoaPhong ?? 'Không tên',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: provider.isLoading || provider.isPageLoading
                ? null
                : provider.setKhoaPhong,
          ),

          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey<String>('${provider.sortBy}_${provider.sortOrder}'),
            initialValue: '${provider.sortBy}_${provider.sortOrder}',
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            decoration: InputDecoration(
              labelText: 'Sắp xếp',
              prefixIcon: const Icon(Icons.sort_rounded, size: 19),
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem<String>(
                value: 'maSo_desc',
                child: Text('Mã NV mới nhất'),
              ),
              DropdownMenuItem<String>(
                value: 'maSo_asc',
                child: Text('Mã NV cũ nhất'),
              ),
              DropdownMenuItem<String>(
                value: 'hoVaTen_asc',
                child: Text('Tên A → Z'),
              ),
              DropdownMenuItem<String>(
                value: 'hoVaTen_desc',
                child: Text('Tên Z → A'),
              ),
            ],
            onChanged: provider.isLoading || provider.isPageLoading
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    final parts = value.split('_');

                    provider.setSort(by: parts[0], order: parts[1]);
                  },
          ),

          const SizedBox(height: 8),
          // ===================================================
          // NGHỈ VIỆC
          // ===================================================
          Container(
            decoration: BoxDecoration(
              color: provider.includeNghiViec
                  ? const Color(0xFFFFF7E9)
                  : const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: provider.includeNghiViec
                    ? const Color(0xFFF1D5A5)
                    : _border,
              ),
            ),
            child: SwitchListTile.adaptive(
              value: provider.includeNghiViec,
              contentPadding: const EdgeInsets.only(left: 12, right: 8),
              dense: true,
              visualDensity: VisualDensity.compact,
              title: const Text(
                'Bao gồm nhân viên nghỉ việc',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onChanged: provider.isLoading || provider.isPageLoading
                  ? null
                  : (value) => provider.setIncludeNghiViec(value),
            ),
          ),

          // ===================================================
          // TOTAL
          // ===================================================
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Đang tải danh sách...',
                    style: TextStyle(color: _mutedText, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _primary),

          const SizedBox(width: 5),

          Text(
            '$label: ',
            style: const TextStyle(color: _mutedText, fontSize: 9.5),
          ),

          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF244259),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
  // ===========================================================
  // EMPLOYEE LIST
  // ===========================================================

  Widget _buildEmployeeList(NhanVienV2Provider provider) {
    if (provider.isLoading && provider.danhSach.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.danhSach.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 38,
                color: Color(0xFFC43C35),
              ),
              const SizedBox(height: 10),
              Text(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () {
                        provider.loadDanhSach();
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.danhSach.isEmpty) {
      return const Center(child: Text('Không có nhân viên.'));
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Scrollbar(
            controller: _employeeScrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _employeeScrollController,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              itemCount: provider.danhSach.length,
              itemBuilder: (context, index) {
                final nv = provider.danhSach[index];
                final bool selected = provider.selectedMaSo == nv.maSo;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFEAF5FC) : Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF88C7EA)
                          : Colors.transparent,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: InkWell(
                    onTap: () {
                      if (!selected) {
                        setState(() => _profileTabIndex = 0);
                      }

                      provider.selectNhanVien(
                        nv.maSo,
                        loadKhenThuongKyLuat: hasRole(53),
                      );
                    },
                    borderRadius: BorderRadius.circular(13),
                    hoverColor: const Color(0xFFF1F7FB),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _avatar(nv.avatarBytes, nv.hoVaTen, radius: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nv.hoVaTen ?? nv.maSo,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF172B3E),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (nv.taiKhoanDaKhoa)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFE5E5),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.lock_outline_rounded,
                                              size: 10,
                                              color: Color(0xFFB42318),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Đã khóa',
                                              style: TextStyle(
                                                color: Color(0xFFB42318),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (nv.isNghiViec == true)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEAD0),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          'Nghỉ việc',
                                          style: TextStyle(
                                            color: Color(0xFF935B0A),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mã NV  •  ${nv.maSo}',
                                  style: const TextStyle(
                                    color: _mutedText,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (nv.tenKhoaPhong != null &&
                                    nv.tenKhoaPhong!.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.business_outlined,
                                          size: 14,
                                          color: _primary,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            nv.tenKhoaPhong!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF52677A),
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (nv.tenChucDanh != null &&
                                    nv.tenChucDanh!.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.badge_outlined,
                                          size: 14,
                                          color: Color(0xFF7890A4),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            nv.tenChucDanh!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Color(0xFF66788A),
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: _primary,
                              size: 19,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (provider.isPageLoading)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  // ===========================================================
  // PAGINATION
  // ===========================================================

  Widget _buildPagination(NhanVienV2Provider provider) {
    final int totalPages = provider.totalPages <= 0 ? 1 : provider.totalPages;

    final bool busy = provider.isLoading || provider.isPageLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: const Color(0xFFFBFCFE),
      child: Row(
        children: [
          _paginationButton(
            tooltip: 'Trang đầu',
            icon: Icons.first_page_rounded,
            onPressed: !busy && provider.currentPage > 1
                ? () {
                    _changePage(provider, 1);
                  }
                : null,
          ),
          const SizedBox(width: 4),
          _paginationButton(
            tooltip: 'Trang trước',
            icon: Icons.chevron_left_rounded,
            onPressed: !busy && provider.currentPage > 1
                ? () {
                    _changePage(provider, provider.currentPage - 1);
                  }
                : null,
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: busy
                  ? null
                  : () {
                      _showGoToPageDialog(provider);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Trang ${provider.currentPage} / $totalPages',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF334A5E),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${provider.totalCount} hồ sơ • Bấm để đi tới trang',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _mutedText, fontSize: 8.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _paginationButton(
            tooltip: 'Trang sau',
            icon: Icons.chevron_right_rounded,
            onPressed: !busy && provider.currentPage < provider.totalPages
                ? () {
                    _changePage(provider, provider.currentPage + 1);
                  }
                : null,
          ),
          const SizedBox(width: 4),
          _paginationButton(
            tooltip: 'Trang cuối',
            icon: Icons.last_page_rounded,
            onPressed: !busy && provider.currentPage < provider.totalPages
                ? () {
                    _changePage(provider, provider.totalPages);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _changePage(NhanVienV2Provider provider, int page) async {
    await provider.goToPage(page);

    if (!mounted) {
      return;
    }

    if (_employeeScrollController.hasClients) {
      _employeeScrollController.jumpTo(0);
    }
  }

  Future<void> _showGoToPageDialog(NhanVienV2Provider provider) async {
    final int maxPage = provider.totalPages <= 0 ? 1 : provider.totalPages;

    final controller = TextEditingController(
      text: provider.currentPage.toString(),
    );

    final int? page = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đi tới trang'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Nhập trang từ 1 đến $maxPage',
              prefixIcon: const Icon(Icons.find_in_page_outlined),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              final value = int.tryParse(controller.text.trim());

              if (value == null) {
                return;
              }

              Navigator.pop(dialogContext, value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());

                if (value == null) {
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Đi tới'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (page == null || !mounted) {
      return;
    }

    await _changePage(provider, page);
  }

  Future<void> _editFileInfoInline(
    NhanVienProfileV2Model profile,
    NhanVienTaiLieuKhacV2Model file,
  ) async {
    final provider = context.read<NhanVienV2Provider>();
    final tenController = TextEditingController(text: file.tenTaiLieu);
    final ghiChuController = TextEditingController(text: file.ghiChu);

    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật thông tin file'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(
                labelText: 'Tên tài liệu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ghiChuController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await provider.updateTaiLieuKhac(
                maSo: profile.maSo,
                idTaiLieu: file.idTaiLieuNhanVien,
                tenTaiLieu: tenController.text,
                ghiChu: ghiChuController.text,
              );
              if (ctx.mounted) Navigator.pop(ctx, ok);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (success == true && mounted) {
      _showMessage('Cập nhật thông tin file thành công.');
    } else if (success == false &&
        mounted &&
        provider.taiLieuKhacError != null) {
      _showMessage(provider.taiLieuKhacError!, isError: true);
    }
  }

  // Hàm xóa nhanh file
  Future<void> _deleteFileInline(
    String maSo,
    int idTaiLieu,
    String fileName,
  ) async {
    await _deleteRelatedRecord(
      dialogTitle: 'Xóa file cá nhân?',
      itemName: fileName,
      successMessage: 'Đã xóa file cá nhân thành công.',
      fallbackError: 'Không thể xóa file cá nhân.',
      deleteAction: (provider) =>
          provider.deleteTaiLieuKhac(maSo: maSo, idTaiLieu: idTaiLieu),
    );
  }

  Future<void> _unlinkViTriFile(
    NhanVienProfileV2Model profile,
    ViTriCongTacV2Model position,
  ) async {
    final ngayBatDau = position.ngayBatDau;
    if (ngayBatDau == null) {
      _showMessage('Vị trí công tác thiếu ngày bắt đầu.', isError: true);
      return;
    }

    await _deleteRelatedRecord(
      dialogTitle: 'Gỡ file khỏi vị trí công tác?',
      itemName: position.fileName ?? 'File đính kèm',
      successMessage: 'Đã gỡ file khỏi vị trí công tác.',
      fallbackError: 'Không thể gỡ file khỏi vị trí công tác.',
      deleteAction: (provider) => provider.updateViTriCongTac(
        profile.maSo,
        position.idViTriCongTac,
        <String, dynamic>{
          'idChucDanh': position.idChucDanh,
          'idChucVu': position.idChucVu,
          'idKhoaPhong': position.idKhoaPhong,
          'idToDoi': position.idToDoi,
          'ngayBatDau': ngayBatDau.toIso8601String(),
          'ngayKetThuc': position.ngayKetThuc?.toIso8601String(),
          'fileId': null,
          'isKiemNhiem': position.isKiemNhiem,
          'idTinhTrang': position.idTinhTrang,
        },
      ),
    );
  }

  Future<void> _unlinkHopDongFile(
    NhanVienProfileV2Model profile,
    HopDongLaoDongV2Model contract,
  ) async {
    await _deleteRelatedRecord(
      dialogTitle: 'Gỡ file khỏi hợp đồng?',
      itemName: contract.fileName ?? 'File đính kèm',
      successMessage: 'Đã gỡ file khỏi hợp đồng lao động.',
      fallbackError: 'Không thể gỡ file khỏi hợp đồng lao động.',
      deleteAction: (provider) => provider
          .updateHopDong(profile.maSo, contract.idHopDong, <String, dynamic>{
            'soHopDong': contract.soHopDong,
            'idLoaiHopDong': contract.idLoaiHopDong,
            'ngayKy': contract.ngayKy?.toIso8601String(),
            'ngayKetThuc': contract.ngayKetThuc?.toIso8601String(),
            'idFile': null,
          }),
    );
  }

  List<_EmployeeFileEntry> _employeeFiles(
    NhanVienProfileV2Model profile,
    NhanVienV2Provider provider,
  ) {
    final files = <int, _EmployeeFileEntry>{};

    for (final file in provider.taiLieuKhac) {
      if (file.idFile <= 0) continue;
      files[file.idFile] = _EmployeeFileEntry(
        idFile: file.idFile,
        fileName: file.fileName,
        fileType: file.fileType,
        title: file.tenTaiLieu?.trim().isNotEmpty == true
            ? file.tenTaiLieu!.trim()
            : file.fileName,
        source: 'File cá nhân',
        date: file.ngayTaiLieu,
        note: file.ghiChu,
        personalFile: file,
      );
    }

    final positions = <ViTriCongTacV2Model>[
      ...profile.viTriCongTacHienTai,
      ...profile.lichSuViTriCongTac,
    ];
    for (final position in positions) {
      final idFile = position.fileId;
      final fileName = position.fileName;
      if (idFile == null || idFile <= 0 || fileName?.trim().isEmpty != false) {
        continue;
      }
      files.putIfAbsent(
        idFile,
        () => _EmployeeFileEntry(
          idFile: idFile,
          fileName: fileName!,
          fileType: position.fileType,
          title: fileName,
          source:
              'Vị trí công tác${position.tenKhoaPhong?.trim().isNotEmpty == true ? ' – ${position.tenKhoaPhong}' : ''}',
          date: position.ngayBatDau,
          position: position,
        ),
      );
    }

    for (final contract in profile.hopDongLaoDong) {
      final idFile = contract.idFile;
      final fileName = contract.fileName;
      if (idFile == null || idFile <= 0 || fileName?.trim().isEmpty != false) {
        continue;
      }
      files.putIfAbsent(
        idFile,
        () => _EmployeeFileEntry(
          idFile: idFile,
          fileName: fileName!,
          fileType: contract.fileType,
          title: fileName,
          source: 'Hợp đồng ${contract.soHopDong}',
          date: contract.ngayKy,
          contract: contract,
        ),
      );
    }

    return files.values.toList();
  }

  Future<void> _openEmployeeFile(
    String maSo,
    int idFile,
    String fileName,
    String? fileType,
  ) async {
    if (_openingEmployeeFileIds.contains(idFile)) return;

    setState(() => _openingEmployeeFileIds.add(idFile));
    final provider = context.read<NhanVienV2Provider>();
    final bytes = await provider.downloadNhanVienFile(
      maSo: maSo,
      idFile: idFile,
    );

    if (!mounted) return;
    setState(() => _openingEmployeeFileIds.remove(idFile));

    if (bytes == null) {
      _showMessage(
        provider.errorMessage ?? 'Không thể mở file đính kèm.',
        isError: true,
      );
      return;
    }

    await openEmployeeFile(
      bytes: bytes,
      fileName: fileName,
      fileType: fileType,
    );
  }

  Widget _paginationButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onPressed == null ? const Color(0xFFF1F4F7) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: const BorderSide(color: _border),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 20,
              color: onPressed == null ? const Color(0xFFB6C1CB) : _primary,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================
  // RIGHT PANEL
  // ===========================================================

  Widget _buildRightPanel() {
    return Consumer<NhanVienV2Provider>(
      builder: (context, provider, child) {
        if (provider.selectedMaSo == null) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.badge_outlined, size: 64),
                SizedBox(height: 12),
                Text('Chọn một nhân viên để xem thông tin'),
              ],
            ),
          );
        }

        if (provider.isLoadingProfile) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = provider.profile;

        if (profile == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined, size: 54),

                const SizedBox(height: 12),

                Text(
                  provider.errorMessage ?? 'Không tải được hồ sơ.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: provider.refreshProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        return _buildProfile(profile, provider);
      },
    );
  }

  // ===========================================================
  // PROFILE
  // ===========================================================

  Widget _buildProfile(
    NhanVienProfileV2Model profile,
    NhanVienV2Provider provider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useTwoColumns = constraints.maxWidth >= 980;
        final double horizontalPadding = constraints.maxWidth >= 1250 ? 24 : 16;

        final Widget currentPosition = _section(
          title: 'Vị trí công tác hiện tại',
          icon: Icons.business_center_outlined,
          itemCount: profile.viTriCongTacHienTai.length,
          trailing: _canAddToProfile(profile: profile, roleId: 40)
              ? _addButton('Thêm vị trí', () => _openCreateViTri(profile))
              : null,
          child: _buildViTriHienTai(profile),
        );
        final Widget positionHistory = _section(
          title: 'Lịch sử công tác',
          icon: Icons.history_rounded,
          itemCount: profile.lichSuViTriCongTac.length,
          child: _buildViTriHistory(profile),
        );
        final Widget practiceHistory = _section(
          title: 'Thực hành tại khoa/phòng',
          icon: Icons.medical_services_outlined,
          itemCount: profile.thucHanhs.length,
          child: _buildThucHanhHistory(profile),
        );
        final Widget cme = _section(
          title: 'Chứng chỉ CME',
          icon: Icons.school_outlined,
          itemCount: profile.chungChiCme.length,
          trailing: _canAddToProfile(profile: profile, roleId: 41)
              ? _addButton('Thêm CME', () => _openChungChi(profile, cme: true))
              : null,
          child: _buildChungChi(profile, profile.chungChiCme, cme: true),
        );
        final Widget otherCertificates = _section(
          title: 'Chứng chỉ khác',
          icon: Icons.workspace_premium_outlined,
          itemCount: profile.chungChiKhac.length,
          trailing: _canAddToProfile(profile: profile, roleId: 41)
              ? _addButton(
                  'Thêm chứng chỉ',
                  () => _openChungChi(profile, cme: false),
                )
              : null,
          child: _buildChungChi(profile, profile.chungChiKhac, cme: false),
        );
        final Widget internalTraining = _section(
          title: 'Đào tạo nội viện',

          icon: Icons.school_rounded,

          itemCount: profile.daoTaoNoiVien.length,
          child: _buildDaoTaoNoiVien(profile),
        );
        final Widget degrees = _section(
          title: 'Bằng cấp',
          icon: Icons.account_balance_outlined,
          itemCount: profile.bangCap.length,
          trailing: _canAddToProfile(profile: profile, roleId: 46)
              ? _addButton('Thêm bằng cấp', () => _openBangCap(profile))
              : null,
          child: _buildBangCap(profile),
        );
        final Widget practicingCertificates = _section(
          title: 'Chứng chỉ hành nghề',
          icon: Icons.medical_information_outlined,
          itemCount: profile.cchn.length,
          trailing: _canAddToProfile(profile: profile, roleId: 43)
              ? _addButton('Thêm CCHN', () => _openCchn(profile))
              : null,
          child: _buildCchn(profile),
        );
        final Widget contracts = _section(
          title: 'Hợp đồng lao động',
          icon: Icons.description_outlined,
          itemCount: profile.hopDongLaoDong.length,
          trailing: _canAddToProfile(profile: profile, roleId: 44)
              ? _addButton('Thêm hợp đồng', () => _openHopDong(profile))
              : null,
          child: _buildHopDong(profile),
        );
        final Widget relatives = _section(
          title: 'Thân nhân',
          icon: Icons.family_restroom_outlined,
          itemCount: profile.thanNhan.length,
          trailing: _canAddToProfile(profile: profile, roleId: 45)
              ? _addButton('Thêm thân nhân', () => _openThanNhan(profile))
              : null,
          child: _buildThanNhan(profile),
        );
        final Widget rewards = _section(
          title: 'Khen thưởng',
          icon: Icons.emoji_events_outlined,
          itemCount: provider.khenThuongKyLuat.khenThuongs.length,
          trailing: _canAddToProfile(profile: profile, roleId: 53)
              ? _addButton('Thêm khen thưởng', () => _openKhenThuong(profile))
              : null,
          child: _buildKhenThuong(profile, provider),
        );
        final Widget disciplines = _section(
          title: 'Kỷ luật',
          icon: Icons.gavel_outlined,
          itemCount: provider.khenThuongKyLuat.kyLuats.length,
          trailing: _canAddToProfile(profile: profile, roleId: 53)
              ? _addButton('Thêm kỷ luật', () => _openKyLuat(profile))
              : null,
          child: _buildKyLuat(profile, provider),
        );
        final employeeFiles = _employeeFiles(profile, provider);
        final Widget fileCaNhanTab = _section(
          title: 'File cá nhân của nhân viên',
          icon: Icons.insert_drive_file_outlined,
          itemCount: employeeFiles.length,
          trailing: _canAddToProfile(profile: profile, roleId: 51)
              ? _addButton('Thêm file', () => _openFileCaNhan(profile))
              : null,
          child: provider.isLoadingTaiLieuKhac && employeeFiles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : employeeFiles.isEmpty
              ? _emptySection(
                  icon: Icons.insert_drive_file_outlined,
                  message: 'Chưa có file cá nhân nào.',
                )
              : _boundedRecordList(
                  controller: _chungChiScrollController,
                  children: employeeFiles.map((e) {
                    final details = <String>[];

                    details.add('Nguồn: ${e.source}');
                    if (e.note != null && e.note!.trim().isNotEmpty) {
                      details.add('Ghi chú: ${e.note}');
                    }
                    if (e.date != null) {
                      details.add('Ngày: ${_date(e.date)}');
                    }

                    final personalFile = e.personalFile;
                    final canManagePosition =
                        e.position != null &&
                        _canAddToProfile(profile: profile, roleId: 40);
                    final canManageContract =
                        e.contract != null &&
                        _canAddToProfile(profile: profile, roleId: 44);

                    return _recordTile(
                      icon: Icons.insert_drive_file_rounded,
                      title: e.title,
                      details: details,
                      onOpen: () => _openEmployeeFile(
                        profile.maSo,
                        e.idFile,
                        e.fileName,
                        e.fileType,
                      ),
                      isOpening: _openingEmployeeFileIds.contains(e.idFile),
                      deleteTooltip: personalFile != null
                          ? 'Xóa file'
                          : 'Gỡ file',
                      onEdit:
                          personalFile != null &&
                              _canAddToProfile(profile: profile, roleId: 51)
                          ? () => _editFileInfoInline(profile, personalFile)
                          : null,
                      onDelete:
                          personalFile != null &&
                              _canAddToProfile(profile: profile, roleId: 51)
                          ? () => _deleteFileInline(
                              profile.maSo,
                              personalFile.idTaiLieuNhanVien,
                              e.title,
                            )
                          : canManagePosition
                          ? () => _unlinkViTriFile(profile, e.position!)
                          : canManageContract
                          ? () => _unlinkHopDongFile(profile, e.contract!)
                          : null,
                    );
                  }).toList(),
                ),
        );
        late final Widget tabContent;
        switch (_profileTabIndex) {
          case 1:
            tabContent = _responsiveSectionRow([
              currentPosition,
              positionHistory,
              practiceHistory,
            ], useTwoColumns: useTwoColumns);
            break;
          case 2:
            tabContent = Column(
              children: [
                _responsiveSectionRow([
                  cme,
                  otherCertificates,
                ], useTwoColumns: useTwoColumns),

                _responsiveSectionRow([internalTraining], useTwoColumns: false),

                _responsiveSectionRow([
                  degrees,
                  practicingCertificates,
                ], useTwoColumns: useTwoColumns),
              ],
            );

            break;
          case 3:
            tabContent = Column(
              children: [
                _responsiveSectionRow([
                  contracts,
                  relatives,
                ], useTwoColumns: useTwoColumns),
                if (hasRole(53))
                  _responsiveSectionRow([
                    rewards,
                    disciplines,
                  ], useTwoColumns: useTwoColumns),
              ],
            );
            break;
          case 4:
            // Tab 4: File cá nhân nằm ở tab riêng biệt hoàn toàn
            tabContent = _responsiveSectionRow([
              fileCaNhanTab,
            ], useTwoColumns: false);
            break;
          default:
            tabContent = Column(
              children: [
                _section(
                  title: 'Thông tin hành chính',
                  icon: Icons.person_outline_rounded,
                  child: _buildAdministrative(profile),
                ),
                currentPosition,
              ],
            );
            break;
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            18,
            horizontalPadding,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(profile, provider),
              if (profile.isNghiViec == true) ...[
                const SizedBox(height: 12),
                _buildNghiViecBanner(),
              ],
              const SizedBox(height: 14),
              _buildProfileMetrics(profile),
              const SizedBox(height: 14),
              _buildProfileNavigation(profile, provider),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey<int>(_profileTabIndex),
                  child: tabContent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileMetrics(NhanVienProfileV2Model profile) {
    final totalDaoTao =
        profile.chungChiCme.length +
        profile.chungChiKhac.length +
        profile.daoTaoNoiVien.length +
        profile.bangCap.length +
        profile.cchn.length;

    final metrics = <Widget>[
      NhanVienMetricCard(
        label: 'Trạng thái nhân sự',
        value: profile.isNghiViec == true ? 'Đã nghỉ việc' : 'Đang làm việc',
        icon: profile.isNghiViec == true
            ? Icons.work_off_outlined
            : Icons.verified_user_outlined,
        color: profile.isNghiViec == true
            ? NhanVienWebColors.warning
            : NhanVienWebColors.success,
      ),
      NhanVienMetricCard(
        label: 'Đào tạo & chứng chỉ',
        value: '$totalDaoTao',
        icon: Icons.workspace_premium_outlined,
        color: const Color(0xFF7B61A8),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map((metric) => SizedBox(width: width, child: metric))
              .toList(),
        );
      },
    );
  }

  Widget _buildProfileNavigation(
    NhanVienProfileV2Model profile,
    NhanVienV2Provider provider,
  ) {
    final employeeFileCount = _employeeFiles(profile, provider).length;
    final items = <({String label, IconData icon, int? count})>[
      (label: 'Tổng quan', icon: Icons.dashboard_outlined, count: null),
      (
        label: 'Quá trình công tác',
        icon: Icons.account_tree_outlined,
        count: profile.lichSuViTriCongTac.length,
      ),
      (
        label: 'Đào tạo & chứng chỉ',
        icon: Icons.school_outlined,
        count:
            profile.chungChiCme.length +
            profile.chungChiKhac.length +
            profile.daoTaoNoiVien.length +
            profile.bangCap.length +
            profile.cchn.length,
      ),
      (
        label: hasRole(53) ? 'Hợp đồng & hồ sơ' : 'Hợp đồng & thân nhân',
        icon: Icons.family_restroom_outlined,
        count:
            profile.hopDongLaoDong.length +
            profile.thanNhan.length +
            (hasRole(53)
                ? provider.khenThuongKyLuat.khenThuongs.length +
                      provider.khenThuongKyLuat.kyLuats.length
                : 0),
      ),
      (
        label: 'File cá nhân',
        icon: Icons.folder_shared_outlined,
        count: employeeFileCount,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: NhanVienWebColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NhanVienWebColors.border),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = _profileTabIndex == index;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 5),
              child: Material(
                color: selected ? const Color(0xFFE7F3FA) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() => _profileTabIndex = index);
                    if (index == 4) {
                      // Nếu bấm vào tab số 4 (File cá nhân)
                      context.read<NhanVienV2Provider>().loadTaiLieuKhac(
                        profile.maSo,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 11,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: selected
                              ? NhanVienWebColors.primary
                              : NhanVienWebColors.muted,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? NhanVienWebColors.primaryDark
                                  : NhanVienWebColors.muted,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item.count != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFFF0F3F6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${item.count}',
                              style: TextStyle(
                                color: selected
                                    ? NhanVienWebColors.primary
                                    : NhanVienWebColors.muted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _responsiveSectionRow(
    List<Widget> children, {
    required bool useTwoColumns,
  }) {
    if (!useTwoColumns) {
      return Column(children: children);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: children.first),
        const SizedBox(width: 14),
        Expanded(child: children.last),
      ],
    );
  }

  Widget _buildNghiViecBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD59A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.work_off_outlined, color: Color(0xFF9A5C00)),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Nhân viên này đã nghỉ việc. '
              'Không thể thêm mới vị trí công tác, chứng chỉ, bằng cấp, '
              'CCHN, hợp đồng hoặc thân nhân.',
              style: TextStyle(
                color: Color(0xFF744600),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // PROFILE HEADER
  // ===========================================================

  Widget _buildProfileHeader(
    NhanVienProfileV2Model profile,
    NhanVienV2Provider provider,
  ) {
    final List<Widget> metadata = [
      _profileMetaChip(Icons.badge_outlined, 'Mã ${profile.maSo}'),
      if (_hasText(profile.tenKhoaPhong))
        _profileMetaChip(Icons.apartment_rounded, profile.tenKhoaPhong!),
      if (_hasText(profile.tenChucDanh))
        _profileMetaChip(Icons.work_outline_rounded, profile.tenChucDanh!),
      if (_hasText(profile.tenChucVu))
        _profileMetaChip(Icons.military_tech_outlined, profile.tenChucVu!),
      if (profile.isNghiViec == true)
        _profileMetaChip(
          Icons.work_off_outlined,
          'Đã nghỉ việc',
          warning: true,
        ),
      if (profile.taiKhoanDaKhoa)
        _profileMetaChip(
          Icons.lock_outline_rounded,
          'Đã khóa tài khoản',
          danger: true,
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF2F8FC)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _primaryDark.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Widget identity = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatar(
                profile.avatarBytes,
                profile.hoVaTen,
                radius: constraints.maxWidth < 650 ? 32 : 38,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.hoVaTen ?? profile.maSo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFF142A3D),
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(spacing: 7, runSpacing: 7, children: metadata),
                  ],
                ),
              ),
            ],
          );

          final Widget actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasRole(39) && !profile.taiKhoanDaKhoa)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB42318),
                    backgroundColor: const Color(0xFFFFF4F2),
                    side: const BorderSide(color: Color(0xFFF2B8B5)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  onPressed: provider.isLockingAccount
                      ? null
                      : () => _confirmLockNhanVienAccounts(profile),
                  icon: provider.isLockingAccount
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_person_outlined, size: 18),
                  label: Text(
                    provider.isLockingAccount
                        ? 'Đang khóa...'
                        : 'Khóa tài khoản',
                  ),
                ),
              if (hasRole(39))
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: Color(0xFFAFD5EA)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  onPressed: () => _openEditNhanVien(profile),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Sửa hồ sơ'),
                ),
              _squareActionButton(
                tooltip: 'Làm mới hồ sơ',
                icon: Icons.refresh_rounded,
                onPressed: provider.isLoadingProfile
                    ? null
                    : provider.refreshProfile,
              ),
            ],
          );

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: actions),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: identity),
              const SizedBox(width: 18),
              actions,
            ],
          );
        },
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  Widget _profileMetaChip(
    IconData icon,
    String text, {
    bool warning = false,
    bool danger = false,
  }) {
    final backgroundColor = danger
        ? const Color(0xFFFFE5E5)
        : warning
        ? const Color(0xFFFFEED7)
        : Colors.white;
    final borderColor = danger
        ? const Color(0xFFF2B8B5)
        : warning
        ? const Color(0xFFF0CD94)
        : _border;
    final foregroundColor = danger
        ? const Color(0xFFB42318)
        : warning
        ? const Color(0xFF80500B)
        : _primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: danger || warning
                  ? foregroundColor
                  : const Color(0xFF435A6E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _squareActionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          minimumSize: const Size(44, 44),
          padding: EdgeInsets.zero,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        onPressed: onPressed,
        child: Icon(icon, size: 20),
      ),
    );
  }

  // ===========================================================
  // ADMINISTRATIVE
  // ===========================================================

  Widget _buildAdministrative(NhanVienProfileV2Model p) {
    final entries = <({String label, String? value, IconData icon})>[
      (label: 'Ngày sinh', value: _date(p.namSinh), icon: Icons.cake_outlined),
      (
        label: 'Giới tính',
        value: p.gioiTinh == null
            ? null
            : p.gioiTinh!
            ? 'Nam'
            : 'Nữ',
        icon: Icons.wc_outlined,
      ),
      (
        label: 'Số điện thoại',
        value: p.soDienThoai,
        icon: Icons.phone_outlined,
      ),
      (label: 'CCCD', value: p.soCCCD, icon: Icons.credit_card_outlined),
      (
        label: 'Ngày cấp CCCD',
        value: _date(p.ngayCapCCCD),
        icon: Icons.event_outlined,
      ),
      (
        label: 'Nơi cấp CCCD',
        value: p.noiCapCCCD,
        icon: Icons.location_city_outlined,
      ),
      (
        label: 'Tôn giáo',
        value: p.tenTonGiao,
        icon: Icons.diversity_3_outlined,
      ),
      (
        label: 'Tình trạng hôn nhân',
        value: p.tenTinhTrangHonNhan,
        icon: Icons.favorite_border_rounded,
      ),
      (label: 'Dân tộc', value: p.danToc, icon: Icons.groups_outlined),
      (label: 'Quê quán', value: p.queQuan, icon: Icons.home_work_outlined),
      (label: 'Nơi sinh', value: p.noiSinh, icon: Icons.place_outlined),
      (
        label: 'Thường trú',
        value: p.diaChiThuongTru,
        icon: Icons.home_outlined,
      ),
      (
        label: 'Nơi ở hiện tại',
        value: p.noiOHienTai,
        icon: Icons.location_on_outlined,
      ),
      (label: 'BHXH', value: p.soBHXH, icon: Icons.health_and_safety_outlined),
      (
        label: 'Ngân hàng',
        value: p.tenNH,
        icon: Icons.account_balance_outlined,
      ),
      (label: 'Số tài khoản', value: p.taiKhoanNH, icon: Icons.numbers_rounded),
      (
        label: 'Tên tài khoản',
        value: p.tenTaiKhoanNH,
        icon: Icons.person_pin_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 430
            ? 2
            : 1;
        const double spacing = 10;
        final double width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: entries
              .map(
                (entry) => _info(
                  entry.label,
                  entry.value,
                  icon: entry.icon,
                  width: width,
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ===========================================================
  // VỊ TRÍ HIỆN TẠI
  // ===========================================================

  Widget _buildViTriHienTai(NhanVienProfileV2Model p) {
    if (p.viTriCongTacHienTai.isEmpty) {
      return _emptySection(
        icon: Icons.business_center_outlined,
        message: 'Không có vị trí đang hiệu lực.',
      );
    }

    return Column(
      children: p.viTriCongTacHienTai
          .map((item) => _viTriCard(item, showActions: hasRole(40)))
          .toList(),
    );
  }

  // ===========================================================
  // LỊCH SỬ VỊ TRÍ
  //
  // Bản ghi hiện tại có thể đồng thời xuất hiện trong lịch sử.
  // Menu được giữ ở cả hai nơi để thao tác luôn sẵn có.
  // ===========================================================

  Widget _buildViTriHistory(NhanVienProfileV2Model p) {
    if (p.lichSuViTriCongTac.isEmpty) {
      return _emptySection(
        icon: Icons.history_rounded,
        message: 'Chưa có lịch sử công tác.',
      );
    }

    return Column(
      children: p.lichSuViTriCongTac
          .map((item) => _viTriCard(item, showActions: hasRole(40)))
          .toList(),
    );
  }

  Widget _buildThucHanhHistory(NhanVienProfileV2Model profile) {
    if (profile.thucHanhs.isEmpty) {
      return _emptySection(
        icon: Icons.medical_services_outlined,
        message: 'Nhân sự này chưa có quá trình thực hành tại khoa/phòng.',
      );
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Column(
      children: profile.thucHanhs.map((item) {
        final active =
            item.ngayBatDau != null &&
            item.ngayKetThuc != null &&
            !item.ngayBatDau!.isAfter(today) &&
            !item.ngayKetThuc!.isBefore(today);
        final details = <String>[
          '${_date(item.ngayBatDau) ?? '-'} → ${_date(item.ngayKetThuc) ?? '-'}',
          if (item.tenNguoiHuongDan?.trim().isNotEmpty == true)
            'Người hướng dẫn: ${item.tenNguoiHuongDan} (${item.maSoNguoiHuongDan ?? '-'})',
        ];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF9F5) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? const Color(0xFFB8E2D1) : _border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_hospital_outlined,
                color: active
                    ? const Color(0xFF16805B)
                    : const Color(0xFF7890A4),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tenKhoaPhong ?? 'Chưa xác định khoa/phòng',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF20384D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details.join(' • '),
                      style: const TextStyle(color: _mutedText, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (active)
                const Chip(
                  label: Text('Đang thực hành'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================
  // VỊ TRÍ CARD
  // ===========================================================

  Widget _viTriCard(ViTriCongTacV2Model item, {required bool showActions}) {
    final List<String> subtitleParts = [];

    if (item.tenToDoi != null && item.tenToDoi!.trim().isNotEmpty) {
      subtitleParts.add(item.tenToDoi!);
    }

    if (item.tenChucDanh != null && item.tenChucDanh!.trim().isNotEmpty) {
      subtitleParts.add(item.tenChucDanh!);
    }

    if (item.tenChucVu != null && item.tenChucVu!.trim().isNotEmpty) {
      subtitleParts.add(item.tenChucVu!);
    }

    subtitleParts.add(
      '${_date(item.ngayBatDau) ?? '-'} → '
      '${_date(item.ngayKetThuc) ?? 'Hiện tại'}',
    );

    if (item.tenTinhTrang != null && item.tenTinhTrang!.trim().isNotEmpty) {
      subtitleParts.add(item.tenTinhTrang!);
    }

    if (item.isKiemNhiem == true) {
      subtitleParts.add('Kiêm nhiệm');
    }

    if (item.fileName?.trim().isNotEmpty == true) {
      subtitleParts.add('Tệp: ${item.fileName}');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: item.isHienTai
            ? const Color(0xFFF0F8FC)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isHienTai ? const Color(0xFFB7DAED) : _border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.isHienTai ? const Color(0xFFDCEFF9) : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.apartment_rounded,
              color: item.isHienTai ? _primary : const Color(0xFF7890A4),
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.tenKhoaPhong ?? 'Chưa xác định khoa/phòng',
                        style: const TextStyle(
                          color: Color(0xFF20384D),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (item.isHienTai)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8F1E5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Hiện tại',
                          style: TextStyle(
                            color: Color(0xFF19734B),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitleParts.join('  •  '),
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if ((item.fileId ?? 0) > 0 || showActions)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((item.fileId ?? 0) > 0) ...[
                  _recordActionButton(
                    tooltip: item.fileName?.trim().isNotEmpty == true
                        ? 'Xem ${item.fileName}'
                        : 'Xem file đính kèm',
                    icon: _openingEmployeeFileIds.contains(item.fileId)
                        ? Icons.hourglass_top_rounded
                        : Icons.visibility_outlined,
                    color: const Color(0xFF19734B),
                    onPressed: () => _openEmployeeFile(
                      item.maSo ??
                          context.read<NhanVienV2Provider>().profile?.maSo ??
                          '',
                      item.fileId!,
                      item.fileName ??
                          'vi_tri_cong_tac.${item.fileType ?? 'pdf'}',
                      item.fileType,
                    ),
                  ),
                  if (showActions) const SizedBox(width: 4),
                ],
                if (showActions) ...[
                  _recordActionButton(
                    tooltip: 'Sửa vị trí',
                    icon: Icons.edit_outlined,
                    color: _primary,
                    onPressed: () => _openEditViTri(item),
                  ),
                  const SizedBox(width: 4),
                  _recordActionButton(
                    tooltip: 'Xóa vị trí',
                    icon: Icons.delete_outline,
                    color: const Color(0xFFC43C35),
                    onPressed: () => _deleteViTri(item),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ===========================================================
  // CHỨNG CHỈ
  // ===========================================================
  bool _matchesProfileSearch(String keyword, Iterable<String?> values) {
    final key = keyword.trim().toLowerCase();

    if (key.isEmpty) {
      return true;
    }

    final tokens = key
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    final haystack = values.whereType<String>().join(' ').toLowerCase();

    return tokens.every((token) => haystack.contains(token));
  }

  Widget _profileSearchField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: TextField(
        controller: controller,

        onChanged: (_) {
          setState(() {});
        },

        style: const TextStyle(fontSize: 12.5),

        decoration: InputDecoration(
          hintText: hintText,

          prefixIcon: const Icon(Icons.search_rounded, size: 18),

          suffixIcon: controller.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: 'Xóa tìm kiếm',

                  onPressed: () {
                    controller.clear();

                    setState(() {});
                  },

                  icon: const Icon(Icons.close_rounded, size: 17),
                ),

          filled: true,

          fillColor: const Color(0xFFF7F9FC),

          isDense: true,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),

            borderSide: const BorderSide(color: _border),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),

            borderSide: const BorderSide(color: _primary),
          ),
        ),
      ),
    );
  }

  Widget _boundedRecordList({
    required ScrollController controller,
    required List<Widget> children,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 390),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        radius: const Radius.circular(8),
        child: ListView(
          controller: controller,
          primary: false,
          shrinkWrap: true,
          padding: const EdgeInsets.only(right: 12),
          children: children,
        ),
      ),
    );
  }

  Widget _buildChungChi(
    NhanVienProfileV2Model profile,
    List<ChungChiNhanVienV2Model> list, {
    required bool cme,
  }) {
    final controller = cme ? _cmeSearchController : _chungChiSearchController;
    final scrollController = cme
        ? _cmeScrollController
        : _chungChiScrollController;

    final filtered = list.where((e) {
      return _matchesProfileSearch(controller.text, [
        e.tenChungChi,
        e.soChungChi,
        e.donViDaoTao,
        e.tenHinhThucDaoTao,

        e.ngayCap == null ? null : _date(e.ngayCap),

        e.ngayHetHan == null ? null : _date(e.ngayHetHan),
      ]);
    }).toList();

    return Column(
      children: [
        // =====================================================
        // SEARCH
        // =====================================================
        if (list.isNotEmpty)
          _profileSearchField(
            controller: controller,

            hintText: cme ? 'Tìm CME...' : 'Tìm chứng chỉ...',
          ),

        // =====================================================
        // EMPTY
        // =====================================================
        if (list.isEmpty)
          _emptySection(
            icon: Icons.workspace_premium_outlined,

            message: cme ? 'Chưa có chứng chỉ CME.' : 'Chưa có chứng chỉ.',
          )
        else if (filtered.isEmpty)
          _emptySection(
            icon: Icons.search_off_rounded,

            message: 'Không tìm thấy kết quả phù hợp.',
          )
        else
          // ===================================================
          // DATA
          //
          // Toàn bộ sửa/xóa CME/Chứng chỉ GIỮ NGUYÊN.
          // ===================================================
          _boundedRecordList(
            controller: scrollController,
            children: filtered.map((e) {
              final details = <String>[];
              final int? attachmentId = e.idFile;
              final String attachmentName = e.fileName?.trim() ?? '';
              final bool hasAttachment =
                  attachmentId != null && attachmentId > 0;

              if (e.soChungChi != null && e.soChungChi!.trim().isNotEmpty) {
                details.add('Số: ${e.soChungChi}');
              }

              if (e.donViDaoTao != null && e.donViDaoTao!.trim().isNotEmpty) {
                details.add(e.donViDaoTao!);
              }

              if (e.tenHinhThucDaoTao != null &&
                  e.tenHinhThucDaoTao!.trim().isNotEmpty) {
                details.add(e.tenHinhThucDaoTao!);
              }

              if (e.ngayCap != null) {
                details.add('Cấp: ${_date(e.ngayCap)}');
              }

              if (e.ngayHetHan != null) {
                details.add('Hết hạn: ${_date(e.ngayHetHan)}');
              }

              if (hasAttachment && attachmentName.isNotEmpty) {
                details.add('File: $attachmentName');
              }

              return _recordTile(
                icon: Icons.workspace_premium_outlined,

                title: e.tenChungChi ?? 'Chứng chỉ',

                details: details,

                onOpen: hasAttachment
                    ? () => _openEmployeeFile(
                        profile.maSo,
                        attachmentId,
                        attachmentName.isNotEmpty
                            ? attachmentName
                            : 'chung-chi-cme-${e.idChungChi}',
                        e.fileType,
                      )
                    : null,
                isOpening:
                    hasAttachment &&
                    _openingEmployeeFileIds.contains(attachmentId),

                // =========================================
                // GIỮ NGUYÊN SỬA
                // =========================================
                onEdit: hasRole(41)
                    ? () => _openChungChi(profile, cme: cme, item: e)
                    : null,

                // =========================================
                // GIỮ NGUYÊN XÓA
                // =========================================
                onDelete: hasRole(41)
                    ? () => _deleteRelatedRecord(
                        dialogTitle: cme
                            ? 'Xóa chứng chỉ CME?'
                            : 'Xóa chứng chỉ?',

                        itemName: e.tenChungChi ?? 'Chứng chỉ',

                        successMessage: cme
                            ? 'Đã xóa chứng chỉ CME.'
                            : 'Đã xóa chứng chỉ.',

                        fallbackError: 'Không thể xóa chứng chỉ.',

                        deleteAction: (provider) =>
                            provider.deleteChungChi(profile.maSo, e.idChungChi),
                      )
                    : null,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDaoTaoNoiVien(NhanVienProfileV2Model profile) {
    final list = profile.daoTaoNoiVien;

    final filtered = list.where((e) {
      return _matchesProfileSearch(_daoTaoNoiVienSearchController.text, [
        e.tenLopDaoTao,

        e.donViDaoTao,

        e.baoCaoVien,

        e.donViGiangDay,

        e.tenHinhThucDaoTao,

        e.tenLoaiHinhDaoTao,

        e.diaDiem,

        e.thoiGianDetails,

        e.tpThamDu,

        e.ghiChu,

        e.ngayBatDau == null ? null : _date(e.ngayBatDau),

        e.ngayKetThuc == null ? null : _date(e.ngayKetThuc),
      ]);
    }).toList();

    return Column(
      children: [
        if (list.isNotEmpty)
          _profileSearchField(
            controller: _daoTaoNoiVienSearchController,

            hintText: 'Tìm đào tạo nội viện...',
          ),

        if (list.isEmpty)
          _emptySection(
            icon: Icons.school_rounded,

            message: 'Chưa có đào tạo nội viện.',
          )
        else if (filtered.isEmpty)
          _emptySection(
            icon: Icons.search_off_rounded,

            message: 'Không tìm thấy lớp đào tạo phù hợp.',
          )
        else
          _boundedRecordList(
            controller: _daoTaoNoiVienScrollController,
            children: filtered.map((e) {
              final details = <String>[];

              // ===========================================
              // NGÀY HỌC
              // ===========================================

              if (e.ngayBatDau != null && e.ngayKetThuc != null) {
                details.add(
                  'Thời gian: '
                  '${_date(e.ngayBatDau)}'
                  ' - '
                  '${_date(e.ngayKetThuc)}',
                );
              } else if (e.ngayBatDau != null) {
                details.add(
                  'Ngày học: '
                  '${_date(e.ngayBatDau)}',
                );
              }

              if (e.thoiGianDetails != null &&
                  e.thoiGianDetails!.trim().isNotEmpty) {
                details.add(e.thoiGianDetails!);
              }

              // ===========================================
              // SỐ TIẾT
              // ===========================================

              if (e.soTiet != null) {
                details.add('Số tiết: ${e.soTiet}');
              }

              // ===========================================
              // BÁO CÁO VIÊN
              // ===========================================

              if (e.baoCaoVien != null && e.baoCaoVien!.trim().isNotEmpty) {
                details.add('BCV: ${e.baoCaoVien}');
              }

              // ===========================================
              // ĐƠN VỊ GIẢNG DẠY
              // ===========================================

              if (e.donViGiangDay != null &&
                  e.donViGiangDay!.trim().isNotEmpty) {
                details.add(
                  'Đơn vị giảng dạy: '
                  '${e.donViGiangDay}',
                );
              }

              // ===========================================
              // ĐƠN VỊ ĐÀO TẠO
              // ===========================================

              if (e.donViDaoTao != null && e.donViDaoTao!.trim().isNotEmpty) {
                details.add(
                  'Đơn vị đào tạo: '
                  '${e.donViDaoTao}',
                );
              }

              // ===========================================
              // HÌNH THỨC
              // ===========================================

              if (e.tenHinhThucDaoTao != null &&
                  e.tenHinhThucDaoTao!.trim().isNotEmpty) {
                details.add(e.tenHinhThucDaoTao!);
              }

              if (e.tenLoaiHinhDaoTao != null &&
                  e.tenLoaiHinhDaoTao!.trim().isNotEmpty) {
                details.add(e.tenLoaiHinhDaoTao!);
              }

              // ===========================================
              // TRỰC TIẾP / ONLINE
              // ===========================================

              details.add(e.isDangKyOnline ? 'Online' : 'Trực tiếp');

              // ===========================================
              // ĐỊA ĐIỂM
              // ===========================================

              if (e.diaDiem != null && e.diaDiem!.trim().isNotEmpty) {
                details.add('Địa điểm: ${e.diaDiem}');
              }

              // ===========================================
              // BỔ SUNG SAU
              // ===========================================

              if (e.isBoSungSau) {
                details.add('Bổ sung sau');
              }

              return _recordTile(
                icon: Icons.school_rounded,

                title: e.tenLopDaoTao,

                details: details,

                // =========================================
                // TUYỆT ĐỐI KHÔNG CÓ SỬA
                // =========================================
                onEdit: null,

                // =========================================
                // CHỈ CÓ XÓA
                // Role 41 giống quản lý đào tạo.
                // =========================================
                onDelete: hasRole(41)
                    ? () => _deleteRelatedRecord(
                        dialogTitle: 'Xóa đào tạo nội viện?',

                        itemName: e.tenLopDaoTao,

                        successMessage: 'Đã xóa khỏi đào tạo nội viện.',

                        fallbackError: 'Không thể xóa đào tạo nội viện.',

                        deleteAction: (provider) =>
                            provider.deleteDaoTaoNoiVien(
                              profile.maSo,

                              e.idDangKyDaoTao,
                            ),
                      )
                    : null,
              );
            }).toList(),
          ),
      ],
    );
  }

  // ===========================================================
  // BẰNG CẤP
  // ===========================================================

  Widget _buildBangCap(NhanVienProfileV2Model p) {
    if (p.bangCap.isEmpty) {
      return _emptySection(
        icon: Icons.school_outlined,
        message: 'Chưa có bằng cấp.',
      );
    }

    return Column(
      children: p.bangCap.map((e) {
        final details = <String>[];

        if (e.tenTrinhDo != null && e.tenTrinhDo!.trim().isNotEmpty) {
          details.add(e.tenTrinhDo!);
        }

        if (e.donViDaoTao != null && e.donViDaoTao!.trim().isNotEmpty) {
          details.add(e.donViDaoTao!);
        }

        if (e.namTotNghiep != null && e.namTotNghiep!.trim().isNotEmpty) {
          details.add('Tốt nghiệp: ${e.namTotNghiep}');
        }

        if (e.tenXepLoaiDaoTao != null &&
            e.tenXepLoaiDaoTao!.trim().isNotEmpty) {
          details.add(e.tenXepLoaiDaoTao!);
        }

        return _recordTile(
          icon: Icons.school_outlined,
          title: e.tenBangCap,
          details: details,
          onEdit: hasRole(46) ? () => _openBangCap(p, item: e) : null,
          onDelete: hasRole(46)
              ? () => _deleteRelatedRecord(
                  dialogTitle: 'Xóa bằng cấp?',
                  itemName: e.tenBangCap,
                  successMessage: 'Đã xóa bằng cấp.',
                  fallbackError: 'Không thể xóa bằng cấp.',
                  deleteAction: (provider) =>
                      provider.deleteBangCap(p.maSo, e.idBangCap),
                )
              : null,
        );
      }).toList(),
    );
  }

  // ===========================================================
  // CCHN
  // ===========================================================

  Widget _buildCchn(NhanVienProfileV2Model p) {
    if (p.cchn.isEmpty) {
      return _emptySection(
        icon: Icons.medical_information_outlined,
        message: 'Chưa có chứng chỉ hành nghề.',
      );
    }

    return Column(
      children: p.cchn.map((e) {
        final details = <String>[];

        if (e.noiCap != null && e.noiCap!.trim().isNotEmpty) {
          details.add(e.noiCap!);
        }

        if (e.phamViHoatDong != null && e.phamViHoatDong!.trim().isNotEmpty) {
          details.add(e.phamViHoatDong!);
        }

        if (e.ngayBatDau != null || e.ngayKetThuc != null) {
          details.add(
            '${_date(e.ngayBatDau) ?? '-'} → '
            '${_date(e.ngayKetThuc) ?? 'Hiện tại'}',
          );
        }

        if (e.isPhamViBoSung == true) {
          details.add('Phạm vi bổ sung');
        }

        return _recordTile(
          icon: Icons.medical_information_outlined,
          title: e.soCchn ?? 'Chứng chỉ hành nghề',
          details: details,
          onEdit: hasRole(43) ? () => _openCchn(p, item: e) : null,
          onDelete: hasRole(43)
              ? () => _deleteRelatedRecord(
                  dialogTitle: 'Xóa chứng chỉ hành nghề?',
                  itemName: e.soCchn ?? 'Chứng chỉ hành nghề',
                  successMessage: 'Đã xóa chứng chỉ hành nghề.',
                  fallbackError: 'Không thể xóa chứng chỉ hành nghề.',
                  deleteAction: (provider) =>
                      provider.deleteCchn(p.maSo, e.idCchn),
                )
              : null,
        );
      }).toList(),
    );
  }

  // ===========================================================
  // HỢP ĐỒNG
  // ===========================================================

  Widget _buildHopDong(NhanVienProfileV2Model p) {
    if (p.hopDongLaoDong.isEmpty) {
      return _emptySection(
        icon: Icons.description_outlined,
        message: 'Chưa có hợp đồng lao động.',
      );
    }

    return Column(
      children: p.hopDongLaoDong.map((e) {
        final details = <String>[];

        if (e.tenLoaiHopDong != null && e.tenLoaiHopDong!.trim().isNotEmpty) {
          details.add(e.tenLoaiHopDong!);
        }

        if (e.ngayKy != null) {
          details.add('Ký: ${_date(e.ngayKy)}');
        }

        if (e.ngayKetThuc != null) {
          details.add('Kết thúc: ${_date(e.ngayKetThuc)}');
        }

        if (e.fileName?.trim().isNotEmpty == true) {
          details.add('Tệp: ${e.fileName}');
        }

        return _recordTile(
          icon: Icons.description_outlined,
          title: e.soHopDong,
          details: details,
          onOpen: (e.idFile ?? 0) > 0
              ? () => _openEmployeeFile(
                  p.maSo,
                  e.idFile!,
                  e.fileName ??
                      'hop_dong_${e.soHopDong}.${e.fileType ?? 'pdf'}',
                  e.fileType,
                )
              : null,
          isOpening:
              e.idFile != null && _openingEmployeeFileIds.contains(e.idFile),
          onEdit: hasRole(44) ? () => _openHopDong(p, item: e) : null,
          onDelete: hasRole(44)
              ? () => _deleteRelatedRecord(
                  dialogTitle: 'Xóa hợp đồng lao động?',
                  itemName: e.soHopDong,
                  successMessage: 'Đã xóa hợp đồng lao động.',
                  fallbackError: 'Không thể xóa hợp đồng lao động.',
                  deleteAction: (provider) =>
                      provider.deleteHopDong(p.maSo, e.idHopDong),
                )
              : null,
        );
      }).toList(),
    );
  }

  // ===========================================================
  // THÂN NHÂN
  // ===========================================================

  Widget _buildThanNhan(NhanVienProfileV2Model p) {
    if (p.thanNhan.isEmpty) {
      return _emptySection(
        icon: Icons.family_restroom_outlined,
        message: 'Chưa có thông tin thân nhân.',
      );
    }

    return Column(
      children: p.thanNhan.map((e) {
        final details = <String>[];

        if (e.moiQuanHe != null && e.moiQuanHe!.trim().isNotEmpty) {
          details.add(e.moiQuanHe!);
        }

        if (e.soCCCD != null && e.soCCCD!.trim().isNotEmpty) {
          details.add('CCCD: ${e.soCCCD}');
        }

        return _recordTile(
          icon: Icons.person_outline_rounded,
          title: e.tenThanNhan,
          details: details,
          onEdit: hasRole(45) ? () => _openThanNhan(p, item: e) : null,
          onDelete: hasRole(45)
              ? () => _deleteRelatedRecord(
                  dialogTitle: 'Xóa thông tin thân nhân?',
                  itemName: e.tenThanNhan,
                  successMessage: 'Đã xóa thông tin thân nhân.',
                  fallbackError: 'Không thể xóa thông tin thân nhân.',
                  deleteAction: (provider) =>
                      provider.deleteThanNhan(p.maSo, e.idThanNhan),
                )
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildKhenThuong(
    NhanVienProfileV2Model profile,
    NhanVienV2Provider provider,
  ) {
    if (provider.isLoadingKhenThuongKyLuat) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final items = provider.khenThuongKyLuat.khenThuongs;
    if (items.isEmpty) {
      return _emptySection(
        icon: Icons.emoji_events_outlined,
        message: 'Chưa có thông tin khen thưởng.',
      );
    }
    return Column(
      children: items.map((item) {
        final details = <String>[
          if (item.hinhThucKhen?.trim().isNotEmpty == true)
            'Hình thức: ${item.hinhThucKhen}',
          if (item.ngayKhen != null) 'Ngày khen: ${_date(item.ngayKhen)}',
          if (item.soQuyetDinhKhen?.trim().isNotEmpty == true)
            'QĐ: ${item.soQuyetDinhKhen}',
          if (item.soTienKhen != null) 'Số tiền: ${item.soTienKhen}',
          if (item.soDiemKhen != null) 'Điểm: ${item.soDiemKhen}',
          if (item.file != null) 'Tệp: ${item.file!.fileName}',
        ];
        final fileKey = 'khen-thuong:${item.maKhenThuong}';
        return _recordTile(
          icon: Icons.emoji_events_outlined,
          title: item.lyDoKhen?.trim().isNotEmpty == true
              ? item.lyDoKhen!
              : 'Khen thưởng',
          details: details,
          onOpen: item.file == null
              ? null
              : () => _openKhenThuongKyLuatFile(
                  profile.maSo,
                  'khen-thuong',
                  item.maKhenThuong,
                  item.file!,
                ),
          isOpening: _openingKhenThuongKyLuatFiles.contains(fileKey),
          onEdit: _canAddToProfile(profile: profile, roleId: 53)
              ? () => _openKhenThuong(profile, item: item)
              : null,
          onDelete: _canAddToProfile(profile: profile, roleId: 53)
              ? () => _deleteRelatedRecord(
                  dialogTitle: 'Xóa khen thưởng?',
                  itemName: item.lyDoKhen ?? 'Khen thưởng',
                  successMessage: 'Đã xóa khen thưởng.',
                  fallbackError: 'Không thể xóa khen thưởng.',
                  deleteAction: (p) =>
                      p.deleteKhenThuong(profile.maSo, item.maKhenThuong),
                )
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildKyLuat(
    NhanVienProfileV2Model profile,
    NhanVienV2Provider provider,
  ) {
    if (provider.isLoadingKhenThuongKyLuat) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final items = provider.khenThuongKyLuat.kyLuats;
    if (items.isEmpty) {
      return _emptySection(
        icon: Icons.gavel_outlined,
        message: 'Chưa có thông tin kỷ luật.',
      );
    }
    final totalMonths = provider.khenThuongKyLuat.tongSoThangKeoDaiThamNien;
    return Column(
      children: [
        if (totalMonths > 0)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1D49B)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_outlined, color: Color(0xFFA96400)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Tổng thời gian kéo dài thâm niên: ${_durationFromMonths(totalMonths)}',
                    style: const TextStyle(
                      color: Color(0xFF805000),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...items.map((item) {
          final details = <String>[
            if (item.hinhThucKyLuat?.trim().isNotEmpty == true)
              'Hình thức: ${item.hinhThucKyLuat}',
            if (item.ngayXayRa != null) 'Xảy ra: ${_date(item.ngayXayRa)}',
            if (item.ngayKy != null) 'Ngày ký: ${_date(item.ngayKy)}',
            if (item.soQuyetDinhKyLuat?.trim().isNotEmpty == true)
              'QĐ: ${item.soQuyetDinhKyLuat}',
            if (item.keoDaiThamNien)
              'Kéo dài thâm niên: ${_durationFromMonths(item.soThangKeoDaiThamNien ?? 0)}',
            if (item.keoDaiThamNien && item.ngayBatDauKeoDaiThamNien != null)
              'Áp dụng từ: ${_date(item.ngayBatDauKeoDaiThamNien)}',
            if (item.file != null) 'Tệp: ${item.file!.fileName}',
          ];
          final fileKey = 'ky-luat:${item.maKyLuat}';
          return _recordTile(
            icon: Icons.gavel_outlined,
            title: item.lyDoKyLuat?.trim().isNotEmpty == true
                ? item.lyDoKyLuat!
                : 'Kỷ luật',
            details: details,
            onOpen: item.file == null
                ? null
                : () => _openKhenThuongKyLuatFile(
                    profile.maSo,
                    'ky-luat',
                    item.maKyLuat,
                    item.file!,
                  ),
            isOpening: _openingKhenThuongKyLuatFiles.contains(fileKey),
            onEdit: _canAddToProfile(profile: profile, roleId: 53)
                ? () => _openKyLuat(profile, item: item)
                : null,
            onDelete: _canAddToProfile(profile: profile, roleId: 53)
                ? () => _deleteRelatedRecord(
                    dialogTitle: 'Xóa kỷ luật?',
                    itemName: item.lyDoKyLuat ?? 'Kỷ luật',
                    successMessage: 'Đã xóa kỷ luật.',
                    fallbackError: 'Không thể xóa kỷ luật.',
                    deleteAction: (p) =>
                        p.deleteKyLuat(profile.maSo, item.maKyLuat),
                  )
                : null,
          );
        }),
      ],
    );
  }

  String _durationFromMonths(int months) {
    if (months <= 0) return 'chưa xác định';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (years == 0) return '$remainingMonths tháng';
    if (remainingMonths == 0) return '$years năm';
    return '$years năm $remainingMonths tháng';
  }

  Future<void> _openKhenThuong(
    NhanVienProfileV2Model profile, {
    KhenThuongNhanVienModel? item,
  }) async {
    final provider = context.read<NhanVienV2Provider>();
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: KhenThuongKyLuatFormDialog.khenThuong(
          maSo: profile.maSo,
          khenThuong: item,
        ),
      ),
    );
  }

  Future<void> _openKyLuat(
    NhanVienProfileV2Model profile, {
    KyLuatNhanVienModel? item,
  }) async {
    final provider = context.read<NhanVienV2Provider>();
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: KhenThuongKyLuatFormDialog.kyLuat(
          maSo: profile.maSo,
          kyLuat: item,
        ),
      ),
    );
  }

  Future<void> _openKhenThuongKyLuatFile(
    String maSo,
    String loai,
    String ma,
    KhenThuongKyLuatFileModel file,
  ) async {
    final key = '$loai:$ma';
    if (_openingKhenThuongKyLuatFiles.contains(key)) return;
    setState(() => _openingKhenThuongKyLuatFiles.add(key));
    final provider = context.read<NhanVienV2Provider>();
    final bytes = await provider.downloadKhenThuongKyLuatFile(
      maSo: maSo,
      loai: loai,
      ma: ma,
    );
    if (!mounted) return;
    setState(() => _openingKhenThuongKyLuatFiles.remove(key));
    if (bytes == null) {
      _showMessage(
        provider.errorMessage ?? 'Không thể mở file đính kèm.',
        isError: true,
      );
      return;
    }
    await openEmployeeFile(
      bytes: bytes,
      fileName: file.fileName,
      fileType: file.fileType,
    );
  }

  Future<void> _ensureDanhMuc() async {
    await context.read<NhanVienV2Provider>().ensureDanhMuc();
  }

  Future<void> _openChungChi(
    NhanVienProfileV2Model profile, {
    required bool cme,
    ChungChiNhanVienV2Model? item,
  }) async {
    await _ensureDanhMuc();

    if (!mounted) return;

    final provider = context.read<NhanVienV2Provider>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: ChungChiFormDialog(maSo: profile.maSo, cme: cme, item: item),
      ),
    );
  }

  Future<void> _openBangCap(
    NhanVienProfileV2Model profile, {
    BangCapV2Model? item,
  }) async {
    await _ensureDanhMuc();

    if (!mounted) return;

    final provider = context.read<NhanVienV2Provider>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: BangCapFormDialog(maSo: profile.maSo, item: item),
      ),
    );
  }

  Future<void> _openCchn(
    NhanVienProfileV2Model profile, {
    CchnV2Model? item,
  }) async {
    if (!mounted) return;

    final provider = context.read<NhanVienV2Provider>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: CchnFormDialog(maSo: profile.maSo, item: item),
      ),
    );
  }

  Future<void> _openHopDong(
    NhanVienProfileV2Model profile, {
    HopDongLaoDongV2Model? item,
  }) async {
    await _ensureDanhMuc();

    if (!mounted) return;

    final provider = context.read<NhanVienV2Provider>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: HopDongFormDialog(maSo: profile.maSo, item: item),
      ),
    );
  }

  Future<void> _openThanNhan(
    NhanVienProfileV2Model profile, {
    ThanNhanV2Model? item,
  }) async {
    if (!mounted) return;

    final provider = context.read<NhanVienV2Provider>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: ThanNhanFormDialog(maSo: profile.maSo, item: item),
      ),
    );
  }

  Future<void> _openFileCaNhan(NhanVienProfileV2Model profile) async {
    if (!mounted) return;

    final provider = context.read<NhanVienV2Provider>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: FileCaNhanFormDialog(
          maSo: profile.maSo,
          // Truyền quyền vào đây: Chỉ được sửa nếu có role 51 VÀ nhân viên chưa nghỉ việc
          canEdit: _canAddToProfile(profile: profile, roleId: 51),
        ),
      ),
    );
  }

  Future<void> _exportNhanSuReport() async {
    final now = DateTime.now();
    final reportDate = DateTime(now.year, now.month, now.day);

    setState(() => _isExportingReport = true);

    try {
      final bytes = await context
          .read<NhanVienV2Provider>()
          .service
          .exportBaoCaoNhanSuExcel(reportDate);
      final year = reportDate.year.toString().padLeft(4, '0');
      final month = reportDate.month.toString().padLeft(2, '0');
      final day = reportDate.day.toString().padLeft(2, '0');

      await downloadExcelFile(
        bytes: bytes,
        fileName: 'TinhHinhNhanSu_$year$month$day.xlsx',
      );

      if (!mounted) return;
      _showMessage('Đã xuất báo cáo nhân sự ngày ${_date(reportDate)}.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingReport = false);
      }
    }
  }

  // ===========================================================
  // TẠO NHÂN VIÊN TỪ HỒ SƠ TUYỂN DỤNG
  //
  // Luồng này hoàn toàn tách khỏi _openCreateNhanVien() cũ.
  // ===========================================================

  Future<void> _openCreateNhanVienFromTuyenDung() async {
    final provider = context.read<NhanVienV2Provider>();

    // Preview cần danh mục cho các dropdown.
    try {
      await provider.ensureDanhMuc();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Không tải được danh mục: $e', isError: true);

      return;
    }

    if (!mounted) {
      return;
    }

    final danhMuc = provider.danhMuc;

    if (danhMuc == null) {
      _showMessage('Không tải được danh mục nhân viên.', isError: true);

      return;
    }

    // =========================================================
    // 1. CHỌN ỨNG VIÊN
    // =========================================================

    final candidate = await showDialog<NhanVienTuyenDungItemV2Model>(
      context: context,
      builder: (_) {
        return TuyenDungCandidateDialog(service: _tuyenDungService);
      },
    );

    if (candidate == null || !mounted) {
      return;
    }

    // =========================================================
    // 2. XEM TRƯỚC / CHỈNH SỬA / IMPORT
    // =========================================================

    final String? maSo = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return TuyenDungPreviewDialog(
          idTuyenDung: candidate.idTuyenDung,
          service: _tuyenDungService,
          danhMuc: danhMuc,
        );
      },
    );

    if (maSo == null || maSo.trim().isEmpty || !mounted) {
      return;
    }

    final String maSoMoi = maSo.trim();

    // =========================================================
    // 3. REFRESH TỔNG QUAN + DANH SÁCH
    // =========================================================

    await provider.loadTongQuan();

    await provider.loadDanhSach(resetPage: true);

    if (!mounted) {
      return;
    }

    // =========================================================
    // 4. MỞ NGAY HỒ SƠ NHÂN VIÊN VỪA TẠO
    // =========================================================

    setState(() {
      _profileTabIndex = 0;
    });

    await provider.selectNhanVien(maSoMoi, loadKhenThuongKyLuat: hasRole(53));

    if (!mounted) {
      return;
    }

    _showMessage(
      'Đã tạo nhân viên $maSoMoi và tài khoản đăng nhập thành công.',
    );
  }

  Future<void> _openCreateNhanVien() async {
    final provider = context.read<NhanVienV2Provider>();

    try {
      await provider.ensureDanhMuc();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Không tải được danh mục: $e', isError: true);

      return;
    }

    if (!mounted) {
      return;
    }

    final bool? created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: const NhanVienFormDialog(),
        );
      },
    );

    if (created == true && mounted) {
      _showMessage('Đã thêm nhân viên và tạo tài khoản đăng nhập thành công.');
    }
  }

  // ===========================================================
  // OPEN EDIT NHÂN VIÊN
  // ===========================================================

  Future<void> _openEditNhanVien(NhanVienProfileV2Model profile) async {
    final provider = context.read<NhanVienV2Provider>();

    try {
      await provider.ensureDanhMuc();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Không tải được danh mục: $e', isError: true);

      return;
    }

    if (!mounted) {
      return;
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: NhanVienFormDialog(profile: profile),
        );
      },
    );
  }

  Future<void> _confirmLockNhanVienAccounts(
    NhanVienProfileV2Model profile,
  ) async {
    final String employeeName = profile.hoVaTen?.trim().isNotEmpty == true
        ? profile.hoVaTen!.trim()
        : 'nhân viên này';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: const Row(
            children: [
              _LockDialogIcon(
                color: Color(0xFFB42318),
                backgroundColor: Color(0xFFFFE8E5),
                icon: Icons.lock_person_outlined,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Xác nhận khóa tài khoản',
                  style: TextStyle(
                    color: Color(0xFF243B4E),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF526779),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Bạn có chắc chắn muốn khóa toàn bộ tài khoản của ',
                      ),
                      TextSpan(
                        text: employeeName,
                        style: const TextStyle(
                          color: Color(0xFF243B4E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(text: ' (Mã nhân viên: ${profile.maSo}) không?'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF4D3A5)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thao tác sẽ khóa đồng thời:',
                        style: TextStyle(
                          color: Color(0xFF8A4B08),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 9),
                      _LockSystemLine(text: 'Tài khoản ứng dụng nội bộ'),
                      _LockSystemLine(text: 'Tài khoản HIS'),
                      _LockSystemLine(text: 'Tài khoản Domain'),
                      SizedBox(height: 7),
                      Text(
                        'Sau khi khóa, nhân viên sẽ không thể đăng nhập vào các hệ thống trên.',
                        style: TextStyle(
                          color: Color(0xFF8A4B08),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: const Text('Xác nhận khóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<NhanVienV2Provider>();
    final result = await provider.lockNhanVienAccounts(profile.maSo);

    if (!mounted) {
      return;
    }

    if (result == null) {
      _showMessage(
        provider.errorMessage ?? 'Không thể khóa tài khoản nhân viên.',
        isError: true,
      );
      return;
    }

    await _showLockNhanVienResult(result);
  }

  Future<void> _showLockNhanVienResult(
    KhoaTaiKhoanNhanVienV2Model result,
  ) async {
    final bool success = result.thanhCongToanBo;
    final Color statusColor = success
        ? const Color(0xFF07875D)
        : const Color(0xFFB42318);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              _LockDialogIcon(
                color: statusColor,
                backgroundColor: success
                    ? const Color(0xFFE7F7F1)
                    : const Color(0xFFFFE8E5),
                icon: success
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  success
                      ? 'Đã khóa tài khoản'
                      : 'Khóa tài khoản chưa hoàn tất',
                  style: const TextStyle(
                    color: Color(0xFF243B4E),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.message.trim().isNotEmpty) ...[
                  Text(
                    result.message,
                    style: const TextStyle(
                      color: Color(0xFF526779),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                ...result.ketQua.map(_buildLockSystemResult),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLockSystemResult(KhoaTaiKhoanHeThongV2Model item) {
    final Color color = item.thanhCong
        ? const Color(0xFF07875D)
        : const Color(0xFFB42318);
    final String status = item.thanhCong
        ? item.daKhoaTruocDo
              ? 'Đã khóa trước đó'
              : 'Thành công'
        : 'Chưa thành công';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: item.thanhCong
            ? const Color(0xFFF1FAF6)
            : const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.thanhCong
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.heThong,
                        style: const TextStyle(
                          color: Color(0xFF243B4E),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (item.thongBao?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.thongBao!,
                    style: const TextStyle(
                      color: Color(0xFF66788A),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // CREATE VỊ TRÍ
  // ===========================================================

  Future<void> _openCreateViTri(NhanVienProfileV2Model profile) async {
    // Chặn thêm dữ liệu khi nghỉ việc
    // cả ở UI lẫn tại hàm xử lý.
    if (profile.isNghiViec == true) {
      _showMessage(
        'Nhân viên đã nghỉ việc, không thể thêm vị trí công tác.',
        isError: true,
      );

      return;
    }

    final provider = context.read<NhanVienV2Provider>();

    try {
      await provider.ensureDanhMuc();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Không tải được danh mục: $e', isError: true);

      return;
    }

    if (!mounted) {
      return;
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: ViTriCongTacFormDialog(maSo: profile.maSo),
        );
      },
    );
  }

  // ===========================================================
  // EDIT VỊ TRÍ
  // ===========================================================

  Future<void> _openEditViTri(ViTriCongTacV2Model item) async {
    final provider = context.read<NhanVienV2Provider>();

    final String? maSo = item.maSo ?? provider.profile?.maSo;

    if (maSo == null || maSo.trim().isEmpty) {
      _showMessage('Không xác định được mã nhân viên.', isError: true);

      return;
    }

    try {
      await provider.ensureDanhMuc();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Không tải được danh mục: $e', isError: true);

      return;
    }

    if (!mounted) {
      return;
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: ViTriCongTacFormDialog(maSo: maSo, item: item),
        );
      },
    );
  }

  // ===========================================================
  // DELETE VỊ TRÍ
  // ===========================================================

  Future<void> _deleteViTri(ViTriCongTacV2Model item) async {
    final provider = context.read<NhanVienV2Provider>();

    final String? maSo = item.maSo ?? provider.profile?.maSo;

    if (maSo == null || maSo.trim().isEmpty) {
      _showMessage('Không xác định được mã nhân viên.', isError: true);

      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa vị trí công tác?'),
          content: Text(
            'Bạn có chắc chắn muốn xóa vị trí công tác'
            '${item.tenKhoaPhong != null ? ' tại "${item.tenKhoaPhong}"' : ''} không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Không'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    final bool ok = await provider.deleteViTriCongTac(
      maSo,
      item.idViTriCongTac,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      _showMessage('Đã xóa vị trí công tác.');
    } else {
      _showMessage(
        provider.errorMessage ?? 'Không thể xóa vị trí công tác.',
        isError: true,
      );
    }
  }

  Future<void> _deleteRelatedRecord({
    required String dialogTitle,
    required String itemName,
    required String successMessage,
    required String fallbackError,
    required Future<bool> Function(NhanVienV2Provider provider) deleteAction,
  }) async {
    final String normalizedName = itemName.trim().isEmpty
        ? 'Bản ghi đã chọn'
        : itemName.trim();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFC43C35),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dialogTitle,
                  style: const TextStyle(
                    color: Color(0xFF20384D),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text.rich(
            TextSpan(
              style: const TextStyle(
                color: _mutedText,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Bạn có chắc chắn muốn xóa '),
                TextSpan(
                  text: '"$normalizedName"',
                  style: const TextStyle(
                    color: Color(0xFF263F54),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '? Thao tác này không thể hoàn tác.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC43C35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<NhanVienV2Provider>();
    final bool ok = await deleteAction(provider);

    if (!mounted) {
      return;
    }

    if (ok) {
      _showMessage(successMessage);
    } else {
      _showMessage(provider.errorMessage ?? fallbackError, isError: true);
    }
  }

  // ===========================================================
  // SECTION
  // ===========================================================

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
    int? itemCount,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22384A).withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: _primary),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF20384D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (itemCount != null) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        color: _mutedText,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _emptySection({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: const Color(0xFFA5B4C1)),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedText, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _recordTile({
    required IconData icon,
    required String title,
    required List<String> details,
    VoidCallback? onOpen,
    bool isOpening = false,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    String deleteTooltip = 'Xóa',
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, size: 17, color: _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF293F52),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details.join('  •  '),
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onOpen != null || onEdit != null || onDelete != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onOpen != null)
                  _recordActionButton(
                    tooltip: 'Xem file',
                    icon: isOpening
                        ? Icons.hourglass_top_rounded
                        : Icons.visibility_outlined,
                    color: const Color(0xFF19734B),
                    onPressed: onOpen,
                  ),
                if (onOpen != null && (onEdit != null || onDelete != null))
                  const SizedBox(width: 4),
                if (onEdit != null)
                  _recordActionButton(
                    tooltip: 'Sửa',
                    icon: Icons.edit_outlined,
                    color: _primary,
                    onPressed: onEdit,
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(width: 4),
                if (onDelete != null)
                  _recordActionButton(
                    tooltip: deleteTooltip,
                    icon: Icons.delete_outline,
                    color: const Color(0xFFC43C35),
                    onPressed: onDelete,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _recordActionButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: color.withValues(alpha: .18)),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }

  // ===========================================================
  // INFO
  // ===========================================================

  Widget _info(
    String label,
    String? value, {
    required IconData icon,
    required double width,
  }) {
    final bool hasValue = value != null && value.trim().isNotEmpty;

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF6C8BA0), size: 16),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasValue ? value : '-',
                  style: TextStyle(
                    color: hasValue
                        ? const Color(0xFF2A4053)
                        : const Color(0xFF9EABB7),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // ADD BUTTON
  // ===========================================================

  Widget _addButton(String text, VoidCallback onPressed) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        visualDensity: VisualDensity.compact,
        side: const BorderSide(color: Color(0xFFB7D9EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 11.5)),
    );
  }

  // ===========================================================
  // AVATAR
  // ===========================================================

  Widget _avatar(Uint8List? bytes, String? name, {double radius = 24}) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFB9D9EA)),
        boxShadow: [
          BoxShadow(
            color: _primaryDark.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFDCEFF9),
        foregroundColor: _primaryDark,
        backgroundImage: bytes != null ? MemoryImage(bytes) : null,
        child: bytes == null
            ? Text(
                _initials(name),
                style: TextStyle(
                  fontSize: radius * 0.52,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
    );
  }

  // ===========================================================
  // INITIALS
  // ===========================================================

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '?';
    }

    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return '?';
    }

    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  // ===========================================================
  // DATE
  // ===========================================================

  String? _date(DateTime? date) {
    if (date == null) {
      return null;
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ===========================================================
  // MESSAGE
  // ===========================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final backgroundColor = isError
        ? const Color(0xFFC93C3C)
        : const Color(0xFF14845E);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          width: 560,
          elevation: 8,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}

class _LockDialogIcon extends StatelessWidget {
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  const _LockDialogIcon({
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _LockSystemLine extends StatelessWidget {
  final String text;

  const _LockSystemLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFFB76A12),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF6F4A1E),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeFileEntry {
  final int idFile;
  final String fileName;
  final String? fileType;
  final String title;
  final String source;
  final DateTime? date;
  final String? note;
  final NhanVienTaiLieuKhacV2Model? personalFile;
  final ViTriCongTacV2Model? position;
  final HopDongLaoDongV2Model? contract;

  const _EmployeeFileEntry({
    required this.idFile,
    required this.fileName,
    required this.fileType,
    required this.title,
    required this.source,
    this.date,
    this.note,
    this.personalFile,
    this.position,
    this.contract,
  });
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2392D0), Color(0xFF0B5E91)],
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1274BC).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(Icons.groups_2_rounded, color: Colors.white, size: 22),
    );
  }
}
