import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/cham_truc_model.dart';
import '../../providers/cham_truc_provider.dart';

class ChamTrucScreen extends StatefulWidget {
  const ChamTrucScreen({
    super.key,
  });

  @override
  State<ChamTrucScreen> createState() =>
      _ChamTrucScreenState();
}

class _ChamTrucScreenState extends State<ChamTrucScreen> {
  final Color primaryColor =
      const Color(0xFF1274BC);

  final TextEditingController _searchController =
      TextEditingController();

  /// Những khoa đang bị thu gọn.
  final Set<String> _collapsedKhoa = {};

  final List<_CoSoOption> _coSoOptions = const [
    _CoSoOption(
      code: null,
      name: 'Tất cả',
    ),
    _CoSoOption(
      code: 'BVHV',
      name: 'BV Hùng Vương',
    ),
    _CoSoOption(
      code: 'CHANMONG',
      name: 'Chân Mộng',
    ),
    _CoSoOption(
      code: 'KIMXUYEN',
      name: 'Kim Xuyên',
    ),
    _CoSoOption(
      code: 'SONDUONG',
      name: 'Sơn Dương',
    ),
    _CoSoOption(
      code: 'THANHBA',
      name: 'Thanh Ba',
    ),
  ];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context
          .read<ChamTrucProvider>()
          .fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // =========================================================
  // AVATAR KHÔNG DÙNG ẢNH
  // =========================================================

