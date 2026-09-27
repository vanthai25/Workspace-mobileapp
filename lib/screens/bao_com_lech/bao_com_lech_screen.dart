import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/bao_com_lech_model.dart';
import '../../providers/bao_com_lech_provider.dart';
import '../../utils/helpers.dart';
import 'bao_com_lech_phan_hoi_screen.dart';

class BaoComLechScreen
    extends StatefulWidget {
  const BaoComLechScreen({
    super.key,
  });

  @override
  State<BaoComLechScreen>
      createState() =>
          _BaoComLechScreenState();
}

class _BaoComLechScreenState
    extends State<BaoComLechScreen> {
  final Color primaryColor =
      const Color(0xFF1274BC);

  final NumberFormat moneyFormat =
      NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      context
          .read<
              BaoComLechProvider>()
          .fetchData();
    });
  }

  String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return '';
    }

    return DateFormat(
      'dd/MM/yyyy',
    ).format(
      date,
    );
  }

  String _formatDateTime(
    DateTime? date,
  ) {
    if (date == null) {
      return '';
    }

    return DateFormat(
      'HH:mm - dd/MM/yyyy',
    ).format(
      date,
    );
  }

  // =========================================================
  // STATUS
  // =========================================================

  Color _statusColor(
    int status,
  ) {
    switch (status) {
      case 0:
        return Colors.blueGrey;

      case 1:
        return Colors.orange;

      case 2:
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(
    int status,
  ) {
    switch (status) {
      case 0:
        return Icons
            .edit_note_rounded;

      case 1:
        return Icons
            .schedule_rounded;

      case 2:
        return Icons
            .verified_rounded;

      default:
        return Icons
            .help_outline;
    }
  }

  // =========================================================
  // MONTH SELECTOR
  // =========================================================

  Widget _buildMonthSelector(
    BaoComLechProvider provider,
  ) {
    return Container(
      color: Colors.white,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),

      child: Row(
        children: [
          IconButton(
            onPressed:
                provider.isLoading
                    ? null
                    : () {
                        provider
                            .changeMonth(
                          -1,
                        );
                      },

            icon: Icon(
              Icons
                  .chevron_left_rounded,
              color:
                  primaryColor,
            ),
          ),

          Expanded(
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 11,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF1F7FC,
                ),

                borderRadius:
                    BorderRadius
                        .circular(
                  12,
                ),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [
                  Icon(
                    Icons
                        .calendar_month_rounded,
                    size: 19,
                    color:
                        primaryColor,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    'Tháng '
                    '${provider.selectedMonth}'
                    ' / '
                    '${provider.selectedYear}',

                    style:
                        TextStyle(
                      color:
                          primaryColor,

                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          IconButton(
            onPressed:
                !provider.canGoNext ||
                        provider.isLoading
                    ? null
                    : () {
                        provider
                            .changeMonth(
                          1,
                        );
                      },

            icon: Icon(
              Icons
                  .chevron_right_rounded,

              color:
                  provider.canGoNext
                      ? primaryColor
                      : Colors
                          .grey
                          .shade300,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // OPEN FORM
  // =========================================================

  Future<void> _openPhanHoi(
    BaoComLechModel item,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BaoComLechPhanHoiScreen(
          item: item,
        ),
      ),
    );
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> _deletePhanHoi(
    BaoComLechModel item,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext context,
      ) {
        return AlertDialog(
          title:
              const Text(
            'Xóa phản hồi',
          ),

          content:
              const Text(
            'Bạn chắc chắn muốn '
            'xóa phản hồi này?\n\n'
            'Sau khi xóa, trạng thái sẽ '
            'trở về "Tạo mới".',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'HỦY',
              ),
            ),

            ElevatedButton(
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    Colors.red,

                foregroundColor:
                    Colors.white,
              ),

              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  const Text(
                'XÓA',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    final BaoComLechProvider
        provider =
        context.read<
            BaoComLechProvider>();

    final bool success =
        await provider
            .deletePhanHoi(
      item.id,
    );

    if (!mounted) {
      return;
    }

    AppHelpers.showSnackBar(
      success
          ? 'Xóa phản hồi thành công.'
          : provider.errorMessage ??
              'Không thể xóa phản hồi.',
      isError: !success,
    );
  }

  // =========================================================
  // VIEW IMAGE
  // =========================================================

  Future<void> _showImage(
    BaoComLechModel item,
  ) async {
    final Future<Uint8List?> future =
        context
            .read<
                BaoComLechProvider>()
            .getHinhAnh(
      item.id,
    );

    await showDialog(
      context: context,

      builder: (
        BuildContext context,
      ) {
        return Dialog(
          child: FutureBuilder<
              Uint8List?>(
            future: future,

            builder: (
              BuildContext context,
              AsyncSnapshot<
                      Uint8List?>
                  snapshot,
            ) {
              if (snapshot
                      .connectionState !=
                  ConnectionState.done) {
                return const SizedBox(
                  height: 300,

                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.data ==
                  null) {
                return const Padding(
                  padding:
                      EdgeInsets.all(
                    30,
                  ),

                  child: Text(
                    'Không tải được ảnh.',
                  ),
                );
              }

              return InteractiveViewer(
                child: Image.memory(
                  snapshot.data!,

                  fit:
                      BoxFit.contain,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _buildCard(
    BaoComLechModel item,
  ) {
    final Color statusColor =
        _statusColor(
      item.keToanDuyet,
    );

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        14,
        7,
        14,
        7,
      ),

      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withOpacity(
              0.04,
            ),

            blurRadius: 10,

            offset:
                const Offset(
              0,
              3,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          // ===============================================
          // HEADER
          // ===============================================

          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      statusColor
                          .withOpacity(
                    0.09,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),

                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Icon(
                      _statusIcon(
                        item.keToanDuyet,
                      ),

                      size: 15,

                      color:
                          statusColor,
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Text(
                      item.trangThaiText,

                      style:
                          TextStyle(
                        color:
                            statusColor,

                        fontWeight:
                            FontWeight
                                .bold,

                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Text(
                _formatDate(
                  item.ngayLech,
                ),

                style:
                    TextStyle(
                  color: Colors
                      .grey
                      .shade600,

                  fontSize: 13,

                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ===============================================
          // NỘI DUNG
          // ===============================================

          Text(
            item.noiDung ??
                'Không có nội dung.',

            style:
                const TextStyle(
              fontSize: 15,

              fontWeight:
                  FontWeight.w600,

              height: 1.4,
            ),
          ),

          if (item.soTien !=
              null) ...[
            const SizedBox(
              height: 9,
            ),

            Row(
              children: [
                Icon(
                  Icons
                      .payments_outlined,

                  size: 17,

                  color:
                      Colors.grey
                          .shade600,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  'Số tiền: '
                  '${moneyFormat.format(item.soTien)}',

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ],
            ),
          ],

          if (item.ghiChu !=
                  null &&
              item.ghiChu!
                  .isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            Text(
              'Ghi chú: '
              '${item.ghiChu}',

              style:
                  TextStyle(
                color: Colors
                    .grey.shade600,

                fontSize: 13,
              ),
            ),
          ],

          // ===============================================
          // PHẢN HỒI
          // ===============================================

          if (item.phanHoi !=
                  null &&
              item.phanHoi!
                  .isNotEmpty) ...[
            const SizedBox(
              height: 15,
            ),

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets
                      .all(
                12,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF5F9FC,
                ),

                borderRadius:
                    BorderRadius
                        .circular(
                  12,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    'PHẢN HỒI CỦA BẠN',

                    style:
                        TextStyle(
                      color:
                          primaryColor,

                      fontSize: 12,

                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    item.phanHoi!,

                    style:
                        const TextStyle(
                      height:
                          1.4,
                    ),
                  ),

                  if (item
                          .ngayPhanHoi !=
                      null) ...[
                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      _formatDateTime(
                        item.ngayPhanHoi,
                      ),

                      style:
                          TextStyle(
                        color: Colors
                            .grey
                            .shade500,

                        fontSize:
                            12,
                      ),
                    ),
                  ],

                  if (item
                      .coHinhAnh)
                    TextButton.icon(
                      onPressed: () {
                        _showImage(
                          item,
                        );
                      },

                      icon:
                          const Icon(
                        Icons
                            .image_outlined,
                      ),

                      label:
                          const Text(
                        'Xem ảnh đính kèm',
                      ),
                    ),
                ],
              ),
            ),
          ],

          if (item.noiDungDuyet !=
                  null &&
              item.noiDungDuyet!
                  .isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            Text(
              'Kế toán: '
              '${item.noiDungDuyet}',

              style:
                  const TextStyle(
                color:
                    Colors.green,

                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],

          // ===============================================
          // BUTTON
          // ===============================================

          if (item.duocPhanHoi) ...[
            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton.icon(
                onPressed: () {
                  _openPhanHoi(
                    item,
                  );
                },

                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      primaryColor,

                  foregroundColor:
                      Colors.white,
                ),

                icon:
                    const Icon(
                  Icons
                      .reply_rounded,
                ),

                label:
                    const Text(
                  'PHẢN HỒI',
                ),
              ),
            ),
          ]

          else if (item
              .duocSuaXoa) ...[
            const SizedBox(
              height: 16,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton
                          .icon(
                    onPressed: () {
                      _openPhanHoi(
                        item,
                      );
                    },

                    icon:
                        const Icon(
                      Icons
                          .edit_outlined,
                    ),

                    label:
                        const Text(
                      'SỬA',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      OutlinedButton
                          .icon(
                    onPressed: () {
                      _deletePhanHoi(
                        item,
                      );
                    },

                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          Colors.red,
                    ),

                    icon:
                        const Icon(
                      Icons
                          .delete_outline,
                    ),

                    label:
                        const Text(
                      'XÓA',
                    ),
                  ),
                ),
              ],
            ),
          ],

          /*
           * KeToanDuyet == 2:
           * không render bất kỳ nút nào.
           */
        ],
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
        0xFFF4F7FB,
      ),

      appBar: AppBar(
        title:
            const Text(
          'Lệch báo cơm',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        backgroundColor:
            primaryColor,

        foregroundColor:
            Colors.white,

        centerTitle: true,
      ),

      body:
          Consumer<
              BaoComLechProvider>(
        builder: (
          BuildContext context,
          BaoComLechProvider provider,
          Widget? child,
        ) {
          return Column(
            children: [
              _buildMonthSelector(
                provider,
              ),

              Expanded(
                child:
                    provider.isLoading
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
                            ? Center(
                                child:
                                    Padding(
                                  padding:
                                      const EdgeInsets
                                          .all(
                                    25,
                                  ),

                                  child:
                                      Column(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,

                                    children: [
                                      Text(
                                        provider
                                            .errorMessage!,

                                        textAlign:
                                            TextAlign
                                                .center,
                                      ),

                                      TextButton.icon(
                                        onPressed:
                                            provider
                                                .fetchData,

                                        icon:
                                            const Icon(
                                          Icons
                                              .refresh,
                                        ),

                                        label:
                                            const Text(
                                          'Thử lại',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )

                            : provider
                                    .items
                                    .isEmpty
                                ? RefreshIndicator(
                                    onRefresh:
                                        provider
                                            .refresh,

                                    child:
                                        ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),

                                      children: [
                                        const SizedBox(
                                          height:
                                              120,
                                        ),

                                        Icon(
                                          Icons
                                              .restaurant_menu_outlined,

                                          size:
                                              65,

                                          color: Colors
                                              .grey
                                              .shade300,
                                        ),

                                        const SizedBox(
                                          height:
                                              15,
                                        ),

                                        Text(
                                          'Không có dữ liệu lệch cơm '
                                          'tháng ${provider.selectedMonth}'
                                          '/${provider.selectedYear}',

                                          textAlign:
                                              TextAlign.center,

                                          style:
                                              TextStyle(
                                            color: Colors
                                                .grey
                                                .shade600,

                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )

                                : RefreshIndicator(
                                    onRefresh:
                                        provider
                                            .refresh,

                                    child:
                                        ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),

                                      padding:
                                          const EdgeInsets.only(
                                        top:
                                            7,
                                        bottom:
                                            30,
                                      ),

                                      itemCount:
                                          provider
                                              .items
                                              .length,

                                      itemBuilder:
                                          (
                                        BuildContext context,
                                        int index,
                                      ) {
                                        return _buildCard(
                                          provider
                                              .items[index],
                                        );
                                      },
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