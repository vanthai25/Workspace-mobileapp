import 'dart:async';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../models/dao_tao_v2_models.dart';
import '../../../../../../providers/dao_tao_v2_provider.dart';

class DaoTaoV2MobileScreen extends StatefulWidget {
  const DaoTaoV2MobileScreen({super.key});

  @override
  State<DaoTaoV2MobileScreen> createState() => _DaoTaoV2MobileScreenState();
}

class _DaoTaoV2MobileScreenState extends State<DaoTaoV2MobileScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF087DBA);

  static const Color _navy = Color(0xFF12324A);

  static const Color _background = Color(0xFFF3F7FA);

  final TextEditingController _searchController = TextEditingController();

  late final TabController _tabController;

  Timer? _searchDebounce;
  late DateTime _tuNgay;
  late DateTime _denNgay;

  @override
  void initState() {
    super.initState();

    final now =
        DateTime.now();

    _tuNgay =
        DateTime(
      now.year,
      now.month,
      1,
    );

    _denNgay =
        DateTime(
      now.year,
      now.month + 1,
      0,
    );


    _tabController =
        TabController(
      length: 2,
      vsync: this,
    );

    _tabController.addListener(
      _handleTabChanged,
    );


    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) async {
        if (!mounted) {
          return;
        }

        final provider =
            context.read<
                DaoTaoV2Provider>();

        await Future.wait<void>([
          provider.loadDanhSach(
            tuNgay:
                _tuNgay,

            denNgay:
                _denNgay,
          ),

          provider.loadLopCuaToi(),
        ]);
      },
    );
  }
  @override
  void dispose() {
    _searchDebounce?.cancel();

    _searchController.dispose();

    _tabController.removeListener(_handleTabChanged);

    _tabController.dispose();

    super.dispose();
  }

  // ==========================================================
  // TAB
  // ==========================================================

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      context.read<DaoTaoV2Provider>().loadLopCuaToi();
    }
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  void _onSearchChanged(
    String value,
  ) {
    setState(() {});

    _searchDebounce?.cancel();

    _searchDebounce =
        Timer(
      const Duration(
        milliseconds: 450,
      ),
      () {
        if (!mounted) {
          return;
        }

        context
            .read<
                DaoTaoV2Provider>()
            .setKeyword(
          value,

          tuNgay:
              _tuNgay,

          denNgay:
              _denNgay,
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DaoTaoV2Provider>();

    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        elevation: 0,

        backgroundColor: Colors.white,

        surfaceTintColor: Colors.white,

        foregroundColor: _navy,

        titleSpacing: 0,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              'Đào tạo',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),

            Text(
              'Khám phá và đăng ký lớp học',
              style: TextStyle(
                color: Color(0xFF718496),

                fontSize: 11.5,

                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Làm mới',

            onPressed:
            provider.isLoading
                ? null
                : () async {
                    await Future.wait<void>([
                      provider.loadDanhSach(
                        tuNgay:
                            _tuNgay,

                        denNgay:
                            _denNgay,
                      ),

                      provider.loadLopCuaToi(),
                    ]);
                  },

            icon: const Icon(Icons.refresh_rounded),
          ),

          const SizedBox(width: 6),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),

          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),

            alignment: Alignment.centerLeft,

            child: TabBar(
              controller: _tabController,

              dividerColor: Colors.transparent,

              indicatorSize: TabBarIndicatorSize.tab,

              indicator: BoxDecoration(
                color: const Color(0xFFE4F3FA),

                borderRadius: BorderRadius.circular(12),
              ),

              labelColor: _primary,

              unselectedLabelColor: const Color(0xFF718496),

              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,

                fontSize: 13,
              ),

              tabs: const [
                Tab(text: 'Danh sách lớp'),

                Tab(text: 'Lớp của tôi'),
              ],
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,

        children: [_buildAvailableClasses(provider), _buildMyClasses(provider)],
      ),
    );
  }

  // ==========================================================
  // LỚP ĐANG MỞ
  // ==========================================================

  Widget _buildAvailableClasses(DaoTaoV2Provider provider) {
    return Column(
      children: [
        Container(
          color:
              Colors.white,

          padding:
              const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            14,
          ),

          child:
              Column(
            children: [
              // ======================================================
              // TÌM KIẾM
              // ======================================================

              TextField(
                controller:
                    _searchController,

                onChanged:
                    _onSearchChanged,

                textInputAction:
                    TextInputAction.search,

                decoration:
                    InputDecoration(
                  hintText:
                      'Tìm tên lớp, chứng chỉ, đơn vị đào tạo...',

                  hintStyle:
                      const TextStyle(
                    fontSize:
                        13,
                  ),

                  prefixIcon:
                      const Icon(
                    Icons.search_rounded,
                    size:
                        21,
                  ),

                  suffixIcon:
                      _searchController
                              .text
                              .isEmpty
                          ? null
                          : IconButton(
                              tooltip:
                                  'Xóa tìm kiếm',

                              onPressed:
                                  () {
                                _searchDebounce
                                    ?.cancel();

                                _searchController
                                    .clear();

                                setState(
                                  () {},
                                );

                                provider
                                    .setKeyword(
                                  '',

                                  tuNgay:
                                      _tuNgay,

                                  denNgay:
                                      _denNgay,
                                );
                              },

                              icon:
                                  const Icon(
                                Icons
                                    .close_rounded,

                                size:
                                    20,
                              ),
                            ),

                  filled:
                      true,

                  fillColor:
                      _background,

                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical:
                        12,
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),

                    borderSide:
                        BorderSide.none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),

                    borderSide:
                        const BorderSide(
                      color:
                          Color(
                        0xFFDDE8EF,
                      ),
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),

                    borderSide:
                        const BorderSide(
                      color:
                          _primary,

                      width:
                          1.4,
                    ),
                  ),
                ),
              ),


              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        _dateFilterTile(
                      label:
                          'Từ ngày',

                      value:
                          _tuNgay,

                      onTap:
                          () =>
                              _chonTuNgay(
                        provider,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child:
                        _dateFilterTile(
                      label:
                          'Đến ngày',

                      value:
                          _denNgay,

                      onTap:
                          () =>
                              _chonDenNgay(
                        provider,
                      ),
                    ),
                  ),
                ],
              ),


              const SizedBox(
                height: 8,
              ),

              Row(
                children: [
                  const Icon(
                    Icons
                        .filter_alt_outlined,

                    size:
                        16,

                    color:
                        Color(
                      0xFF718496,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Expanded(
                    child:
                        Text(
                      'Đang lọc ${_formatFilterDate(_tuNgay)}'
                      ' - '
                      '${_formatFilterDate(_denNgay)}',

                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF718496,
                        ),

                        fontSize:
                            11.5,

                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                  TextButton.icon(
                    onPressed:
                        provider.isLoading
                            ? null
                            : () =>
                                _veThangHienTai(
                                  provider,
                                ),

                    icon:
                        const Icon(
                      Icons.today_rounded,
                      size:
                          17,
                    ),

                    label:
                        const Text(
                      'Tháng này',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (provider.errorMessage != null && provider.danhSach.isNotEmpty)
          _errorBanner(provider.errorMessage!),

        Expanded(
          child: provider.isLoading && provider.danhSach.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _classList(
                  provider: provider,

                  items: provider.danhSach,

                  isMyClasses: false,

                  onRefresh: provider.loadDanhSach,
                ),
        ),
      ],
    );
  }

  // ==========================================================
  // LỚP CỦA TÔI
  // ==========================================================

  Widget _buildMyClasses(DaoTaoV2Provider provider) {
    if (provider.isLoadingMyClasses && provider.lopCuaToi.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return _classList(
      provider: provider,

      items: provider.lopCuaToi,

      isMyClasses: true,

      onRefresh: provider.loadLopCuaToi,
    );
  }
  Widget _dateFilterTile({
  required String label,
  required DateTime value,
  required VoidCallback onTap,
}) {
  return Material(
    color:
        _background,

    borderRadius:
        BorderRadius.circular(
      12,
    ),

    child:
        InkWell(
      onTap:
          onTap,

      borderRadius:
          BorderRadius.circular(
        12,
      ),

      child:
          Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal:
              11,

          vertical:
              9,
        ),

        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(
            12,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xFFDDE8EF,
            ),
          ),
        ),

        child:
            Row(
          children: [
            const Icon(
              Icons
                  .calendar_month_outlined,

              color:
                  _primary,

              size:
                  19,
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    label,

                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF718496,
                      ),

                      fontSize:
                          10.5,
                    ),
                  ),

                  const SizedBox(
                    height: 1,
                  ),

                  Text(
                    _formatFilterDate(
                      value,
                    ),

                    style:
                        const TextStyle(
                      color:
                          _navy,

                      fontSize:
                          12.5,

                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .arrow_drop_down_rounded,

              color:
                  Color(
                0xFF718496,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Future<void> _chonTuNgay(
  DaoTaoV2Provider provider,
) async {
  final picked =
      await showDatePicker(
    context:
        context,

    initialDate:
        _tuNgay,

    firstDate:
        DateTime(
      2000,
    ),

    lastDate:
        DateTime(
      2100,
    ),

    helpText:
        'Chọn từ ngày',

    cancelText:
        'Hủy',

    confirmText:
        'Chọn',
  );


  if (
      picked == null ||
      !mounted) {
    return;
  }


  final selected =
      DateTime(
    picked.year,
    picked.month,
    picked.day,
  );


  setState(() {
    _tuNgay =
        selected;

    // Nếu từ ngày mới vượt đến ngày
    // thì tự kéo đến ngày theo.
    if (_denNgay.isBefore(
      _tuNgay,
    )) {
      _denNgay =
          _tuNgay;
    }
  });


  await provider.loadDanhSach(
    tuNgay:
        _tuNgay,

    denNgay:
        _denNgay,
  );
}
Future<void> _chonDenNgay(
  DaoTaoV2Provider provider,
) async {
  final picked =
      await showDatePicker(
    context:
        context,

    initialDate:
        _denNgay.isBefore(
          _tuNgay,
        )
            ? _tuNgay
            : _denNgay,

    firstDate:
        _tuNgay,

    lastDate:
        DateTime(
      2100,
    ),

    helpText:
        'Chọn đến ngày',

    cancelText:
        'Hủy',

    confirmText:
        'Chọn',
  );


  if (
      picked == null ||
      !mounted) {
    return;
  }


  setState(() {
    _denNgay =
        DateTime(
      picked.year,
      picked.month,
      picked.day,
    );
  });


  await provider.loadDanhSach(
    tuNgay:
        _tuNgay,

    denNgay:
        _denNgay,
  );
}
Future<void> _veThangHienTai(
  DaoTaoV2Provider provider,
) async {
  final now =
      DateTime.now();


  setState(() {
    _tuNgay =
        DateTime(
      now.year,
      now.month,
      1,
    );

    _denNgay =
        DateTime(
      now.year,
      now.month + 1,
      0,
    );
  });


  await provider.loadDanhSach(
    tuNgay:
        _tuNgay,

    denNgay:
        _denNgay,
  );
}
String _formatFilterDate(
  DateTime value,
) {
  return DateFormat(
    'dd/MM/yyyy',
  ).format(
    value,
  );
}
  // ==========================================================
  // LIST
  // ==========================================================

  Widget _classList({
    required DaoTaoV2Provider provider,
    required List<LopDaoTaoV2Model> items,
    required bool isMyClasses,
    required Future<void> Function() onRefresh,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(24),

          children: [
            const SizedBox(height: 78),

            Icon(
              isMyClasses ? Icons.school_outlined : Icons.event_busy_outlined,

              color: const Color(0xFFA9BBC8),

              size: 58,
            ),

            const SizedBox(height: 15),

            Text(
              isMyClasses
                  ? 'Bạn chưa đăng ký lớp nào'
                  : 'Chưa có lớp đang mở đăng ký',

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: _navy,

                fontSize: 17,

                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              isMyClasses
                  ? 'Các lớp đã đăng ký sẽ được lưu tại đây.'
                  : 'Kéo xuống để làm mới hoặc quay lại kiểm tra sau.',

              textAlign: TextAlign.center,

              style: const TextStyle(color: Color(0xFF718496), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,

      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),

        itemCount: items.length,

        separatorBuilder: (_, _) => const SizedBox(height: 9),

        itemBuilder: (context, index) => _classCard(provider, items[index]),
      ),
    );
  }

  // ==========================================================
  // CARD
  // ==========================================================

  Widget _classCard(DaoTaoV2Provider provider, LopDaoTaoV2Model item) {
    final String? certificate = item.tenChungChi?.trim();
    final String? trainingUnit = item.donViDaoTao?.trim();
    final String? timeDetails = item.thoiGianDetails?.trim();
    final String? location = item.diaDiem?.trim();
    final String? participants = item.tpThamDu?.trim();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDCE7EE)),
      ),
      child: InkWell(
        onTap: () => _showClassDetail(provider, item),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: _primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.tenLopDaoTao,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (certificate?.isNotEmpty == true) ...[
                          const SizedBox(height: 3),
                          Text(
                            certificate!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF718496),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _background,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF718496),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _statusPill(item),
                  _scopePill(item),
                  _mobileMetaPill(
                    Icons.people_outline_rounded,
                    '${item.soNguoiDangKy} học viên',
                    _primary,
                  ),
                  if (item.isOnline)
                    _mobileMetaPill(
                      Icons.video_camera_front_rounded,
                      'Có học online',
                      const Color(0xFF6750A4),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoLine(
                      Icons.calendar_month_outlined,
                      'Thời gian học',
                      _courseDateText(item),
                    ),
                    if (timeDetails?.isNotEmpty == true) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 7),
                        child: Divider(height: 1, color: Color(0xFFE4ECF1)),
                      ),
                      _infoLine(
                        Icons.access_time_rounded,
                        'Giờ học',
                        timeDetails!,
                      ),
                    ],
                    if (location?.isNotEmpty == true) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 7),
                        child: Divider(height: 1, color: Color(0xFFE4ECF1)),
                      ),
                      _infoLine(
                        Icons.location_on_outlined,
                        'Địa điểm',
                        location!,
                      ),
                    ],
                    if (participants?.isNotEmpty == true) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 7),
                        child: Divider(height: 1, color: Color(0xFFE4ECF1)),
                      ),
                      _infoLine(
                        Icons.groups_2_outlined,
                        'Thành phần',
                        participants!,
                      ),
                    ],
                    if (trainingUnit?.isNotEmpty == true) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 7),
                        child: Divider(height: 1, color: Color(0xFFE4ECF1)),
                      ),
                      _infoLine(
                        Icons.apartment_rounded,
                        'Đơn vị',
                        trainingUnit!,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 7),
                      child: Divider(height: 1, color: Color(0xFFE4ECF1)),
                    ),
                    _infoLine(
                      Icons.schedule_rounded,
                      'Hạn đăng ký',
                      _registrationDateText(item),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: Color(0xFF718496),
                  ),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'Chạm để xem chi tiết',
                      style: TextStyle(
                        color: Color(0xFF718496),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _actionButton(provider, item, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileMetaPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _scopeText(LopDaoTaoV2Model item) {
    if (item.phamViDaoTao == 1) {
      return 'Toàn viện';
    }

    final tenKhoa = item.tenKhoaPhong?.trim();

    return tenKhoa?.isNotEmpty == true
        ? 'Nội bộ • $tenKhoa'
        : 'Nội bộ khoa/phòng';
  }

  Widget _scopePill(LopDaoTaoV2Model item) {
    final isToanVien = item.phamViDaoTao == 1;

    return _mobileMetaPill(
      isToanVien
          ? Icons.public_rounded
          : Icons.apartment_rounded,
      _scopeText(item),
      isToanVien
          ? _primary
          : const Color(0xFF6750A4),
    );
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  Widget _statusPill(LopDaoTaoV2Model item) {
    final Color color;
    final String label;
    final IconData icon;

    if (item.isDaDangKy) {
      color = const Color(0xFF12835B);

      label = 'Đã đăng ký';

      icon = Icons.check_circle_rounded;
    } else if (item.isChuaMoDangKy) {
      color = const Color(0xFFB26A00);

      label = 'Sắp mở đăng ký';

      icon = Icons.schedule_rounded;
    } else if (item.isHetHanDangKy) {
      color = const Color(0xFFC64545);

      label = 'Đã hết hạn';

      icon = Icons.lock_clock_rounded;
    } else {
      color = const Color(0xFF12835B);

      label = 'Đang mở đăng ký';

      icon = Icons.lock_open_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, size: 14, color: color),

          const SizedBox(width: 5),

          Text(
            label,

            style: TextStyle(
              color: color,

              fontSize: 11,

              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFO
  // ==========================================================

  Widget _infoLine(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, size: 18, color: const Color(0xFF6D8799)),

        const SizedBox(width: 8),

        SizedBox(
          width: 91,

          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF718496), fontSize: 12),
          ),
        ),

        Expanded(
          child: Text(
            value,

            style: const TextStyle(
              color: _navy,

              fontSize: 12,

              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ACTION BUTTON
  // ==========================================================

  Widget _actionButton(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model item, {
    required bool compact,
  }) {
    if (item.isDaDangKy) {
      return OutlinedButton.icon(
        onPressed: provider.isSaving || item.isHetHanDangKy
            ? null
            : () => _confirmUnregister(provider, item),

        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC64545),

          side: const BorderSide(color: Color(0xFFE8BABA)),

          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 18,

            vertical: compact ? 9 : 13,
          ),

          visualDensity: VisualDensity.compact,
        ),

        icon: Icon(Icons.close_rounded, size: compact ? 16 : 18),

        label: Text(compact ? 'Hủy' : 'Hủy đăng ký'),
      );
    }

    final bool enabled = !provider.isSaving && item.isMoDangKy;

    final String text = item.isChuaMoDangKy
        ? 'Chưa mở'
        : item.isHetHanDangKy
        ? 'Hết hạn'
        : 'Đăng ký';

    return FilledButton.icon(
      onPressed: enabled ? () => _confirmRegister(provider, item) : null,

      style: FilledButton.styleFrom(
        backgroundColor: _primary,

        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 20,

          vertical: compact ? 9 : 13,
        ),

        visualDensity: VisualDensity.compact,
      ),

      icon: Icon(Icons.how_to_reg_rounded, size: compact ? 16 : 18),

      label: Text(text),
    );
  }

  // ==========================================================
  // CHI TIẾT LỚP
  // ==========================================================

  Future<void> _showClassDetail(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model item,
  ) async {
    if (item.isDaDangKy || item.canTaiLieu) {
      unawaited(provider.loadTaiLieu(item.idLopDaoTao));
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: DraggableScrollableSheet(
          initialChildSize: .72,
          minChildSize: .52,
          maxChildSize: .94,
          expand: false,
          builder: (sheetContext, scrollController) {
            return Consumer<DaoTaoV2Provider>(
              builder: (context, currentProvider, _) {
                final currentItem = _latestItem(currentProvider, item);

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: Column(
                    children: [
                      // ==========================================
                      // THANH KÉO
                      // ==========================================
                      Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD2DDE4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      // ==========================================
                      // NỘI DUNG
                      // ==========================================
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                          children: [
                            // ====================================
                            // ICON
                            // ====================================
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F5FC),
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: _primary,
                                size: 29,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ====================================
                            // TÊN LỚP
                            // ====================================
                            Text(
                              currentItem.tenLopDaoTao,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 21,
                                height: 1.25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: _statusPill(currentItem),
                            ),

                            const SizedBox(height: 22),

                            _detailTile(
                              Icons.apartment_rounded,
                              'Phạm vi',
                              _scopeText(currentItem),
                            ),

                            // ====================================
                            // BÁO CÁO VIÊN
                            // ====================================
                            if (currentItem.baoCaoVien?.trim().isNotEmpty ==
                                true)
                              _detailTile(
                                Icons.person_outline_rounded,
                                'Báo cáo viên',
                                currentItem.baoCaoVien!.trim(),
                              ),

                            // ====================================
                            // ĐƠN VỊ GIẢNG DẠY
                            // ====================================
                            if (currentItem.donViGiangDay?.trim().isNotEmpty ==
                                true)
                              _detailTile(
                                Icons.business_center_outlined,
                                'Đơn vị giảng dạy',
                                currentItem.donViGiangDay!.trim(),
                              ),

                            // ====================================
                            // HÌNH THỨC ONLINE
                            // ====================================
                            if (currentItem.isOnline)
                              _detailTile(
                                Icons.video_camera_front_rounded,
                                'Hình thức tham gia',
                                currentItem.isDaDangKy
                                    ? currentItem.isDangKyOnline
                                          ? 'Online'
                                          : 'Trực tiếp'
                                    : 'Có hỗ trợ Online',
                              ),

                            // ====================================
                            // THỜI GIAN HỌC
                            // ====================================
                            _detailTile(
                              Icons.calendar_month_outlined,
                              'Thời gian học',
                              _courseDateText(currentItem),
                            ),

                            if (currentItem.thoiGianDetails
                                    ?.trim()
                                    .isNotEmpty ==
                                true)
                              _detailTile(
                                Icons.access_time_rounded,
                                'Thời gian chi tiết',
                                currentItem.thoiGianDetails!.trim(),
                              ),

                            if (currentItem.diaDiem?.trim().isNotEmpty == true)
                              _detailTile(
                                Icons.location_on_outlined,
                                'Địa điểm',
                                currentItem.diaDiem!.trim(),
                              ),

                            if (currentItem.tpThamDu?.trim().isNotEmpty == true)
                              _detailTile(
                                Icons.groups_2_outlined,
                                'Thành phần tham dự',
                                currentItem.tpThamDu!.trim(),
                              ),

                            // ====================================
                            // THỜI GIAN ĐĂNG KÝ
                            // ====================================
                            _detailTile(
                              Icons.schedule_rounded,
                              'Thời gian đăng ký',
                              _registrationDateText(currentItem),
                            ),

                            // ====================================
                            // SỐ TIẾT
                            // ====================================
                            if (currentItem.soTiet != null)
                              _detailTile(
                                Icons.timer_outlined,
                                'Thời lượng',
                                '${_number(currentItem.soTiet!)} tiết',
                              ),

                            // ====================================
                            // HÌNH THỨC ĐÀO TẠO
                            // ====================================
                            if (currentItem.tenHinhThucDaoTao
                                    ?.trim()
                                    .isNotEmpty ==
                                true)
                              _detailTile(
                                Icons.category_outlined,
                                'Hình thức',
                                currentItem.tenHinhThucDaoTao!.trim(),
                              ),

                            // ====================================
                            // ĐƠN VỊ ĐÀO TẠO
                            // ====================================
                            if (currentItem.donViDaoTao?.trim().isNotEmpty ==
                                true)
                              _detailTile(
                                Icons.apartment_rounded,
                                'Đơn vị đào tạo',
                                currentItem.donViDaoTao!.trim(),
                              ),

                            if (currentItem.tenChungChi?.trim().isNotEmpty ==
                                true)
                              _detailTile(
                                Icons.workspace_premium_outlined,
                                'Chứng chỉ',
                                currentItem.tenChungChi!.trim(),
                              ),

                            if (currentItem.ghiChu?.trim().isNotEmpty ==
                                true) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E8),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFF0DEB4),
                                  ),
                                ),
                                child: Text(
                                  currentItem.ghiChu!.trim(),
                                  style: const TextStyle(
                                    color: _navy,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],

                            if (currentItem.isDaDangKy ||
                                currentItem.canTaiLieu) ...[
                              const SizedBox(height: 22),
                              _buildTaiLieuSection(
                                currentProvider,
                                currentItem,
                              ),
                            ],

                            if (currentItem.isDaDangKy &&
                                currentItem.isOnline &&
                                currentItem.isDangKyOnline) ...[
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showThongTinOnline(
                                    currentProvider,
                                    currentItem,
                                  ),
                                  icon: const Icon(
                                    Icons.video_camera_front_rounded,
                                  ),
                                  label: const Text('Thông tin học online'),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // ====================================
                            // ĐĂNG KÝ / HỦY ĐĂNG KÝ
                            // ====================================
                            SizedBox(
                              width: double.infinity,
                              child: _actionButton(
                                currentProvider,
                                currentItem,
                                compact: false,
                              ),
                            ),
                          ], // <-- đóng children của ListView
                        ),
                      ),
                    ], // <-- đóng children của Column
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // LẤY ITEM MỚI NHẤT TỪ PROVIDER
  // ==========================================================

  LopDaoTaoV2Model _latestItem(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model fallback,
  ) {
    for (final item in [...provider.danhSach, ...provider.lopCuaToi]) {
      if (item.idLopDaoTao == fallback.idLopDaoTao) {
        return item;
      }
    }

    return fallback;
  }

  // ==========================================================
  // TÀI LIỆU
  // ==========================================================

  Widget _buildTaiLieuSection(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model item,
  ) {
    // ========================================================
    // ĐIỀU KIỆN QUAN TRỌNG
    // ========================================================

    if (!item.isDaDangKy && !item.canTaiLieu) {
      return const SizedBox.shrink();
    }

    final isLoading = provider.isLoadingTaiLieu(item.idLopDaoTao);

    final files = provider.taiLieuTheoLop[item.idLopDaoTao] ?? [];

    final error = provider.taiLieuErrorTheoLop[item.idLopDaoTao];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Container(
              width: 38,

              height: 38,

              decoration: BoxDecoration(
                color: const Color(0xFFE5F5FC),

                borderRadius: BorderRadius.circular(11),
              ),

              child: const Icon(
                Icons.folder_open_rounded,

                color: _primary,

                size: 19,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Tài liệu lớp học',

                    style: TextStyle(
                      color: _navy,

                      fontSize: 15,

                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  if (!isLoading && files.isNotEmpty)
                    Text(
                      '${files.length} tài liệu',

                      style: const TextStyle(
                        color: Color(0xFF718496),

                        fontSize: 11.5,
                      ),
                    ),
                ],
              ),
            ),

            if (!isLoading)
              IconButton(
                tooltip: 'Làm mới tài liệu',

                onPressed: () {
                  provider.loadTaiLieu(item.idLopDaoTao, force: true);
                },

                icon: const Icon(
                  Icons.refresh_rounded,

                  size: 20,

                  color: _primary,
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(18),

              child: CircularProgressIndicator(),
            ),
          )
        else if (error != null && files.isEmpty)
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),

              borderRadius: BorderRadius.circular(12),
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  error,

                  style: const TextStyle(
                    color: Color(0xFFB63D3D),

                    fontSize: 12.5,
                  ),
                ),

                const SizedBox(height: 5),

                TextButton.icon(
                  onPressed: () =>
                      provider.loadTaiLieu(item.idLopDaoTao, force: true),

                  icon: const Icon(Icons.refresh_rounded),

                  label: const Text('Thử lại'),
                ),
              ],
            ),
          )
        else if (files.isEmpty)
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(
              color: _background,

              borderRadius: BorderRadius.circular(12),

              border: Border.all(color: const Color(0xFFDDE8EF)),
            ),

            child: const Row(
              children: [
                Icon(
                  Icons.folder_off_outlined,

                  color: Color(0xFF718496),

                  size: 20,
                ),

                SizedBox(width: 9),

                Expanded(
                  child: Text(
                    'Lớp học chưa có tài liệu.',

                    style: TextStyle(color: Color(0xFF718496), fontSize: 12.5),
                  ),
                ),
              ],
            ),
          )
        else
          ...files.map((file) => _mobileFileTile(provider, item, file)),
      ],
    );
  }

  // ==========================================================
  // FILE TILE
  // ==========================================================

  Widget _mobileFileTile(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model lop,
    LopDaoTaoFileV2Model file,
  ) {
    final downloading = provider.isDownloadingFile(file.idFile);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),

      padding: const EdgeInsets.all(11),

      decoration: BoxDecoration(
        color: _background,

        borderRadius: BorderRadius.circular(13),

        border: Border.all(color: const Color(0xFFDDE8EF)),
      ),

      child: Row(
        children: [
          Container(
            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(_fileIcon(file.fileName), color: _primary, size: 22),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  file.fileName,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: _navy,

                    fontWeight: FontWeight.w700,

                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${_mobileFileType(file)}'
                  ' • '
                  '${_mobileFileSize(file.fileSize)}',

                  style: const TextStyle(
                    color: Color(0xFF718496),

                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Tải xuống',

            onPressed: downloading
                ? null
                : () => _downloadMobileFile(provider, lop, file),

            icon: downloading
                ? const SizedBox(
                    width: 18,

                    height: 18,

                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, color: _primary),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DOWNLOAD
  // ==========================================================

  Future<void> _downloadMobileFile(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model lop,
    LopDaoTaoFileV2Model file,
  ) async {
    // ========================================================
    // CHẶN UI
    //
    // Backend vẫn phải kiểm tra đăng ký một lần nữa.
    // ========================================================

    if (!lop.isDaDangKy && !lop.canTaiLieu) {
      _showMessage(
        'Bạn không có quyền tải tài liệu của lớp này.',
        isError: true,
      );

      return;
    }

    final bytes = await provider.downloadTaiLieu(
      idLopDaoTao: lop.idLopDaoTao,

      idFile: file.idFile,
    );

    if (!mounted) {
      return;
    }

    if (bytes == null || bytes.isEmpty) {
      _showMessage(
        provider.errorMessage ?? 'Không tải được tài liệu.',
        isError: true,
      );

      return;
    }

    try {
      final savedPath = await fp.FilePicker.platform.saveFile(
        dialogTitle: 'Lưu tài liệu',

        fileName: file.fileName,

        bytes: bytes,
      );

      if (!mounted) {
        return;
      }

      // Trên một số nền tảng saveFile có thể
      // trả null sau khi user đóng dialog.
      if (savedPath == null) {
        return;
      }

      _showMessage('Đã lưu tài liệu.', isError: false);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Không thể lưu tài liệu: $e', isError: true);
    }
  }

  // ==========================================================
  // FILE HELPERS
  // ==========================================================

  String _mobileFileType(LopDaoTaoFileV2Model file) {
    var type = file.fileType?.trim().replaceAll('.', '').toUpperCase();

    if (type != null && type.isNotEmpty) {
      return type;
    }

    final index = file.fileName.lastIndexOf('.');

    if (index >= 0 && index < file.fileName.length - 1) {
      return file.fileName.substring(index + 1).toUpperCase();
    }

    return 'FILE';
  }

  String _mobileFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _fileIcon(String fileName) {
    final index = fileName.lastIndexOf('.');

    final extension = index >= 0 && index < fileName.length - 1
        ? fileName.substring(index + 1).toLowerCase()
        : '';

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;

      case 'doc':
      case 'docx':
      case 'txt':
        return Icons.description_rounded;

      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;

      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;

      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return Icons.image_rounded;

      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;

      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // ==========================================================
  // DETAIL TILE
  // ==========================================================

  Widget _detailTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 38,

            height: 38,

            decoration: BoxDecoration(
              color: _background,

              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(icon, color: _primary, size: 19),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    color: Color(0xFF718496),

                    fontSize: 11.5,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,

                  style: const TextStyle(
                    color: _navy,

                    fontSize: 13.5,

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

  // ==========================================================
  // ĐĂNG KÝ
  // ==========================================================

  Future<void> _confirmRegister(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model item,
  ) async {
    bool? isDangKyOnline;

    if (item.isOnline) {
      bool selectedOnline = false;

      isDangKyOnline = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                padding: EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  18 + MediaQuery.paddingOf(sheetContext).bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD2DDE4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),
                        const Row(
                          children: [
                            Icon(Icons.how_to_reg_rounded, color: _primary),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Đăng ký lớp đào tạo',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.tenLopDaoTao,
                          style: const TextStyle(
                            color: Color(0xFF718496),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 17),
                        const Text(
                          'Chọn hình thức tham gia',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 9),
                        _registrationModeOption(
                          icon: Icons.groups_rounded,
                          title: 'Trực tiếp',
                          subtitle: 'Tham gia học tại địa điểm tổ chức',
                          selected: !selectedOnline,
                          onTap: () {
                            setSheetState(() => selectedOnline = false);
                          },
                        ),
                        const SizedBox(height: 9),
                        _registrationModeOption(
                          icon: Icons.video_camera_front_rounded,
                          title: 'Online',
                          subtitle: 'Tham gia học từ xa qua Zoom',
                          selected: selectedOnline,
                          onTap: () {
                            setSheetState(() => selectedOnline = true);
                          },
                        ),
                        if (selectedOnline) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2F1),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: const Color(0xFFF2B8B5),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFC62828),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Quý đồng nghiệp vui lòng sắp xếp học trực tiếp, trường hợp học online ưu tiên dành cho Phòng khám vệ tinh và CBNV không thể tham dự học trực tiếp vì có lý do chính đáng. Trân trọng./.',
                                    style: TextStyle(
                                      color: Color(0xFFC62828),
                                      fontSize: 12.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                child: const Text('Để sau'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () =>
                                    Navigator.pop(sheetContext, selectedOnline),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Xác nhận'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Đăng ký lớp đào tạo'),
          content: Text('Bạn muốn đăng ký lớp “${item.tenLopDaoTao}”?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Đăng ký'),
            ),
          ],
        ),
      );
      isDangKyOnline = confirm == true ? false : null;
    }

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
      await provider.loadTaiLieu(item.idLopDaoTao);
      if (!mounted) {
        return;
      }
    }

    _showMessage(
      ok
          ? isDangKyOnline
                ? 'Đăng ký tham gia online thành công.'
                : 'Đăng ký lớp đào tạo thành công.'
          : provider.errorMessage ?? 'Không thể đăng ký lớp đào tạo.',
      isError: !ok,
    );
  }

  Widget _registrationModeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFEAF6FC) : const Color(0xFFF7F9FB),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? _primary : const Color(0xFFDDE6EC),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? _primary.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: selected ? _primary : const Color(0xFF718496),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected ? _primary : _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF718496),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  color: selected ? _primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _primary : const Color(0xFF9AAAB6),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showThongTinOnline(
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
      _showMessage(
        provider.errorMessage ?? 'Không lấy được thông tin học online.',
        isError: true,
      );

      return;
    }

    await showModalBottomSheet<void>(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(sheetContext).padding.bottom,
          ),

          decoration: const BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),

          child: SafeArea(
            top: false,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Align(
                  alignment: Alignment.center,

                  child: Container(
                    width: 42,

                    height: 4,

                    decoration: BoxDecoration(
                      color: const Color(0xFFD2DDE4),

                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Row(
                  children: [
                    Icon(Icons.video_camera_front_rounded, color: _primary),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Thông tin học online',

                        style: TextStyle(
                          color: _navy,

                          fontSize: 18,

                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  info.tenLopDaoTao,

                  style: const TextStyle(
                    color: Color(0xFF718496),

                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                _onlineInfoTile(
                  icon: Icons.numbers_rounded,

                  label: 'Zoom ID',

                  value: info.zoomID,
                ),

                _onlineInfoTile(
                  icon: Icons.password_rounded,

                  label: 'Passcode',

                  value: info.zoomPasscode,
                ),

                _onlineInfoTile(
                  icon: Icons.video_call_rounded,

                  label: 'Link Zoom',

                  value: info.linkZoom,
                  isLink: true,
                ),

                _onlineInfoTile(
                  icon: Icons.chat_bubble_outline_rounded,

                  label: 'Link Chat',

                  value: info.linkChat,
                  isLink: true,
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,

                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),

                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _onlineInfoTile({
    required IconData icon,
    required String label,
    required String? value,
    bool isLink = false,
  }) {
    final text = value?.trim();
    final bool hasValue = text?.isNotEmpty == true;
    final String displayText = hasValue ? text! : 'Chưa cấu hình';

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: _background,

        borderRadius: BorderRadius.circular(13),

        border: Border.all(color: const Color(0xFFDDE8EF)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 38,

            height: 38,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, color: _primary, size: 19),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,

                  style: const TextStyle(
                    color: Color(0xFF718496),

                    fontSize: 11.5,
                  ),
                ),

                const SizedBox(height: 3),

                if (isLink && hasValue)
                  InkWell(
                    onTap: () => _openOnlineLink(displayText),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        displayText,
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                else
                  SelectableText(
                    displayText,
                    style: TextStyle(
                      color: hasValue ? _navy : const Color(0xFF718496),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          IconButton(
            tooltip: hasValue ? 'Sao chép $label' : 'Chưa có dữ liệu',
            onPressed: hasValue
                ? () => _copyOnlineInfo(label, displayText)
                : null,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, size: 19),
          ),
          if (isLink && hasValue)
            IconButton(
              tooltip: 'Mở $label',
              onPressed: () => _openOnlineLink(displayText),
              visualDensity: VisualDensity.compact,
              color: _primary,
              icon: const Icon(Icons.open_in_new_rounded, size: 19),
            ),
        ],
      ),
    );
  }

  Future<void> _copyOnlineInfo(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      _showMessage('Đã sao chép $label.', isError: false);
    }
  }

  Future<void> _openOnlineLink(String value) async {
    final String rawValue = value.trim();
    final String normalizedValue = rawValue.contains('://')
        ? rawValue
        : 'https://$rawValue';
    final Uri? uri = Uri.tryParse(normalizedValue);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _showMessage('Đường dẫn không hợp lệ.', isError: true);
      return;
    }

    try {
      final bool opened = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (!opened && mounted) {
        _showMessage('Không thể mở đường dẫn này.', isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Không thể mở đường dẫn này.', isError: true);
      }
    }
  }
  // ==========================================================
  // HỦY ĐĂNG KÝ
  // ==========================================================

  Future<void> _confirmUnregister(
    DaoTaoV2Provider provider,
    LopDaoTaoV2Model item,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,

      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đăng ký'),

        content: Text(
          'Bạn có chắc muốn hủy đăng ký lớp “${item.tenLopDaoTao}”?',
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),

            child: const Text('Không'),
          ),

          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC64545),
            ),

            onPressed: () => Navigator.pop(dialogContext, true),

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

    _showMessage(
      ok
          ? 'Đã hủy đăng ký lớp đào tạo.'
          : provider.errorMessage ?? 'Không thể hủy đăng ký.',

      isError: !ok,
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),

      padding: const EdgeInsets.all(11),

      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),

        borderRadius: BorderRadius.circular(12),
      ),

      child: Text(
        message,

        style: const TextStyle(color: Color(0xFFB63D3D), fontSize: 12.5),
      ),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          behavior: SnackBarBehavior.floating,

          backgroundColor: isError
              ? const Color(0xFFC64545)
              : const Color(0xFF12835B),
        ),
      );
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String _courseDateText(LopDaoTaoV2Model item) {
    if (item.ngayBatDau == null && item.ngayKetThuc == null) {
      return 'Chưa xác định';
    }

    if (item.ngayBatDau != null && item.ngayKetThuc == null) {
      return DateFormat('dd/MM/yyyy').format(item.ngayBatDau!);
    }

    if (item.ngayBatDau == null) {
      return DateFormat('dd/MM/yyyy').format(item.ngayKetThuc!);
    }

    return '${DateFormat('dd/MM/yyyy').format(item.ngayBatDau!)}'
        ' - '
        '${DateFormat('dd/MM/yyyy').format(item.ngayKetThuc!)}';
  }

  String _registrationDateText(LopDaoTaoV2Model item) {
    final start = item.batDauDangKy;

    final end = item.ketThucDangKy;

    final format = DateFormat('dd/MM/yyyy HH:mm');

    if (start == null && end == null) {
      return 'Không giới hạn';
    }

    if (start != null && end == null) {
      return 'Từ ${format.format(start)}';
    }

    if (start == null) {
      return 'Đến ${format.format(end!)}';
    }

    return '${format.format(start)}'
        ' - '
        '${format.format(end!)}';
  }

  String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}
