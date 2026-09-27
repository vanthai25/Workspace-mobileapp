import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cap_cchn_models.dart';
import '../../providers/cap_cchn_provider.dart';
import '../../services/nhan_vien_v2_service.dart';
import 'cap_cchn_detail_dialog.dart';
import 'cap_cchn_form_dialog.dart';

class CapCchnScreen extends StatefulWidget {
  final NhanVienV2Service nhanVienService;

  const CapCchnScreen({super.key, required this.nhanVienService});

  @override
  State<CapCchnScreen> createState() => _CapCchnScreenState();
}

class _CapCchnScreenState extends State<CapCchnScreen> {
  static const Color _primary = Color(0xFF087DBA);
  static const Color _navy = Color(0xFF173B52);
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  int? _loadingDetailId;
  String? _downloadingKey;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm([
    CapCchnModel? item,
    bool detailLoaded = false,
  ]) async {
    final CapCchnProvider provider = context.read<CapCchnProvider>();
    CapCchnModel? detail = item;
    if (item != null && !detailLoaded) {
      setState(() => _loadingDetailId = item.idCapCCCHN);
      detail = await provider.getDetail(item.idCapCCCHN);
      if (mounted) setState(() => _loadingDetailId = null);
      if (detail == null || !mounted) {
        _showMessage(
          provider.errorMessage ?? 'Không thể tải chi tiết hồ sơ.',
          error: true,
        );
        return;
      }
    }
    if (!mounted) return;
    final bool? saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider<CapCchnProvider>.value(
        value: provider,
        child: CapCchnFormDialog(
          initialData: detail,
          nhanVienService: widget.nhanVienService,
        ),
      ),
    );
    if (saved == true && mounted) {
      _showMessage(
        item == null ? 'Đã thêm hồ sơ thực hành.' : 'Đã cập nhật hồ sơ.',
      );
    }
  }

  Future<void> _openDetail(CapCchnModel item) async {
    final CapCchnProvider provider = context.read<CapCchnProvider>();
    setState(() => _loadingDetailId = item.idCapCCCHN);
    final CapCchnModel? detail = await provider.getDetail(item.idCapCCCHN);
    if (mounted) setState(() => _loadingDetailId = null);
    if (detail == null || !mounted) {
      _showMessage(
        provider.errorMessage ?? 'Không thể tải chi tiết hồ sơ.',
        error: true,
      );
      return;
    }

    final String? action = await showDialog<String>(
      context: context,
      builder: (_) => CapCchnDetailDialog(
        item: detail,
        onDownload: (String type, CapCchnFileModel file) =>
            _download(detail, type, file),
      ),
    );
    if (action == 'edit' && mounted) {
      await _openForm(detail, true);
    }
  }

  Future<void> _delete(CapCchnModel item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Xóa hồ sơ?'),
        content: Text(
          'Bạn có chắc muốn xóa hồ sơ của ${item.hoVaTen ?? item.maSo}?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC43C35),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final CapCchnProvider provider = context.read<CapCchnProvider>();
    final bool ok = await provider.remove(item.idCapCCCHN);
    if (!mounted) return;
    _showMessage(
      ok ? 'Đã xóa hồ sơ.' : (provider.errorMessage ?? 'Không thể xóa hồ sơ.'),
      error: !ok,
    );
  }

  Future<void> _download(
    CapCchnModel item,
    String type,
    CapCchnFileModel file,
  ) async {
    final String key = '${item.idCapCCCHN}:$type';
    if (_downloadingKey != null) return;
    setState(() => _downloadingKey = key);
    try {
      final bytes = await context.read<CapCchnProvider>().download(
        item.idCapCCCHN,
        type,
      );
      await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu file đính kèm',
        fileName: file.fileName,
        bytes: bytes,
      );
    } catch (error) {
      if (mounted) {
        _showMessage(
          error.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingKey = null);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFFC43C35)
            : const Color(0xFF18775A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Consumer<CapCchnProvider>(
          builder:
              (BuildContext context, CapCchnProvider provider, Widget? child) {
                return Column(
                  children: <Widget>[
                    _buildHeader(provider),
                    _buildFilters(provider),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => provider.load(),
                        child: _buildBody(provider),
                      ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }

  Widget _buildHeader(CapCchnProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E9EE))),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 720;
          final Widget title = const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Quản lý thực hành',
                style: TextStyle(
                  color: _navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Quản lý hồ sơ, người hướng dẫn và file đính kèm',
                style: TextStyle(color: Color(0xFF718496), fontSize: 12),
              ),
            ],
          );
          final Widget actions = Row(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: <Widget>[
              if (!compact)
                SizedBox(width: 300, child: _searchField(provider))
              else
                Expanded(child: _searchField(provider)),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: provider.isSaving ? null : () => _openForm(),
                icon: const Icon(Icons.add_rounded),
                label: Text(compact ? 'Thêm' : 'Thêm hồ sơ'),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[title, const SizedBox(height: 14), actions],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: title),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(CapCchnProvider provider) {
    const List<(String, String, IconData)> filters =
        <(String, String, IconData)>[
          ('', 'Tất cả', Icons.people_alt_outlined),
          ('dang-thuc-hanh', 'Đang thực hành', Icons.play_circle_outline),
          (
            'sap-ket-thuc',
            'Sắp kết thúc',
            Icons.notification_important_outlined,
          ),
          ('sap-bat-dau', 'Sắp bắt đầu', Icons.event_available_outlined),
          ('da-hoan-thanh', 'Đã hoàn thành', Icons.task_alt_outlined),
          ('chua-phan-cong', 'Chưa phân công', Icons.person_add_alt_outlined),
        ];
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map(((String, String, IconData) filter) {
            final bool selected = provider.status == filter.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: selected,
                onSelected: provider.isLoading
                    ? null
                    : (_) => provider.changeStatus(filter.$1),
                avatar: Icon(
                  filter.$3,
                  size: 17,
                  color: selected ? Colors.white : const Color(0xFF587080),
                ),
                label: Text(filter.$2),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF405866),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: _primary,
                backgroundColor: const Color(0xFFF2F6F8),
                side: BorderSide(
                  color: selected ? _primary : const Color(0xFFDCE6EC),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _searchField(CapCchnProvider provider) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Tìm họ tên, CCCD, SĐT, trường/đơn vị...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  provider.search('');
                },
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: const Color(0xFFF5F8FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
      onChanged: (String value) {
        setState(() {});
        _searchTimer?.cancel();
        _searchTimer = Timer(
          const Duration(milliseconds: 450),
          () => provider.search(value),
        );
      },
      onSubmitted: provider.search,
    );
  }

  Widget _buildBody(CapCchnProvider provider) {
    if (provider.isLoading && provider.result.items.isEmpty) {
      return ListView(
        children: <Widget>[
          const SizedBox(height: 220),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (provider.errorMessage != null && provider.result.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 100),
          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFF8A9BA8),
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(provider.errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => provider.load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }
    if (provider.result.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 100),
          const Icon(
            Icons.assignment_outlined,
            color: Color(0xFF9AADB9),
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            provider.keyword.isEmpty && provider.status.isEmpty
                ? 'Chưa có hồ sơ đào tạo thực hành.'
                : 'Không tìm thấy hồ sơ phù hợp.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF647889)),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              '${provider.result.totalCount} hồ sơ',
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            if (provider.isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ...provider.result.items.map(
          (CapCchnModel item) => _recordCardV2(item, provider),
        ),
        if (provider.result.totalPages > 1) _pagination(provider),
      ],
    );
  }

  Widget _recordCardV2(CapCchnModel item, CapCchnProvider provider) {
    final _CapCchnStatusVisual status = _statusOf(item);
    final String position = <String?>[
      item.tenLoaiNhanVien,
      item.truongDonVi,
      item.soCCCD == null ? null : 'CCCD: ${item.soCCCD}',
    ].where((String? value) => value?.trim().isNotEmpty == true).join(' • ');
    final int fileCount = <CapCchnFileModel?>[
      item.fileHopDong,
      item.fileQuyetDinh,
      item.fileXacNhanTH,
      item.fileThongBaoTiepNhan,
      item.anhDaiDien,
      item.fileHocPhi,
    ].whereType<CapCchnFileModel>().length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: status.color.withValues(alpha: .28)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _loadingDetailId == null ? () => _openDetail(item) : null,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 5, color: status.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          CircleAvatar(
                            radius: 23,
                            backgroundColor: status.color.withValues(
                              alpha: .11,
                            ),
                            child: Text(
                              (item.hoVaTen?.trim().isNotEmpty ?? false)
                                  ? item.hoVaTen!.trim()[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: status.color,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      item.hoVaTen?.trim().isNotEmpty == true
                                          ? item.hoVaTen!.trim()
                                          : 'Chưa có tên',
                                      style: const TextStyle(
                                        color: _navy,
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F4F6),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Text(
                                        item.maSo.trim().isEmpty
                                            ? 'Chưa cấp Mã số'
                                            : 'Mã số ${item.maSo} • TT ${item.idTinhTrang ?? '-'}',
                                        style: const TextStyle(
                                          color: Color(0xFF5D7180),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (position.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 4),
                                  Text(
                                    position,
                                    maxLines: 2,
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
                          if (_loadingDetailId == item.idCapCCCHN)
                            const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else
                            PopupMenuButton<String>(
                              tooltip: 'Thao tác',
                              onSelected: (String action) {
                                if (action == 'detail') _openDetail(item);
                                if (action == 'edit') _openForm(item);
                                if (action == 'delete') _delete(item);
                              },
                              itemBuilder: (_) =>
                                  const <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'detail',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        title: Text('Xem chi tiết'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit_outlined),
                                        title: Text('Chỉnh sửa'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFC43C35),
                                        ),
                                        title: Text(
                                          'Xóa',
                                          style: TextStyle(
                                            color: Color(0xFFC43C35),
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          _statusChip(status),
                          if (item.soDotDangThucHanh > 0)
                            _stat(
                              Icons.play_circle_outline_rounded,
                              '${item.soDotDangThucHanh} đang thực hành',
                              const Color(0xFF16845E),
                            ),
                          if (item.soDotDaHoanThanh > 0)
                            _stat(
                              Icons.task_alt_rounded,
                              '${item.soDotDaHoanThanh} đợt hoàn thành',
                              const Color(0xFF7357B5),
                            ),
                          if (item.soDotSapBatDau > 0)
                            _stat(
                              Icons.event_available_outlined,
                              '${item.soDotSapBatDau} sắp bắt đầu',
                              _primary,
                            ),
                          if (item.soNguoiHuongDan == 0)
                            _stat(
                              Icons.person_add_alt_outlined,
                              'Chưa có đợt hướng dẫn',
                              const Color(0xFF7B8B95),
                            ),
                        ],
                      ),
                      if (item.ngayKetThucGanNhat != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: status.color.withValues(alpha: .055),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.event_outlined,
                                size: 17,
                                color: status.color,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  _nearestEndText(item),
                                  style: TextStyle(
                                    color: status.color,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(height: 22),
                      Row(
                        children: <Widget>[
                          _miniInfo(
                            Icons.fact_check_outlined,
                            '${item.completedDocumentCount}/7 hồ sơ',
                          ),
                          const SizedBox(width: 14),
                          _miniInfo(
                            Icons.attach_file_rounded,
                            '$fileCount file',
                          ),
                          const Spacer(),
                          const Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _primary,
                            size: 19,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(_CapCchnStatusVisual status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: .2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(status.icon, size: 15, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: const Color(0xFF78909D)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF667C89), fontSize: 10.5),
        ),
      ],
    );
  }

  String _nearestEndText(CapCchnModel item) {
    final String date = DateFormat(
      'dd/MM/yyyy',
    ).format(item.ngayKetThucGanNhat!);
    final int? days = item.daysUntilNearestEnd;
    if (days == 0) return 'Đợt gần nhất kết thúc hôm nay ($date)';
    if (days == 1) return 'Đợt gần nhất kết thúc ngày mai ($date)';
    if (days != null && days > 1) {
      return 'Đợt gần nhất còn $days ngày, kết thúc $date';
    }
    return 'Kết thúc gần nhất: $date';
  }

  _CapCchnStatusVisual _statusOf(CapCchnModel item) {
    if (item.soDotSapKetThuc > 0) {
      final int? days = item.daysUntilNearestEnd;
      final String label = days == 0
          ? 'Kết thúc hôm nay'
          : days == 1
          ? 'Kết thúc ngày mai'
          : days != null && days > 1
          ? 'Còn $days ngày'
          : 'Sắp kết thúc';
      return _CapCchnStatusVisual(
        label,
        Icons.notification_important_outlined,
        days != null && days <= 1
            ? const Color(0xFFD33C32)
            : const Color(0xFFE07920),
      );
    }
    if (item.soDotDangThucHanh > 0) {
      return const _CapCchnStatusVisual(
        'Đang thực hành',
        Icons.play_circle_outline_rounded,
        Color(0xFF16845E),
      );
    }
    if (item.soDotSapBatDau > 0) {
      return const _CapCchnStatusVisual(
        'Sắp bắt đầu',
        Icons.event_available_outlined,
        Color(0xFF087DBA),
      );
    }
    if (item.soDotDaHoanThanh > 0) {
      return const _CapCchnStatusVisual(
        'Đã hoàn thành',
        Icons.task_alt_rounded,
        Color(0xFF7357B5),
      );
    }
    return const _CapCchnStatusVisual(
      'Chưa phân công',
      Icons.hourglass_empty_rounded,
      Color(0xFF7B8B95),
    );
  }

  // ignore: unused_element
  Widget _recordCard(CapCchnModel item, CapCchnProvider provider) {
    final String position =
        <String?>[
              item.tenKhoaPhong,
              item.tenToDoi,
              item.tenChucDanh,
              item.tenChucVu,
            ]
            .where((String? value) => value != null && value.trim().isNotEmpty)
            .join(' • ');
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFDCE6EC)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFDFF1F9),
                  child: Text(
                    (item.hoVaTen?.trim().isNotEmpty ?? false)
                        ? item.hoVaTen!.trim()[0]
                        : '?',
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${item.hoVaTen ?? 'Chưa có tên'} (${item.maSo})',
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (position.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          position,
                          style: const TextStyle(
                            color: Color(0xFF718496),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_loadingDetailId == item.idCapCCCHN)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    onSelected: (String action) {
                      if (action == 'edit') _openForm(item);
                      if (action == 'delete') _delete(item);
                    },
                    itemBuilder: (_) => const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Chỉnh sửa'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: Color(0xFFC43C35),
                          ),
                          title: Text(
                            'Xóa',
                            style: TextStyle(color: Color(0xFFC43C35)),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: <Widget>[
                _stat(
                  Icons.fact_check_outlined,
                  '${item.completedDocumentCount}/7 hồ sơ',
                  item.completedDocumentCount == 7
                      ? const Color(0xFF16845E)
                      : const Color(0xFFE58B1A),
                ),
                const SizedBox(width: 8),
                _stat(
                  Icons.supervisor_account_outlined,
                  '${item.soNguoiHuongDan} hướng dẫn',
                  _primary,
                ),
                if (item.ngayUD != null) ...<Widget>[
                  const Spacer(),
                  Text(
                    'Cập nhật ${DateFormat('dd/MM/yyyy').format(item.ngayUD!)}',
                    style: const TextStyle(
                      color: Color(0xFF82939F),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ],
            ),
            if (item.fileHopDong != null ||
                item.fileQuyetDinh != null ||
                item.fileXacNhanTH != null) ...<Widget>[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: <Widget>[
                    if (item.fileHopDong != null)
                      _fileChip(
                        item,
                        'Hợp đồng',
                        'hop-dong',
                        item.fileHopDong!,
                      ),
                    if (item.fileQuyetDinh != null)
                      _fileChip(
                        item,
                        'Quyết định',
                        'quyet-dinh',
                        item.fileQuyetDinh!,
                      ),
                    if (item.fileXacNhanTH != null)
                      _fileChip(
                        item,
                        'Xác nhận TH',
                        'xac-nhan-th',
                        item.fileXacNhanTH!,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
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

  Widget _fileChip(
    CapCchnModel item,
    String label,
    String type,
    CapCchnFileModel file,
  ) {
    final bool loading = _downloadingKey == '${item.idCapCCCHN}:$type';
    return ActionChip(
      onPressed: loading ? null : () => _download(item, type, file),
      avatar: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_outlined, size: 17, color: _primary),
      label: Text(label),
      tooltip: file.fileName,
    );
  }

  Widget _pagination(CapCchnProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            onPressed: provider.result.currentPage > 1 && !provider.isLoading
                ? () => provider.load(page: provider.result.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            'Trang ${provider.result.currentPage}/${provider.result.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed:
                provider.result.currentPage < provider.result.totalPages &&
                    !provider.isLoading
                ? () => provider.load(page: provider.result.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _CapCchnStatusVisual {
  final String label;
  final IconData icon;
  final Color color;

  const _CapCchnStatusVisual(this.label, this.icon, this.color);
}
