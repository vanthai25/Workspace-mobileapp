import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../models/nhan_vien_tuyen_dung_v2_models.dart';
import '../../../../services/nhan_vien_tuyen_dung_service.dart';

class TuyenDungCandidateDialog extends StatefulWidget {
  final NhanVienTuyenDungService service;

  const TuyenDungCandidateDialog({
    super.key,
    required this.service,
  });

  @override
  State<TuyenDungCandidateDialog> createState() =>
      _TuyenDungCandidateDialogState();
}

class _TuyenDungCandidateDialogState
    extends State<TuyenDungCandidateDialog> {
  static const Color _primary =
      Color(0xFF1274BC);

  static const Color _border =
      Color(0xFFE3EAF2);

  static const Color _muted =
      Color(0xFF66788A);

  final TextEditingController
      _searchController =
      TextEditingController();

  Timer? _debounce;

  bool _isLoading = false;

  String? _errorMessage;

  List<NhanVienTuyenDungItemV2Model>
      _items = [];

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _searchController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD
  // =========================================================

  Future<void> _load({
    String? keyword,
  }) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
          await widget.service.getDanhSach(
        keyword: keyword,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _items = result;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void _onSearchChanged(
    String value,
  ) {
    setState(() {});

    _debounce?.cancel();

    _debounce = Timer(
      const Duration(
        milliseconds: 400,
      ),
      () {
        if (!mounted) {
          return;
        }

        _load(
          keyword:
              value.trim().isEmpty
                  ? null
                  : value.trim(),
        );
      },
    );
  }

  Future<void> _clearSearch() async {
    _debounce?.cancel();

    _searchController.clear();

    setState(() {});

    await _load();
  }

  // =========================================================
  // SELECT
  // =========================================================

  void _select(
    NhanVienTuyenDungItemV2Model item,
  ) {
    Navigator.of(context).pop(
      item,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.sizeOf(context);

    final width =
        size.width >= 1200
            ? 920.0
            : size.width * 0.88;

    final height =
        size.height * 0.82;

    return Dialog(
      insetPadding:
          const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            _buildHeader(),

            const Divider(
              height: 1,
              color: _border,
            ),

            _buildSearch(),

            const Divider(
              height: 1,
              color: _border,
            ),

            Expanded(
              child: _buildContent(),
            ),

            const Divider(
              height: 1,
              color: _border,
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        22,
        18,
        14,
        18,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  const Color(
                0xFFEAF5FC,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: const Icon(
              Icons
                  .person_search_rounded,
              color: _primary,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn hồ sơ tuyển dụng',
                  style: TextStyle(
                    color:
                        Color(
                      0xFF172B3E,
                    ),
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(
                  height: 3,
                ),
                Text(
                  'Danh sách ứng viên trúng tuyển chưa được tạo nhân viên',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Đóng',
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            icon:
                const Icon(
              Icons.close_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Widget _buildSearch() {
    return Container(
      color:
          const Color(
        0xFFFAFCFE,
      ),
      padding:
          const EdgeInsets.all(
        16,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:
                  _searchController,
              onChanged:
                  _onSearchChanged,
              decoration:
                  InputDecoration(
                hintText:
                    'Tìm theo họ tên, CCCD, số điện thoại hoặc mã tuyển dụng...',
                prefixIcon:
                    const Icon(
                  Icons.search_rounded,
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
                                _clearSearch,
                            icon:
                                const Icon(
                              Icons
                                  .close_rounded,
                            ),
                          ),
                filled: true,
                fillColor:
                    Colors.white,
                isDense: true,
                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                  borderSide:
                      const BorderSide(
                    color: _border,
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                  borderSide:
                      const BorderSide(
                    color: _primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Tooltip(
            message:
                'Làm mới',
            child: OutlinedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                          _load(
                            keyword:
                                _searchController
                                        .text
                                        .trim()
                                        .isEmpty
                                    ? null
                                    : _searchController
                                        .text
                                        .trim(),
                          );
                        },
              style:
                  OutlinedButton
                      .styleFrom(
                minimumSize:
                    const Size(
                  48,
                  48,
                ),
                padding:
                    EdgeInsets.zero,
                side:
                    const BorderSide(
                  color: _border,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),
              ),
              child:
                  const Icon(
                Icons
                    .refresh_rounded,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CONTENT
  // =========================================================

  Widget _buildContent() {
    if (_isLoading &&
        _items.isEmpty) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null &&
        _items.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .error_outline_rounded,
                size: 46,
                color:
                    Color(
                  0xFFC43C35,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 14,
              ),

              OutlinedButton.icon(
                onPressed: _load,
                icon:
                    const Icon(
                  Icons
                      .refresh_rounded,
                ),
                label:
                    const Text(
                  'Thử lại',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .person_search_outlined,
              size: 52,
              color:
                  Color(
                0xFFA5B4C1,
              ),
            ),

            SizedBox(
              height: 10,
            ),

            Text(
              'Không có ứng viên phù hợp.',
              style: TextStyle(
                color: _muted,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ListView.separated(
            padding:
                const EdgeInsets.all(
              16,
            ),
            itemCount:
                _items.length,
            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              height: 8,
            ),
            itemBuilder:
                (
                  context,
                  index,
                ) {
              return _buildItem(
                _items[index],
              );
            },
          ),
        ),

        if (_isLoading)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child:
                LinearProgressIndicator(
              minHeight: 2,
            ),
          ),
      ],
    );
  }

  // =========================================================
  // ITEM
  // =========================================================

  Widget _buildItem(
    NhanVienTuyenDungItemV2Model item,
  ) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
        side:
            const BorderSide(
          color: _border,
        ),
      ),
      child: InkWell(
        onTap: () =>
            _select(item),
        borderRadius:
            BorderRadius.circular(14),
        hoverColor:
            const Color(
          0xFFF4F9FC,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(
            14,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              _buildAvatar(
                item,
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      _textOr(
                        item.hoVaTen,
                        'Chưa có họ tên',
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF20384D,
                        ),
                        fontSize: 14,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      children: [
                        _metadata(
                          Icons
                              .confirmation_number_outlined,
                          'TD ${item.idTuyenDung}',
                        ),

                        if (_hasText(
                          item.soDienThoai,
                        ))
                          _metadata(
                            Icons
                                .phone_outlined,
                            item.soDienThoai!,
                          ),

                        if (_hasText(
                          item.soCCCD,
                        ))
                          _metadata(
                            Icons
                                .credit_card_outlined,
                            item.soCCCD!,
                          ),

                        if (item
                                .namSinh !=
                            null)
                          _metadata(
                            Icons
                                .cake_outlined,
                            _date(
                              item.namSinh!,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    if (_hasText(
                      item.tenDotTuyenDung,
                    ))
                      _labelValue(
                        'Đợt tuyển dụng',
                        item.tenDotTuyenDung!,
                      ),

                    if (_hasText(
                      item.viTriChiTiet,
                    ))
                      Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 7,
                        ),
                        child:
                            _labelValue(
                          'Vị trí',
                          item.viTriChiTiet!,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              FilledButton.icon(
                onPressed: () =>
                    _select(
                  item,
                ),
                style:
                    FilledButton
                        .styleFrom(
                  backgroundColor:
                      _primary,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      10,
                    ),
                  ),
                ),
                icon:
                    const Icon(
                  Icons
                      .visibility_outlined,
                  size: 18,
                ),
                label:
                    const Text(
                  'Xem hồ sơ',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // AVATAR
  // =========================================================

  Widget _buildAvatar(
    NhanVienTuyenDungItemV2Model item,
  ) {
    final String? url =
        _normalizeUrl(
      item.anhDaiDienUrl,
    );

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            const Color(
          0xFFDCEFF9,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFB8DCEB,
          ),
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: url == null
          ? Center(
              child: Text(
                _initials(
                  item.hoVaTen,
                ),
                style:
                    const TextStyle(
                  color:
                      Color(
                    0xFF0B5E91,
                  ),
                  fontWeight:
                      FontWeight
                          .w800,
                ),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder:
                  (
                    context,
                    error,
                    stackTrace,
                  ) {
                return Center(
                  child: Text(
                    _initials(
                      item.hoVaTen,
                    ),
                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF0B5E91,
                      ),
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),
                );
              },
            ),
    );
  }

  // =========================================================
  // FOOTER
  // =========================================================

  Widget _buildFooter() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 13,
      ),
      color:
          const Color(
        0xFFFAFCFE,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color:
                Colors.blueGrey[
              500
            ],
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child: Text(
              '${_items.length} ứng viên',
              style:
                  const TextStyle(
                color: _muted,
                fontSize: 11.5,
              ),
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            child:
                const Text(
              'Đóng',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  Widget _metadata(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: _muted,
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style:
              const TextStyle(
            color: _muted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  Widget _labelValue(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            color: _muted,
            fontSize: 9.5,
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        Text(
          value,
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            color:
                Color(
              0xFF41596C,
            ),
            fontSize: 11.5,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _textOr(
    String? value,
    String fallback,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return fallback;
    }

    return value.trim();
  }

  bool _hasText(
    String? value,
  ) {
    return value != null &&
        value.trim().isNotEmpty;
  }

  String? _normalizeUrl(
    String? value,
  ) {
    if (value == null) {
      return null;
    }

    final url =
        value.trim();

    if (url.isEmpty) {
      return null;
    }

    if (!url.startsWith(
          'http://',
        ) &&
        !url.startsWith(
          'https://',
        )) {
      return null;
    }

    return url;
  }

  String _initials(
    String? name,
  ) {
    if (name == null ||
        name.trim().isEmpty) {
      return '?';
    }

    final parts =
        name
            .trim()
            .split(
              RegExp(
                r'\s+',
              ),
            )
            .where(
              (e) =>
                  e.isNotEmpty,
            )
            .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  String _date(
    DateTime value,
  ) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}