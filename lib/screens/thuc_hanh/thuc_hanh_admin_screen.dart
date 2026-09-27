import 'dart:async';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'thuc_hanh_file_viewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/nhan_vien_v2_models.dart';
import '../../models/thuc_hanh_models.dart';
import '../../providers/thuc_hanh_provider.dart';
import '../../services/nhan_vien_v2_service.dart';
import '../../services/thuc_hanh_service.dart';
import '../../features/nhan_vien_v2/screens/dialogs/dao_tao_v2/dialogs/excel_download.dart';

class ThucHanhAdminScreen extends StatefulWidget {
  final NhanVienV2Service nhanVienService;
  const ThucHanhAdminScreen({super.key, required this.nhanVienService});
  @override
  State<ThucHanhAdminScreen> createState() => _ThucHanhAdminScreenState();
}

class _ThucHanhAdminScreenState extends State<ThucHanhAdminScreen>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF087DBA);
  late final TabController _tabs;
  DotThucHanhModel? _selectedBatch;
  bool _peopleLoaded = false;
  String? _batchFileAction;
  String get _publicWebUrl {
    final uri = Uri.base;

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return uri.origin;
    }

    return '';
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 && !_peopleLoaded) {
        _peopleLoaded = true;
        context.read<ThucHanhProvider>().loadPeople();
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _snack(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFC43C35)
              : const Color(0xFF18775A),
        ),
      );
  Future<void> _delete(String title, Future<bool> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text('Dữ liệu sẽ được chuyển sang trạng thái đã xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final done = await action();
      if (mounted) {
        _snack(
          done
              ? 'Đã xóa dữ liệu.'
              : (context.read<ThucHanhProvider>().error ?? 'Không thể xóa.'),
          error: !done,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF0F5F8),
    body: SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF075E91), Color(0xFF0796C5)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33075E91),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x26FFFFFF),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(11),
                        child: Icon(
                          Icons.school_outlined,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'Quản lý sinh viên',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.only(left: 65),
                  child: Text(
                    'Chọn đợt để xem danh sách và phân công thực hành',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.event_note_outlined),
                      text: 'Đợt thực hành',
                    ),
                    Tab(icon: Icon(Icons.people_alt_outlined), text: 'Hồ sơ'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _selectedBatch == null ? _batches() : _batchMembers(),
                _people(),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _openBatch(DotThucHanhModel batch) {
    setState(() => _selectedBatch = batch);
    context.read<ThucHanhProvider>().selectBatch(batch.id);
  }

  Widget _batchMembers() => Consumer<ThucHanhProvider>(
    builder: (context, p, _) {
      final batch =
          p.batches.items
              .where((x) => x.id == _selectedBatch!.id)
              .firstOrNull ??
          _selectedBatch!;
      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE9EF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Quay lại danh sách đợt',
                      onPressed: () => setState(() => _selectedBatch = null),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        batch.tenDot,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    'Đăng ký: ${_dt(batch.batDauDangKy)} – ${_dt(batch.ketThucDangKy)} • ${batch.soNguoiDangKy} người',
                    style: const TextStyle(color: Color(0xFF536A7B)),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showRegistrationQr(batch),
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('Link & QR'),
                      ),
                      TextButton.icon(
                        onPressed: () => _batchForm(batch),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Sửa đợt'),
                      ),
                      TextButton.icon(
                        onPressed: _batchFileAction == null
                            ? () => _downloadImportTemplate(batch)
                            : null,
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Tải Excel mẫu'),
                      ),
                      TextButton.icon(
                        onPressed: _batchFileAction == null
                            ? () => _importExcel(batch)
                            : null,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: const Text('Import Excel'),
                      ),
                      TextButton.icon(
                        onPressed: _batchFileAction == null
                            ? () => _exportBatchReport(batch)
                            : null,
                        icon: const Icon(Icons.assessment_outlined),
                        label: Text(
                          _batchFileAction == 'report'
                              ? 'Đang xuất...'
                              : 'Xuất báo cáo',
                        ),
                      ),
                      if (batch.fileQuyetDinh != null)
                        TextButton.icon(
                          onPressed: () => showThucHanhFile(
                            context,
                            p.service,
                            p.service.decisionUrl(batch.id),
                            batch.fileQuyetDinh!,
                          ),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Quyết định'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _registrations()),
        ],
      );
    },
  );

  Future<void> _pickBatchDate(bool from) async {
    final p = context.read<ThucHanhProvider>();
    final value = await showDatePicker(
      context: context,
      initialDate: (from ? p.batchFromDate : p.batchToDate) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (value == null || !mounted) return;
    final start = from ? value : p.batchFromDate;
    final end = from ? p.batchToDate : value;
    if (start != null && end != null && start.isAfter(end)) {
      _snack('Từ ngày không được sau đến ngày.', error: true);
      return;
    }
    p.batchFromDate = start;
    p.batchToDate = end;
    await p.loadBatches();
  }

  Widget _toolbar({
    required String hint,
    String initialText = '',
    required ValueChanged<String> onSearch,
    required VoidCallback onAdd,
    required String addLabel,
    List<Widget> filters = const [],
  }) => _SearchToolbar(
    key: ValueKey(hint),
    initialText: initialText,
    hint: hint,
    onSearch: onSearch,
    onAdd: onAdd,
    addLabel: addLabel,
    filters: filters,
  );

  Widget _batches() => Consumer<ThucHanhProvider>(
    builder: (context, p, _) => Column(
      children: [
        _toolbar(
          hint: 'Tìm tên hoặc nội dung đợt...',
          initialText: p.keywordBatches,
          addLabel: 'Thêm đợt',
          onSearch: (v) {
            p.keywordBatches = v;
            p.loadBatches();
          },
          onAdd: () => _batchForm(),
          filters: [
            _filter<int>(
              value: p.batchRegistrationState,
              label: 'Thời gian đăng ký',
              items: const {0: 'Sắp mở', 1: 'Đang mở', 2: 'Đã đóng'},
              onChanged: (v) {
                p.batchRegistrationState = v;
                p.loadBatches();
              },
            ),
            OutlinedButton.icon(
              onPressed: () => _pickBatchDate(true),
              icon: const Icon(Icons.calendar_today_outlined, size: 17),
              label: Text(
                p.batchFromDate == null
                    ? 'Từ ngày'
                    : 'Từ: ${_dt(p.batchFromDate!)}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickBatchDate(false),
              icon: const Icon(Icons.event_outlined, size: 17),
              label: Text(
                p.batchToDate == null
                    ? 'Đến ngày'
                    : 'Đến: ${_dt(p.batchToDate!)}',
              ),
            ),
            if (p.batchFromDate != null || p.batchToDate != null)
              IconButton(
                tooltip: 'Bỏ lọc ngày',
                icon: const Icon(Icons.filter_alt_off_outlined),
                onPressed: () {
                  p.batchFromDate = null;
                  p.batchToDate = null;
                  p.loadBatches();
                },
              ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Lọc theo thời gian mở đăng ký • Chọn một đợt để xem danh sách',
              style: TextStyle(fontSize: 12, color: Color(0xFF536A7B)),
            ),
          ),
        ),
        Expanded(
          child: _listState(
            loading: p.loadingBatches,
            empty: p.batches.items.isEmpty,
            refresh: p.loadBatches,
            children: p.batches.items
                .map(
                  (x) => Card(
                    margin: const EdgeInsets.fromLTRB(16, 5, 16, 6),
                    elevation: 0,
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFDDE9EF)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openBatch(x),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE4F3FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.event_available,
                                    color: _blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        x.tenDot,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'Đăng ký: ${_dt(x.batDauDangKy)} - ${_dt(x.ketThucDangKy)}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _statusChip(x.trangThai),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') {
                                      _batchForm(x);
                                    }
                                    if (v == 'delete') {
                                      _delete(
                                        'Xóa đợt thực hành?',
                                        () => p.mutate(
                                          () => p.service.deleteBatch(x.id),
                                          reloadBatches: true,
                                          reloadRegistrations: true,
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Chỉnh sửa'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Xóa'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 22),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.people_outline,
                                      size: 18,
                                      color: _blue,
                                    ),
                                    Text(' ${x.soNguoiDangKy} đăng ký'),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () => _openBatch(x),
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                  ),
                                  label: const Text('Xem danh sách'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _showRegistrationQr(x),
                                  icon: const Icon(Icons.qr_code_2, size: 19),
                                  label: const Text('Link & QR đăng ký'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _blue,
                                  ),
                                ),
                                if (x.fileQuyetDinh != null)
                                  OutlinedButton.icon(
                                    onPressed: () => showThucHanhFile(
                                      context,
                                      p.service,
                                      p.service.decisionUrl(x.id),
                                      x.fileQuyetDinh!,
                                    ),
                                    icon: const Icon(
                                      Icons.description_outlined,
                                      size: 19,
                                    ),
                                    label: const Text('Xem quyết định'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            page: p.batches.page,
            totalPages: p.batches.totalPages,
            onPage: (v) => p.loadBatches(page: v),
          ),
        ),
      ],
    ),
  );

  Widget _registrations() => Consumer<ThucHanhProvider>(
    builder: (context, p, _) => Column(
      children: [
        _toolbar(
          hint: 'Tìm họ tên, CCCD...',
          initialText: p.keywordRegistrations,
          addLabel: 'Thêm vào đợt',
          onSearch: (v) {
            p.keywordRegistrations = v;
            p.loadRegistrations();
          },
          onAdd: _createRegistration,
          filters: [
            TextButton.icon(
              onPressed: () => _personForm(),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Tạo hồ sơ'),
            ),
            _filter<int>(
              value: p.registrationPracticeState,
              label: 'Tình trạng thực hành',
              items: const {
                0: 'Chưa phân công',
                1: 'Sắp thực hành',
                2: 'Đang thực hành',
                3: 'Đã kết thúc',
              },
              onChanged: (v) {
                p.registrationPracticeState = v;
                p.loadRegistrations();
              },
            ),
            _filter<int>(
              value: p.registrationSource,
              label: 'Nguồn đăng ký',
              items: const {
                0: 'Đăng ký công khai',
                1: 'Nhân viên nhập',
                2: 'Import Excel',
              },
              onChanged: (v) {
                p.registrationSource = v;
                p.loadRegistrations();
              },
            ),
          ],
        ),
        Expanded(
          child: _listState(
            loading: p.loadingRegistrations,
            empty: p.registrations.items.isEmpty,
            refresh: p.loadRegistrations,
            children: p.registrations.items
                .map(
                  (x) => Card(
                    margin: const EdgeInsets.fromLTRB(16, 5, 16, 6),
                    elevation: 0,
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFDDE9EF)),
                    ),
                    child: ListTile(
                      onTap: () => _registrationDetail(x.id),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE7F5EF),
                        child: Text(x.hoVaTen.isEmpty ? '?' : x.hoVaTen[0]),
                      ),
                      title: Text(
                        x.hoVaTen,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${x.soCCCD ?? 'Chưa có CCCD'} • ${x.khoaHoc ?? 'Chưa có khóa học'} • ${x.hocKy ?? 'Chưa có học kỳ'} • ${x.soPhanCong} phân công',
                      ),
                      trailing: _practiceStatus(x.tinhTrangThucHanh),
                    ),
                  ),
                )
                .toList(),
            page: p.registrations.page,
            totalPages: p.registrations.totalPages,
            onPage: (v) => p.loadRegistrations(page: v),
          ),
        ),
      ],
    ),
  );

  Widget _people() => Consumer<ThucHanhProvider>(
    builder: (context, p, _) => Column(
      children: [
        _toolbar(
          hint: 'Tìm họ tên, CCCD, điện thoại...',
          initialText: p.keywordPeople,
          addLabel: 'Thêm người',
          onSearch: (v) {
            p.keywordPeople = v;
            p.loadPeople();
          },
          onAdd: () => _personForm(),
        ),
        Expanded(
          child: _listState(
            loading: p.loadingPeople,
            empty: p.people.items.isEmpty,
            refresh: p.loadPeople,
            children: p.people.items
                .map(
                  (x) => Card(
                    margin: const EdgeInsets.fromLTRB(16, 5, 16, 6),
                    elevation: 0,
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFDDE9EF)),
                    ),
                    child: ListTile(
                      onTap: () => _personDetail(x.id),
                      leading: _PersonAvatar(
                        service: p.service,
                        person: x,
                        size: 46,
                      ),
                      title: Text(
                        x.hoVaTen,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${x.email ?? 'Chưa có email'} • ${x.soDienThoai ?? 'Chưa có SĐT'} • ${x.soDotDaDangKy} đợt',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            final d = await p.service.getPerson(x.id);
                            if (mounted) {
                              _personForm(d);
                            }
                          }
                          if (v == 'delete') {
                            _delete(
                              'Xóa người thực hành?',
                              () => p.mutate(
                                () => p.service.deletePerson(x.id),
                                reloadPeople: true,
                                reloadRegistrations: true,
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Chỉnh sửa'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Xóa')),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
            page: p.people.page,
            totalPages: p.people.totalPages,
            onPage: (v) => p.loadPeople(page: v),
          ),
        ),
      ],
    ),
  );

  Widget _listState({
    required bool loading,
    required bool empty,
    required Future<void> Function({int page}) refresh,
    required List<Widget> children,
    required int page,
    required int totalPages,
    required ValueChanged<int> onPage,
  }) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = context.read<ThucHanhProvider>().error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => refresh(page: page),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (empty) {
      return RefreshIndicator(
        onRefresh: () => refresh(page: 1),
        child: ListView(
          children: const [
            SizedBox(height: 140),
            Icon(Icons.inbox_outlined, size: 50, color: Colors.grey),
            Center(child: Text('Chưa có dữ liệu.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => refresh(page: page),
      child: ListView(
        children: [
          ...children,
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: page > 1 ? () => onPage(page - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('$page/$totalPages'),
                IconButton(
                  onPressed: page < totalPages ? () => onPage(page + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _batchForm([DotThucHanhModel? initial]) async {
    final saved = await showDialog<DotThucHanhModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ThucHanhProvider>(),
        child: _BatchDialog(initial: initial),
      ),
    );
    if (saved != null && mounted) {
      _snack('Đã lưu đợt thực hành.');
      if (initial == null) await _showRegistrationQr(saved);
    }
  }

  String _registrationLink(DotThucHanhModel batch) {
    final base = _publicWebUrl;

    if (base.isEmpty) {
      return '';
    }

    return '$base/#/dang-ky-thuc-hanh/${batch.publicToken}';
  }

  Future<void> _showRegistrationQr(DotThucHanhModel batch) async {
    final link = _registrationLink(batch);

    if (link.isEmpty) {
      _snack('Không xác định được địa chỉ web công khai.', error: true);

      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code_2, color: _blue),
            const SizedBox(width: 9),
            Expanded(child: Text('QR đăng ký • ${batch.tenDot}')),
          ],
        ),
        content: SizedBox(
          width: 430,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDCEAF2)),
                ),
                child: QrImageView(
                  data: link,
                  version: QrVersions.auto,
                  size: 245,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF087DBA),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF173B52),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Quét mã để mở biểu mẫu đăng ký công khai',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SelectableText(
                link,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF607D8B)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép link đăng ký.')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Sao chép link'),
          ),
          OutlinedButton.icon(
            onPressed: () => _downloadQr(batch, link),
            icon: const Icon(Icons.download),
            label: const Text('Tải QR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQr(DotThucHanhModel batch, String link) async {
    final painter = QrPainter(
      data: link,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(color: Color(0xFF087DBA)),
      dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF173B52)),
    );
    final data = await painter.toImageData(
      1000,
      format: ui.ImageByteFormat.png,
    );
    if (data == null) return;
    await FilePicker.platform.saveFile(
      dialogTitle: 'Lưu mã QR đăng ký',
      fileName: 'QR_dang_ky_dot_${batch.id}.png',
      type: FileType.custom,
      allowedExtensions: ['png'],
      bytes: data.buffer.asUint8List(),
    );
  }

  Future<void> _downloadImportTemplate(DotThucHanhModel batch) async {
    if (_batchFileAction != null) return;
    setState(() => _batchFileAction = 'template');
    try {
      final bytes = await context
          .read<ThucHanhProvider>()
          .service
          .downloadImportTemplate(batch.id);
      await downloadExcelFile(
        bytes: bytes,
        fileName: 'Mau_import_nguoi_thuc_hanh_${batch.maDot}.xlsx',
      );
      if (mounted) _snack('Đã tải file Excel mẫu.');
    } catch (error) {
      if (mounted) {
        _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _batchFileAction = null);
    }
  }

  Future<void> _importExcel(DotThucHanhModel batch) async {
    if (_batchFileAction != null) return;
    final picked = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (picked == null || !mounted) return;
    setState(() => _batchFileAction = 'import');
    final provider = context.read<ThucHanhProvider>();
    try {
      final result = await provider.service.importPeople(
        batch.id,
        picked.files.single,
      );
      await provider.loadRegistrations(page: 1);
      await provider.loadBatches(page: provider.batches.page);
      if (mounted) {
        final total = result['tongSoDong'] ?? 0;
        final created = result['soDangKyTaoMoi'] ?? 0;
        final updated = result['soDangKyCapNhat'] ?? 0;
        _snack(
          'Đã import $total dòng: thêm $created, cập nhật $updated đăng ký.',
        );
      }
    } catch (error) {
      if (mounted) {
        _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _batchFileAction = null);
    }
  }

  Future<void> _exportBatchReport(DotThucHanhModel batch) async {
    if (_batchFileAction != null) return;
    setState(() => _batchFileAction = 'report');
    try {
      final bytes = await context
          .read<ThucHanhProvider>()
          .service
          .exportBatchReport(batch.id);
      await downloadExcelFile(
        bytes: bytes,
        fileName:
            'Bao_cao_nguoi_thuc_hanh_${batch.maDot}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
      );
      if (mounted) _snack('Đã xuất báo cáo Excel.');
    } catch (error) {
      if (mounted) {
        _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _batchFileAction = null);
    }
  }

  Future<void> _personForm([NguoiThucHanhModel? initial]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ThucHanhProvider>(),
        child: _PersonDialog(initial: initial),
      ),
    );
    if (saved == true && mounted) _snack('Đã lưu người thực hành.');
  }

  Future<void> _personDetail(int id) async {
    final p = context.read<ThucHanhProvider>();
    try {
      final person = await p.service.getPerson(id);
      if (!mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (_) => _PersonDetailDialog(person: person, service: p.service),
      );
      if (action == 'edit' && mounted) await _personForm(person);
    } catch (error) {
      if (mounted) _snack(error.toString(), error: true);
    }
  }

  Future<void> _createRegistration() async {
    final p = context.read<ThucHanhProvider>();
    final result = await showDialog<List<int>>(
      context: context,
      builder: (_) => _RegistrationCreateDialog(
        service: p.service,
        selectedBatch: _selectedBatch,
      ),
    );
    if (result == null) return;
    String? successMessage;
    final ok = await p.mutate(
      () async {
        successMessage = await p.service.createRegistration(
          result[0],
          result[1],
        );
      },
      reloadRegistrations: true,
      reloadPeople: true,
      reloadBatches: true,
    );
    if (mounted) {
      _snack(
        ok
            ? (successMessage ?? 'Đã thêm người vào đợt.')
            : (p.error ?? 'Không thể lưu.'),
        error: !ok,
      );
    }
  }

  Future<void> _registrationDetail(int id) async {
    final p = context.read<ThucHanhProvider>();
    try {
      final detail = await p.service.getRegistration(id);
      final person = await p.service.getPerson(detail.idNguoi);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => ChangeNotifierProvider.value(
          value: p,
          child: _RegistrationDetailDialog(
            data: detail,
            person: person,
            nhanVienService: widget.nhanVienService,
          ),
        ),
      );
      await p.loadRegistrations(page: p.registrations.page);
    } catch (e) {
      if (mounted) _snack(e.toString(), error: true);
    }
  }

  String _dt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  Widget _statusChip(int status) {
    const names = ['Sắp mở', 'Đang mở', 'Đã đóng', 'Đã đóng'];
    const colors = [
      Colors.blueGrey,
      Colors.green,
      Colors.orange,
      Colors.orange,
    ];
    return Chip(
      label: Text(
        names[status.clamp(0, 3)],
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: colors[status.clamp(0, 3)].withValues(alpha: .12),
      side: BorderSide.none,
    );
  }

  Widget _practiceStatus(int status) {
    const names = [
      'Chưa phân công',
      'Sắp thực hành',
      'Đang thực hành',
      'Đã kết thúc',
    ];
    const colors = [Colors.grey, Colors.blue, Colors.green, Colors.blueGrey];
    return Chip(
      label: Text(
        names[status.clamp(0, 3)],
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: colors[status.clamp(0, 3)].withValues(alpha: .12),
      side: BorderSide.none,
    );
  }

  Widget _filter<T>({
    required T? value,
    required String label,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) => SizedBox(
    width: 190,
    child: DropdownButtonFormField<T?>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<T?>(value: null, child: const Text('Tất cả')),
        ...items.entries.map(
          (e) => DropdownMenuItem<T?>(value: e.key, child: Text(e.value)),
        ),
      ],
      onChanged: onChanged,
    ),
  );
}