  Widget _buildAvatar(
    ChamTrucModel item, {
    double radius = 22,
  }) {
    String text = '?';

    final String name =
        item.tenNhanVienHienThi.trim();

    if (name.isNotEmpty) {
      text = name[0].toUpperCase();
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          primaryColor.withOpacity(0.10),
      child: Text(
        text,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }

  // =========================================================
  // NGÀY
  // =========================================================

  String _formatDateTitle(
    DateTime date,
  ) {
    const List<String> days = [
      '',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];

    return '${days[date.weekday]}, '
        '${DateFormat('dd/MM/yyyy').format(date)}';
  }

  Future<void> _pickDate(
    ChamTrucProvider provider,
  ) async {
    final DateTime? date =
        await showDatePicker(
      context: context,
      initialDate:
          provider.selectedDate,
      firstDate:
          DateTime(2023),
      lastDate:
          DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null &&
        mounted) {
      await provider.selectDate(
        date,
      );
    }
  }

  Widget _buildDateSelector(
    ChamTrucProvider provider,
  ) {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        10,
        12,
        10,
        9,
      ),
      child: Row(
        children: [
          _buildArrowButton(
            icon:
                Icons.chevron_left_rounded,
            onTap: provider.isLoading
                ? null
                : () {
                    provider.changeDate(
                      -1,
                    );
                  },
          ),

          Expanded(
            child: InkWell(
              onTap: provider.isLoading
                  ? null
                  : () {
                      _pickDate(
                        provider,
                      );
                    },
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              child: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 9,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .calendar_month_rounded,
                      size: 18,
                      color:
                          primaryColor,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Flexible(
                      child: Text(
                        _formatDateTitle(
                          provider
                              .selectedDate,
                        ),
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .w800,
                          color:
                              Color(
                            0xFF222222,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          _buildArrowButton(
            icon:
                Icons.chevron_right_rounded,
            onTap: provider.isLoading
                ? null
                : () {
                    provider.changeDate(
                      1,
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFFEAF4FC,
          ),
          borderRadius:
              BorderRadius.circular(
            11,
          ),
        ),
        child: Icon(
          icon,
          color:
              primaryColor,
        ),
      ),
    );
  }

  // =========================================================
  // CƠ SỞ
  // =========================================================

  Widget _buildCoSoSelector(
    ChamTrucProvider provider,
  ) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          12,
          6,
          12,
          10,
        ),
        child: Row(
          children:
              _coSoOptions.map(
            (option) {
              final bool selected =
                  provider
                          .selectedCoSo ==
                      option.code;

              return Padding(
                padding:
                    const EdgeInsets
                        .only(
                  right: 8,
                ),
                child: ChoiceChip(
                  selected:
                      selected,
                  showCheckmark:
                      false,
                  label:
                      Text(
                    option.name,
                  ),
                  selectedColor:
                      primaryColor,
                  backgroundColor:
                      const Color(
                    0xFFF2F4F7,
                  ),
                  side:
                      BorderSide.none,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      18,
                    ),
                  ),
                  labelStyle:
                      TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors
                            .grey
                            .shade700,
                    fontSize: 12,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                  onSelected: (_) async {
                    _collapsedKhoa.clear();

                    await provider
                        .selectCoSo(
                      option.code,
                    );
                  },
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // =========================================================
  // SEARCH + FILTER KHOA
  // =========================================================

  Widget _buildFilterArea(
    ChamTrucProvider provider,
  ) {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12,
      ),
      child: Column(
        children: [
          // -------------------------------------------------
          // TÌM THEO MÃ / TÊN NHÂN VIÊN
          // -------------------------------------------------

          TextField(
            controller:
                _searchController,
            onChanged: (value) {
              provider.setSearchText(
                value,
              );

              setState(() {});
            },
            textInputAction:
                TextInputAction.search,
            decoration:
                InputDecoration(
              hintText:
                  'Tìm mã hoặc tên nhân viên...',
              hintStyle:
                  TextStyle(
                color:
                    Colors.grey.shade400,
                fontSize: 13,
              ),
              prefixIcon:
                  Icon(
                Icons.search_rounded,
                color:
                    Colors.grey.shade500,
              ),
              suffixIcon:
                  _searchController
                          .text
                          .isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController
                                .clear();

                            provider
                                .setSearchText(
                              '',
                            );

                            setState(
                              () {},
                            );
                          },
                          icon:
                              const Icon(
                            Icons
                                .close_rounded,
                          ),
                        ),
              filled: true,
              fillColor:
                  const Color(
                0xFFF3F5F7,
              ),
              contentPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  13,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // -------------------------------------------------
          // CHỌN KHOA / PHÒNG
          // -------------------------------------------------

          DropdownButtonFormField<String?>(
            value:
                provider.selectedMaKhoa,
            isExpanded: true,
            icon:
                const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
            ),
            decoration:
                InputDecoration(
              labelText:
                  'Khoa / Phòng',
              labelStyle:
                  TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 13,
              ),
              prefixIcon:
                  Icon(
                Icons.domain_rounded,
                color:
                    primaryColor,
              ),
              filled: true,
              fillColor:
                  const Color(
                0xFFF3F5F7,
              ),
              contentPadding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius
                        .circular(
                  13,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem<
                  String?>(
                value: null,
                child: Text(
                  'Tất cả khoa / phòng',
                ),
              ),

              ...provider
                  .danhSachKhoa
                  .map(
                (khoa) {
                  return DropdownMenuItem<
                      String?>(
                    value:
                        khoa['makhoa'],
                    child: Text(
                      khoa['tenkhoa'] ??
                          khoa['makhoa'] ??
                          '',
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  );
                },
              ),
            ],
            onChanged:
                (String? value) {
              _collapsedKhoa.clear();

              provider.selectKhoa(
                value,
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // GROUP DATA: KHOA -> TỔ -> NHÂN VIÊN
  // =========================================================

  Map<
      String,
      Map<String,
          List<ChamTrucModel>>> _groupData(
    List<ChamTrucModel> source,
  ) {
    final List<ChamTrucModel>
        sorted =
        List<ChamTrucModel>.from(
      source,
    );

    sorted.sort(
      (a, b) {
        final String khoaA =
            a.tenKhoaHienThi
                .trim()
                .toLowerCase();

        final String khoaB =
            b.tenKhoaHienThi
                .trim()
                .toLowerCase();

        int result =
            khoaA.compareTo(
          khoaB,
        );

        if (result != 0) {
          return result;
        }

        final String toA =
            a.tenToHienThi
                .trim()
                .toLowerCase();

        final String toB =
            b.tenToHienThi
                .trim()
                .toLowerCase();

        result =
            toA.compareTo(
          toB,
        );

        if (result != 0) {
          return result;
        }

        return a
            .tenNhanVienHienThi
            .toLowerCase()
            .compareTo(
          b.tenNhanVienHienThi
              .toLowerCase(),
        );
      },
    );

    final Map<
            String,
            Map<
                String,
                List<
                    ChamTrucModel>>>
        result = {};

    for (final item in sorted) {
      final String khoa =
          item.tenKhoaHienThi
              .trim()
              .isEmpty
              ? 'Chưa xác định khoa/phòng'
              : item.tenKhoaHienThi
                  .trim();

      final String to =
          item.tenToHienThi
              .trim()
              .isEmpty
              ? 'Chưa xác định'
              : item.tenToHienThi
                  .trim();

      result.putIfAbsent(
        khoa,
        () => {},
      );

      result[khoa]!
          .putIfAbsent(
        to,
        () => [],
      );

      result[khoa]![to]!
          .add(
        item,
      );
    }

    return result;
  }

  // =========================================================
  // THU GỌN / MỞ RỘNG KHOA
  // =========================================================

  bool _isKhoaExpanded(
    String khoa,
  ) {
    return !_collapsedKhoa
        .contains(khoa);
  }

  void _toggleKhoa(
    String khoa,
  ) {
    setState(() {
      if (_collapsedKhoa
          .contains(khoa)) {
        _collapsedKhoa.remove(
          khoa,
        );
      } else {
        _collapsedKhoa.add(
          khoa,
        );
      }
    });
  }

  // =========================================================
  // KHOA
  // =========================================================

  Widget _buildKhoaSection(
    String khoa,
    Map<String,
        List<ChamTrucModel>> teams,
  ) {
    final int total =
        teams.values.fold<int>(
      0,
      (
        int sum,
        List<ChamTrucModel> list,
      ) =>
          sum + list.length,
    );

    final bool expanded =
        _isKhoaExpanded(
      khoa,
    );

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        8,
        7,
        8,
        2,
      ),
      clipBehavior:
          Clip.antiAlias,
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              0.035,
            ),
            blurRadius: 8,
            offset:
                const Offset(
              0,
              2,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          // -------------------------------------------------
          // HEADER KHOA
          // -------------------------------------------------

          Material(
            color:
                const Color(
              0xFFF7F8FA,
            ),
            child: InkWell(
              onTap: () =>
                  _toggleKhoa(
                khoa,
              ),
              child: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEAF4FC,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          9,
                        ),
                      ),
                      child: Icon(
                        Icons
                            .domain_rounded,
                        color:
                            primaryColor,
                        size: 18,
                      ),
                    ),

                    const SizedBox(
                      width: 9,
                    ),

                    Expanded(
                      child: Text(
                        khoa,
                        style:
                            const TextStyle(
                          fontSize:
                              13.5,
                          fontWeight:
                              FontWeight
                                  .w800,
                          color:
                              Color(
                            0xFF30343B,
                          ),
                        ),
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFE4F0FD,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                      child: Text(
                        '$total người',
                        style:
                            TextStyle(
                          color:
                              primaryColor,
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    AnimatedRotation(
                      duration:
                          const Duration(
                        milliseconds:
                            180,
                      ),
                      turns:
                          expanded
                              ? 0
                              : -0.25,
                      child: Icon(
                        Icons
                            .keyboard_arrow_up_rounded,
                        color:
                            Colors.grey
                                .shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------------------------
          // DANH SÁCH TỔ
          // -------------------------------------------------

          AnimatedCrossFade(
            duration:
                const Duration(
              milliseconds: 180,
            ),
            firstCurve:
                Curves.easeOut,
            secondCurve:
                Curves.easeOut,
            sizeCurve:
                Curves.easeOut,
            crossFadeState:
                expanded
                    ? CrossFadeState
                        .showFirst
                    : CrossFadeState
                        .showSecond,
            firstChild:
                Column(
              children:
                  teams.entries.map(
                (entry) {
                  return _buildToSection(
                    entry.key,
                    entry.value,
                  );
                },
              ).toList(),
            ),
            secondChild:
                const SizedBox(
              width: double.infinity,
              height: 0,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TỔ
  // =========================================================

  Widget _buildToSection(
    String tenTo,
    List<ChamTrucModel> items,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.fromLTRB(
            14,
            9,
            14,
            7,
          ),
          color:
              Colors.white,
          child: Row(
            children: [
              Icon(
                Icons
                    .groups_2_outlined,
                size: 16,
                color:
                    Colors.grey
                        .shade500,
              ),

              const SizedBox(
                width: 6,
              ),

              Expanded(
                child: Text(
                  tenTo,
                  style:
                      TextStyle(
                    color:
                        Colors.grey
                            .shade700,
                    fontSize: 12,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey
                          .shade100,
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
                child: Text(
                  '${items.length}',
                  style:
                      TextStyle(
                    color:
                        Colors.grey
                            .shade600,
                    fontSize: 10,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        ...items.asMap().entries.map(
          (entry) {
            return Column(
              children: [
                if (entry.key > 0)
                  Divider(
                    height: 1,
                    indent: 67,
                    endIndent: 12,
                    color: Colors
                        .grey
                        .shade200,
                  ),

                _buildEmployeeRow(
                  entry.value,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // NHÂN VIÊN
  // =========================================================

  Widget _buildEmployeeRow(
    ChamTrucModel item,
  ) {
    return InkWell(
      onTap: () {
        _showEmployeeDetail(
          item,
        );
      },
      child: Padding(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        child: Row(
          children: [
            _buildAvatar(
              item,
              radius: 21,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item
                              .tenNhanVienHienThi,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize:
                                13.5,
                            fontWeight:
                                FontWeight
                                    .w800,
                            color:
                                Color(
                              0xFF25282D,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    item.manv.isEmpty
                        ? 'Chưa có mã nhân viên'
                        : 'Mã NV: ${item.manv}',
                    style:
                        TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey
                              .shade500,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    item.tenLoaiCong ??
                        'Chưa xác định loại công',
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        TextStyle(
                      fontSize: 11.5,
                      color:
                          Colors.grey
                              .shade600,
                    ),
                  ),
                ],
              ),
            ),

            if (item.kyHieuId !=
                    null &&
                item.kyHieuId!
                    .trim()
                    .isNotEmpty)
              Container(
                constraints:
                    const BoxConstraints(
                  minWidth: 42,
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE6F1FD,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
                child: Text(
                  item.kyHieuId!
                      .trim(),
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        primaryColor,
                    fontSize: 11.5,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
              ),

            const SizedBox(
              width: 3,
            ),

            Icon(
              Icons
                  .chevron_right_rounded,
              size: 20,
              color:
                  Colors.grey
                      .shade300,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // GỌI ĐIỆN
  // =========================================================

  Future<void> _callPhone(
    String? phone,
  ) async {
    final String raw =
        phone?.trim() ?? '';

    if (raw.isEmpty) {
      return;
    }

    final String cleanPhone =
        raw.replaceAll(
      RegExp(r'[^\d+]'),
      '',
    );

    if (cleanPhone.isEmpty) {
      return;
    }

    try {
      final Uri uri =
          Uri(
        scheme: 'tel',
        path: cleanPhone,
      );

      final bool success =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!success &&
          mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể mở chức năng gọi điện.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể thực hiện cuộc gọi.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // DETAIL NHÂN VIÊN
  // =========================================================

  void _showEmployeeDetail(
    ChamTrucModel item,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (sheetContext) {
        final double maxHeight =
            MediaQuery.of(
                  sheetContext,
                ).size.height *
                0.88;

        return Container(
          constraints:
              BoxConstraints(
            maxHeight: maxHeight,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(
                24,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                20,
                12,
                20,
                28,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.grey
                              .shade300,
                      borderRadius:
                          BorderRadius
                              .circular(
                        10,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _buildAvatar(
                    item,
                    radius: 45,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    item
                        .tenNhanVienHienThi,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight
                              .w900,
                      color:
                          Color(
                        0xFF25282D,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    item.manv.isEmpty
                        ? 'Chưa có mã nhân viên'
                        : 'Mã NV: ${item.manv}',
                    style:
                        TextStyle(
                      color:
                          Colors.grey
                              .shade500,
                      fontSize: 13,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _buildDetailRow(
                    Icons.badge_outlined,
                    'Mã nhân viên',
                    item.manv.isEmpty
                        ? 'Chưa xác định'
                        : item.manv,
                  ),

                  _buildDetailRow(
                    Icons.domain_outlined,
                    'Khoa / Phòng',
                    item.tenKhoaHienThi,
                  ),

                  _buildDetailRow(
                    Icons
                        .groups_2_outlined,
                    'Tổ đội',
                    item.tenToHienThi,
                  ),

                  _buildDetailRow(
                    Icons
                        .schedule_outlined,
                    'Ký hiệu trực',
                    item.kyHieuId
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? item.kyHieuId!
                            .trim()
                        : 'Chưa xác định',
                  ),

                  _buildDetailRow(
                    Icons
                        .fact_check_outlined,
                    'Loại chấm công',
                    item.tenLoaiCong
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? item
                            .tenLoaiCong!
                            .trim()
                        : 'Chưa xác định',
                  ),

                  _buildPhoneRow(
                    'Điện thoại 1',
                    item.dienthoai1,
                  ),

                  _buildPhoneRow(
                    'Điện thoại 2',
                    item.dienthoai2,
                  ),

                  _buildDetailRow(
                    Icons
                        .location_on_outlined,
                    'Cơ sở',
                    _getCoSoName(
                      item.coSo,
                    ),
                  ),

                  if (item.ghiChu !=
                          null &&
                      item.ghiChu!
                          .trim()
                          .isNotEmpty)
                    _buildDetailRow(
                      Icons.notes_outlined,
                      'Ghi chú',
                      item.ghiChu!
                          .trim(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // DETAIL ROW
  // =========================================================

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 11,
      ),
      decoration:
          BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                Colors.grey
                    .shade100,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF1F7FC,
              ),
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color:
                  primaryColor,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            flex: 4,
            child: Padding(
              padding:
                  const EdgeInsets
                      .only(
                top: 8,
              ),
              child: Text(
                label,
                style:
                    TextStyle(
                  color:
                      Colors.grey
                          .shade600,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 6,
            child: Padding(
              padding:
                  const EdgeInsets
                      .only(
                top: 8,
              ),
              child: Text(
                value,
                textAlign:
                    TextAlign.right,
                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(
                    0xFF30343B,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PHONE ROW
  // =========================================================

  Widget _buildPhoneRow(
    String label,
    String? phone,
  ) {
    final String value =
        phone?.trim() ?? '';

    final bool hasPhone =
        value.isNotEmpty;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      decoration:
          BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                Colors.grey
                    .shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF1F7FC,
              ),
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),
            child: Icon(
              Icons.phone_outlined,
              size: 18,
              color:
                  primaryColor,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style:
                      TextStyle(
                    color:
                        Colors.grey
                            .shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  hasPhone
                      ? value
                      : 'Chưa cập nhật',
                  style:
                      TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight
                            .w700,
                    color: hasPhone
                        ? primaryColor
                        : Colors.grey
                            .shade500,
                  ),
                ),
              ],
            ),
          ),

          if (hasPhone)
            Material(
              color:
                  Colors.green
                      .withOpacity(
                0.10,
              ),
              shape:
                  const CircleBorder(),
              child: IconButton(
                tooltip:
                    'Gọi $value',
                onPressed: () {
                  _callPhone(
                    value,
                  );
                },
                icon:
                    const Icon(
                  Icons.call_rounded,
                  color:
                      Colors.green,
                  size: 21,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // CƠ SỞ DISPLAY
  // =========================================================

  String _getCoSoName(
    String code,
  ) {
    final String value =
        code.trim().toUpperCase();

    switch (value) {
      case 'BVHV':
      case 'BVHUNGVUONG':
        return 'BV Hùng Vương';

      case 'PKCM':
      case 'CHANMONG':
        return 'Chân Mộng';

      case 'PKKX':
      case 'KIMXUYEN':
        return 'Kim Xuyên';

      case 'PKSD':
      case 'SONDUONG':
        return 'Sơn Dương';

      case 'PKTB':
      case 'THANHBA':
        return 'Thanh Ba';

      default:
        return value.isEmpty
            ? 'Chưa xác định'
            : code;
    }
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _buildEmpty(
    ChamTrucProvider provider,
  ) {
    final bool hasFilter =
        provider.searchText
                .trim()
                .isNotEmpty ||
            provider.selectedMaKhoa !=
                null;

    return RefreshIndicator(
      color:
          primaryColor,
      onRefresh:
          provider.refresh,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(
            height: 95,
          ),

          Icon(
            hasFilter
                ? Icons
                    .search_off_rounded
                : Icons
                    .event_busy_outlined,
            size: 65,
            color:
                Colors.grey
                    .shade300,
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            hasFilter
                ? 'Không tìm thấy nhân viên phù hợp'
                : 'Không có lịch trực ngày '
                    '${DateFormat('dd/MM/yyyy').format(provider.selectedDate)}',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.grey
                      .shade600,
              fontSize: 15,
              fontWeight:
                  FontWeight
                      .w600,
            ),
          ),

          if (hasFilter) ...[
            const SizedBox(
              height: 5,
            ),

            Text(
              'Hãy thử thay đổi từ khóa hoặc khoa/phòng',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.grey
                        .shade400,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildError(
    ChamTrucProvider provider,
  ) {
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
              color:
                  Colors.redAccent,
              size: 48,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              provider.errorMessage ??
                  'Không thể tải dữ liệu lịch trực.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.grey
                        .shade700,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            ElevatedButton.icon(
              onPressed: () {
                provider.fetchData();
              },
              icon:
                  const Icon(
                Icons.refresh_rounded,
              ),
              label:
                  const Text(
                'Thử lại',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryColor,
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF3F5F8,
      ),

      appBar: AppBar(
        title:
            const Text(
          'Lịch Trực',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            primaryColor,
        foregroundColor:
            Colors.white,
        elevation: 0,
      ),

      body:
          Consumer<ChamTrucProvider>(
        builder: (
          context,
          provider,
          child,
        ) {
          final List<ChamTrucModel>
              filtered =
              provider.filteredItems;

          final Map<
                  String,
                  Map<
                      String,
                      List<
                          ChamTrucModel>>>
              grouped =
              _groupData(
            filtered,
          );

          return Column(
            children: [
              // NGÀY
              _buildDateSelector(
                provider,
              ),

              // CƠ SỞ
              _buildCoSoSelector(
                provider,
              ),

              // SEARCH + KHOA
              _buildFilterArea(
                provider,
              ),

              // LOADING NHỎ KHI ĐỔI NGÀY / CƠ SỞ
              if (provider.isLoading)
                LinearProgressIndicator(
                  minHeight: 2,
                  color:
                      primaryColor,
                  backgroundColor:
                      Colors.transparent,
                ),

              Expanded(
                child:
                    provider.isLoading &&
                            provider
                                .items
                                .isEmpty
                        ? Center(
                            child:
                                CircularProgressIndicator(
                              color:
                                  primaryColor,
                            ),
                          )
                        : provider
                                    .errorMessage !=
                                null
                            ? _buildError(
                                provider,
                              )
                            : filtered
                                    .isEmpty
                                ? _buildEmpty(
                                    provider,
                                  )
                                : RefreshIndicator(
                                    color:
                                        primaryColor,
                                    onRefresh:
                                        provider
                                            .refresh,
                                    child:
                                        ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding:
                                          const EdgeInsets
                                              .only(
                                        top: 4,
                                        bottom:
                                            30,
                                      ),
                                      children:
                                          grouped
                                              .entries
                                              .map(
                                        (
                                          entry,
                                        ) {
                                          return _buildKhoaSection(
                                            entry
                                                .key,
                                            entry
                                                .value,
                                          );
                                        },
                                      ).toList(),
                                    ),
                                  ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================
// OPTION CƠ SỞ
// ===========================================================

class _CoSoOption {
  final String? code;
  final String name;

  const _CoSoOption({
    required this.code,
    required this.name,
  });
}