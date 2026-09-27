import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cham_cong_phep_model.dart';
import '../../providers/cham_cong_phep_provider.dart';

class TaoDonNghiScreen extends StatefulWidget {
  const TaoDonNghiScreen({
    super.key,
  });

  @override
  State<TaoDonNghiScreen> createState() =>
      _TaoDonNghiScreenState();
}

class _TaoDonNghiScreenState
    extends State<TaoDonNghiScreen> {
  static const Color primaryColor =
      Color(0xFF1274BC);

  final TextEditingController
      _lyDoController =
      TextEditingController(
    text: 'Xin nghỉ phép',
  );

  String? _selectedNguoiDuyet;

  DateTime _fromDate =
      DateTime.now();

  DateTime _toDate =
      DateTime.now();

  List<ChamCongPhepChiTietDto>
      _danhSachNgay = [];

  bool _hasInitializedList =
      false;

  // Loading riêng của màn hình.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context
          .read<ChamCongPhepProvider>()
          .fetchDanhMuc();
    });
  }

  @override
  void dispose() {
    _lyDoController.dispose();

    super.dispose();
  }

  // =========================================================
  // DATE ONLY
  // =========================================================

  DateTime _dateOnly(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  // =========================================================
  // ĐỒNG BỘ DANH SÁCH NGÀY
  // =========================================================

  void _syncDateRange() {
    final provider =
        context.read<
            ChamCongPhepProvider>();

    if (provider
        .listKyHieu.isEmpty) {
      return;
    }

    final defaultKyHieu =
        provider.listKyHieu.firstWhere(
      (k) =>
          k.kyHieu
              ?.toUpperCase() ==
          'P',
      orElse: () =>
          provider.listKyHieu.first,
    );

    DateTime from =
        _dateOnly(
      _fromDate,
    );

    DateTime to =
        _dateOnly(
      _toDate,
    );

    if (to.isBefore(from)) {
      to = from;
    }

    final List<
            ChamCongPhepChiTietDto>
        newList = [];

    DateTime current =
        from;

    while (!current.isAfter(to)) {
      ChamCongPhepChiTietDto?
          existing;

      for (final item
          in _danhSachNgay) {
        if (_dateOnly(
              item.ngayNghi,
            ) ==
            current) {
          existing =
              item;
          break;
        }
      }

      if (existing != null) {
        newList.add(
          existing,
        );
      } else {
        newList.add(
          ChamCongPhepChiTietDto(
            ngayNghi:
                current,
            kyHieuId:
                defaultKyHieu
                    .kyHieu!,
            tenKyHieu:
                defaultKyHieu
                        .tenLoaiCong ??
                    '',
          ),
        );
      }

      current =
          current.add(
        const Duration(
          days: 1,
        ),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _fromDate =
          from;

      _toDate =
          to;

      _danhSachNgay =
          newList;
    });
  }

  // =========================================================
  // RESET
  // =========================================================

  void _resetDateRange() {
    final now =
        _dateOnly(
      DateTime.now(),
    );

    _fromDate =
        now;

    _toDate =
        now;

    _danhSachNgay =
        [];

    _syncDateRange();
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void>
      _showCupertinoDatePicker(
    DateTime initialDate,
    bool isFrom,
  ) async {
    DateTime tempDate =
        initialDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (
        popupContext,
      ) {
        return Container(
          height:
              300,
          decoration:
              const BoxDecoration(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(
                20,
              ),
            ),
          ),
          child:
              Column(
            children: [
              Container(
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey
                          .shade50,
                  borderRadius:
                      const BorderRadius
                          .vertical(
                    top:
                        Radius.circular(
                      20,
                    ),
                  ),
                  border:
                      Border(
                    bottom:
                        BorderSide(
                      color:
                          Colors.grey
                              .shade200,
                    ),
                  ),
                ),
                child:
                    Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed:
                          () {
                        Navigator.of(
                          popupContext,
                        ).pop();
                      },
                      child:
                          Text(
                        'Hủy',
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      onPressed:
                          () {
                        final selected =
                            _dateOnly(
                          tempDate,
                        );

                        if (isFrom) {
                          _fromDate =
                              selected;

                          if (_toDate
                              .isBefore(
                            selected,
                          )) {
                            _toDate =
                                selected;
                          }
                        } else {
                          _toDate =
                              selected;

                          if (_toDate
                              .isBefore(
                            _fromDate,
                          )) {
                            _fromDate =
                                selected;
                          }
                        }

                        Navigator.of(
                          popupContext,
                        ).pop();

                        WidgetsBinding
                            .instance
                            .addPostFrameCallback(
                          (_) {
                            if (!mounted) {
                              return;
                            }

                            _syncDateRange();
                          },
                        );
                      },
                      child:
                          const Text(
                        'Xong',
                        style:
                            TextStyle(
                          color:
                              primaryColor,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    CupertinoDatePicker(
                  mode:
                      CupertinoDatePickerMode
                          .date,
                  initialDateTime:
                      initialDate,
                  onDateTimeChanged:
                      (
                    value,
                  ) {
                    tempDate =
                        value;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // CHỌN KÝ HIỆU
  // =========================================================

  Future<void>
      _showKyHieuSearchSheet(
    int index,
  ) async {
    final provider =
        context.read<
            ChamCongPhepProvider>();

    final selected =
        await showModalBottomSheet<
            ChamCongPhepKyHieuResponseDto>(
      context:
          context,
      isScrollControlled:
          true,
      backgroundColor:
          Colors.transparent,
      builder: (_) {
        return _KyHieuSearchSheet(
          listKyHieu:
              provider.listKyHieu,
          currentKyHieuId:
              _danhSachNgay[index]
                      .kyHieuId ??
                  '',
        );
      },
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    if (index < 0 ||
        index >=
            _danhSachNgay.length) {
      return;
    }

    setState(() {
      _danhSachNgay[index] =
          ChamCongPhepChiTietDto(
        ngayNghi:
            _danhSachNgay[index]
                .ngayNghi,
        kyHieuId:
            selected.kyHieu!,
        tenKyHieu:
            selected.tenLoaiCong ??
                '',
      );
    });
  }

  // =========================================================
  // SUBMIT
  // =========================================================

  Future<void> _submitForm() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context)
        .unfocus();

    final String?
        nguoiDuyet =
        _selectedNguoiDuyet
            ?.trim();

    if (nguoiDuyet == null ||
        nguoiDuyet.isEmpty) {
      _showMessage(
        'Vui lòng chọn người duyệt phiếu.',
      );

      return;
    }

    if (_danhSachNgay.isEmpty) {
      _showMessage(
        'Vui lòng chọn ít nhất 1 ngày nghỉ.',
      );

      return;
    }

    final String lyDo =
        _lyDoController.text
            .trim();

    if (lyDo.isEmpty) {
      _showMessage(
        'Vui lòng nhập lý do nghỉ.',
      );

      return;
    }

    final request =
        ChamCongPhepCreateRequestDto(
      ngayNghi:
          _danhSachNgay
              .first
              .ngayNghi,
      kyHieuId:
          _danhSachNgay
              .first
              .kyHieuId,
      lyDoNghiPhep:
          lyDo,
      nguoiDuyet:
          nguoiDuyet,
      danhSachNgay:
          _danhSachNgay,
    );

    setState(() {
      _isSubmitting =
          true;
    });

    String? error;

    try {
      error = await context
          .read<
              ChamCongPhepProvider>()
          .submitDonXinPhepV2(
        request,
      );
    } catch (e) {
      error =
          'Có lỗi xảy ra khi gửi đơn.';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting =
          false;
    });

    if (error == null) {
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text(
            'Tạo đơn xin nghỉ thành công!',
          ),
          backgroundColor:
              Colors.green,
        ),
      );

      Navigator.of(context)
          .pop();

      return;
    }

    await showDialog<void>(
      context:
          context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          title:
              const Row(
            children: [
              Icon(
                Icons
                    .error_outline_rounded,
                color:
                    Colors.redAccent,
              ),
              SizedBox(
                width:
                    8,
              ),
              Text(
                'Thất bại',
                style:
                    TextStyle(
                  color:
                      Colors.redAccent,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          content:
              Text(
            error!,
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text(
                'Đóng',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(
          message,
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
    final provider =
        context.watch<
            ChamCongPhepProvider>();

    // Chỉ khởi tạo ngày đúng 1 lần.
    if (!provider.isLoading &&
        provider
            .listKyHieu.isNotEmpty &&
        !_hasInitializedList) {
      _hasInitializedList =
          true;

      WidgetsBinding.instance
          .addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          _syncDateRange();
        },
      );
    }

    final bool
        dangTaiDanhMuc =
        provider.isLoading &&
            provider
                .listKyHieu
                .isEmpty;

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF5F7FA,
      ),
      appBar:
          AppBar(
        title:
            const Text(
          'Tạo đơn xin nghỉ',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,
        elevation:
            0,
        centerTitle:
            true,
      ),
      body:
          dangTaiDanhMuc
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color:
                        primaryColor,
                  ),
                )
              : GestureDetector(
                  onTap:
                      () {
                    FocusScope.of(
                      context,
                    ).unfocus();
                  },
                  child:
                      SingleChildScrollView(
                    physics:
                        const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      120,
                    ),
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildThongTinCard(
                          provider,
                        ),
                        const SizedBox(
                          height:
                              24,
                        ),
                        _buildSectionTitle(
                          'Khoảng thời gian',
                        ),
                        _buildDateRangeCard(),
                        const SizedBox(
                          height:
                              18,
                        ),
                        if (_danhSachNgay
                            .isNotEmpty)
                          _buildDanhSachNgay(),
                      ],
                    ),
                  ),
                ),
      bottomSheet:
          dangTaiDanhMuc
              ? const SizedBox
                  .shrink()
              : _buildBottomButton(
                  provider,
                ),
    );
  }

  // =========================================================
  // THÔNG TIN
  // =========================================================

  Widget _buildThongTinCard(
    ChamCongPhepProvider provider,
  ) {
    return Container(
      width:
          double.infinity,
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
          16,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.03,
            ),
            blurRadius:
                10,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn người duyệt',
            style:
                TextStyle(
              color:
                  Colors.grey
                      .shade800,
              fontSize:
                  14,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height:
                5,
          ),
          Text(
            'Người được chọn sẽ nhận thông báo và trực tiếp xử lý phiếu của bạn.',
            style:
                TextStyle(
              color:
                  Colors.grey
                      .shade500,
              fontSize:
                  12,
              height:
                  1.4,
            ),
          ),
          const SizedBox(
            height:
                12,
          ),

          if (provider
              .listNguoiDuyet
              .isEmpty)
            _buildNoNguoiDuyet()
          else
            ...provider
                .listNguoiDuyet
                .map(
              (
                item,
              ) =>
                  _buildNguoiDuyetItem(
                item,
              ),
            ),

          const SizedBox(
            height:
                12,
          ),
          Divider(
            color:
                Colors.grey
                    .shade200,
          ),
          const SizedBox(
            height:
                12,
          ),

          Text(
            'Lý do nghỉ',
            style:
                TextStyle(
              color:
                  Colors.grey
                      .shade800,
              fontSize:
                  14,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height:
                8,
          ),
          TextField(
            controller:
                _lyDoController,
            maxLines:
                3,
            textCapitalization:
                TextCapitalization
                    .sentences,
            decoration:
                _inputDecoration(
              'Nhập lý do nghỉ...',
              Icons
                  .edit_note_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KHÔNG CÓ NGƯỜI DUYỆT
  // =========================================================

  Widget _buildNoNguoiDuyet() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.orange.shade50,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color:
              Colors.orange.shade200,
        ),
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons
                .warning_amber_rounded,
            color:
                Colors.orange.shade700,
          ),
          const SizedBox(
            width:
                9,
          ),
          const Expanded(
            child:
                Text(
              'Bạn chưa được cấu hình người duyệt. '
              'Vui lòng liên hệ quản trị hệ thống.',
              style:
                  TextStyle(
                fontSize:
                    13,
                height:
                    1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NGƯỜI DUYỆT ITEM
  // =========================================================

  Widget _buildNguoiDuyetItem(
    ChamCongPhepNguoiDuyetResponseDto item,
  ) {
    final String manv =
        item.manv?.trim() ??
            '';

    final bool selected =
        manv.isNotEmpty &&
            _selectedNguoiDuyet ==
                manv;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            8,
      ),
      child:
          Material(
        color:
            Colors.transparent,
        child:
            InkWell(
          onTap:
              manv.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _selectedNguoiDuyet =
                            manv;
                      });
                    },
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          child:
              AnimatedContainer(
            duration:
                const Duration(
              milliseconds:
                  150,
            ),
            padding:
                const EdgeInsets.all(
              12,
            ),
            decoration:
                BoxDecoration(
              color:
                  selected
                      ? primaryColor.withOpacity(
                          0.06,
                        )
                      : Colors.grey.shade50,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              border:
                  Border.all(
                color:
                    selected
                        ? primaryColor
                        : Colors.grey.shade200,
                width:
                    selected
                        ? 1.5
                        : 1,
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
                        selected
                            ? primaryColor.withOpacity(
                                0.10,
                              )
                            : Colors.grey.shade200,
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      Icon(
                    Icons
                        .person_rounded,
                    color:
                        selected
                            ? primaryColor
                            : Colors.grey.shade500,
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
                    children: [
                      Text(
                        item.tenNhanVien
                                    ?.trim()
                                    .isNotEmpty ==
                                true
                            ? item.tenNhanVien!
                                .trim()
                            : 'Không xác định',
                        style:
                            TextStyle(
                          fontSize:
                              14,
                          fontWeight:
                              selected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                          color:
                              selected
                                  ? primaryColor
                                  : Colors.black87,
                        ),
                      ),
                      const SizedBox(
                        height:
                            3,
                      ),
                      Text(
                        'Mã NV: $manv',
                        style:
                            TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize:
                              12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons
                          .check_circle_rounded
                      : Icons
                          .radio_button_unchecked_rounded,
                  color:
                      selected
                          ? primaryColor
                          : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DATE RANGE
  // =========================================================

  Widget _buildDateRangeCard() {
    return Container(
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
          16,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.03,
            ),
            blurRadius:
                10,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Từ ngày',
                  style:
                      TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize:
                        12,
                  ),
                ),
                const SizedBox(
                  height:
                      4,
                ),
                _buildDateButton(
                  _fromDate,
                  true,
                ),
              ],
            ),
          ),
          const Padding(
            padding:
                EdgeInsets.fromLTRB(
              8,
              28,
              8,
              0,
            ),
            child:
                Icon(
              Icons
                  .arrow_right_alt_rounded,
              color:
                  Colors.grey,
            ),
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Đến ngày',
                  style:
                      TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize:
                        12,
                  ),
                ),
                const SizedBox(
                  height:
                      4,
                ),
                _buildDateButton(
                  _toDate,
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DANH SÁCH NGÀY
  // =========================================================

  Widget _buildDanhSachNgay() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child:
                  Text(
                'Chi tiết từng ngày (${_danhSachNgay.length})',
                style:
                    const TextStyle(
                  fontSize:
                      15,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            if (_danhSachNgay
                    .length >
                1)
              TextButton.icon(
                onPressed:
                    _resetDateRange,
                icon:
                    const Icon(
                  Icons
                      .restart_alt_rounded,
                  color:
                      Colors.redAccent,
                  size:
                      18,
                ),
                label:
                    const Text(
                  'Reset',
                  style:
                      TextStyle(
                    color:
                        Colors.redAccent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(
          height:
              8,
        ),
        ..._danhSachNgay
            .asMap()
            .entries
            .map(
          (
            entry,
          ) {
            final int index =
                entry.key;

            final item =
                entry.value;

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom:
                    12,
              ),
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border:
                    Border.all(
                  color:
                      Colors.grey.shade200,
                ),
              ),
              child:
                  Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius:
                            14,
                        backgroundColor:
                            primaryColor.withOpacity(
                          0.10,
                        ),
                        child:
                            const Icon(
                          Icons
                              .event_rounded,
                          color:
                              primaryColor,
                          size:
                              16,
                        ),
                      ),
                      const SizedBox(
                        width:
                            8,
                      ),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(
                          item.ngayNghi,
                        ),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize:
                              15,
                        ),
                      ),
                      const Spacer(),
                      if (_danhSachNgay
                              .length >
                          1)
                        IconButton(
                          onPressed:
                              () {
                            setState(() {
                              _danhSachNgay
                                  .removeAt(
                                index,
                              );
                            });
                          },
                          visualDensity:
                              VisualDensity.compact,
                          icon:
                              const Icon(
                            Icons
                                .close_rounded,
                            color:
                                Colors.redAccent,
                            size:
                                20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height:
                        10,
                  ),
                  InkWell(
                    onTap:
                        () {
                      _showKyHieuSearchSheet(
                        index,
                      );
                    },
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    child:
                        Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal:
                            12,
                        vertical:
                            12,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade50,
                        border:
                            Border.all(
                          color:
                              Colors.grey.shade300,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),
                      child:
                          Row(
                        children: [
                          Expanded(
                            child:
                                Text(
                              item.tenKyHieu
                                          ?.trim()
                                          .isNotEmpty ==
                                      true
                                  ? item.tenKyHieu!
                                  : 'Chọn loại nghỉ',
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontSize:
                                    14,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons
                                .arrow_drop_down_rounded,
                            color:
                                Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // BOTTOM BUTTON
  // =========================================================

  Widget _buildBottomButton(
    ChamCongPhepProvider provider,
  ) {
    final bool disabled =
        _isSubmitting ||
            provider
                .listNguoiDuyet
                .isEmpty;

    return Container(
      padding:
          EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 +
            MediaQuery.of(
              context,
            ).padding.bottom,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.05,
            ),
            blurRadius:
                10,
            offset:
                const Offset(
              0,
              -5,
            ),
          ),
        ],
      ),
      child:
          SizedBox(
        width:
            double.infinity,
        child:
            ElevatedButton(
          onPressed:
              disabled
                  ? null
                  : _submitForm,
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                primaryColor,
            foregroundColor:
                Colors.white,
            disabledBackgroundColor:
                Colors.grey.shade300,
            padding:
                const EdgeInsets.symmetric(
              vertical:
                  16,
            ),
            elevation:
                0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                      width:
                          22,
                      height:
                          22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2.5,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons
                              .send_rounded,
                        ),
                        SizedBox(
                          width:
                              8,
                        ),
                        Text(
                          'Gửi đơn xin nghỉ',
                          style:
                              TextStyle(
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // =========================================================
  // TITLE
  // =========================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        left:
            4,
        bottom:
            10,
      ),
      child:
          Text(
        title,
        style:
            const TextStyle(
          fontSize:
              16,
          fontWeight:
              FontWeight.w800,
          color:
              Colors.black87,
        ),
      ),
    );
  }

  // =========================================================
  // INPUT
  // =========================================================

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText:
          hint,
      prefixIcon:
          Icon(
        icon,
        color:
            Colors.grey.shade400,
      ),
      filled:
          true,
      fillColor:
          Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal:
            16,
        vertical:
            14,
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        borderSide:
            const BorderSide(
          color:
              primaryColor,
          width:
              1.5,
        ),
      ),
    );
  }

  // =========================================================
  // DATE BUTTON
  // =========================================================

  Widget _buildDateButton(
    DateTime date,
    bool isFrom,
  ) {
    return InkWell(
      onTap:
          () {
        _showCupertinoDatePicker(
          date,
          isFrom,
        );
      },
      borderRadius:
          BorderRadius.circular(
        12,
      ),
      child:
          Container(
        padding:
            const EdgeInsets.symmetric(
          vertical:
              14,
          horizontal:
              10,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.grey.shade50,
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          border:
              Border.all(
            color:
                Colors.grey.shade200,
          ),
        ),
        child:
            Row(
          children: [
            Expanded(
              child:
                  Text(
                DateFormat(
                  'dd/MM/yyyy',
                ).format(
                  date,
                ),
                style:
                    const TextStyle(
                  fontSize:
                      13,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons
                  .calendar_month_rounded,
              size:
                  18,
              color:
                  primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// BOTTOM SHEET CHỌN KÝ HIỆU
//
// STATEFULWIDGET RIÊNG.
// Controller được dispose đúng lifecycle của Flutter.
// ===========================================================

class _KyHieuSearchSheet
    extends StatefulWidget {
  final List<
          ChamCongPhepKyHieuResponseDto>
      listKyHieu;

  final String
      currentKyHieuId;

  const _KyHieuSearchSheet({
    required this.listKyHieu,
    required this.currentKyHieuId,
  });

  @override
  State<_KyHieuSearchSheet>
      createState() =>
          _KyHieuSearchSheetState();
}

class _KyHieuSearchSheetState
    extends State<_KyHieuSearchSheet> {
  static const Color primaryColor =
      Color(0xFF1274BC);

  late final TextEditingController
      _searchController;

  late List<
          ChamCongPhepKyHieuResponseDto>
      _filteredList;

  @override
  void initState() {
    super.initState();

    _searchController =
        TextEditingController();

    _filteredList =
        List<
            ChamCongPhepKyHieuResponseDto>.from(
      widget.listKyHieu,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  void _search(
    String value,
  ) {
    final query =
        value
            .trim()
            .toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredList =
            List<
                ChamCongPhepKyHieuResponseDto>.from(
          widget.listKyHieu,
        );

        return;
      }

      _filteredList =
          widget.listKyHieu
              .where(
        (item) {
          final ma =
              (item.kyHieu ??
                      '')
                  .toLowerCase();

          final ten =
              (item.tenLoaiCong ??
                      '')
                  .toLowerCase();

          return ma.contains(
                query,
              ) ||
              ten.contains(
                query,
              );
        },
      ).toList();
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height:
          MediaQuery.of(context)
                  .size
                  .height *
              0.75,
      decoration:
          const BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            20,
          ),
        ),
      ),
      child:
          Column(
        children: [
          Container(
            margin:
                const EdgeInsets.only(
              top:
                  10,
              bottom:
                  5,
            ),
            width:
                40,
            height:
                5,
            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade300,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
          ),
          const Padding(
            padding:
                EdgeInsets.all(
              12,
            ),
            child:
                Text(
              'Chọn loại nghỉ',
              style:
                  TextStyle(
                fontSize:
                    18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  16,
              vertical:
                  8,
            ),
            child:
                TextField(
              controller:
                  _searchController,
              onChanged:
                  _search,
              decoration:
                  InputDecoration(
                hintText:
                    'Tìm theo tên hoặc mã...',
                prefixIcon:
                    const Icon(
                  Icons
                      .search_rounded,
                ),
                filled:
                    true,
                fillColor:
                    Colors.grey.shade100,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _filteredList.isEmpty
                    ? const Center(
                        child:
                            Text(
                          'Không tìm thấy kết quả',
                        ),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.only(
                          bottom:
                              20,
                        ),
                        itemCount:
                            _filteredList.length,
                        separatorBuilder:
                            (
                          _,
                          __,
                        ) =>
                                Divider(
                          height:
                              1,
                          color:
                              Colors.grey.shade200,
                        ),
                        itemBuilder:
                            (
                          context,
                          index,
                        ) {
                          final item =
                              _filteredList[index];

                          final bool
                              selected =
                              item.kyHieu ==
                                  widget.currentKyHieuId;

                          return ListTile(
                            leading:
                                CircleAvatar(
                              backgroundColor:
                                  selected
                                      ? primaryColor.withOpacity(
                                          0.10,
                                        )
                                      : Colors.grey.shade100,
                              child:
                                  Text(
                                item.kyHieu ??
                                    '',
                                style:
                                    TextStyle(
                                  color:
                                      selected
                                          ? primaryColor
                                          : Colors.grey.shade600,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                            title:
                                Text(
                              item.tenLoaiCong ??
                                  '',
                              style:
                                  TextStyle(
                                color:
                                    selected
                                        ? primaryColor
                                        : Colors.black87,
                                fontWeight:
                                    selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            trailing:
                                selected
                                    ? const Icon(
                                        Icons
                                            .check_circle_rounded,
                                        color:
                                            primaryColor,
                                      )
                                    : null,
                            onTap:
                                () {
                              Navigator.of(
                                context,
                              ).pop(
                                item,
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}