class _SearchToolbar extends StatefulWidget {
  final String initialText;
  final String hint;
  final String addLabel;
  final ValueChanged<String> onSearch;
  final VoidCallback onAdd;
  final List<Widget> filters;
  const _SearchToolbar({
    super.key,
    this.initialText = '',
    required this.hint,
    required this.addLabel,
    required this.onSearch,
    required this.onAdd,
    required this.filters,
  });

  @override
  State<_SearchToolbar> createState() => _SearchToolbarState();
}

class _SearchToolbarState extends State<_SearchToolbar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => widget.onSearch(value.trim()),
    );
    setState(() {});
  }

  Widget _searchField(double width) => SizedBox(
    width: width,
    child: TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa tìm kiếm',
                onPressed: () {
                  _debounce?.cancel();
                  _controller.clear();
                  widget.onSearch('');
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
      onChanged: _changed,
      onSubmitted: (value) {
        _debounce?.cancel();
        widget.onSearch(value.trim());
      },
    ),
  );

  Widget get _addButton => FilledButton.icon(
    onPressed: widget.onAdd,
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF087DBA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    icon: const Icon(Icons.add),
    label: Text(widget.addLabel),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _searchField(constraints.maxWidth),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...widget.filters.expand(
                      (item) => [item, const SizedBox(width: 8)],
                    ),
                    _addButton,
                  ],
                ),
              ),
            ],
          );
        }
        final searchWidth = (constraints.maxWidth * .42).clamp(280.0, 520.0);
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [_searchField(searchWidth), ...widget.filters, _addButton],
        );
      },
    ),
  );
}

