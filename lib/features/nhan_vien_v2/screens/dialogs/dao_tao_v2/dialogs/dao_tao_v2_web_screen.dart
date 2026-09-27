import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../models/dao_tao_v2_models.dart';
import '../../../../../../providers/dao_tao_v2_provider.dart';
import 'bo_sung_hoc_vien_dao_tao_dialog.dart';
import 'cap_chung_chi_dao_tao_dialog.dart';
import 'dao_tao_cham_cong_dialog.dart';
import 'dao_tao_dashboard_dialog.dart';
import 'dao_tao_bao_cao_cme_dialog.dart';
import 'dao_tao_bao_cao_tong_hop_dialog.dart';
import 'dao_tao_design.dart';
import 'dao_tao_diem_danh_print.dart';
import 'lop_dao_tao_form_dialog.dart';

enum _DiemDanhOutput { print, pdf, word }

class DaoTaoV2WebScreen extends StatefulWidget {
  final Set<int> roleIds;

  const DaoTaoV2WebScreen({super.key, required this.roleIds});

  @override
  State<DaoTaoV2WebScreen> createState() => _DaoTaoV2WebScreenState();
}

class _DaoTaoV2WebScreenState extends State<DaoTaoV2WebScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  final _searchController = TextEditingController();
  late DateTime _tuNgay;
  late DateTime _denNgay;
  final _mySearchController = TextEditingController();

  String _myKeyword = '';
  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _tuNgay = DateTime(now.year, now.month, 1);

    _denNgay = DateTime(now.year, now.month + 1, 0);

    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<DaoTaoV2Provider>().loadDanhSach(
        tuNgay: _tuNgay,
        denNgay: _denNgay,
      );
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);

    _tabController.dispose();
    _searchController.dispose();
    _mySearchController.dispose();
    super.dispose();
  }

  bool get isRole47 => widget.roleIds.contains(47);

  bool get isRole48 => widget.roleIds.contains(48);

  bool get canCreate => isRole47 || isRole48;

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    if (_tabController.index == 1) {
      context.read<DaoTaoV2Provider>().loadLopCuaToi();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DaoTaoV2Provider>();

    return Theme(
      data: daoTaoTheme(context),
      child: ColoredBox(
        color: DaoTaoColors.background,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              decoration: const BoxDecoration(
                color: DaoTaoColors.surface,
                border: Border(bottom: BorderSide(color: DaoTaoColors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2999D7),
                              DaoTaoColors.primaryDark,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: DaoTaoColors.primary.withValues(alpha: .2),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quản lý đào tạo',
                              style: TextStyle(
                                color: DaoTaoColors.text,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Lớp học, đăng ký và theo dõi kết quả đào tạo',
                              style: TextStyle(
                                color: DaoTaoColors.muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Làm mới dữ liệu',

                        onPressed: provider.isLoading
                            ? null
                            : () {
                                provider.loadDanhSach(
                                  tuNgay: _tuNgay,

                                  denNgay: _denNgay,
                                );

                                if (_tabController.index == 1) {
                                  provider.loadLopCuaToi();
                                }
                              },

                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      if (canCreate) ...[
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _openBaoCaoTongHop,
                          icon: const Icon(Icons.analytics_rounded),
                          label: const Text('Báo cáo đào tạo'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _openBaoCaoCme,
                          icon: const Icon(Icons.workspace_premium_rounded),
                          label: const Text('Báo cáo CME'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: provider.isSaving ? null : _openCreate,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Tạo lớp đào tạo'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 390,
                      child: TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.view_list_rounded, size: 19),
                            text: isRole47 ? 'Tất cả lớp' : 'Lớp đào tạo',
                          ),
                          const Tab(
                            icon: Icon(Icons.how_to_reg_rounded, size: 19),
                            text: 'Lớp đã đăng ký',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllClasses(provider),
                  _buildMyClasses(provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TẤT CẢ LỚP
  // ==========================================================

  Widget _buildAllClasses(DaoTaoV2Provider provider) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DaoTaoColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DaoTaoColors.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final search = TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  provider.setKeyword(
                    value,

                    tuNgay: _tuNgay,

                    denNgay: _denNgay,
                  );
                },
                decoration: daoTaoInputDecoration(
                  hint: 'Tìm tên lớp, chứng chỉ hoặc đơn vị đào tạo...',
                  icon: Icons.search_rounded,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Xóa từ khóa',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            provider.setKeyword(
                              '',

                              tuNgay: _tuNgay,

                              denNgay: _denNgay,
                            );
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              );

              final status = DropdownButtonFormField<bool?>(
                key: ValueKey(provider.dangMoDangKy),
                initialValue: provider.dangMoDangKy,
                isExpanded: true,
                decoration: daoTaoInputDecoration(
                  label: 'Trạng thái đăng ký',
                  icon: Icons.tune_rounded,
                ),
                items: const [
                  DropdownMenuItem<bool?>(value: null, child: Text('Tất cả')),
                  DropdownMenuItem<bool?>(
                    value: true,
                    child: Text('Đang mở đăng ký'),
                  ),
                  DropdownMenuItem<bool?>(
                    value: false,
                    child: Text('Chưa mở / đã đóng'),
                  ),
                ],
                onChanged: (value) {
                  provider.setDangMoDangKy(
                    value,

                    tuNgay: _tuNgay,

                    denNgay: _denNgay,
                  );
                },
              );
              final tuNgay = _dateFilterField(
                label: 'Từ ngày',

                value: _tuNgay,

                onTap: () => _chonTuNgay(provider),
              );

              final denNgay = _dateFilterField(
                label: 'Đến ngày',

                value: _denNgay,

                onTap: () => _chonDenNgay(provider),
              );

              return Wrap(
                spacing: 12,

                runSpacing: 10,

                crossAxisAlignment: WrapCrossAlignment.center,

                children: [
                  SizedBox(
                    width: constraints.maxWidth < 900
                        ? constraints.maxWidth
                        : 340,

                    child: search,
                  ),

                  SizedBox(width: 180, child: tuNgay),

                  SizedBox(width: 180, child: denNgay),

                  SizedBox(width: 230, child: status),

                  OutlinedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => _veThangHienTai(provider),

                    icon: const Icon(Icons.today_rounded),

                    label: const Text('Tháng hiện tại'),
                  ),
                ],
              );
            },
          ),
        ),

        if (provider.errorMessage != null) _errorBanner(provider.errorMessage!),

        Expanded(
          child: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: DaoTaoColors.primary),
                )
              : _buildList(provider, provider.danhSach),
        ),
      ],
    );
  }

  Widget _dateFilterField({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(10),

      child: InputDecorator(
        decoration: daoTaoInputDecoration(
          label: label,

          icon: Icons.calendar_month_rounded,
        ),

        child: Row(
          children: [
            Expanded(
              child: Text(
                _date(value),

                style: const TextStyle(
                  color: DaoTaoColors.text,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const Icon(
              Icons.arrow_drop_down_rounded,

              color: DaoTaoColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chonTuNgay(DaoTaoV2Provider provider) async {
    final picked = await showDatePicker(
      context: context,

      initialDate: _tuNgay,

      firstDate: DateTime(2000),

      lastDate: DateTime(2100),

      helpText: 'Chọn từ ngày',
    );

    if (picked == null || !mounted) {
      return;
    }

    final value = DateTime(picked.year, picked.month, picked.day);

    setState(() {
      _tuNgay = value;
      if (_denNgay.isBefore(_tuNgay)) {
        _denNgay = _tuNgay;
      }
    });

    await provider.loadDanhSach(tuNgay: _tuNgay, denNgay: _denNgay);
  }

  Future<void> _chonDenNgay(DaoTaoV2Provider provider) async {
    final picked = await showDatePicker(
      context: context,

      initialDate: _denNgay.isBefore(_tuNgay) ? _tuNgay : _denNgay,

      firstDate: _tuNgay,

      lastDate: DateTime(2100),

      helpText: 'Chọn đến ngày',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _denNgay = DateTime(picked.year, picked.month, picked.day);
    });

    await provider.loadDanhSach(tuNgay: _tuNgay, denNgay: _denNgay);
  }

  Future<void> _veThangHienTai(DaoTaoV2Provider provider) async {
    final now = DateTime.now();

    setState(() {
      _tuNgay = DateTime(now.year, now.month, 1);

      _denNgay = DateTime(now.year, now.month + 1, 0);
    });

    await provider.loadDanhSach(tuNgay: _tuNgay, denNgay: _denNgay);
  }

  List<LopDaoTaoV2Model> _filterMyClasses(List<LopDaoTaoV2Model> items) {
    final keyword = _myKeyword.trim().toLowerCase();

    if (keyword.isEmpty) {
      return items;
    }

    bool contains(String? value) {
      return value?.trim().toLowerCase().contains(keyword) == true;
    }

    return items.where((item) {
      return contains(item.tenLopDaoTao) ||
          contains(item.tenChungChi) ||
          contains(item.donViDaoTao) ||
          contains(item.baoCaoVien) ||
          contains(item.donViGiangDay) ||
          contains(item.tenKhoaPhong);
    }).toList();
  }

  Widget _buildMyClasses(DaoTaoV2Provider provider) {
    if (provider.isLoadingMyClasses && provider.lopCuaToi.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredItems = _filterMyClasses(provider.lopCuaToi);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(18, 16, 18, 14),

          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: DaoTaoColors.surface,

            borderRadius: BorderRadius.circular(16),

            border: Border.all(color: DaoTaoColors.border),
          ),

          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mySearchController,

                  textInputAction: TextInputAction.search,

                  decoration: daoTaoInputDecoration(
                    hint: 'Tìm trong các lớp của tôi...',

                    icon: Icons.search_rounded,

                    suffixIcon: _mySearchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa từ khóa',

                            onPressed: () {
                              _mySearchController.clear();

                              setState(() {
                                _myKeyword = '';
                              });
                            },

                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),

                  onChanged: (value) {
                    setState(() {
                      _myKeyword = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 10),

              IconButton.filledTonal(
                tooltip: 'Làm mới lớp của tôi',

                onPressed: provider.isLoadingMyClasses
                    ? null
                    : () => provider.loadLopCuaToi(),

                icon: provider.isLoadingMyClasses
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),

        if (provider.errorMessage != null && provider.lopCuaToi.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),

            child: _errorBanner(provider.errorMessage!),
          ),

        Expanded(
          child: provider.lopCuaToi.isEmpty
              ? const DaoTaoEmptyState(
                  icon: Icons.school_outlined,

                  title: 'Bạn chưa có lớp đào tạo',

                  message: 'Các lớp bạn đăng ký sẽ được hiển thị tại đây.',
                )
              // Có lớp nhưng search không ra.
              : filteredItems.isEmpty
              ? DaoTaoEmptyState(
                  icon: Icons.search_off_rounded,

                  title: 'Không tìm thấy lớp phù hợp',

                  message:
                      'Không có lớp nào khớp với từ khóa '
                      '"${_myKeyword.trim()}".',
                )
              : _buildList(provider, filteredItems),
        ),
      ],
    );
  }

  Widget _buildList(DaoTaoV2Provider provider, List<LopDaoTaoV2Model> items) {
    if (items.isEmpty) {
      return const DaoTaoEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy lớp phù hợp',
        message: 'Hãy thử thay đổi từ khóa hoặc trạng thái đăng ký.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final item = items[index];

        return _classCard(provider, item);
      },
    );
  }

  // ==========================================================
  // CARD
  // ==========================================================

  Widget _classCard(DaoTaoV2Provider provider, LopDaoTaoV2Model item) {
    final canEdit = item.canEdit;

    final canDelete = item.canDelete;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE5F4FC), Color(0xFFD5EBF7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: DaoTaoColors.primary,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tenLopDaoTao,
                        style: const TextStyle(
                          color: DaoTaoColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      if (item.tenChungChi?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Chứng chỉ: ${item.tenChungChi}',
                          style: const TextStyle(
                            color: DaoTaoColors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      if (item.baoCaoVien?.trim().isNotEmpty == true ||
                          item.donViGiangDay?.trim().isNotEmpty == true ||
                          item.isOnline) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            if (item.baoCaoVien?.trim().isNotEmpty == true)
                              _compactMeta(
                                Icons.person_outline_rounded,
                                'Báo cáo viên',
                                item.baoCaoVien!.trim(),
                              ),
                            if (item.donViGiangDay?.trim().isNotEmpty == true)
                              _compactMeta(
                                Icons.business_center_outlined,
                                'Đơn vị giảng dạy',
                                item.donViGiangDay!.trim(),
                              ),
                            if (item.isOnline)
                              _compactMeta(
                                Icons.video_camera_front_rounded,
                                'Học online',
                                'Có hỗ trợ',
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 7),

                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _statusChip(item),

                          _scopeChip(item),

                          if (isRole47 &&
                              item.maNguoiTao?.trim().isNotEmpty == true)
                            DaoTaoStatusPill(
                              icon: Icons.person_outline_rounded,
                              label: 'Người tạo: ${item.maNguoiTao!.trim()}',
                              color: const Color(0xFF6B63A8),
                            ),

                          if (item.isDaDangKy)
                            const DaoTaoStatusPill(
                              icon: Icons.check_circle_rounded,
                              label: 'Đã đăng ký',
                              color: DaoTaoColors.success,
                            ),

                          DaoTaoStatusPill(
                            icon: Icons.people_outline_rounded,
                            label: '${item.soNguoiDangKy} người đăng ký',
                            color: DaoTaoColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (canEdit || canDelete)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _openEdit(item);
                          break;

                        case 'delete':
                          _deleteLop(provider, item);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        enabled: canEdit,
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: canEdit ? null : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.isHetHanDangKy && isRole47
                                  ? 'Sửa tên lớp/chứng chỉ'
                                  : 'Sửa',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        enabled: canDelete,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: canDelete ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.soNguoiDangKy > 0
                                  ? 'Không thể xóa - đã có đăng ký'
                                  : 'Xóa',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const Divider(height: 22, color: DaoTaoColors.border),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _info(
                  Icons.calendar_month,
                  'Thời gian học',
                  _courseDateText(item),
                ),

                if (item.thoiGianDetails?.trim().isNotEmpty == true)
                  _info(
                    Icons.access_time_rounded,
                    'Thời gian chi tiết',
                    item.thoiGianDetails!.trim(),
                  ),

                if (item.diaDiem?.trim().isNotEmpty == true)
                  _info(
                    Icons.location_on_outlined,
                    'Địa điểm',
                    item.diaDiem!.trim(),
                  ),

                if (item.tpThamDu?.trim().isNotEmpty == true)
                  _info(
                    Icons.groups_2_outlined,
                    'Thành phần tham dự',
                    item.tpThamDu!.trim(),
                  ),

                _info(Icons.schedule, 'Đăng ký', _registrationDateText(item)),

                if (item.soTiet != null)
                  _info(
                    Icons.timer_outlined,
                    'Giờ tín chỉ',
                    _number(item.soTiet!),
                  ),

                if (item.tenHinhThucDaoTao?.isNotEmpty == true)
                  _info(
                    Icons.category_outlined,
                    'Hình thức',
                    item.tenHinhThucDaoTao!,
                  ),

                if (item.tenLoaiHinhDaoTao?.isNotEmpty == true)
                  _info(
                    Icons.school_outlined,
                    'Loại hình',
                    item.tenLoaiHinhDaoTao!,
                  ),

                if (item.tenNguonKinhPhi?.isNotEmpty == true)
                  _info(
                    Icons.account_balance_wallet_outlined,
                    'Nguồn kinh phí',
                    item.tenNguonKinhPhi!,
                  ),

                if (item.donViDaoTao?.isNotEmpty == true)
                  _info(Icons.business_outlined, 'Đơn vị', item.donViDaoTao!),
              ],
            ),

            if (item.ghiChu?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFF1DFB7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.notes_rounded,
                      color: DaoTaoColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.ghiChu!,
                        style: const TextStyle(color: DaoTaoColors.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 11),

            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // =====================================================
                  // QUYỀN THAO TÁC DO BACKEND TRẢ VỀ
                  // =====================================================
                  if (item.canDashboard)
                    OutlinedButton.icon(
                      onPressed: () => _openDashboard(item),
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Dashboard'),
                    ),

                  // "Chấm công" là chức năng quản trị đầy đủ.
                  // Role 48 không thấy nút này.
                  if (item.canDashboard)
                    OutlinedButton.icon(
                      onPressed: () => _openChamCong(item),
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Chấm công'),
                    ),

                  if (item.canCapChungChi)
                    OutlinedButton.icon(
                      onPressed: () => _openCapChungChi(item),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Cấp CME/Chứng chỉ'),
                    ),

                  if (item.canPrintExport)
                    PopupMenuButton<String>(
                      tooltip: 'In hoặc xuất danh sách điểm danh',

                      onSelected: (value) => _inDiemDanh(provider, item, value),

                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'truoc-tong-hop',
                          child: ListTile(
                            leading: Icon(Icons.pending_actions_rounded),
                            title: Text('In trước tổng hợp'),
                            subtitle: Text(
                              'Người đăng ký trước, chưa tổng hợp',
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'sau-tong-hop',
                          child: ListTile(
                            leading: Icon(Icons.verified_rounded),
                            title: Text('In sau tổng hợp'),
                            subtitle: Text('Người tham gia hợp lệ'),
                          ),
                        ),
                      ],

                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.print_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('In / Xuất'),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_drop_down_rounded),
                          ],
                        ),
                      ),
                    ),

                  if (item.canBoSungHocVien)
                    OutlinedButton.icon(
                      onPressed: provider.isSaving
                          ? null
                          : () => _openBoSungHocVien(item),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Bổ sung học viên'),
                    ),

                  if (item.isDaDangKy && item.isOnline && item.isDangKyOnline)
                    OutlinedButton.icon(
                      onPressed: () => _openThongTinOnline(provider, item),

                      icon: const Icon(Icons.video_camera_front_rounded),

                      label: const Text('Học online'),
                    ),
                  if (item.isDaDangKy || item.canTaiLieu)
                    OutlinedButton.icon(
                      onPressed: () => _openTaiLieu(provider, item),

                      icon: const Icon(Icons.folder_open_rounded),

                      label: const Text('Tài liệu'),
                    ),
                  if (item.isDaDangKy)
                    OutlinedButton.icon(
                      onPressed: provider.isSaving || item.isHetHanDangKy
                          ? null
                          : () => _huyDangKy(provider, item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DaoTaoColors.danger,
                        backgroundColor: const Color(0xFFFFF5F4),
                        side: const BorderSide(color: Color(0xFFE7AAA5)),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy đăng ký'),
                    )
                  // =====================================================
                  // USER CHƯA ĐĂNG KÝ
                  // =====================================================
                  else
                    FilledButton.icon(
                      onPressed: provider.isSaving || !item.isMoDangKy
                          ? null
                          : () => _dangKy(provider, item),
                      icon: const Icon(Icons.how_to_reg),
                      label: Text(
                        item.isChuaMoDangKy
                            ? 'Chưa mở đăng ký'
                            : item.isHetHanDangKy
                            ? 'Đã hết hạn'
                            : 'Đăng ký',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _inDiemDanh(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model item,
    String loaiIn,
  ) async {
    if (!item.canPrintExport) {
      _message('Bạn không có quyền in hoặc xuất lớp đào tạo này.');
      return;
    }

    final initialDate = item.ngayInDiemDanh ?? DateTime.now();

    final ngay = await showDatePicker(
      context: context,

      initialDate: initialDate,

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),

      helpText: loaiIn == 'truoc-tong-hop'
          ? 'Ngày in điểm danh trước tổng hợp'
          : 'Ngày in điểm danh sau tổng hợp',

      cancelText: 'Hủy',

      confirmText: 'Tiếp tục',
    );

    if (ngay == null || !mounted) {
      return;
    }

    final data = await provider.prepareInDiemDanh(
      idLopDaoTao: item.idLopDaoTao,

      loaiIn: loaiIn,

      ngayInDiemDanh: ngay,
    );

    if (!mounted) {
      return;
    }

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Không thể chuẩn bị dữ liệu in.',
          ),
        ),
      );

      return;
    }

    final output = await _selectDiemDanhOutput();
    if (output == null || !mounted) {
      return;
    }

    final fileBaseName = 'Danh_sach_diem_danh_${item.idLopDaoTao}_$loaiIn';

    try {
      switch (output) {
        case _DiemDanhOutput.print:
          await DaoTaoDiemDanhPrint.print(data);
        case _DiemDanhOutput.pdf:
          final bytes = await DaoTaoDiemDanhPrint.buildPdf(data);
          await fp.FilePicker.platform.saveFile(
            dialogTitle: 'Lưu danh sách điểm danh PDF',
            fileName: '$fileBaseName.pdf',
            type: fp.FileType.custom,
            allowedExtensions: const ['pdf'],
            bytes: bytes,
          );
        case _DiemDanhOutput.word:
          final bytes = DaoTaoDiemDanhPrint.buildWordDocx(data);
          await fp.FilePicker.platform.saveFile(
            dialogTitle: 'Lưu danh sách điểm danh Word',
            fileName: '$fileBaseName.docx',
            type: fp.FileType.custom,
            allowedExtensions: const ['docx'],
            bytes: bytes,
          );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể in hoặc xuất danh sách: $e')),
      );
    }
  }

  Future<_DiemDanhOutput?> _selectDiemDanhOutput() {
    return showDialog<_DiemDanhOutput>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('In và xuất danh sách điểm danh'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _outputOption(
                dialogContext,
                value: _DiemDanhOutput.print,
                icon: Icons.print_rounded,
                title: 'In trực tiếp',
                subtitle: 'Mở bản xem trước và chọn máy in',
              ),
              const SizedBox(height: 8),
              _outputOption(
                dialogContext,
                value: _DiemDanhOutput.pdf,
                icon: Icons.picture_as_pdf_rounded,
                title: 'Xuất PDF',
                subtitle: 'Tải bản in định dạng PDF',
                color: const Color(0xFFD32F2F),
              ),
              const SizedBox(height: 8),
              _outputOption(
                dialogContext,
                value: _DiemDanhOutput.word,
                icon: Icons.description_rounded,
                title: 'Xuất Word',
                subtitle: 'Tải tệp Word có thể chỉnh sửa (.docx)',
                color: const Color(0xFF185ABD),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _outputOption(
    BuildContext dialogContext, {
    required _DiemDanhOutput value,
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = const Color(0xFF0878C9),
  }) {
    return Material(
      color: color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(dialogContext).pop(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(
                          dialogContext,
                        ).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTaiLieu(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model item,
  ) async {
    // ===============================================
    // UI CŨNG CHẶN
    // Backend vẫn là lớp bảo vệ chính.
    // ===============================================

    if (!item.isDaDangKy && !item.canTaiLieu) {
      _message('Bạn không có quyền xem tài liệu của lớp này.');

      return;
    }

    await provider.loadTaiLieu(item.idLopDaoTao, force: true);

    if (!mounted) {
      return;
    }

    final files = provider.taiLieuTheoLop[item.idLopDaoTao] ?? [];

    await showDialog<void>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.folder_open_rounded,

                color: DaoTaoColors.primary,
              ),

              const SizedBox(width: 10),

              const Expanded(child: Text('Tài liệu lớp học')),
            ],
          ),

          content: SizedBox(
            width: 650,

            child: files.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),

                    child: Center(child: Text('Lớp học chưa có tài liệu.')),
                  )
                : ListView.separated(
                    shrinkWrap: true,

                    itemCount: files.length,

                    separatorBuilder: (_, _) => const Divider(),

                    itemBuilder: (context, index) {
                      final file = files[index];

                      final downloading = provider.isDownloadingFile(
                        file.idFile,
                      );

                      return ListTile(
                        leading: const Icon(
                          Icons.insert_drive_file_rounded,

                          color: DaoTaoColors.primary,
                        ),

                        title: Text(file.fileName),

                        subtitle: Text(
                          '${_fileTypeText(file)}'
                          ' • '
                          '${_formatFileSize(file.fileSize)}',
                        ),

                        trailing: FilledButton.icon(
                          onPressed: downloading
                              ? null
                              : () => _downloadTaiLieu(provider, item, file),

                          icon: downloading
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_rounded),

                          label: const Text('Tải'),
                        ),
                      );
                    },
                  ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),

              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadTaiLieu(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model lop,
    LopDaoTaoFileV2Model file,
  ) async {
    if (!lop.isDaDangKy && !lop.canTaiLieu) {
      _message('Bạn không có quyền tải tài liệu của lớp này.');

      return;
    }

    final bytes = await provider.downloadTaiLieu(
      idLopDaoTao: lop.idLopDaoTao,

      idFile: file.idFile,
    );

    if (!mounted || bytes == null) {
      if (mounted) {
        _message(provider.errorMessage ?? 'Không tải được tài liệu.');
      }

      return;
    }

    try {
      await fp.FilePicker.platform.saveFile(
        dialogTitle: 'Lưu tài liệu',

        fileName: file.fileName,

        bytes: bytes,
      );
    } catch (e) {
      if (mounted) {
        _message('Không thể lưu file: $e');
      }
    }
  }

  String _fileTypeText(LopDaoTaoFileV2Model file) {
    var type = file.fileType?.trim().replaceAll('.', '').toUpperCase();

    if (type == null || type.isEmpty) {
      final index = file.fileName.lastIndexOf('.');

      if (index >= 0 && index < file.fileName.length - 1) {
        type = file.fileName.substring(index + 1).toUpperCase();
      }
    }

    return type?.isNotEmpty == true ? type! : 'FILE';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openDashboard(LopDaoTaoV2Model item) async {
    if (!item.canDashboard) {
      _message('Bạn không có quyền xem Dashboard của lớp này.');
      return;
    }

    final provider = context.read<DaoTaoV2Provider>();

    provider.clearDashboard();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: DaoTaoDashboardDialog(
          idLopDaoTao: item.idLopDaoTao,
          tenLopDaoTao: item.tenLopDaoTao,
        ),
      ),
    );

    if (mounted) {
      provider.clearDashboard();
    }
  }

  Future<void> _openChamCong(LopDaoTaoV2Model item) async {
    if (!item.canDashboard) {
      _message('Bạn không có quyền xem chấm công của lớp này.');
      return;
    }

    final provider = context.read<DaoTaoV2Provider>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,

      builder: (_) => ChangeNotifierProvider.value(
        value: provider,

        child: DaoTaoChamCongDialog(item: item),
      ),
    );
  }

  Future<void> _openCapChungChi(LopDaoTaoV2Model item) async {
    if (!item.canCapChungChi) {
      _message('Bạn không có quyền cấp CME/Chứng chỉ cho lớp này.');
      return;
    }

    final provider = context.read<DaoTaoV2Provider>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,

      builder: (_) => ChangeNotifierProvider.value(
        value: provider,

        child: CapChungChiDaoTaoDialog(item: item),
      ),
    );
  }
  // ==========================================================
  // CREATE / EDIT
  // ==========================================================

  Future<void> _openBaoCaoTongHop() async {
    final provider = context.read<DaoTaoV2Provider>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const DaoTaoBaoCaoTongHopDialog(),
      ),
    );
  }

  Future<void> _openBaoCaoCme() async {
    final provider = context.read<DaoTaoV2Provider>();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const DaoTaoBaoCaoCmeDialog(),
      ),
    );
  }

  Future<void> _openCreate() async {
    if (!canCreate) {
      _message('Bạn không có quyền tạo lớp đào tạo.');
      return;
    }

    final provider = context.read<DaoTaoV2Provider>();

    final ok = await provider.ensureDanhMuc();

    if (!mounted) {
      return;
    }

    if (!ok) {
      _message(provider.errorMessage ?? 'Không tải được danh mục đào tạo.');

      return;
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: LopDaoTaoFormDialog(isRole47: isRole47),
      ),
    );
  }

  Future<void> _openEdit(LopDaoTaoV2Model item) async {
    if (!item.canEdit) {
      _message('Bạn không có quyền sửa lớp đào tạo này.');
      return;
    }

    final provider = context.read<DaoTaoV2Provider>();

    final isExpiredNameOnly = isRole47 && item.isHetHanDangKy && item.canEdit;

    final ok = isExpiredNameOnly ? true : await provider.ensureDanhMuc();

    if (!mounted) {
      return;
    }

    if (!ok) {
      _message(provider.errorMessage ?? 'Không tải được danh mục đào tạo.');

      return;
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: LopDaoTaoFormDialog(item: item, isRole47: isRole47),
      ),
    );
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> _deleteLop(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model item,
  ) async {
    if (!item.canDelete) {
      if (item.isHetHanDangKy) {
        _message('Lớp đã hết hạn đăng ký nên không được xóa.');
      } else if (item.soNguoiDangKy > 0) {
        _message('Lớp đã có người đăng ký nên không được xóa.');
      } else {
        _message('Bạn không có quyền xóa lớp đào tạo này.');
      }

      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa lớp đào tạo'),
        content: Text('Bạn có chắc muốn xóa lớp "${item.tenLopDaoTao}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    final ok = await provider.deleteLop(item.idLopDaoTao);

    if (!mounted) {
      return;
    }

    if (ok) {
      _message('Đã xóa lớp đào tạo.');
    } else {
      _message(provider.errorMessage ?? 'Không thể xóa lớp đào tạo.');
    }
  }

  // ==========================================================
  // ĐĂNG KÝ
  // ==========================================================

  Future<void> _dangKy(DaoTaoV2Provider provider, LopDaoTaoV2Model item) async {
    bool? isDangKyOnline;

    // ========================================================
    // LỚP CÓ ONLINE
    // => CHỌN TRỰC TIẾP / ONLINE
    // ========================================================

    if (item.isOnline) {
      bool selectedOnline = false;

      isDangKyOnline = await showDialog<bool>(
        context: context,

        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Đăng ký lớp đào tạo'),

                content: SizedBox(
                  width: 430,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        item.tenLopDaoTao,

                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),

                      const SizedBox(height: 16),

                      const Text('Bạn muốn tham gia theo hình thức nào?'),

                      const SizedBox(height: 8),

                      RadioListTile<bool>(
                        value: false,

                        groupValue: selectedOnline,

                        title: const Text('Trực tiếp'),

                        secondary: const Icon(Icons.groups_rounded),

                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            selectedOnline = value;
                          });
                        },
                      ),

                      RadioListTile<bool>(
                        value: true,

                        groupValue: selectedOnline,

                        title: const Text('Online'),

                        secondary: const Icon(Icons.video_camera_front_rounded),

                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            selectedOnline = value;
                          });
                        },
                      ),

                      if (selectedOnline) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2F1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF2B8B5)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFC62828),
                                size: 20,
                              ),
                              SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Quý đồng nghiệp vui lòng sắp xếp học trực tiếp, trường hợp học online ưu tiên dành cho Phòng khám vệ tinh và CBNV không thể tham dự học trực tiếp vì có lý do chính đáng. Trân trọng./.',
                                  style: TextStyle(
                                    color: Color(0xFFC62828),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),

                    child: const Text('Hủy'),
                  ),

                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, selectedOnline),

                    child: const Text('Xác nhận đăng ký'),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      // ========================================================
      // LỚP CHỈ TRỰC TIẾP
      // ========================================================

      isDangKyOnline = await showDialog<bool>(
        context: context,

        builder: (dialogContext) => AlertDialog(
          title: const Text('Đăng ký lớp đào tạo'),

          content: Text(
            'Bạn muốn đăng ký lớp '
            '"${item.tenLopDaoTao}"?',
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),

              child: const Text('Không'),
            ),

            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, false),

              child: const Text('Đăng ký'),
            ),
          ],
        ),
      );
    }

    // null = user đóng dialog
    if (isDangKyOnline == null || !mounted) {
      return;
    }

    final ok = await provider.dangKy(
      item.idLopDaoTao,

      isDangKyOnline: isDangKyOnline,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      _message(
        isDangKyOnline
            ? 'Đăng ký tham gia online thành công.'
            : 'Đăng ký lớp đào tạo thành công.',
      );
    } else {
      _message(provider.errorMessage ?? 'Không thể đăng ký lớp đào tạo.');
    }
  }

  Future<void> _openBoSungHocVien(LopDaoTaoV2Model item) async {
    if (!item.canBoSungHocVien) {
      _message('Bạn không có quyền bổ sung học viên cho lớp này.');
      return;
    }

    final provider = context.read<DaoTaoV2Provider>();

    await showDialog<void>(
      context: context,

      barrierDismissible: false,

      builder: (_) => ChangeNotifierProvider.value(
        value: provider,

        child: BoSungHocVienDaoTaoDialog(item: item),
      ),
    );
  }

  Future<void> _openThongTinOnline(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model item,
  ) async {
    final info = await provider.loadThongTinOnline(
      item.idLopDaoTao,
      force: true,
    );

    if (!mounted) {
      return;
    }

    if (info == null) {
      _message(provider.errorMessage ?? 'Không lấy được thông tin học online.');

      return;
    }

    await showDialog<void>(
      context: context,

      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.video_camera_front_rounded, color: DaoTaoColors.primary),
            SizedBox(width: 10),
            Text('Thông tin học online'),
          ],
        ),

        content: SizedBox(
          width: 520,

          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                info.tenLopDaoTao,

                style: const TextStyle(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 18),

              _onlineInfoRow('Zoom ID', info.zoomID),

              _onlineInfoRow('Passcode', info.zoomPasscode),

              _onlineInfoRow('Link Zoom', info.linkZoom, isLink: true),

              _onlineInfoRow('Link Chat', info.linkChat, isLink: true),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),

            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _onlineInfoRow(String label, String? value, {bool isLink = false}) {
    final text = value?.trim();
    final hasValue = text?.isNotEmpty == true;
    final displayText = hasValue ? text! : 'Chưa cấu hình';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 100,

            child: Text(
              label,

              style: const TextStyle(
                color: DaoTaoColors.muted,

                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: isLink && hasValue
                ? InkWell(
                    onTap: () => _openOnlineLink(displayText),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          color: DaoTaoColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                : SelectableText(
                    displayText,
                    style: TextStyle(
                      color: hasValue ? DaoTaoColors.text : DaoTaoColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: hasValue ? 'Sao chép $label' : 'Chưa có dữ liệu',
            onPressed: hasValue
                ? () => _copyOnlineInfo(label, displayText)
                : null,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
          if (isLink && hasValue)
            IconButton(
              tooltip: 'Mở $label',
              onPressed: () => _openOnlineLink(displayText),
              visualDensity: VisualDensity.compact,
              color: DaoTaoColors.primary,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
            ),
        ],
      ),
    );
  }

  Future<void> _copyOnlineInfo(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      _message('Đã sao chép $label.');
    }
  }

  Future<void> _openOnlineLink(String value) async {
    final rawValue = value.trim();
    final normalizedValue = rawValue.contains('://')
        ? rawValue
        : 'https://$rawValue';
    final uri = Uri.tryParse(normalizedValue);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _message('Đường dẫn không hợp lệ.');
      return;
    }

    try {
      final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (!opened && mounted) {
        _message('Không thể mở đường dẫn này.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _message('Không thể mở đường dẫn này.');
    }
  }
  // ==========================================================
  // HỦY ĐĂNG KÝ
  // ==========================================================

  Future<void> _huyDangKy(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model item,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy đăng ký'),
        content: Text(
          'Bạn có chắc muốn hủy đăng ký lớp "${item.tenLopDaoTao}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: DaoTaoColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    final ok = await provider.huyDangKy(item.idLopDaoTao);

    if (!mounted) {
      return;
    }

    if (ok) {
      _message('Đã hủy đăng ký lớp đào tạo.');
    } else {
      _message(provider.errorMessage ?? 'Không thể hủy đăng ký.');
    }
  }

  // ==========================================================
  // UI HELPERS
  // ==========================================================

  Widget _scopeChip(LopDaoTaoV2Model item) {
    if (item.phamViDaoTao == 1) {
      return const DaoTaoStatusPill(
        icon: Icons.public_rounded,
        label: 'Toàn viện',
        color: DaoTaoColors.primary,
      );
    }

    final tenKhoa = item.tenKhoaPhong?.trim();

    return DaoTaoStatusPill(
      icon: Icons.apartment_rounded,
      label: tenKhoa?.isNotEmpty == true
          ? 'Nội bộ • $tenKhoa'
          : 'Nội bộ khoa/phòng',
      color: const Color(0xFF6750A4),
    );
  }

  Widget _statusChip(LopDaoTaoV2Model item) {
    if (item.isHetHanDangKy) {
      return const DaoTaoStatusPill(
        icon: Icons.lock_clock_rounded,
        label: 'Đã hết hạn đăng ký',
        color: DaoTaoColors.danger,
      );
    }

    if (item.isChuaMoDangKy) {
      return const DaoTaoStatusPill(
        icon: Icons.schedule_rounded,
        label: 'Chưa mở đăng ký',
        color: DaoTaoColors.warning,
      );
    }

    return const DaoTaoStatusPill(
      icon: Icons.lock_open_rounded,
      label: 'Đang mở đăng ký',
      color: DaoTaoColors.success,
    );
  }

  Widget _compactMeta(IconData icon, String label, String value) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 310),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: DaoTaoColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: DaoTaoColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      color: DaoTaoColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: DaoTaoColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Container(
      width: 250,
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: DaoTaoColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: DaoTaoColors.primary),
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: DaoTaoColors.muted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DaoTaoColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2C7C2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: DaoTaoColors.danger),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: DaoTaoColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  String _courseDateText(LopDaoTaoV2Model item) {
    final start = item.ngayBatDau;

    final end = item.ngayKetThuc;

    if (start == null && end == null) {
      return 'Chưa xác định';
    }

    if (start != null && end == null) {
      return _date(start);
    }

    if (start == null && end != null) {
      return _date(end);
    }

    return '${_date(start!)} - ${_date(end!)}';
  }

  String _registrationDateText(LopDaoTaoV2Model item) {
    final start = item.batDauDangKy;

    final end = item.ketThucDangKy;

    if (start == null && end == null) {
      return 'Không giới hạn';
    }

    if (start != null && end == null) {
      return 'Từ ${_dateTime(start)}';
    }

    if (start == null && end != null) {
      return 'Đến ${_dateTime(end)}';
    }

    return '${_dateTime(start!)} → ${_dateTime(end!)}';
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _dateTime(DateTime value) {
    return '${_date(value)} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _number(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
