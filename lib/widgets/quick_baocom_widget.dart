import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/baocom_model.dart';
import '../models/baocom_menu.dart';
import '../providers/auth_provider.dart';
import '../services/baocom_service.dart';

class QuickBaoComWidget extends StatefulWidget {
  final BaoCom? preloadedMeal;
  final BaoComMenu? preloadedMenu;

  final VoidCallback onRefreshNeeded;

  final int baoComLechCount;

  /// Mở màn hình Lệch cơm.
  final VoidCallback? onBaoComLechTap;

  const QuickBaoComWidget({
    super.key,
    this.preloadedMeal,
    this.preloadedMenu,
    required this.onRefreshNeeded,
    this.baoComLechCount = 0,
    this.onBaoComLechTap,
  });

  @override
  State<QuickBaoComWidget> createState() =>
      _QuickBaoComWidgetState();
}

class _QuickBaoComWidgetState
    extends State<QuickBaoComWidget> {
  final BaoComService _apiService =
      BaoComService();

  bool _isTrua = false;
  bool _isToi = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _isTrua =
        widget.preloadedMeal?.ansang ??
            false;

    _isToi =
        widget.preloadedMeal?.anchieu ??
            false;
  }

  @override
  void didUpdateWidget(
    QuickBaoComWidget oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.preloadedMeal !=
        oldWidget.preloadedMeal) {
      _isTrua =
          widget.preloadedMeal?.ansang ??
              false;

      _isToi =
          widget.preloadedMeal?.anchieu ??
              false;
    }
  }

  bool _isLocked() {
    return DateTime.now().hour >= 8;
  }

  // =========================================================
  // LƯU BÁO CƠM
  // =========================================================

  Future<void> _toggleMeal(
    bool isTruaToggle,
  ) async {
    if (_isLocked() || _isSaving) {
      return;
    }

    final auth =
        context.read<AuthProvider>();

    final String currentUserMaNV =
        auth.currentManv ?? '';

    final String currentUserTenNV =
        auth.currentTenNV ?? '';

    final String currentUserMaKhoa =
        auth.currentMaKhoa ?? '';

    final bool newTrua =
        isTruaToggle
            ? !_isTrua
            : _isTrua;

    final bool newToi =
        !isTruaToggle
            ? !_isToi
            : _isToi;

    setState(() {
      _isSaving = true;

      _isTrua = newTrua;
      _isToi = newToi;
    });

    final bool isUpdate =
        widget.preloadedMeal != null;

    final String action =
        isUpdate
            ? 'Update'
            : 'Insert';

    final String currentActionTime =
        DateFormat(
      'dd/MM/yyyy HH:mm:ss',
    ).format(
      DateTime.now(),
    );

    final String truaStr =
        newTrua
            ? 'Có'
            : 'Không';

    final String toiStr =
        newToi
            ? 'Có'
            : 'Không';

    final String generatedGhiChu =
        '$currentUserMaNV - '
        '$currentUserTenNV '
        '|$action| '
        '$currentActionTime '
        '| Trưa: $truaStr, '
        'Tối: $toiStr';

    final DateTime today =
        DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final BaoCom submitData =
        BaoCom(
      id: widget.preloadedMeal?.id,

      manv: currentUserMaNV,

      tennv: currentUserTenNV,

      makhoa: currentUserMaKhoa,

      nguoibao: currentUserMaNV,

      ngaybaocom: isUpdate
          ? widget
              .preloadedMeal!
              .ngaybaocom
          : today.toIso8601String(),

      ansang: newTrua,

      anchieu: newToi,

      ghichu: generatedGhiChu,

      mamaubaocom: 0,
    );

    try {
      final bool success =
          isUpdate
              ? await _apiService
                  .updateBaoCom(
                  submitData,
                )
              : await _apiService
                  .createBaoCom(
                  submitData,
                );

      if (!success) {
        throw Exception(
          'Lỗi server',
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
              ),

              SizedBox(
                width: 8,
              ),

              Text(
                'Đã lưu suất ăn thành công!',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          backgroundColor:
              Colors.green,
          duration:
              Duration(
            seconds: 2,
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      widget.onRefreshNeeded();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isTrua =
            widget
                    .preloadedMeal
                    ?.ansang ??
                false;

        _isToi =
            widget
                    .preloadedMeal
                    ?.anchieu ??
                false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Lỗi mạng, chưa lưu được!',
          ),
          backgroundColor:
              Colors.red,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =========================================================
  // POPUP MENU
  // =========================================================

  void _showMenuPopup() {
    final BaoComMenu? menu =
        widget.preloadedMenu;

    final String dateStr =
        DateFormat(
      'dd/MM/yyyy',
    ).format(
      DateTime.now(),
    );

    showGeneralDialog(
      context: context,

      barrierDismissible: true,

      barrierLabel:
          'MenuPopup',

      barrierColor:
          Colors.black.withOpacity(
        0.5,
      ),

      transitionDuration:
          const Duration(
        milliseconds: 300,
      ),

      pageBuilder: (
        context,
        animation,
        secondaryAnimation,
      ) {
        return Center(
          child: Container(
            margin:
                const EdgeInsets
                    .symmetric(
              horizontal: 24,
            ),

            padding:
                const EdgeInsets.all(
              24,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.white,

              borderRadius:
                  BorderRadius
                      .circular(
                24,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(
                    0.2,
                  ),

                  blurRadius: 20,

                  offset:
                      const Offset(
                    0,
                    10,
                  ),
                ),
              ],
            ),

            child: Material(
              color:
                  Colors.transparent,

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,

                    children: [
                      const Icon(
                        Icons
                            .restaurant_menu_rounded,

                        color:
                            Color(
                          0xFF1274BC,
                        ),

                        size: 28,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Flexible(
                        child: Text(
                          'Thực Đơn '
                          '$dateStr',

                          textAlign:
                              TextAlign
                                  .center,

                          style:
                              const TextStyle(
                            fontSize: 18,

                            fontWeight:
                                FontWeight
                                    .w900,

                            color:
                                Color(
                              0xFF1274BC,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  if (menu == null)
                    Column(
                      children: [
                        Icon(
                          Icons
                              .no_meals_rounded,

                          size: 50,

                          color: Colors
                              .grey
                              .shade300,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          'Chưa cập nhật thực đơn',

                          style:
                              TextStyle(
                            color: Colors
                                .grey
                                .shade600,

                            fontSize: 15,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildMenuSection(
                      'Bữa Trưa',
                      Icons
                          .wb_sunny_rounded,
                      Colors.orange,
                      menu.menuTrua ??
                          'Chưa có',
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _buildMenuSection(
                      'Bữa Tối',
                      Icons
                          .nights_stay_rounded,
                      Colors.indigo,
                      menu.menuToi ??
                          'Chưa có',
                    ),
                  ],

                  const SizedBox(
                    height: 24,
                  ),

                  SizedBox(
                    width:
                        double.infinity,

                    height: 48,

                    child:
                        ElevatedButton(
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF1274BC,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),

                        elevation: 2,
                      ),

                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },

                      child:
                          const Text(
                        'Đóng',

                        style:
                            TextStyle(
                          color:
                              Colors.white,

                          fontWeight:
                              FontWeight
                                  .bold,

                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      transitionBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        final double curvedValue =
            Curves.easeOutBack
                .transform(
          animation.value,
        );

        return Transform.scale(
          scale:
              0.8 +
                  (
                    0.2 *
                        curvedValue
                  ),

          child: Opacity(
            opacity:
                animation.value,

            child:
                child,
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(
    String title,
    IconData icon,
    Color color,
    String content,
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
        color: color.withOpacity(
          0.05,
        ),

        border: Border.all(
          color: color.withOpacity(
            0.2,
          ),
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 22,
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                title,

                style:
                    TextStyle(
                  fontSize: 16,

                  fontWeight:
                      FontWeight.bold,

                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            content,

            style:
                const TextStyle(
              fontSize: 15,

              color:
                  Colors.black87,

              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NÚT MENU HEADER
  // =========================================================

  Widget _buildMenuButton() {
    return InkWell(
      onTap:
          _showMenuPopup,

      borderRadius:
          BorderRadius.circular(
        18,
      ),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),

        decoration:
            BoxDecoration(
          color: Colors
              .orange
              .shade50
              .withOpacity(
            0.7,
          ),

          border: Border.all(
            color: Colors
                .orange
                .shade200,

            width: 1.2,
          ),

          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),

        child: Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              Icons
                  .restaurant_menu_rounded,

              size: 14,

              color: Colors
                  .orange
                  .shade800,
            ),

            const SizedBox(
              width: 3,
            ),

            Text(
              'Menu',

              style:
                  TextStyle(
                color: Colors
                    .orange
                    .shade800,

                fontWeight:
                    FontWeight.bold,

                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NÚT LỆCH CƠM + BADGE
  // =========================================================

  Widget _buildBaoComLechButton() {
    final int count =
        widget.baoComLechCount;

    final String badgeText =
        count > 99
            ? '99+'
            : '$count';

    return Badge(
      isLabelVisible:
          count > 0,

      label: Text(
        badgeText,

        style:
            const TextStyle(
          color:
              Colors.white,

          fontSize: 9,

          fontWeight:
              FontWeight.bold,
        ),
      ),

      backgroundColor:
          Colors.redAccent,

      /*
       * Đẩy badge lên góc trên bên phải.
       */
      offset:
          const Offset(
        3,
        -6,
      ),

      child: InkWell(
        onTap:
            widget
                .onBaoComLechTap,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 5,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFF0F7FD,
            ),

            border:
                Border.all(
              color:
                  const Color(
                0xFF1274BC,
              ).withOpacity(
                0.25,
              ),

              width: 1.2,
            ),

            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),

          child: const Row(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                Icons
                    .difference_outlined,

                size: 14,

                color:
                    Color(
                  0xFF1274BC,
                ),
              ),

              SizedBox(
                width: 3,
              ),

              Text(
                'Lệch cơm',

                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF1274BC,
                  ),

                  fontWeight:
                      FontWeight.bold,

                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // NÚT TRƯA / TỐI
  // =========================================================

  Widget _buildMealToggle(
    bool isTrua,
    bool isSelected,
    bool locked,
  ) {
    final MaterialColor baseColor =
        isTrua
            ? Colors.orange
            : Colors.indigo;

    final IconData icon =
        isTrua
            ? Icons.wb_sunny_rounded
            : Icons
                .nights_stay_rounded;

    final String title =
        isTrua
            ? 'Ăn Trưa'
            : 'Ăn Tối';

    return GestureDetector(
      onTap:
          locked || _isSaving
              ? null
              : () {
                  _toggleMeal(
                    isTrua,
                  );
                },

      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),

        padding:
            const EdgeInsets.symmetric(
          vertical: 16,
        ),

        decoration:
            BoxDecoration(
          color: isSelected
              ? baseColor
                  .withOpacity(
                  0.1,
                )
              : locked
                  ? Colors
                      .grey
                      .shade100
                  : Colors.white,

          border:
              Border.all(
            color: isSelected
                ? baseColor
                : Colors
                    .grey
                    .shade300,

            width:
                isSelected
                    ? 2
                    : 1,
          ),

          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),

        child: Stack(
          clipBehavior:
              Clip.none,

          alignment:
              Alignment.center,

          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,

              children: [
                Icon(
                  icon,

                  size: 22,

                  color: isSelected
                      ? baseColor
                      : Colors.grey,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  title,

                  style:
                      TextStyle(
                    color: isSelected
                        ? baseColor
                            .shade800
                        : Colors
                            .grey
                            .shade600,

                    fontWeight:
                        FontWeight.bold,

                    fontSize: 15,
                  ),
                ),
              ],
            ),

            if (isSelected)
              Positioned(
                top: -12,
                right: -10,

                child: Icon(
                  Icons
                      .check_circle_rounded,

                  color:
                      baseColor,

                  size: 20,
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
    final bool locked =
        _isLocked();

    return Card(
      elevation: 6,

      shadowColor:
          Colors.black.withOpacity(
        0.1,
      ),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // =================================================
            // HEADER
            // =================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .center,

              children: [
                /*
                 * BÁO CƠM BÊN TRÁI
                 *
                 * Expanded để nhường chỗ cho
                 * Menu + Lệch cơm bên phải.
                 */
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restaurant,

                        color:
                            Color(
                          0xFF1274BC,
                        ),

                        size: 21,
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      Expanded(
                        child: Text(
                          'Báo cơm '
                          '(${DateFormat('dd/MM/yyyy').format(DateTime.now())})',

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 13,

                            fontWeight:
                                FontWeight
                                    .bold,

                            color:
                                Color(
                              0xFF2C3E50,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 5,
                ),

                /*
                 * MENU + LỆCH CƠM
                 */
                Row(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    _buildMenuButton(),

                    const SizedBox(
                      width: 5,
                    ),

                    _buildBaoComLechButton(),
                  ],
                ),
              ],
            ),

            const Divider(
              height: 20,
            ),

            // =================================================
            // TRƯA / TỐI
            // =================================================

            Row(
              children: [
                Expanded(
                  child:
                      _buildMealToggle(
                    true,
                    _isTrua,
                    locked,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      _buildMealToggle(
                    false,
                    _isToi,
                    locked,
                  ),
                ),
              ],
            ),

            // =================================================
            // LOADING
            // =================================================

            if (_isSaving) ...[
              const SizedBox(
                height: 16,
              ),

              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,

                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ]

            // =================================================
            // LOCK SAU 8H
            // =================================================

            else if (locked) ...[
              const SizedBox(
                height: 16,
              ),

              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                  10,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors
                      .orange
                      .shade50,

                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),

                  border:
                      Border.all(
                    color: Colors
                        .orange
                        .shade200,
                  ),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [
                    const Icon(
                      Icons.lock_clock,

                      color:
                          Colors.orange,

                      size: 18,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Flexible(
                      child: Text(
                        'Đã qua 8h00 sáng, '
                        'không thể thay đổi.',

                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          color: Colors
                              .orange
                              .shade800,

                          fontSize: 12,

                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
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
}