class _BatchDialog extends StatefulWidget {
  final DotThucHanhModel? initial;
  const _BatchDialog({this.initial});
  @override
  State<_BatchDialog> createState() => _BatchDialogState();
}

class _BatchDialogState extends State<_BatchDialog> {
  late final TextEditingController ten, moTa;
  late DateTime start, end;
  DateTime? practiceStart, practiceEnd;
  PlatformFile? decision;
  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    ten = TextEditingController(text: x?.tenDot);
    moTa = TextEditingController(text: x?.moTa);
    start = x?.batDauDangKy ?? DateTime.now();
    end = x?.ketThucDangKy ?? DateTime.now().add(const Duration(days: 30));
    practiceStart = x?.ngayBatDauDuKien;
    practiceEnd = x?.ngayKetThucDuKien;
  }

  Future<DateTime?> pick(DateTime v) => showDatePicker(
    context: context,
    initialDate: v,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThucHanhProvider>();
    return AlertDialog(
      backgroundColor: const Color(0xFFFBFDFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE4F3FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_note, color: Color(0xFF087DBA)),
          ),
          const SizedBox(width: 11),
          Text(
            widget.initial == null
                ? 'Thêm đợt thực hành'
                : 'Cập nhật đợt thực hành',
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: ten,
                decoration: _dialogInput('Tên đợt *', Icons.title),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: moTa,
                maxLines: 3,
                decoration: _dialogInput('Mô tả', Icons.notes_outlined),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _dateBox('Bắt đầu đăng ký', start, () async {
                    final v = await pick(start);
                    if (v != null) {
                      setState(() => start = v);
                    }
                  }),
                  _dateBox('Kết thúc đăng ký', end, () async {
                    final v = await pick(end);
                    if (v != null) {
                      setState(
                        () => end = DateTime(v.year, v.month, v.day, 23, 59),
                      );
                    }
                  }),
                  _dateBox('Bắt đầu dự kiến', practiceStart, () async {
                    final v = await pick(practiceStart ?? DateTime.now());
                    if (v != null) {
                      setState(() => practiceStart = v);
                    }
                  }),
                  _dateBox('Kết thúc dự kiến', practiceEnd, () async {
                    final v = await pick(practiceEnd ?? DateTime.now());
                    if (v != null) setState(() => practiceEnd = v);
                  }),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final r = await FilePicker.platform.pickFiles(
                    withData: true,
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx'],
                  );
                  if (r != null) setState(() => decision = r.files.single);
                },
                icon: const Icon(Icons.attach_file),
                label: Text(
                  decision?.name ??
                      widget.initial?.fileQuyetDinh?.fileName ??
                      'Chọn file quyết định',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: p.saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: p.saving
              ? null
              : () async {
                  if (ten.text.trim().isEmpty || end.isBefore(start)) return;
                  final payload = {
                    'tenDot': ten.text.trim(),
                    'moTa': moTa.text.trim(),
                    'batDauDangKy': start.toIso8601String(),
                    'ketThucDangKy': end.toIso8601String(),
                    'ngayBatDauDuKien': practiceStart?.toIso8601String(),
                    'ngayKetThucDuKien': practiceEnd?.toIso8601String(),
                    'xoaFileQuyetDinh': false,
                  };
                  DotThucHanhModel? saved;
                  final ok = await p.mutate(() async {
                    saved = await p.service.saveBatch(
                      id: widget.initial?.id,
                      payload: payload,
                      decision: decision,
                    );
                  }, reloadBatches: true);
                  if (ok && saved != null && context.mounted) {
                    Navigator.pop(context, saved);
                  }
                },
          child: Text(p.saving ? 'Đang lưu...' : 'Lưu'),
        ),
      ],
    );
  }

  InputDecoration _dialogInput(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF5F9FB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
  );

  Widget _dateBox(String label, DateTime? value, VoidCallback tap) => SizedBox(
    width: 290,
    child: ListTile(
      onTap: tap,
      tileColor: const Color(0xFFF5F9FB),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFD4E3EA)),
        borderRadius: BorderRadius.circular(13),
      ),
      title: Text(label, style: const TextStyle(fontSize: 11)),
      subtitle: Text(
        value == null ? 'Chưa chọn' : DateFormat('dd/MM/yyyy').format(value),
      ),
      trailing: const Icon(Icons.calendar_month, color: Color(0xFF087DBA)),
    ),
  );
}

