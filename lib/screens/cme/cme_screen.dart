import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cme_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cme_provider.dart';
import 'cme_detail_dialog.dart';
import 'cme_request_form_dialog.dart';

class CmeScreen extends StatefulWidget {
  const CmeScreen({super.key, this.initialTab = 0});

  /// 0: CME của tôi, 1: Duyệt CME.
  final int initialTab;

  @override
  State<CmeScreen> createState() => _CmeScreenState();
}

class _CmeScreenState extends State<CmeScreen> {
  static const Color _primary = Color(0xFF1274BC);
  static const Color _background = Color(0xFFF4F7FB);

  final TextEditingController _myKeywordController = TextEditingController();
  final TextEditingController _approvalKeywordController =
      TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final FocusNode _departmentFocusNode = FocusNode();

  Timer? _keywordDebounce;

  late int _activeTab;
  String _myStatus = '';
  String _approvalStatus = CmeStatus.choDuyet;
  String? _selectedDepartmentCode;
  DateTime? _myFromDate;
  DateTime? _myToDate;
  DateTime? _approvalFromDate;
  DateTime? _approvalToDate;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab == 1 ? 1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _keywordDebounce?.cancel();
    _myKeywordController.dispose();
    _approvalKeywordController.dispose();
    _departmentController.dispose();
    _departmentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (!mounted) {
      return;
    }

