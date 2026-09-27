import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/su_kien/screens/dialogs/su_kien_banner_manager_dialog.dart';
import '../../models/su_kien_v2_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/su_kien_v2_provider.dart';
import '../../features/su_kien/screens/dialogs/su_kien_form_dialog.dart';


class SuKienAdminWebScreen
    extends StatefulWidget {
  const SuKienAdminWebScreen({
    super.key,
  });

  @override
  State<SuKienAdminWebScreen>
      createState() =>
          _SuKienAdminWebScreenState();
}


class _SuKienAdminWebScreenState
    extends State<SuKienAdminWebScreen> {
  static const Color _primary =
      Color(0xFF1274BC);

  static const Color _background =
      Color(0xFFF4F7FB);

  static const Color _border =
      Color(0xFFE1E9F0);

  static const Color _muted =
      Color(0xFF66788A);


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        final roles =
            context
                .read<AuthProvider>()
                .currentRoleIds;

        if (roles.contains(52)) {
          context
              .read<SuKienV2Provider>()
              .load();
        }
      },
    );
  }


  bool get _hasPermission {
    return context
        .read<AuthProvider>()
        .currentRoleIds
        .contains(52);
  }

  Future<void> _openBannerManager(
  SuKienV2Model item,
) async {
  final provider =
      context.read<
          SuKienV2Provider>();

  await showDialog<void>(
    context:
        context,

    barrierDismissible:
        false,

    builder:
        (_) =>
            ChangeNotifierProvider.value(
      value:
          provider,

      child:
          SuKienBannerManagerDialog(
        event:
            item,
      ),
    ),
  );
}
  Future<void> _openForm({
    SuKienV2Model? item,
  }) async {
    final provider =
        context.read<
            SuKienV2Provider>();

    final result =
        await showDialog<bool>(
      context:
          context,

      barrierDismissible:
          false,

      builder:
          (_) =>
              ChangeNotifierProvider.value(
        value:
            provider,

        child:
            SuKienFormDialog(
          item:
              item,
        ),
      ),
    );

    if (result == true &&
        mounted) {
      _snack(
        item == null
            ? 'Đã tạo sự kiện.'
            : 'Đã cập nhật sự kiện.',
      );
    }
  }


  Future<void> _delete(
    SuKienV2Model item,
  ) async {
    final confirm =
        await showDialog<bool>(
      context:
          context,

      builder:
          (dialogContext) {
        return AlertDialog(
          title:
              const Text(
            'Xóa sự kiện?',
          ),

          content:
              Text(
            'Bạn có chắc chắn muốn xóa '
            '"${item.tenSuKien}"?\n\n'
            'Các banner thuộc sự kiện cũng sẽ bị xóa khỏi liên kết sự kiện.',
          ),

          actions: [
            TextButton(
              onPressed:
                  () =>
                      Navigator.pop(
                dialogContext,
                false,
              ),

              child:
                  const Text(
                'Hủy',
              ),
            ),

            FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFC43C35,
                ),
              ),

              onPressed:
                  () =>
                      Navigator.pop(
                dialogContext,
                true,
              ),

              icon:
                  const Icon(
                Icons.delete_outline,
              ),

              label:
                  const Text(
                'Xóa',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true ||
        !mounted) {
      return;
    }

    final provider =
        context.read<
            SuKienV2Provider>();

    final ok =
        await provider.delete(
      item.idSuKien,
    );

    if (!mounted) {
      return;
    }

    _snack(
      ok
          ? 'Đã xóa sự kiện.'
          : provider.errorMessage ??
              'Không thể xóa sự kiện.',

      error:
          !ok,
    );
  }


  void _snack(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),

          backgroundColor:
              error
                  ? const Color(
                      0xFFC43C35,
                    )
                  : const Color(
                      0xFF14845E,
                    ),
        ),
      );
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    final roles =
        context
            .watch<AuthProvider>()
            .currentRoleIds;

    if (!roles.contains(52)) {
      return const Scaffold(
        body:
            Center(
          child:
              Text(
            'Bạn không có quyền quản lý sự kiện.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          _background,

      appBar:
          AppBar(
        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.white,

        elevation:
            0,

        title:
            const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              'Quản lý sự kiện',
              style:
                  TextStyle(
                fontSize:
                    19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            Text(
              'Banner, thời gian hiển thị và hiệu ứng trên trang chủ',
              style:
                  TextStyle(
                color:
                    _muted,
                fontSize:
                    11,
              ),
            ),
          ],
        ),

        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right:
                  18,
            ),

            child:
                FilledButton.icon(
              onPressed:
                  () =>
                      _openForm(),

              icon:
                  const Icon(
                Icons.add_rounded,
              ),

              label:
                  const Text(
                'Thêm sự kiện',
              ),
            ),
          ),
        ],
      ),

      body:
          Consumer<
              SuKienV2Provider>(
        builder:
            (
          context,
          provider,
          child,
        ) {
          if (provider.isLoading &&
              provider.items.isEmpty) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (provider.errorMessage !=
                  null &&
              provider.items.isEmpty) {
            return Center(
              child:
                  Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.error_outline,
                    size:
                        44,
                    color:
                        Color(
                      0xFFC43C35,
                    ),
                  ),

                  const SizedBox(
                    height:
                        10,
                  ),

                  Text(
                    provider.errorMessage!,
                  ),

                  const SizedBox(
                    height:
                        12,
                  ),

                  OutlinedButton.icon(
                    onPressed:
                        provider.load,

                    icon:
                        const Icon(
                      Icons.refresh,
                    ),

                    label:
                        const Text(
                      'Thử lại',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh:
                provider.load,

            child:
                ListView(
              padding:
                  const EdgeInsets.all(
                22,
              ),

              children: [
                _summary(
                  provider,
                ),

                const SizedBox(
                  height:
                      16,
                ),

                if (provider.items.isEmpty)
                  _empty()
                else
                  ...provider.items.map(
                    (item) =>
                        _eventCard(
                      provider,
                      item,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _summary(
    SuKienV2Provider provider,
  ) {
    final now =
        DateTime.now();

    final active =
        provider.items.where(
      (x) =>
          x.isActive &&
          !now.isBefore(x.tuNgay) &&
          !now.isAfter(x.denNgay),
    );

    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              _border,
        ),
      ),

      child:
          Row(
        children: [
          _metric(
            'Tổng sự kiện',
            '${provider.items.length}',
            Icons.event_outlined,
          ),

          const SizedBox(
            width:
                14,
          ),

          _metric(
            'Đang hiển thị',
            '${active.length}',
            Icons.visibility_outlined,
          ),
        ],
      ),
    );
  }


  Widget _metric(
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child:
          Container(
        padding:
            const EdgeInsets.all(
          15,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFFF7FAFC,
          ),

          borderRadius:
              BorderRadius.circular(
            12,
          ),

          border:
              Border.all(
            color:
                _border,
          ),
        ),

        child:
            Row(
          children: [
            Icon(
              icon,
              color:
                  _primary,
            ),

            const SizedBox(
              width:
                  12,
            ),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  value,

                  style:
                      const TextStyle(
                    fontSize:
                        22,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                Text(
                  label,

                  style:
                      const TextStyle(
                    color:
                        _muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _eventCard(
    SuKienV2Provider provider,
    SuKienV2Model item,
  ) {
    final status =
        _status(item);

    return Container(
      margin:
          const EdgeInsets.only(
        bottom:
            12,
      ),

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          15,
        ),

        border:
            Border.all(
          color:
              _border,
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width:
                46,
            height:
                46,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEAF5FC,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                const Icon(
              Icons.celebration_outlined,
              color:
                  _primary,
            ),
          ),

          const SizedBox(
            width:
                14,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          Text(
                        item.tenSuKien,

                        style:
                            const TextStyle(
                          color:
                              Color(
                            0xFF20384D,
                          ),

                          fontSize:
                              15,

                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    _statusBadge(
                      status.$1,
                      status.$2,
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      7,
                ),

                Text(
                  '${_dateTime(item.tuNgay)} → '
                  '${_dateTime(item.denNgay)}',

                  style:
                      const TextStyle(
                    color:
                        _muted,

                    fontSize:
                        12,
                  ),
                ),

                const SizedBox(
                  height:
                      5,
                ),

                Wrap(
                  spacing:
                      12,

                  runSpacing:
                      5,

                  children: [
                    Text(
                      'Mã: ${item.maSuKien ?? '-'}',
                    ),

                    Text(
                      'Ưu tiên: ${item.mucUuTien}',
                    ),

                    Text(
                      'Hiệu ứng: ${item.effectType ?? 'Không'}',
                    ),

                    Text(
                      'Banner: ${item.banners.length}',
                    ),
                  ],
                ),

                if (item.moTa
                        ?.trim()
                        .isNotEmpty ==
                    true) ...[
                  const SizedBox(
                    height:
                        7,
                  ),

                  Text(
                    item.moTa!,

                    maxLines:
                        2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      color:
                          _muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed:
                () =>
                    _openBannerManager(
              item,
            ),

            icon:
                const Icon(
              Icons.photo_library_outlined,
              size:
                  17,
            ),

            label:
                Text(
              'Banner (${item.banners.length})',
            ),
          ),

          const SizedBox(
            width:
                6,
          ),
          const SizedBox(
            width:
                12,
          ),

          IconButton(
            tooltip:
                'Sửa',

            onPressed:
                () =>
                    _openForm(
              item:
                  item,
            ),

            icon:
                const Icon(
              Icons.edit_outlined,
              color:
                  _primary,
            ),
          ),

          IconButton(
            tooltip:
                'Xóa',

            onPressed:
                provider.deletingId ==
                        item.idSuKien
                    ? null
                    : () =>
                        _delete(
                          item,
                        ),

            icon:
                provider.deletingId ==
                        item.idSuKien
                    ? const SizedBox(
                        width:
                            18,
                        height:
                            18,

                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline,
                        color:
                            Color(
                          0xFFC43C35,
                        ),
                      ),
          ),
        ],
      ),
    );
  }


  (String, Color) _status(
    SuKienV2Model item,
  ) {
    if (!item.isActive) {
      return (
        'Đang tắt',
        const Color(
          0xFF7A8793,
        ),
      );
    }

    final now =
        DateTime.now();

    if (now.isBefore(
      item.tuNgay,
    )) {
      return (
        'Sắp diễn ra',
        const Color(
          0xFFB26A00,
        ),
      );
    }

    if (now.isAfter(
      item.denNgay,
    )) {
      return (
        'Đã kết thúc',
        const Color(
          0xFF7A8793,
        ),
      );
    }

    return (
      'Đang hiển thị',
      const Color(
        0xFF14845E,
      ),
    );
  }


  Widget _statusBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            9,
        vertical:
            5,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha:
              .1,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Text(
        text,

        style:
            TextStyle(
          color:
              color,

          fontSize:
              11,

          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }


  Widget _empty() {
    return Container(
      padding:
          const EdgeInsets.all(
        50,
      ),

      alignment:
          Alignment.center,

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          15,
        ),

        border:
            Border.all(
          color:
              _border,
        ),
      ),

      child:
          const Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size:
                46,
            color:
                Color(
              0xFF9AA9B5,
            ),
          ),

          SizedBox(
            height:
                10,
          ),

          Text(
            'Chưa có sự kiện nào.',
            style:
                TextStyle(
              color:
                  _muted,
            ),
          ),
        ],
      ),
    );
  }


  String _dateTime(
    DateTime value,
  ) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}