class _PersonAvatar extends StatefulWidget {
  final ThucHanhService service;
  final NguoiThucHanhModel person;
  final double size;

  const _PersonAvatar({
    required this.service,
    required this.person,
    this.size = 64,
  });

  @override
  State<_PersonAvatar> createState() => _PersonAvatarState();
}

class _PersonAvatarState extends State<_PersonAvatar> {
  Future<Uint8List>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.person.anhDaiDien != null) {
      _future = widget.service.download(
        widget.service.avatarUrl(widget.person.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: ClipOval(
      child: _future == null
          ? _fallback()
          : FutureBuilder<Uint8List>(
              future: _future,
              builder: (context, snapshot) => snapshot.hasData
                  ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                  : _fallback(
                      loading: snapshot.connectionState != ConnectionState.done,
                    ),
            ),
    ),
  );

  Widget _fallback({bool loading = false}) => ColoredBox(
    color: const Color(0xFFDFF1F9),
    child: Center(
      child: loading
          ? SizedBox.square(
              dimension: widget.size * .32,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              widget.person.hoVaTen.isEmpty
                  ? '?'
                  : widget.person.hoVaTen.trimLeft()[0].toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF087DBA),
                fontSize: widget.size * .36,
                fontWeight: FontWeight.w900,
              ),
            ),
    ),
  );
}