    final bool canApprove = context
        .read<AuthProvider>()
        .currentRoleIds
        .contains(36);
    await context.read<CmeProvider>().initialize(canApprove);
  }

  Future<void> _openCreateDialog() async {
    final bool created = await showCmeRequestFormDialog(context);
    if (!mounted || !created) {
      return;
    }

    setState(() => _activeTab = 0);
  }

  Future<void> _openDetail(int id) async {
    await showCmeDetailDialog(context, requestId: id);
  }

  CmeQuery _buildCurrentQuery({required int page}) {
    if (_activeTab == 1) {
      return CmeQuery(
        trangThai: _approvalStatus.isEmpty ? null : _approvalStatus,
        keyword: _normalized(_approvalKeywordController.text),
        maKhoa: _selectedDepartmentCode,
        tuNgay: _approvalFromDate,
        denNgay: _approvalToDate,
        page: page,
        pageSize: 20,
      );
    }

    return CmeQuery(
      trangThai: _myStatus.isEmpty ? null : _myStatus,
      keyword: _normalized(_myKeywordController.text),
      tuNgay: _myFromDate,
      denNgay: _myToDate,
      page: page,
      pageSize: 20,
    );
  }

  Future<void> _loadCurrent({int page = 1}) async {
    final CmeProvider provider = context.read<CmeProvider>();
    final CmeQuery query = _buildCurrentQuery(page: page);

    if (_activeTab == 1) {
      await provider.loadApproval(query: query);
    } else {
      await provider.loadMy(query: query);
    }
  }

  Future<void> _clearFilters() async {
    setState(() {
      if (_activeTab == 1) {
        _approvalKeywordController.clear();
        _departmentController.clear();
        _selectedDepartmentCode = null;
        _approvalStatus = CmeStatus.choDuyet;
        _approvalFromDate = null;
        _approvalToDate = null;
      } else {
        _myKeywordController.clear();
        _myStatus = '';
        _myFromDate = null;
        _myToDate = null;
      }
    });
    await _loadCurrent();
  }

  void _changeTab(int tab) {
    if (_activeTab == tab) {
      return;
    }
    _keywordDebounce?.cancel();
    setState(() => _activeTab = tab);
  }

  void _scheduleKeywordFilter(int tab) {
    _keywordDebounce?.cancel();
    _keywordDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _activeTab == tab) {
        unawaited(_loadCurrent());
      }
    });
  }

  Future<void> _selectDate({required bool isFromDate}) async {
    final bool approvalTab = _activeTab == 1;
    final DateTime? current = approvalTab
        ? (isFromDate ? _approvalFromDate : _approvalToDate)
        : (isFromDate ? _myFromDate : _myToDate);
    final DateTime? minimum = approvalTab ? _approvalFromDate : _myFromDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current ?? minimum ?? DateTime.now(),
      firstDate: isFromDate ? DateTime(2000) : minimum ?? DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      if (approvalTab) {
        if (isFromDate) {
          _approvalFromDate = picked;
          if (_approvalToDate != null && picked.isAfter(_approvalToDate!)) {
            _approvalToDate = null;
          }
        } else {
          _approvalToDate = picked;
        }
      } else if (isFromDate) {
        _myFromDate = picked;
        if (_myToDate != null && picked.isAfter(_myToDate!)) {
          _myToDate = null;
        }
      } else {
        _myToDate = picked;
      }
    });
    await _loadCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final bool mobileLayout = MediaQuery.sizeOf(context).width < 600;
    final bool canApprove = context.select<AuthProvider, bool>(
      (AuthProvider auth) => auth.currentRoleIds.contains(36),
    );

    if (!canApprove && _activeTab == 1) {
      _activeTab = 0;
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            mobileLayout
                ? _buildMobileHeader(canApprove)
                : _buildHeader(canApprove),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  mobileLayout ? 10 : 12,
                  mobileLayout ? 10 : 14,
                  mobileLayout ? 10 : 12,
                  mobileLayout ? 10 : 14,
                ),
                child: Column(
                  children: <Widget>[
                    _buildTabs(canApprove),
                    const SizedBox(height: 12),
                    _buildFilterPanel(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildRequestPanel()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader(bool canApprove) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4EAF0))),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: _primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Cập nhật CME',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF17324D),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (canApprove)
                  const Text(
                    'Có quyền duyệt CME',
                    style: TextStyle(
                      color: Color(0xFF16805A),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _openCreateDialog,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Gửi',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool canApprove) {
    final bool canGoBack = Navigator.of(context).canPop();

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4EAF0))),
      ),
      child: Row(
        children: <Widget>[
          if (canGoBack) ...<Widget>[
            IconButton(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: _primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Quản lý CME',
                  style: TextStyle(
                    color: Color(0xFF17324D),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Gửi và theo dõi chứng nhận đào tạo liên tục',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFF718293), fontSize: 12),
                ),
              ],
            ),
          ),
          if (canApprove) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F1),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFC8EBD9)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: Color(0xFF16805A),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Người duyệt',
                    style: TextStyle(
                      color: Color(0xFF16805A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          FilledButton.icon(
            onPressed: _openCreateDialog,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Gửi CME',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool canApprove) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _CmeTabButton(
              label: 'CME của tôi',
              icon: Icons.badge_outlined,
              selected: _activeTab == 0,
              onTap: () => _changeTab(0),
            ),
            if (canApprove)
              _CmeTabButton(
                label: 'Duyệt CME',
                icon: Icons.fact_check_outlined,
                selected: _activeTab == 1,
                onTap: () => _changeTab(1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    final bool approvalTab = _activeTab == 1;
    final TextEditingController keywordController = approvalTab
        ? _approvalKeywordController
        : _myKeywordController;
    final DateTime? fromDate = approvalTab ? _approvalFromDate : _myFromDate;
    final DateTime? toDate = approvalTab ? _approvalToDate : _myToDate;
    final String status = approvalTab ? _approvalStatus : _myStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E9EF)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 760;
          final double regularWidth = compact
              ? (constraints.maxWidth - 12) / 2
              : 220;
          final double searchWidth = compact ? constraints.maxWidth : 280;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: keywordController,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => _scheduleKeywordFilter(_activeTab),
                  onSubmitted: (_) => _loadCurrent(),
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm',
                    hintText: approvalTab
                        ? 'Tên, mã NV, chứng chỉ...'
                        : 'Tên hoặc số chứng chỉ...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: regularWidth,
                child: DropdownButtonFormField<String>(
                  key: ValueKey<String>('$_activeTab-$status'),
                  initialValue: status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _statusOptions(approvalTab)
                      .map(
                        ((String value, String label) item) =>
                            DropdownMenuItem<String>(
                              value: item.$1,
                              child: Text(item.$2),
                            ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      if (approvalTab) {
                        _approvalStatus = value;
                      } else {
                        _myStatus = value;
                      }
                    });
                    unawaited(_loadCurrent());
                  },
                ),
              ),
              if (approvalTab)
                _buildDepartmentAutocomplete(width: regularWidth),
              _DateFilterButton(
                width: regularWidth,
                label: 'Từ ngày',
                date: fromDate,
                onTap: () => _selectDate(isFromDate: true),
              ),
              _DateFilterButton(
                width: regularWidth,
                label: 'Đến ngày',
                date: toDate,
                onTap: () => _selectDate(isFromDate: false),
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 19),
                label: const Text('Đặt lại'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDepartmentAutocomplete({required double width}) {
    return Consumer<CmeProvider>(
      builder: (BuildContext context, CmeProvider provider, Widget? child) {
        final List<CmeDepartment> departments = provider.departments;

        return SizedBox(
          width: width,
          child: RawAutocomplete<CmeDepartment>(
            textEditingController: _departmentController,
            focusNode: _departmentFocusNode,
            displayStringForOption: _departmentDisplayName,
            optionsBuilder: (TextEditingValue value) {
              final String keyword = _searchKey(value.text.trim());
              if (keyword.isEmpty) {
                return departments;
              }

              return departments.where((CmeDepartment department) {
                final String searchable = _searchKey(
                  '${department.tenKhoa ?? ''} ${department.maKhoa}',
                );
                return searchable.contains(keyword);
              });
            },
            onSelected: (CmeDepartment department) {
              setState(() => _selectedDepartmentCode = department.maKhoa);
              unawaited(_loadCurrent());
            },
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController controller,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) {
                      if (_selectedDepartmentCode != null) {
                        setState(() => _selectedDepartmentCode = null);
                      }
                    },
                    onSubmitted: (_) => onFieldSubmitted(),
                    decoration: InputDecoration(
                      labelText: 'Khoa',
                      hintText: 'Gõ tên hoặc mã khoa',
                      prefixIcon: const Icon(Icons.apartment_rounded, size: 19),
                      suffixIcon: provider.isLoadingDepartments
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : provider.departmentError != null
                          ? IconButton(
                              tooltip: 'Tải lại danh sách khoa',
                              onPressed: () => unawaited(
                                context.read<CmeProvider>().loadDepartments(),
                              ),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFFB83D46),
                                size: 19,
                              ),
                            )
                          : controller.text.isEmpty
                          ? IconButton(
                              tooltip: 'Mở danh sách khoa',
                              onPressed: () {
                                if (focusNode.hasFocus) {
                                  focusNode.unfocus();
                                }
                                focusNode.requestFocus();
                              },
                              icon: const Icon(Icons.arrow_drop_down_rounded),
                            )
                          : IconButton(
                              tooltip: 'Tất cả khoa',
                              onPressed: () {
                                controller.clear();
                                setState(() => _selectedDepartmentCode = null);
                                focusNode.requestFocus();
                                unawaited(_loadCurrent());
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                      errorText: provider.departmentError == null
                          ? null
                          : 'Không tải được danh sách khoa',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
            optionsViewBuilder:
                (
                  BuildContext context,
                  AutocompleteOnSelected<CmeDepartment> onSelected,
                  Iterable<CmeDepartment> options,
                ) {
                  final List<CmeDepartment> visibleOptions = options.toList();
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      shadowColor: const Color(0x330B426B),
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: width,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 320),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shrinkWrap: true,
                            itemCount: visibleOptions.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final CmeDepartment department =
                                  visibleOptions[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.account_balance_outlined,
                                  color: _primary,
                                  size: 20,
                                ),
                                title: Text(
                                  _departmentDisplayName(department),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  department.maKhoa,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => onSelected(department),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
          ),
        );
      },
    );
  }

  Widget _buildRequestPanel() {
    return Consumer<CmeProvider>(
      builder: (BuildContext context, CmeProvider provider, Widget? child) {
        final bool approvalTab = _activeTab == 1;
        final CmePagedResult result = approvalTab
            ? provider.approvalResult
            : provider.myResult;
        final bool isLoading = approvalTab
            ? provider.isLoadingApproval
            : provider.isLoadingMy;
        final String? error = approvalTab
            ? provider.approvalError
            : provider.myError;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE2E9EF)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              _buildListHeader(result.totalCount, approvalTab),
              if (isLoading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _buildListBody(
                  result: result,
                  isLoading: isLoading,
                  error: error,
                  approvalTab: approvalTab,
                ),
              ),
              if (result.items.isNotEmpty)
                _buildPagination(result, isLoading: isLoading),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListHeader(int totalCount, bool approvalTab) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 11),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  approvalTab ? 'Danh sách cần xử lý' : 'Yêu cầu đã gửi',
                  style: const TextStyle(
                    color: Color(0xFF233C54),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$totalCount yêu cầu',
                  style: const TextStyle(
                    color: Color(0xFF7B8C9C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () => _loadCurrent(
              page: _activeTab == 1
                  ? context.read<CmeProvider>().approvalResult.page
                  : context.read<CmeProvider>().myResult.page,
            ),
            icon: const Icon(Icons.refresh_rounded, color: _primary),
          ),
        ],
      ),
    );
  }

  Widget _buildListBody({
    required CmePagedResult result,
    required bool isLoading,
    required String? error,
    required bool approvalTab,
  }) {
    if (isLoading && result.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (error != null && result.items.isEmpty) {
      return _CmeMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Không tải được dữ liệu',
        message: error,
        actionLabel: 'Thử lại',
        onAction: _loadCurrent,
      );
    }

    if (result.items.isEmpty) {
      return _CmeMessageState(
        icon: approvalTab
            ? Icons.task_alt_rounded
            : Icons.workspace_premium_outlined,
        title: approvalTab ? 'Không có yêu cầu cần xử lý' : 'Chưa có CME nào',
        message: approvalTab
            ? 'Các yêu cầu phù hợp bộ lọc sẽ xuất hiện tại đây.'
            : 'Hãy gửi chứng nhận CME đầu tiên của bạn.',
        actionLabel: approvalTab ? null : 'Gửi CME',
        onAction: approvalTab ? null : _openCreateDialog,
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= 980) {
          return _buildDesktopTable(result.items, approvalTab);
        }
        return _buildCardList(result.items, approvalTab);
      },
    );
  }

  Widget _buildDesktopTable(List<CmeRequestModel> items, bool approvalTab) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF7F9FC),
                ),
                headingTextStyle: const TextStyle(
                  color: Color(0xFF52687B),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                dataTextStyle: const TextStyle(
                  color: Color(0xFF344C61),
                  fontSize: 13,
                ),
                horizontalMargin: 10,
                columnSpacing: 16,
                columns: <DataColumn>[
                  if (approvalTab) const DataColumn(label: Text('NGƯỜI GỬI')),
                  const DataColumn(label: Text('CHỨNG CHỈ')),
                  const DataColumn(label: Text('ĐƠN VỊ / HÌNH THỨC')),
                  const DataColumn(label: Text('NGÀY GỬI')),
                  const DataColumn(label: Text('MINH CHỨNG')),
                  const DataColumn(label: Text('TRẠNG THÁI')),
                  const DataColumn(label: Text('THAO TÁC')),
                ],
                rows: items.map((CmeRequestModel item) {
                  return DataRow(
                    cells: <DataCell>[
                      if (approvalTab)
                        DataCell(
                          SizedBox(
                            width: 170,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _display(item.tenNguoiGui, item.maSoNguoiGui),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _display(
                                    item.tenKhoa,
                                    item.maKhoa ?? 'Chưa cập nhật',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF81909E),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      DataCell(
                        SizedBox(
                          width: 210,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.tenChungChi,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_hasText(item.soChungChi)) ...<Widget>[
                                const SizedBox(height: 3),
                                Text(
                                  'Số: ${item.soChungChi}',
                                  style: const TextStyle(
                                    color: Color(0xFF81909E),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 190,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _display(item.donViDaoTao, 'Chưa cập nhật'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _display(
                                  item.tenHinhThucDaoTao,
                                  'Không chọn hình thức',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF81909E),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text(_formatDateTime(item.ngayGui))),
                      DataCell(
                        SizedBox(
                          width: 145,
                          child: Row(
                            children: <Widget>[
                              Icon(
                                _isPdf(item)
                                    ? Icons.picture_as_pdf
                                    : Icons.image,
                                size: 18,
                                color: _isPdf(item)
                                    ? const Color(0xFFD34B4B)
                                    : _primary,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  _display(item.fileName, 'Minh chứng'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(_CmeStatusBadge(status: item.trangThai)),
                      DataCell(
                        OutlinedButton.icon(
                          onPressed: () => _openDetail(item.id),
                          icon: const Icon(Icons.visibility_outlined, size: 17),
                          label: Text(
                            approvalTab && item.isPending ? 'Xử lý' : 'Xem',
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardList(List<CmeRequestModel> items, bool approvalTab) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final CmeRequestModel item = items[index];
        return Material(
          color: const Color(0xFFFBFCFE),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _openDetail(item.id),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E9EF)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.tenChungChi,
                          style: const TextStyle(
                            color: Color(0xFF263F56),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _CmeStatusBadge(status: item.trangThai),
                    ],
                  ),
                  if (approvalTab) ...<Widget>[
                    const SizedBox(height: 9),
                    _InfoLine(
                      icon: Icons.person_outline_rounded,
                      text:
                          '${_display(item.tenNguoiGui, item.maSoNguoiGui)} · '
                          '${_display(item.tenKhoa, item.maKhoa ?? 'Chưa cập nhật')}',
                    ),
                  ],
                  const SizedBox(height: 8),
                  _InfoLine(
                    icon: Icons.school_outlined,
                    text: _display(item.donViDaoTao, 'Chưa có đơn vị đào tạo'),
                  ),
                  const SizedBox(height: 6),
                  _InfoLine(
                    icon: Icons.schedule_rounded,
                    text: 'Gửi lúc ${_formatDateTime(item.ngayGui)}',
                  ),
                  const SizedBox(height: 6),
                  _InfoLine(
                    icon: _isPdf(item)
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                    text: _display(item.fileName, 'Minh chứng đính kèm'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openDetail(item.id),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        approvalTab && item.isPending
                            ? 'Xem và xử lý'
                            : 'Xem chi tiết',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination(CmePagedResult result, {required bool isLoading}) {
    final int totalPages = result.totalPages < 1 ? 1 : result.totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFD),
        border: Border(top: BorderSide(color: Color(0xFFE7EDF2))),
      ),
      child: Row(
        children: <Widget>[
          Text(
            'Trang ${result.page}/$totalPages',
            style: const TextStyle(
              color: Color(0xFF667B8D),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton.outlined(
            tooltip: 'Trang trước',
            onPressed: !isLoading && result.page > 1
                ? () => _loadCurrent(page: result.page - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Trang sau',
            onPressed: !isLoading && result.page < totalPages
                ? () => _loadCurrent(page: result.page + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  List<(String, String)> _statusOptions(bool approvalTab) {
    final List<(String, String)> options = <(String, String)>[
      (CmeStatus.choDuyet, 'Chờ duyệt'),
      (CmeStatus.daDuyet, 'Đã duyệt'),
      (CmeStatus.tuChoi, 'Từ chối'),
    ];
    return <(String, String)>[('', 'Tất cả'), ...options];
  }

  static String _departmentDisplayName(CmeDepartment department) =>
      department.displayName;

  static String _searchKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd');
  }

  static String? _normalized(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static bool _hasText(String? value) => value?.trim().isNotEmpty == true;

  static String _display(String? value, String fallback) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '—';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
  }

  static bool _isPdf(CmeRequestModel item) {
    final String fileType = item.fileType?.toLowerCase().trim() ?? '';
    final String fileName = item.fileName?.toLowerCase().trim() ?? '';
    return fileType == 'pdf' || fileType == '.pdf' || fileName.endsWith('.pdf');
  }
}

class _CmeTabButton extends StatelessWidget {
  const _CmeTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x160B426B),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 19,
                color: selected
                    ? const Color(0xFF1274BC)
                    : const Color(0xFF718394),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF174B73)
                      : const Color(0xFF647787),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.width,
    required this.label,
    required this.date,
    required this.onTap,
  });

  final double width;
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: const Color(0xFF40586D),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          side: const BorderSide(color: Color(0xFFB8C6D1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.calendar_today_outlined, size: 17),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                date == null ? label : DateFormat('dd/MM/yyyy').format(date!),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CmeStatusBadge extends StatelessWidget {
  const _CmeStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (
      Color background,
      Color foreground,
      IconData icon,
      String label,
    ) = switch (status.toUpperCase()) {
      CmeStatus.daDuyet => (
        const Color(0xFFE7F7EF),
        const Color(0xFF147A50),
        Icons.check_circle_outline_rounded,
        'Đã duyệt',
      ),
      CmeStatus.tuChoi => (
        const Color(0xFFFDEBEC),
        const Color(0xFFB83D46),
        Icons.cancel_outlined,
        'Từ chối',
      ),
      _ => (
        const Color(0xFFFFF3DB),
        const Color(0xFFA76612),
        Icons.schedule_rounded,
        'Chờ duyệt',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 17, color: const Color(0xFF7890A3)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF62788A), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _CmeMessageState extends StatelessWidget {
  const _CmeMessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4FB),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF1274BC)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF29445B),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A8B99), fontSize: 13),
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
