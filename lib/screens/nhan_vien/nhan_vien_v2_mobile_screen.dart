import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/nhan_vien_mobile_v2_models.dart';
import '../../services/api_client.dart';
import '../../services/nhan_vien_mobile_v2_service.dart';

bool _shouldShowChucVu(String? value) {
  final String normalized = value?.trim().toLowerCase() ?? '';
  return normalized.isNotEmpty &&
      normalized != 'không' &&
      normalized != 'khong';
}

class NhanVienV2MobileScreen
    extends StatefulWidget {
  const NhanVienV2MobileScreen({
    super.key,
  });

  @override
  State<NhanVienV2MobileScreen>
      createState() =>
          _NhanVienV2MobileScreenState();
}

class _NhanVienV2MobileScreenState
    extends State<
        NhanVienV2MobileScreen> {
  static const Color _primary =
      Color(0xFF1274BC);

  static const Color _background =
      Color(0xFFF6F8FA);

  static const Color _border =
      Color(0xFFE5E9ED);

  static const Color _muted =
      Color(0xFF73808C);

  final TextEditingController
      _searchController =
      TextEditingController();

  late final NhanVienMobileV2Service
      _service;

  Timer? _debounce;

  List<NhanVienMobileKhoaPhongV2Model>
      _groups = [];

  bool _loading = true;

  String? _errorMessage;

  int? _tongNhanVien;

  int? _tongKhoaPhong;

  final Set<int>
      _loadedKhoaPhong =
      <int>{};

  final Set<int>
      _loadingKhoaPhong =
      <int>{};

  final Set<int>
      _expandedKhoaPhong =
      <int>{};

  int _searchVersion = 0;

  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();

    _service =
        NhanVienMobileV2Service(
      ApiClient().dio,
    );

    // Danh sách khoa không phải chờ tổng quan.
    _loadKhoaPhongs();

    // Tổng quan chạy song song.
    _loadTongQuan();
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _searchController.dispose();

    super.dispose();
  }

  bool get _isSearching =>
      _searchController.text
          .trim()
          .isNotEmpty;

  // ==========================================================
  // TỔNG QUAN
  // ==========================================================

  Future<void> _loadTongQuan() async {
    try {
      final result =
          await _service
              .getTongQuan();

      if (!mounted) {
        return;
      }

      setState(() {
        _tongNhanVien =
            result.tongNhanVien;

        _tongKhoaPhong =
            result.tongKhoaPhong;
      });
    } catch (_) {
      // Không để lỗi thống kê
      // làm hỏng màn danh bạ.
    }
  }

  // ==========================================================
  // KHOA PHÒNG
  // ==========================================================

  Future<void> _loadKhoaPhongs() async {
    final requestId =
        ++_loadRequestId;

    setState(() {
      _loading = true;

      _errorMessage = null;

      _loadingKhoaPhong.clear();
    });

    try {
      final result =
          await _service
              .getKhoaPhongs();

      if (!mounted ||
          requestId !=
              _loadRequestId) {
        return;
      }

      setState(() {
        _groups =
            result;

        _loading =
            false;

        _errorMessage =
            null;

        _loadedKhoaPhong.clear();

        _loadingKhoaPhong.clear();

        _expandedKhoaPhong.clear();

        // Nếu tổng khoa chưa tải xong,
        // dùng ngay số group thực tế.
        _tongKhoaPhong ??=
            result.length;
      });
    } catch (e) {
      if (!mounted ||
          requestId !=
              _loadRequestId) {
        return;
      }

      setState(() {
        _loading =
            false;

        _errorMessage =
            e.toString();
      });
    }
  }

  // ==========================================================
  // LOAD 1 KHOA
  // ==========================================================

  Future<void> _loadNhanVienKhoa(
    NhanVienMobileKhoaPhongV2Model group,
  ) async {
    final int requestId = _loadRequestId;
    final id =
        group.idKhoaPhong;

    if (_loadedKhoaPhong
            .contains(id) ||
        _loadingKhoaPhong
            .contains(id)) {
      return;
    }

    setState(() {
      _loadingKhoaPhong.add(
        id,
      );
    });

    try {
      final result =
          await _service.getDanhBa(
        idKhoaPhong: id,
      );

      if (!mounted ||
          requestId != _loadRequestId ||
          _isSearching) {
        return;
      }

      NhanVienMobileKhoaPhongV2Model?
          loadedGroup;

      for (final item in result) {
        if (item.idKhoaPhong ==
            id) {
          loadedGroup =
              item;

          break;
        }
      }

      setState(() {
        final index =
            _groups.indexWhere(
          (e) =>
              e.idKhoaPhong ==
              id,
        );

        if (index >= 0) {
          _groups[index] =
              loadedGroup ??
                  NhanVienMobileKhoaPhongV2Model(
                    idKhoaPhong:
                        group.idKhoaPhong,
                    tenKhoaPhong:
                        group.tenKhoaPhong,
                    stt:
                        group.stt,
                    soNhanVien:
                        0,
                    nhanViens:
                        const [],
                  );
        }

        _loadingKhoaPhong.remove(
          id,
        );

        _loadedKhoaPhong.add(
          id,
        );
      });
    } catch (e) {
      if (!mounted ||
          requestId != _loadRequestId) {
        return;
      }

      setState(() {
        _loadingKhoaPhong.remove(
          id,
        );
      });
    }
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  Future<void> _searchNhanVien() async {
    final keyword =
        _searchController.text
            .trim();

    if (keyword.isEmpty) {
      await _loadKhoaPhongs();

      return;
    }

    final requestId =
        ++_loadRequestId;

    setState(() {
      _loading = true;

      _errorMessage = null;

      _loadingKhoaPhong.clear();
    });

    try {
      final result =
          await _service.getDanhBa(
        keyword:
            keyword,
      );

      if (!mounted ||
          requestId !=
              _loadRequestId ||
          _searchController.text.trim() != keyword) {
        return;
      }

      setState(() {
        _groups =
            result;

        _loading =
            false;

        _loadedKhoaPhong.clear();

        _loadingKhoaPhong.clear();

        _expandedKhoaPhong.clear();

        _searchVersion++;
      });
    } catch (e) {
      if (!mounted ||
          requestId !=
              _loadRequestId) {
        return;
      }

      setState(() {
        _loading =
            false;

        _errorMessage =
            e.toString();
      });
    }
  }

  void _search(
    String value,
  ) {
    // Hủy hiệu lực ngay các request tải khoa hoặc tìm kiếm cũ.
    // Request mới sẽ nhận một mã khác sau thời gian debounce.
    _loadRequestId++;

    setState(() {
      _loadingKhoaPhong.clear();
    });

    _debounce?.cancel();

    _debounce =
        Timer(
      const Duration(
        milliseconds: 400,
      ),
      () {
        if (mounted) {
          _searchNhanVien();
        }
      },
    );
  }

  Future<void> _refresh() async {
    if (_isSearching) {
      await _searchNhanVien();
    } else {
      await Future.wait([
        _loadKhoaPhongs(),
        _loadTongQuan(),
      ]);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _background,

      appBar:
          AppBar(
        title:
            const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              'Nhân sự',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.w900,
              ),
            ),

            Text(
              'Danh bạ nhân viên',
              style:
                  TextStyle(
                fontSize: 10.5,
              ),
            ),
          ],
        ),

        backgroundColor:
            Colors.white,

        surfaceTintColor:
            Colors.white,

        elevation:
            0,

        actions: [
          IconButton(
            tooltip:
                'Làm mới',

            onPressed:
                _loading
                    ? null
                    : _refresh,

            icon:
                const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),

      body:
          Column(
        children: [
          _buildTop(),

          Expanded(
            child:
                _buildBody(),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SEARCH + THỐNG KÊ
  // ==========================================================

  Widget _buildTop() {
    return Container(
      color:
          Colors.white,

      padding:
          const EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12,
      ),

      child:
          Column(
        children: [
          TextField(
            controller:
                _searchController,

            onChanged:
                _search,

            textInputAction:
                TextInputAction.search,

            decoration:
                InputDecoration(
              hintText:
                  'Tìm theo tên, chức vụ, mã NV...',

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
                          onPressed:
                              () {
                            _debounce
                                ?.cancel();

                            _searchController
                                .clear();

                            setState(
                              () {},
                            );

                            _loadKhoaPhongs();
                          },

                          icon:
                              const Icon(
                            Icons.close,
                          ),
                        ),

              filled:
                  true,

              fillColor:
                  const Color(
                0xFFF5F7F9,
              ),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _summaryBox(
                  icon:
                      Icons.groups_rounded,

                  value:
                      _tongNhanVien
                              ?.toString() ??
                          '—',

                  label:
                      'Nhân viên',
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    _summaryBox(
                  icon:
                      Icons.apartment_rounded,

                  value:
                      (_tongKhoaPhong ??
                              _groups.length)
                          .toString(),

                  label:
                      'Khoa / Phòng',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBox({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      height:
          76,

      padding:
          const EdgeInsets.symmetric(
        horizontal:
            14,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF3F9FD,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFCDE6F5,
          ),
        ),
      ),

      child:
          Row(
        children: [
          Icon(
            icon,
            color:
                _primary,
            size:
                29,
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            value,
            style:
                const TextStyle(
              color:
                  _primary,
              fontSize:
                  25,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Flexible(
            child:
                Text(
              label,
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF657582,
                ),
                fontSize:
                    12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_loading &&
        _groups.isEmpty) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null &&
        _groups.isEmpty) {
      return Center(
        child:
            Text(
          _errorMessage!,
        ),
      );
    }

    if (_groups.isEmpty) {
      return const Center(
        child:
            Text(
          'Không tìm thấy nhân viên.',
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh:
              _refresh,

          child:
              ListView.builder(
            padding:
                const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              100,
            ),

            itemCount:
                _groups.length,

            itemBuilder:
                (
                  context,
                  index,
                ) {
              return _khoaPhongGroup(
                _groups[index],
              );
            },
          ),
        ),

        if (_loading)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,

            child:
                LinearProgressIndicator(
              minHeight:
                  2,
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // KHOA/PHÒNG
  // ==========================================================

  Widget _khoaPhongGroup(
    NhanVienMobileKhoaPhongV2Model
        group,
  ) {
    final id =
        group.idKhoaPhong;

    final searching =
        _isSearching;

    final loaded =
        _loadedKhoaPhong
            .contains(id);

    final loading =
        _loadingKhoaPhong
            .contains(id);

    final expanded =
        searching ||
        _expandedKhoaPhong
            .contains(id);

    return Container(
      key:
          ValueKey(
        searching
            ? '${id}_$_searchVersion'
            : id,
      ),

      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border:
            Border.all(
          color:
              _border,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha: .035,
            ),

            blurRadius:
                12,

            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      clipBehavior:
          Clip.antiAlias,

      child:
          ExpansionTile(
        initiallyExpanded:
            expanded,

        tilePadding:
            const EdgeInsets.symmetric(
          horizontal:
              16,
          vertical:
              8,
        ),

        leading:
            Container(
          width:
              48,

          height:
              48,

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFEAF5FB,
            ),

            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),

          child:
              const Icon(
            Icons.groups_rounded,

            color:
                _primary,
          ),
        ),

        title:
            Text(
          group.tenKhoaPhong ??
              '',

          style:
              const TextStyle(
            color:
                Color(
              0xFF182329,
            ),

            fontSize:
                16,

            fontWeight:
                FontWeight.w800,
          ),
        ),

        // subtitle:
        //     searching ||
        //             loaded
        //         ? Text(
        //             '${group.soNhanVien} nhân viên',
        //           )
        //         : null,

        onExpansionChanged:
            (value) {
          setState(() {
            if (value) {
              _expandedKhoaPhong
                  .add(id);
            } else {
              _expandedKhoaPhong
                  .remove(id);
            }
          });

          if (value &&
              !searching &&
              !loaded &&
              !loading) {
            _loadNhanVienKhoa(
              group,
            );
          }
        },

        children:
            !expanded
                ? const []
                : loading
                    ? const [
                        Padding(
                          padding:
                              EdgeInsets.all(
                            22,
                          ),
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        ),
                      ]
                    : group
                        .nhanViens
                        .map(
                          _employeeCard,
                        )
                        .toList(),
      ),
    );
  }

  // ==========================================================
  // CARD NHÂN VIÊN
  // ==========================================================

  Widget _employeeCard(
  NhanVienMobileItemV2Model item,
) {
  final color =
      _chucVuColor(
    item.sttChucVu,
  );

  return Padding(
    padding:
        const EdgeInsets.fromLTRB(
      10,
      5,
      10,
      5,
    ),
    child: Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        onTap: () {
          _showEmployeeDetail(
            item,
            color,
          );
        },
        child: Container(
          // =================================================
          // QUAN TRỌNG:
          // Có chiều cao cố định để Column + Spacer
          // không bị unbounded height.
          // =================================================
          height: 150,

          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color:
                  color.withValues(
                alpha: .60,
              ),
              width: 1.4,
            ),
          ),

          clipBehavior:
              Clip.antiAlias,

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [
              // ===============================================
              // ẢNH
              // ===============================================

              SizedBox(
                width: 105,
                height: 150,
                child:
                    _employeePhoto(
                  item,
                  color,
                ),
              ),

              // ===============================================
              // THÔNG TIN
              // ===============================================

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    12,
                    10,
                    9,
                    8,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // =====================================
                      // HỌ TÊN
                      // =====================================

                      Text(
                        item.hoVaTen ??
                            item.maSo,

                        maxLines: 1,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w900,
                          color:
                              Color(
                            0xFF17242C,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      // =====================================
                      // ĐIỆN THOẠI
                      // =====================================

                      if (_hasText(
                        item.soDienThoai,
                      ))
                        _line(
                          Icons.phone_outlined,
                          item.soDienThoai!,
                        ),

                      // =====================================
                      // NGÀY SINH
                      // =====================================

                      if (item.namSinh !=
                          null)
                        _line(
                          Icons
                              .calendar_month_outlined,
                          _date(
                            item.namSinh,
                          ),
                        ),

                      // =====================================
                      // KHOA / PHÒNG HIỂN THỊ
                      // =====================================

                      if (_hasText(
                        item.tenKhoaPhongHienThi,
                      ))
                        _line(
                          Icons.apartment_outlined,
                          item.tenKhoaPhongHienThi!,
                        ),

                      const SizedBox(
                        height: 2,
                      ),

                      // =====================================
                      // CHỨC VỤ
                      // =====================================

                      if (_shouldShowChucVu(
                        item.tenChucVu,
                      ))
                        Text(
                          item.tenChucVu!,

                          maxLines: 1,

                          overflow:
                              TextOverflow.ellipsis,

                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),

                      // =====================================
                      // CHỨC DANH
                      // =====================================

                      if (_hasText(
                        item.tenChucDanh,
                      ))
                        Text(
                          item.tenChucDanh!,

                          maxLines: 1,

                          overflow:
                              TextOverflow.ellipsis,

                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                      // Bây giờ Spacer dùng được vì
                      // card đã có height = 150.
                      const Spacer(),

                      // =====================================
                      // MÃ NV + CHI TIẾT
                      // =====================================

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'ID: ${item.maSo}',

                              maxLines: 1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFEAF5FB,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),

                            child:
                                const Text(
                              'Chi tiết ›',
                              style:
                                  TextStyle(
                                color: _primary,
                                fontSize: 9.5,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
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
    ),
  );
}

  Widget _employeePhoto(
  NhanVienMobileItemV2Model item,
  Color color,
) {
  return FutureBuilder<Uint8List?>(
    future: _service.getAvatar(
      item.maSo,
      size: 160,
    ),
    builder: (
      context,
      snapshot,
    ) {
      final bytes =
          snapshot.data;

      if (bytes == null ||
          bytes.isEmpty) {
        return Container(
          color:
              color.withValues(
            alpha: .08,
          ),
          alignment:
              Alignment.center,
          child: Text(
            _initials(
              item.hoVaTen,
            ),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        );
      }

      return Image.memory(
        bytes,
        width: 105,
        height: 150,
        fit: BoxFit.cover,
        cacheWidth: 180,
        gaplessPlayback: true,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            color:
                color.withValues(
              alpha: .08,
            ),
            alignment:
                Alignment.center,
            child: Text(
              _initials(
                item.hoVaTen,
              ),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          );
        },
      );
    },
  );
}
  Widget _line(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 3,
      ),

      child:
          Row(
        children: [
          Icon(
            icon,
            size:
                13,

            color:
                _muted,
          ),

          const SizedBox(
            width:
                5,
          ),

          Expanded(
            child:
                Text(
              text,

              maxLines:
                  1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                color:
                    _muted,

                fontSize:
                    10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // POPUP CHI TIẾT
  // ==========================================================

  Future<void> _showEmployeeDetail(
    NhanVienMobileItemV2Model item,
    Color color,
  ) async {
    showModalBottomSheet<void>(
      context:
          context,

      isScrollControlled:
          true,

      useSafeArea:
          true,

      backgroundColor:
          Colors.transparent,

      builder:
          (_) =>
              _EmployeeDetailSheet(
        item:
            item,

        color:
            color,

        service:
            _service,
      ),
    );
  }

  Color _chucVuColor(
    int? stt,
  ) {
    switch (stt) {
      case 1:
        return const Color(0xFF9B1C1C);
      case 2:
        return const Color(0xFFC2410C);
      case 3:
        return const Color(0xFFEA580C);
      case 4:
        return const Color(0xFF7C3AED);
      case 5:
        return const Color(0xFF1D4ED8);
      case 6:
        return const Color(0xFF0284C7);
      case 7:
        return const Color(0xFF0891B2);
      case 8:
        return const Color(0xFF16803C);
      case 9:
        return const Color(0xFFB7791F);
      default:
        return const Color(0xFF64748B);
    }
  }

  bool _hasText(
    String? value,
  ) =>
      value != null &&
      value.trim().isNotEmpty;

  String _date(
    DateTime? value,
  ) {
    if (value == null) {
      return '';
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _initials(
    String? name,
  ) {
    if (name == null ||
        name.trim().isEmpty) {
      return '?';
    }

    final words =
        name
            .trim()
            .split(
              RegExp(
                r'\s+',
              ),
            );

    if (words.length ==
        1) {
      return words.first[0]
          .toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'
        .toUpperCase();
  }
}

// ============================================================
// BOTTOM SHEET DETAIL
// ============================================================

class _EmployeeDetailSheet
    extends StatefulWidget {
  final NhanVienMobileItemV2Model item;

  final Color color;

  final NhanVienMobileV2Service service;

  const _EmployeeDetailSheet({
    required this.item,
    required this.color,
    required this.service,
  });

  @override
  State<_EmployeeDetailSheet>
      createState() =>
          _EmployeeDetailSheetState();
}

class _EmployeeDetailSheetState
    extends State<
        _EmployeeDetailSheet> {
  NhanVienMobileDetailV2Model?
      _detail;

  Uint8List? _avatar;

  bool _loading =
      true;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    try {
      final result =
          await Future.wait<dynamic>(
        [
          widget.service
              .getChiTiet(
            widget.item.maSo,
          ),

          widget.service
              .getAvatar(
            widget.item.maSo,
            size: 480,
          ),
        ],
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _detail =
            result[0]
                as NhanVienMobileDetailV2Model;

        _avatar =
            result[1]
                as Uint8List?;

        _loading =
            false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading =
              false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      constraints:
          BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(
                  context,
                ).height *
                .88,
      ),

      decoration:
          const BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            28,
          ),
        ),
      ),

      child:
          _loading
              ? const SizedBox(
                  height:
                      360,

                  child:
                      Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              : _content(),
    );
  }

  Widget _content() {
    final d =
        _detail;

    if (d == null) {
      return const SizedBox(
        height:
            250,

        child:
            Center(
          child:
              Text(
            'Không tải được thông tin.',
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        26,
      ),

      child:
          Column(
        children: [
          Container(
            width:
                42,

            height:
                4,

            margin:
                const EdgeInsets.only(
              bottom:
                  26,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFD6DADD,
              ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
          ),

          Container(
            width:
                130,

            height:
                170,

            clipBehavior:
                Clip.antiAlias,

            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                22,
              ),

              border:
                  Border.all(
                color:
                    widget.color.withValues(
                  alpha:
                      .35,
                ),
              ),
            ),

            child:
                _avatar != null
                    ? Image.memory(
                        _avatar!,
                        fit:
                            BoxFit.cover,
                      )
                    : Center(
                        child:
                            Text(
                          _initials(
                            d.hoVaTen,
                          ),
                          style:
                              TextStyle(
                            color:
                                widget.color,
                            fontSize:
                                30,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ),
          ),

          const SizedBox(
            height:
                18,
          ),

          Text(
            d.hoVaTen ??
                d.maSo,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize:
                  24,

              fontWeight:
                  FontWeight.w900,
            ),
          ),

          if (_shouldShowChucVu(
            d.tenChucVu,
          )) ...[
            const SizedBox(
              height:
                  10,
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    15,
                vertical:
                    7,
              ),

              decoration:
                  BoxDecoration(
                color:
                    widget.color.withValues(
                  alpha:
                      .09,
                ),

                borderRadius:
                    BorderRadius.circular(
                  25,
                ),
              ),

              child:
                  Text(
                d.tenChucVu!,

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      widget.color,

                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],

          const SizedBox(
            height:
                24,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _box(
                  Icons.badge_outlined,
                  'MÃ NHÂN VIÊN',
                  d.maSo,
                ),
              ),

              const SizedBox(
                width:
                    10,
              ),

              Expanded(
                child:
                    _box(
                  Icons.phone_rounded,
                  'ĐIỆN THOẠI',
                  d.soDienThoai ??
                      '-',
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                10,
          ),

          _box(
            Icons.apartment_rounded,
            'KHOA / PHÒNG',
            d.tenKhoaPhong ??
                '-',
          ),

          const SizedBox(
            height:
                10,
          ),

          _box(
            Icons.medical_services_outlined,
            'CHỨC DANH',
            d.tenChucDanh ??
                '-',
          ),

          const SizedBox(
            height:
                10,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _box(
                  Icons.calendar_month,
                  'NGÀY SINH',
                  _date(
                    d.namSinh,
                  ),
                ),
              ),

              const SizedBox(
                width:
                    10,
              ),

              Expanded(
                child:
                    _box(
                  d.gioiTinh ==
                          false
                      ? Icons.female
                      : Icons.male,
                  'GIỚI TÍNH',
                  d.gioiTinh ==
                          null
                      ? '-'
                      : d.gioiTinh!
                          ? 'Nam'
                          : 'Nữ',
                ),
              ),
            ],
          ),

          if (_hasText(
            d.soDienThoai,
          )) ...[
            const SizedBox(
              height:
                  22,
            ),

            SizedBox(
              width:
                  double.infinity,

              height:
                  52,

              child:
                  FilledButton.icon(
                onPressed:
                    () =>
                        _call(
                  d.soDienThoai!,
                ),

                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF20C763,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                ),

                icon:
                    const Icon(
                  Icons.call_rounded,
                ),

                label:
                    Text(
                  'Gọi ${d.soDienThoai}',

                  style:
                      const TextStyle(
                    fontSize:
                        16,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _box(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      width:
          double.infinity,

      constraints:
          const BoxConstraints(
        minHeight:
            82,
      ),

      padding:
          const EdgeInsets.all(
        13,
      ),

      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          15,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE6E9EC,
          ),
        ),
      ),

      child:
          Row(
        children: [
          Container(
            width:
                42,

            height:
                42,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEAF5FB,
              ),

              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),

            child:
                Icon(
              icon,

              color:
                  const Color(
                0xFF1274BC,
              ),
            ),
          ),

          const SizedBox(
            width:
                11,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                Text(
                  label,

                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF1274BC,
                    ),

                    fontSize:
                        10,

                    fontWeight:
                        FontWeight.w800,

                    letterSpacing:
                        .5,
                  ),
                ),

                const SizedBox(
                  height:
                      4,
                ),

                Text(
                  value,

                  style:
                      const TextStyle(
                    fontSize:
                        14,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _call(
    String phone,
  ) async {
    final value =
        phone
            .replaceAll(
              ' ',
              '',
            )
            .trim();

    if (value.isEmpty) {
      return;
    }

    final uri =
        Uri(
      scheme:
          'tel',

      path:
          value,
    );

    await launchUrl(
      uri,

      mode:
          LaunchMode.externalApplication,
    );
  }

  bool _hasText(
    String? value,
  ) =>
      value != null &&
      value.trim().isNotEmpty;

  String _date(
    DateTime? value,
  ) {
    if (value == null) {
      return '-';
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _initials(
    String? name,
  ) {
    if (name == null ||
        name.trim().isEmpty) {
      return '?';
    }

    final list =
        name
            .trim()
            .split(
              RegExp(
                r'\s+',
              ),
            );

    return list.length ==
            1
        ? list.first[0]
            .toUpperCase()
        : '${list.first[0]}${list.last[0]}'
            .toUpperCase();
  }
}