class _PersonDetailDialog extends StatelessWidget {
  final NguoiThucHanhModel person;
  final ThucHanhService service;

  const _PersonDetailDialog({required this.person, required this.service});

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900, maxHeight: 820),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF075E91), Color(0xFF0796C5)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: _PersonAvatar(
                    service: service,
                    person: person,
                    size: 74,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.hoVaTen,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        person.email ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailSection(
                    'Thông tin cá nhân',
                    Icons.person_outline,
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _detailInfo('CCCD', person.soCCCD),
                        _detailInfo('Điện thoại', person.soDienThoai),
                        _detailInfo('Email', person.email),
                        _detailInfo(
                          'Ngày sinh',
                          person.ngaySinh == null
                              ? null
                              : DateFormat(
                                  'dd/MM/yyyy',
                                ).format(person.ngaySinh!),
                        ),
                        _detailInfo(
                          'Giới tính',
                          person.gioiTinh == null
                              ? null
                              : (person.gioiTinh! ? 'Nam' : 'Nữ'),
                        ),
                        _detailInfo('Trường/đơn vị', person.truongDonVi),
                        _detailInfo(
                          'Loại nhân viên',
                          person.tenLoaiNhanVien ??
                              (person.loaiNhanVien == null
                                  ? null
                                  : 'Loại ${person.loaiNhanVien}'),
                        ),
                        _detailInfo('Chuyên ngành', person.chuyenNganh),
                        _detailInfo('Trình độ', person.trinhDoChuyenMon),
                        _detailInfo(
                          'Địa chỉ thường trú',
                          person.diaChiThuongTru,
                        ),
                        _detailInfo('Nơi ở hiện tại', person.noiOHienTai),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _detailSection(
                    'Hồ sơ đính kèm (${person.files.length})',
                    Icons.folder_copy_outlined,
                    person.files.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Chưa có file đính kèm.'),
                          )
                        : Column(
                            children: person.files
                                .map(
                                  (file) => _PersonFileTile(
                                    file: file,
                                    onOpen: () => _showPersonFile(
                                      context,
                                      service,
                                      person.id,
                                      file,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFFF5F9FB),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, 'edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Sửa hồ sơ'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _detailSection(String title, IconData icon, Widget child) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFDCE9EF)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: const Color(0xFF087DBA)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
      const Divider(height: 24),
      child,
    ],
  ),
);

Widget _detailInfo(String label, String? value) => Container(
  width: 265,
  padding: const EdgeInsets.all(11),
  decoration: BoxDecoration(
    color: const Color(0xFFF6FAFC),
    borderRadius: BorderRadius.circular(11),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF69828F)),
      ),
      const SizedBox(height: 3),
      Text(
        value == null || value.isEmpty ? 'Chưa cập nhật' : value,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ],
  ),
);

class _PersonFileTile extends StatelessWidget {
  final ThucHanhFileModel file;
  final VoidCallback onOpen;
  final Widget? trailing;

  const _PersonFileTile({
    required this.file,
    required this.onOpen,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF7FAFC),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE0EBF0)),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE4F3FA),
        child: Icon(_fileIcon(file.fileType), color: const Color(0xFF087DBA)),
      ),
      title: Text(file.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_fileTypeName(file.loaiFile)} • ${_fileSize(file.fileSize)}',
      ),
      onTap: onOpen,
      trailing:
          trailing ??
          IconButton(
            tooltip: 'Xem file',
            onPressed: onOpen,
            icon: const Icon(Icons.visibility_outlined),
          ),
    ),
  );
}

Future<void> _showPersonFile(
  BuildContext context,
  ThucHanhService service,
  int personId,
  ThucHanhFileModel file,
) => showThucHanhFile(
  context,
  service,
  service.personFileUrl(personId, file.idFile),
  file,
);

IconData _fileIcon(String? type) => switch (type?.toLowerCase()) {
  'jpg' || 'jpeg' || 'png' => Icons.image_outlined,
  'pdf' => Icons.picture_as_pdf_outlined,
  _ => Icons.description_outlined,
};

String _fileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

String _fileTypeName(int? value) =>
    const {
      1: 'CCCD mặt trước',
      2: 'CCCD mặt sau',
      3: 'Bằng chuyên môn',
      4: 'Sơ yếu lý lịch',
      5: 'Giấy giới thiệu',
      6: 'Chứng từ khác',
      9: 'Khác',
    }[value] ??
    'Hồ sơ';

class _PersonDialog extends StatefulWidget {
  final NguoiThucHanhModel? initial;
  const _PersonDialog({this.initial});
  @override
  State<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<_PersonDialog> {
  final formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> c;
  DateTime? birthday;
  bool? gender;
  PlatformFile? avatar;
  final List<(PlatformFile, int)> newFiles = [];
  final Set<int> deleted = {};
  @override
  void initState() {
    super.initState();
    final x = widget.initial;
    birthday = x?.ngaySinh;
    gender = x?.gioiTinh;
    c = {
      'name': TextEditingController(text: x?.hoVaTen),
      'cccd': TextEditingController(text: x?.soCCCD),
      'phone': TextEditingController(text: x?.soDienThoai),
      'email': TextEditingController(text: x?.email),
      'address': TextEditingController(text: x?.diaChiThuongTru),
      'current': TextEditingController(text: x?.noiOHienTai),
      'school': TextEditingController(text: x?.truongDonVi),
      'major': TextEditingController(text: x?.chuyenNganh),
      'level': TextEditingController(text: x?.trinhDoChuyenMon),
      'note': TextEditingController(text: x?.ghiChu),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThucHanhProvider>();
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 850),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF075E91), Color(0xFF0796C5)],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.initial == null
                          ? 'Thêm người thực hành'
                          : 'Cập nhật người thực hành',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Thông tin cá nhân',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF173B52),
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _field('Họ và tên *', 'name'),
                          _field('Số CCCD', 'cccd'),
                          _field('Số điện thoại', 'phone'),
                          _field('Email *', 'email'),
                          _field('Địa chỉ thường trú', 'address'),
                          _field('Nơi ở hiện tại', 'current'),
                          _field('Trường/đơn vị', 'school'),
                          _field('Chuyên ngành', 'major'),
                          _field('Trình độ chuyên môn', 'level'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              onTap: () async {
                                final v = await showDatePicker(
                                  context: context,
                                  initialDate: birthday ?? DateTime(2000),
                                  firstDate: DateTime(1940),
                                  lastDate: DateTime.now(),
                                );
                                if (v != null) setState(() => birthday = v);
                              },
                              title: const Text('Ngày sinh'),
                              subtitle: Text(
                                birthday == null
                                    ? 'Chưa chọn'
                                    : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(birthday!),
                              ),
                              trailing: const Icon(Icons.calendar_month),
                              tileColor: const Color(0xFFF7FAFC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFFD4E3EA),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<bool?>(
                              initialValue: gender,
                              decoration: InputDecoration(
                                labelText: 'Giới tính',
                                filled: true,
                                fillColor: const Color(0xFFF7FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: true,
                                  child: Text('Nam'),
                                ),
                                DropdownMenuItem(
                                  value: false,
                                  child: Text('Nữ'),
                                ),
                              ],
                              onChanged: (v) => gender = v,
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: c['note'],
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Ghi chú',
                          filled: true,
                          fillColor: const Color(0xFFF7FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const Divider(height: 28),
                      _detailSection(
                        'Ảnh đại diện và hồ sơ',
                        Icons.folder_copy_outlined,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F3F8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFB9DCEB),
                                      width: 2,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: avatar?.bytes != null
                                      ? Image.memory(
                                          avatar!.bytes!,
                                          fit: BoxFit.cover,
                                        )
                                      : widget.initial != null
                                      ? _PersonAvatar(
                                          service: context
                                              .read<ThucHanhProvider>()
                                              .service,
                                          person: widget.initial!,
                                          size: 82,
                                        )
                                      : const Icon(
                                          Icons.person_outline,
                                          size: 38,
                                          color: Color(0xFF087DBA),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final r = await FilePicker.platform
                                              .pickFiles(
                                                withData: true,
                                                type: FileType.image,
                                              );
                                          if (r != null) {
                                            setState(
                                              () => avatar = r.files.single,
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.photo_camera),
                                        label: Text(
                                          avatar?.name ?? 'Đổi ảnh đại diện',
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: _addFile,
                                        icon: const Icon(Icons.attach_file),
                                        label: const Text('Thêm file hồ sơ'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.initial?.files.isNotEmpty == true ||
                          newFiles.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...?widget.initial?.files.map(
                          (file) => Opacity(
                            opacity: deleted.contains(file.idFile) ? .5 : 1,
                            child: _PersonFileTile(
                              file: file,
                              onOpen: () => _showPersonFile(
                                context,
                                context.read<ThucHanhProvider>().service,
                                widget.initial!.id,
                                file,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Xem file',
                                    onPressed: () => _showPersonFile(
                                      context,
                                      context.read<ThucHanhProvider>().service,
                                      widget.initial!.id,
                                      file,
                                    ),
                                    icon: const Icon(Icons.visibility_outlined),
                                  ),
                                  IconButton(
                                    tooltip: deleted.contains(file.idFile)
                                        ? 'Hoàn tác xóa'
                                        : 'Xóa file',
                                    onPressed: () => setState(
                                      () => deleted.contains(file.idFile)
                                          ? deleted.remove(file.idFile)
                                          : deleted.add(file.idFile),
                                    ),
                                    icon: Icon(
                                      deleted.contains(file.idFile)
                                          ? Icons.undo
                                          : Icons.delete_outline,
                                      color: deleted.contains(file.idFile)
                                          ? const Color(0xFF087DBA)
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ...newFiles.map(
                          (item) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: const Color(0xFFE0EBF0),
                              ),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE4F3FA),
                                child: Icon(Icons.upload_file),
                              ),
                              title: Text(item.$1.name),
                              subtitle: Text(_fileTypeName(item.$2)),
                              trailing: IconButton(
                                tooltip: 'Bỏ file',
                                onPressed: () =>
                                    setState(() => newFiles.remove(item)),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: p.saving ? null : _save,
                    child: Text(p.saving ? 'Đang lưu...' : 'Lưu hồ sơ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String key) => SizedBox(
    width: 365,
    child: TextFormField(
      controller: c[key],
      keyboardType: key == 'email'
          ? TextInputType.emailAddress
          : key == 'phone'
          ? TextInputType.phone
          : null,
      validator: (value) {
        final text = value?.trim() ?? '';
        if ((key == 'name' || key == 'email') && text.isEmpty) {
          return key == 'email'
              ? 'Vui lòng nhập email'
              : 'Vui lòng nhập họ tên';
        }
        if (key == 'email' &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
          return 'Email không đúng định dạng';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
  Future<void> _addFile() async {
    final r = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (r == null || !mounted) return;
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Loại hồ sơ'),
        children: [
          for (final i in [1, 2, 3, 4, 5, 6, 9])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, i),
              child: Text(_fileTypeName(i)),
            ),
        ],
      ),
    );
    if (selected != null) {
      setState(() => newFiles.add((r.files.single, selected)));
    }
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final name = c['name']!.text.trim();
    if (name.isEmpty) return;
    final payload = {
      'hoVaTen': name,
      'ngaySinh': birthday?.toIso8601String(),
      'gioiTinh': gender,
      'soCCCD': c['cccd']!.text.trim(),
      'soDienThoai': c['phone']!.text.trim(),
      'email': c['email']!.text.trim(),
      'diaChiThuongTru': c['address']!.text.trim(),
      'noiOHienTai': c['current']!.text.trim(),
      'truongDonVi': c['school']!.text.trim(),
      'chuyenNganh': c['major']!.text.trim(),
      'trinhDoChuyenMon': c['level']!.text.trim(),
      'loaiNhanVien': widget.initial?.loaiNhanVien,
      'ghiChu': c['note']!.text.trim(),
      'xoaAnhDaiDien': false,
      'fileIdsToDelete': deleted.toList(),
      'loaiFiles': newFiles.map((x) => x.$2).toList(),
    };
    final p = context.read<ThucHanhProvider>();
    final ok = await p.mutate(
      () => p.service.savePerson(
        id: widget.initial?.id,
        payload: payload,
        avatar: avatar,
        files: newFiles.map((x) => x.$1).toList(),
      ),
      reloadPeople: true,
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  String _fileTypeName(int i) => const {
    1: 'CCCD mặt trước',
    2: 'CCCD mặt sau',
    3: 'Bằng chuyên môn',
    4: 'Sơ yếu lý lịch',
    5: 'Giấy giới thiệu',
    6: 'Chứng từ khác',
    9: 'Khác',
  }[i]!;
}

class _RegistrationCreateDialog extends StatefulWidget {
  final ThucHanhService service;
  final DotThucHanhModel? selectedBatch;
  const _RegistrationCreateDialog({required this.service, this.selectedBatch});
  @override
  State<_RegistrationCreateDialog> createState() =>
      _RegistrationCreateDialogState();
}

class _RegistrationCreateDialogState extends State<_RegistrationCreateDialog> {
  int? person, batch;
  String? personLabel, batchLabel;
  List<NguoiThucHanhModel> people = [];
  List<DotThucHanhModel> batches = [];
  Timer? personTimer, batchTimer;
  int personRequest = 0, batchRequest = 0;

  @override
  void initState() {
    super.initState();
    batch = widget.selectedBatch?.id;
    batchLabel = widget.selectedBatch?.tenDot;
    _loadPeople('');
    if (widget.selectedBatch == null) _loadBatches('');
  }

  @override
  void dispose() {
    personTimer?.cancel();
    batchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPeople(String keyword) async {
    final request = ++personRequest;
    final result = await widget.service.getPeople(
      keyword: keyword,
      pageSize: 10,
    );
    if (mounted && request == personRequest) {
      setState(() => people = result.items);
    }
  }

  Future<void> _loadBatches(String keyword) async {
    final request = ++batchRequest;
    final result = await widget.service.getBatches(
      keyword: keyword,
      pageSize: 10,
    );
    if (mounted && request == batchRequest) {
      setState(() => batches = result.items);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFFFBFDFE),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: const Row(
      children: [
        CircleAvatar(
          backgroundColor: Color(0xFFE4F3FA),
          child: Icon(Icons.person_add_alt_1, color: Color(0xFF087DBA)),
        ),
        SizedBox(width: 11),
        Text('Thêm người vào đợt'),
      ],
    ),
    content: SizedBox(
      width: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RemoteChoice<NguoiThucHanhModel>(
            label: 'Người thực hành',
            selectedLabel: personLabel,
            items: people,
            itemLabel: (x) => '${x.hoVaTen} • ${x.email ?? 'Chưa có email'}',
            onSearch: (value) {
              personTimer?.cancel();
              personTimer = Timer(
                const Duration(milliseconds: 400),
                () => _loadPeople(value),
              );
            },
            onSelected: (x) => setState(() {
              person = x.id;
              personLabel = '${x.hoVaTen} • ${x.email ?? 'Chưa có email'}';
            }),
          ),
          const SizedBox(height: 14),
          if (widget.selectedBatch != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_note_outlined),
              title: Text(widget.selectedBatch!.tenDot),
              subtitle: const Text('Thêm vào đợt đang xem'),
            )
          else
            _RemoteChoice<DotThucHanhModel>(
              label: 'Đợt thực hành',
              selectedLabel: batchLabel,
              items: batches,
              itemLabel: (x) => x.tenDot,
              onSearch: (value) {
                batchTimer?.cancel();
                batchTimer = Timer(
                  const Duration(milliseconds: 400),
                  () => _loadBatches(value),
                );
              },
              onSelected: (x) => setState(() {
                batch = x.id;
                batchLabel = x.tenDot;
              }),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (person != null && batch != null) {
            Navigator.pop(context, [person!, batch!]);
          }
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}

class _RemoteChoice<T> extends StatelessWidget {
  final String label;
  final String? selectedLabel;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<String> onSearch;
  final ValueChanged<T> onSelected;
  const _RemoteChoice({
    required this.label,
    required this.selectedLabel,
    required this.items,
    required this.itemLabel,
    required this.onSearch,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (selectedLabel != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Chip(
            avatar: const Icon(Icons.check_circle, size: 18),
            label: Text(selectedLabel!),
            backgroundColor: const Color(0xFFE4F4FA),
            side: BorderSide.none,
          ),
        ),
      TextField(
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Nhập từ khóa để tìm trên hệ thống',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF7FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFD4E3EA)),
          ),
          isDense: true,
        ),
        onChanged: onSearch,
      ),
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 155),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(11),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(
                Icons.person_search_outlined,
                color: Color(0xFF087DBA),
              ),
              title: Text(itemLabel(items[index])),
              trailing: const Icon(Icons.add_circle_outline),
              onTap: () => onSelected(items[index]),
            ),
          ),
        ),
      ),
    ],
  );
}

class _RegistrationDetailDialog extends StatefulWidget {
  final DangKyThucHanhModel data;
  final NguoiThucHanhModel person;
  final NhanVienV2Service nhanVienService;
  const _RegistrationDetailDialog({
    required this.data,
    required this.person,
    required this.nhanVienService,
  });
  @override
  State<_RegistrationDetailDialog> createState() =>
      _RegistrationDetailDialogState();
}

class _RegistrationDetailDialogState extends State<_RegistrationDetailDialog> {
  late DangKyThucHanhModel data;
  @override
  void initState() {
    super.initState();
    data = widget.data;
  }

  Future<void> reload() async {
    data = await context.read<ThucHanhProvider>().service.getRegistration(
      data.id,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThucHanhProvider>();
    return Dialog(
      insetPadding: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 850),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF075E91), Color(0xFF0796C5)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: _PersonAvatar(
                      service: p.service,
                      person: widget.person,
                      size: 68,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.hoVaTen,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          data.tenDot,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  _practiceChip(data.tinhTrangThucHanh),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _detailSection(
                      'Thông tin đăng ký',
                      Icons.badge_outlined,
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _detailInfo('CCCD', widget.person.soCCCD),
                          _detailInfo('Điện thoại', widget.person.soDienThoai),
                          _detailInfo('Email', widget.person.email),
                          _detailInfo(
                            'Ngày đăng ký',
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(data.ngayDangKy),
                          ),
                          _detailInfo('Mã tra cứu', data.maTraCuu),
                          _detailInfo('Khóa học', data.khoaHoc),
                          _detailInfo('Học kỳ', data.hocKy),
                          _detailInfo(
                            'Thời gian học',
                            data.thoiGianHocTuNgay == null ||
                                    data.thoiGianHocDenNgay == null
                                ? null
                                : '${DateFormat('dd/MM/yyyy').format(data.thoiGianHocTuNgay!)} - ${DateFormat('dd/MM/yyyy').format(data.thoiGianHocDenNgay!)}',
                          ),
                          _detailInfo(
                            'Thời gian thực hành',
                            data.ngayBatDauThucHanh == null
                                ? null
                                : '${DateFormat('dd/MM/yyyy').format(data.ngayBatDauThucHanh!)} - ${DateFormat('dd/MM/yyyy').format(data.ngayKetThucThucHanh!)}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _detailSection(
                      'Hồ sơ đính kèm (${widget.person.files.length})',
                      Icons.folder_copy_outlined,
                      widget.person.files.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text('Chưa có file đính kèm.'),
                            )
                          : Column(
                              children: widget.person.files
                                  .map(
                                    (file) => _PersonFileTile(
                                      file: file,
                                      onOpen: () => _showPersonFile(
                                        context,
                                        p.service,
                                        widget.person.id,
                                        file,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _detailSection(
                      'Phân công thực hành',
                      Icons.account_tree_outlined,
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: () => _assignment(),
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm phân công'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (data.phanCongs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(14),
                              child: Text('Chưa có phân công.'),
                            )
                          else
                            ...data.phanCongs.map(
                              (x) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFDCE9EF),
                                  ),
                                ),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFE3F3FA),
                                    child: Icon(Icons.school_outlined),
                                  ),
                                  title: Text(
                                    x.hoVaTenNguoiHuongDan ??
                                        x.maSoNguoiHuongDan,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${x.tenKhoaPhong ?? ''}\n${DateFormat('dd/MM/yyyy').format(x.ngayBatDau)} - ${DateFormat('dd/MM/yyyy').format(x.ngayKetThuc)}',
                                  ),
                                  isThreeLine: true,
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') await _assignment(x);
                                      if (value == 'delete') {
                                        await p.mutate(
                                          () => p.service.deleteAssignment(
                                            data.id,
                                            x.id,
                                          ),
                                        );
                                        await reload();
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Sửa'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Xóa'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(13),
              color: const Color(0xFFF4F8FA),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignment([PhanCongThucHanhModel? initial]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _AssignmentDialog(initial: initial, service: widget.nhanVienService),
    );
    if (result == null) return;
    if (!mounted) return;
    final p = context.read<ThucHanhProvider>();
    if (await p.mutate(
      () => p.service.saveAssignment(data.id, result, id: initial?.id),
    )) {
      await reload();
    }
  }

  Widget _practiceChip(int status) {
    const names = [
      'Chưa phân công',
      'Sắp thực hành',
      'Đang thực hành',
      'Đã kết thúc',
    ];
    const colors = [Colors.grey, Colors.blue, Colors.green, Colors.blueGrey];
    final index = status.clamp(0, 3);
    return Chip(
      avatar: Icon(Icons.schedule, size: 17, color: colors[index]),
      label: Text(names[index]),
      backgroundColor: colors[index].withValues(alpha: .12),
      side: BorderSide.none,
    );
  }
}

class _AssignmentDialog extends StatefulWidget {
  final PhanCongThucHanhModel? initial;
  final NhanVienV2Service service;
  const _AssignmentDialog({this.initial, required this.service});
  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  List<NhanVienV2Model> employees = [];
  List<KhoaPhongV2Model> allDeps = [], deps = [];
  String? employee;
  String? employeeLabel;
  int? dep;
  String? depLabel;
  late DateTime start, end;
  Timer? employeeTimer;
  int employeeRequest = 0;
  String? validationError;
  @override
  void initState() {
    super.initState();
    employee = widget.initial?.maSoNguoiHuongDan;
    employeeLabel = widget.initial?.hoVaTenNguoiHuongDan == null
        ? null
        : '${widget.initial!.hoVaTenNguoiHuongDan} • ${widget.initial!.maSoNguoiHuongDan}';
    dep = widget.initial?.idKhoaPhong;
    depLabel = widget.initial?.tenKhoaPhong;
    start = widget.initial?.ngayBatDau ?? DateTime.now();
    end =
        widget.initial?.ngayKetThuc ??
        DateTime.now().add(const Duration(days: 30));
    _load();
  }

  @override
  void dispose() {
    employeeTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.service.getKhoaPhong();
    if (mounted) {
      setState(() {
        allDeps = result;
        deps = result.take(15).toList();
      });
    }
    await _loadEmployees(employee ?? '');
  }

  void _searchDepartments(String value) {
    final keyword = _plain(value);
    setState(() {
      deps = allDeps
          .where((x) => _plain(x.tenKhoaPhong ?? '').contains(keyword))
          .take(15)
          .toList();
    });
  }

  String _plain(String value) {
    var result = value.toLowerCase();
    result = result.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    result = result.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    result = result.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    result = result.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    result = result.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    result = result.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    result = result.replaceAll('đ', 'd');
    return result;
  }

  Future<void> _loadEmployees(String keyword) async {
    final request = ++employeeRequest;
    final result = await widget.service.getDanhSach(
      keyword: keyword,
      pageSize: 15,
    );
    if (mounted && request == employeeRequest) {
      setState(() => employees = result.items);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 820),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(19),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF075E91), Color(0xFF0796C5)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: Color(0x26FFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    widget.initial == null
                        ? 'Thêm phân công thực hành'
                        : 'Cập nhật phân công thực hành',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Người phụ trách',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  _RemoteChoice<NhanVienV2Model>(
                    label: 'Người hướng dẫn',
                    selectedLabel: employeeLabel,
                    items: employees,
                    itemLabel: (x) =>
                        '${x.hoVaTen} (${x.maSo}) • ${x.tenKhoaPhong ?? 'Chưa có khoa/phòng'}',
                    onSearch: (value) {
                      employeeTimer?.cancel();
                      employeeTimer = Timer(
                        const Duration(milliseconds: 400),
                        () => _loadEmployees(value),
                      );
                    },
                    onSelected: (x) => setState(() {
                      employee = x.maSo;
                      employeeLabel =
                          '${x.hoVaTen} (${x.maSo}) • ${x.tenKhoaPhong ?? 'Chưa có khoa/phòng'}';
                    }),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Địa điểm thực hành',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  _RemoteChoice<KhoaPhongV2Model>(
                    label: 'Khoa/phòng thực hành',
                    selectedLabel: depLabel,
                    items: deps,
                    itemLabel: (x) => x.tenKhoaPhong ?? '',
                    onSearch: _searchDepartments,
                    onSelected: (x) => setState(() {
                      dep = x.idKhoaPhong;
                      depLabel = x.tenKhoaPhong;
                    }),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Thời gian thực hành',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _assignmentDate('Ngày bắt đầu', start, () => _date(true)),
                      _assignmentDate('Ngày kết thúc', end, () => _date(false)),
                    ],
                  ),
                  if (validationError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      validationError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFFF4F8FA),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    if (employee == null || dep == null) {
                      setState(
                        () => validationError =
                            'Vui lòng chọn người hướng dẫn và khoa/phòng.',
                      );
                      return;
                    }
                    if (end.isBefore(start)) {
                      setState(
                        () => validationError =
                            'Ngày kết thúc không được trước ngày bắt đầu.',
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'maSoNguoiHuongDan': employee,
                      'idKhoaPhong': dep,
                      'ngayBatDau': start.toIso8601String(),
                      'ngayKetThuc': end.toIso8601String(),
                    });
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Lưu phân công'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _assignmentDate(String label, DateTime value, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 290,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFD4E3EA)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: Color(0xFF087DBA)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 11)),
                    Text(
                      DateFormat('dd/MM/yyyy').format(value),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  Future<void> _date(bool first) async {
    final v = await showDatePicker(
      context: context,
      initialDate: first ? start : end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (v != null) {
      setState(() {
        if (first) {
          start = v;
        } else {
          end = v;
        }
      });
    }
  }
}
