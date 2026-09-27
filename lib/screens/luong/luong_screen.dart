import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../models/luong_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/luong_provider.dart';
import '../../utils/helpers.dart';

class LuongScreen extends StatefulWidget {
  const LuongScreen({
    super.key,
  });

  @override
  State<LuongScreen> createState() =>
      _LuongScreenState();
}

class _LuongScreenState extends State<LuongScreen> {
  // =========================================================
  // MÀU SẮC
  // =========================================================

  final Color primaryColor =
      const Color(0xFF1274BC);

  final Color backgroundColor =
      const Color(0xFFF4F7FB);

  // =========================================================
  // FORMAT
  // =========================================================

  final NumberFormat _numberFormat =
      NumberFormat(
    '#,##0.##',
    'vi_VN',
  );

  final NumberFormat _moneyFormat =
      NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  // =========================================================
  // AUTH
  // =========================================================

  final LocalAuthentication _localAuth =
      LocalAuthentication();

  bool _showSalary = false;

  bool _isAuthenticatingSalary = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context
          .read<LuongProvider>()
          .fetchAll();
    });
  }

  // =========================================================
  // FORMAT VALUE
  // =========================================================

  String _formatNumber(
    double? value,
  ) {
    if (value == null) {
      return '';
    }

    final String text =
        _numberFormat.format(
      value.abs(),
    );

    if (value < 0) {
      return '($text)';
    }

    return text;
  }

  String _formatMoney(
    double? value,
  ) {
    if (value == null) {
      return '';
    }

    final String text =
        _moneyFormat.format(
      value.abs(),
    );

    if (value < 0) {
      return '($text)';
    }

    return text;
  }

  String _hiddenValue() {
    return '••••••••';
  }

  String _displayMoney(
    double? value,
  ) {
    if (!_showSalary) {
      return _hiddenValue();
    }

    return _formatMoney(
      value,
    );
  }

  String _displayFieldValue(
    LuongFieldModel field,
  ) {
    if (!_showSalary) {
      return _hiddenValue();
    }

    if (_isNonMoneyField(
      field.fieldName,
    )) {
      return _formatNumber(
        field.giaTri,
      );
    }

    return _formatMoney(
      field.giaTri,
    );
  }

  bool _isNonMoneyField(
    String fieldName,
  ) {
    const Set<String> fields = {
      'cong',
      'conglamtruccangay',
      'congtinhphucapngay',
      'congdilamtrucngayc',
      'congc',
    };

    return fields.contains(
      fieldName
          .trim()
          .toLowerCase(),
    );
  }

  // =========================================================
  // SECTION STYLE
  // =========================================================

  IconData _getSectionIcon(
    String maNhom,
  ) {
    switch (maNhom.toUpperCase()) {
      case 'KHOAN_CONG':
        return Icons
            .add_circle_outline_rounded;

      case 'KHOAN_TRU':
        return Icons
            .remove_circle_outline_rounded;

      case 'LUONG_CHI_TIET':
      default:
        return Icons
            .receipt_long_rounded;
    }
  }

  Color _getSectionColor(
    String maNhom,
  ) {
    switch (maNhom.toUpperCase()) {
      case 'KHOAN_CONG':
        return const Color(
          0xFF20985D,
        );

      case 'KHOAN_TRU':
        return const Color(
          0xFFD94C4C,
        );

      case 'LUONG_CHI_TIET':
      default:
        return primaryColor;
    }
  }

  // =========================================================
  // AUTH - LUỒNG GIỐNG DUTRU DETAIL
  // =========================================================

  Future<void>
      _handleSalaryVisibility() async {
    /*
     * Đang hiện -> chỉ cần ẩn.
     */
    if (_showSalary) {
      setState(() {
        _showSalary = false;
      });

      return;
    }

    if (_isAuthenticatingSalary) {
      return;
    }

    setState(() {
      _isAuthenticatingSalary = true;
    });

    try {
      final bool authenticated =
          await _xacThucXemLuong();

      if (!mounted) {
        return;
      }

      if (authenticated) {
        setState(() {
          _showSalary = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticatingSalary =
              false;
        });
      }
    }
  }

  Future<bool>
      _xacThucXemLuong() async {
    final AuthProvider authProvider =
        context.read<AuthProvider>();

    bool processWithPassword = false;

    /*
     * ===============================
     * 1. SINH TRẮC HỌC
     * ===============================
     */
    try {
      final bool supported =
          await authProvider
              .isBiometricSupported();

      if (supported) {
        try {
          final bool didAuthenticate =
              await _localAuth.authenticate(
            localizedReason:
                'Vui lòng xác thực sinh trắc học '
                'để xem thông tin lương',
            biometricOnly: true,
          );

          if (didAuthenticate) {
            return true;
          }

          processWithPassword = true;
        } catch (e) {
          debugPrint(
            '[LUONG AUTH] '
            'Biometric error: $e',
          );

          processWithPassword = true;
        }
      } else {
        processWithPassword = true;
      }
    } catch (e) {
      debugPrint(
        '[LUONG AUTH] '
        'Check biometric error: $e',
      );

      processWithPassword = true;
    }

    /*
     * ===============================
     * 2. FALLBACK MẬT KHẨU
     * ===============================
     */
    if (!processWithPassword) {
      return false;
    }

    final String? password =
        await _yeuCauNhapMatKhauThayThe();

    if (!mounted) {
      return false;
    }

    if (password == null ||
        password.isEmpty) {
      AppHelpers.showSnackBar(
        'Đã hủy xác thực!',
        isError: true,
      );

      return false;
    }

    /*
     * Hiện loading giống DuTruDetailScreen.
     */
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(
        child: CircularProgressIndicator(
          color: Color(
            0xFF1274BC,
          ),
        ),
      ),
    );

    try {
      final String manv =
          authProvider.currentManv ??
              '';

      if (manv.isEmpty) {
        if (mounted) {
          Navigator.pop(context);

          AppHelpers.showSnackBar(
            'Không xác định được '
            'tài khoản đăng nhập!',
            isError: true,
          );
        }

        return false;
      }

      /*
       * GIỐNG DUTRU DETAIL.
       */
      final bool isPassCorrect =
          await authProvider.login(
        manv,
        password,
      );

      if (mounted) {
        Navigator.pop(context);
      }

      if (!isPassCorrect) {
        if (mounted) {
          AppHelpers.showSnackBar(
            'Mật khẩu xác thực '
            'không đúng!',
            isError: true,
          );
        }

        return false;
      }

      return true;
    } catch (e) {
      debugPrint(
        '[LUONG AUTH] '
        'Password error: $e',
      );

      if (mounted) {
        Navigator.pop(context);

        AppHelpers.showSnackBar(
          'Mật khẩu không chính xác '
          'hoặc lỗi kết nối!',
          isError: true,
        );
      }

      return false;
    }
  }

  Future<String?>
      _yeuCauNhapMatKhauThayThe() {
    final TextEditingController
        pwdController =
        TextEditingController();

    bool isVisible = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setStateSB,
          ) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),

              title:
                  const Text(
                'Xác thực mật khẩu',
                style: TextStyle(
                  color:
                      Color(
                    0xFF1274BC,
                  ),
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              content: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Text(
                    'Sinh trắc học thất bại '
                    'hoặc bị hủy. '
                    'Vui lòng nhập mật khẩu '
                    'tài khoản để xem '
                    'thông tin lương!',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  TextField(
                    controller:
                        pwdController,
                    obscureText:
                        !isVisible,
                    autofocus: true,
                    textInputAction:
                        TextInputAction
                            .done,

                    onSubmitted:
                        (
                      String value,
                    ) {
                      if (value
                          .trim()
                          .isEmpty) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        value,
                      );
                    },

                    decoration:
                        InputDecoration(
                      labelText:
                          'Mật khẩu',

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),

                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          isVisible
                              ? Icons
                                  .visibility
                              : Icons
                                  .visibility_off,
                        ),
                        onPressed: () {
                          setStateSB(
                            () {
                              isVisible =
                                  !isVisible;
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text(
                    'HỦY',
                    style: TextStyle(
                      color:
                          Colors.grey,
                    ),
                  ),
                ),

                ElevatedButton(
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF1274BC,
                    ),
                  ),
                  onPressed: () {
                    final String
                        password =
                        pwdController
                            .text;

                    if (password
                        .trim()
                        .isEmpty) {
                      AppHelpers
                          .showSnackBar(
                        'Vui lòng nhập '
                        'mật khẩu!',
                        isError: true,
                      );

                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      password,
                    );
                  },
                  child:
                      const Text(
                    'XÁC NHẬN',
                    style: TextStyle(
                      color:
                          Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // MONTH PICKER
  // =========================================================

  Future<void>
      _showMonthPicker() async {
    final LuongProvider provider =
        context.read<LuongProvider>();

    int selectedYear =
        provider.selectedYear;

    final DateTime now =
        DateTime.now();

    final List<int> years =
        List<int>.generate(
      15,
      (
        int index,
      ) =>
          now.year - index,
    );

    final DateTime? result =
        await showModalBottomSheet<
            DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (
        BuildContext bottomContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setModalState,
          ) {
            return SafeArea(
              child: Container(
                margin:
                    const EdgeInsets.all(
                  12,
                ),
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFEAF4FC,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              11,
                            ),
                          ),
                          child: Icon(
                            Icons
                                .calendar_month_rounded,
                            color:
                                primaryColor,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        const Expanded(
                          child: Text(
                            'Chọn kỳ lương',
                            style:
                                TextStyle(
                              fontSize:
                                  18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: () {
                            Navigator.pop(
                              bottomContext,
                            );
                          },
                          icon:
                              const Icon(
                            Icons.close,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    DropdownButtonFormField<
                        int>(
                      value:
                          selectedYear,

                      decoration:
                          InputDecoration(
                        labelText:
                            'Năm',
                        filled: true,
                        fillColor:
                            backgroundColor,

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                          borderSide:
                              BorderSide
                                  .none,
                        ),
                      ),

                      items: years
                          .map(
                            (
                              int year,
                            ) =>
                                DropdownMenuItem<
                                    int>(
                              value:
                                  year,
                              child: Text(
                                'Năm $year',
                              ),
                            ),
                          )
                          .toList(),

                      onChanged:
                          (
                        int? year,
                      ) {
                        if (year ==
                            null) {
                          return;
                        }

                        setModalState(
                          () {
                            selectedYear =
                                year;
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,

                      physics:
                          const NeverScrollableScrollPhysics(),

                      crossAxisSpacing:
                          8,

                      mainAxisSpacing:
                          8,

                      childAspectRatio:
                          1.5,

                      children:
                          List.generate(
                        12,
                        (
                          int index,
                        ) {
                          final int month =
                              index + 1;

                          final bool
                              isFuture =
                              selectedYear >
                                      now.year ||
                                  (
                                    selectedYear ==
                                            now.year &&
                                    month >
                                        now.month
                                  );

                          final bool
                              isSelected =
                              selectedYear ==
                                      provider
                                          .selectedYear &&
                                  month ==
                                      provider
                                          .selectedMonth;

                          return InkWell(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),

                            onTap:
                                isFuture
                                    ? null
                                    : () {
                                        Navigator.pop(
                                          bottomContext,
                                          DateTime(
                                            selectedYear,
                                            month,
                                            1,
                                          ),
                                        );
                                      },

                            child:
                                Container(
                              decoration:
                                  BoxDecoration(
                                color:
                                    isSelected
                                        ? primaryColor
                                        : backgroundColor,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),

                                border:
                                    Border.all(
                                  color:
                                      isSelected
                                          ? primaryColor
                                          : Colors
                                              .grey
                                              .shade200,
                                ),
                              ),

                              child: Center(
                                child:
                                    Text(
                                  'T$month',
                                  style:
                                      TextStyle(
                                    color: isFuture
                                        ? Colors
                                            .grey
                                            .shade300
                                        : isSelected
                                            ? Colors.white
                                            : Colors.black87,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null &&
        mounted) {
      await provider.selectMonthYear(
        result,
      );
    }
  }

  // =========================================================
  // MONTH SELECTOR
  // =========================================================

  Widget _buildMonthSelector(
    LuongProvider provider,
  ) {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        6,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              0.035,
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

      child: Row(
        children: [
          IconButton(
            onPressed:
                provider.isLoading
                    ? null
                    : () async {
                      await provider
                          .changeMonth(
                        -1,
                      );
                    },

            icon: Icon(
              Icons
                  .chevron_left_rounded,
              color: primaryColor,
            ),
          ),

          Expanded(
            child: InkWell(
              onTap:
                  provider.isLoading
                      ? null
                      : _showMonthPicker,

              borderRadius:
                  BorderRadius.circular(
                14,
              ),

              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 12,
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
                    14,
                  ),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [
                    Icon(
                      Icons
                          .event_available_outlined,
                      color:
                          primaryColor,
                      size: 20,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Text(
                      'Tháng '
                      '${provider.selectedMonth} / '
                      '${provider.selectedYear}',

                      style:
                          TextStyle(
                        color:
                            primaryColor,

                        fontWeight:
                            FontWeight
                                .bold,

                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    Icon(
                      Icons
                          .keyboard_arrow_down_rounded,
                      color:
                          primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),

          IconButton(
            onPressed:
                !provider.canGoNext ||
                        provider.isLoading
                    ? null
                    : () async {
                    await provider
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
  // SUMMARY CARD
  // =========================================================

  Widget _buildSalarySummary(
    LuongThangModel data,
  ) {
    final LuongFieldModel? thuclinh =
        data.getField(
      'Thuclinh',
    );

    final LuongFieldModel? ckDot1 =
        data.getField(
      'CKdot1',
    );

    final LuongFieldModel? ckDot2 =
        data.getField(
      'CKdot2',
    );

    final LuongFieldModel? tienMat =
        data.getField(
      'Tienmat',
    );

    final List<_SalaryPaymentItem>
        paymentItems = [];

    /*
     * Null -> không có field
     * 0 -> vẫn có field.
     */
    if (ckDot1 != null) {
      paymentItems.add(
        _SalaryPaymentItem(
          label: 'CK đợt 1',
          value:
              ckDot1.giaTri,
        ),
      );
    }

    if (ckDot2 != null) {
      paymentItems.add(
        _SalaryPaymentItem(
          label: 'CK đợt 2',
          value:
              ckDot2.giaTri,
        ),
      );
    }

    if (tienMat != null) {
      paymentItems.add(
        _SalaryPaymentItem(
          label: 'Tiền mặt',
          value:
              tienMat.giaTri,
        ),
      );
    }

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ),

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              0.045,
            ),
            blurRadius: 12,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE8F4FC,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    15,
                  ),
                ),

                child: Icon(
                  Icons
                      .savings_outlined,

                  size: 31,

                  color:
                      primaryColor,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      'THỰC NHẬN',

                      style:
                          TextStyle(
                        color: Colors
                            .grey
                            .shade600,

                        fontSize: 14,

                        fontWeight:
                            FontWeight
                                .w600,

                        letterSpacing:
                            1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      thuclinh == null
                          ? '-'
                          : _displayMoney(
                              thuclinh
                                  .giaTri,
                            ),

                      style:
                          TextStyle(
                        fontSize: 27,

                        fontWeight:
                            FontWeight
                                .bold,

                        color:
                            _showSalary
                                ? primaryColor
                                : Colors
                                    .black87,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF6F7FA,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),
                ),

                child: IconButton(
                  tooltip:
                      _showSalary
                          ? 'Ẩn thông tin lương'
                          : 'Xem thông tin lương',

                  onPressed:
                      _isAuthenticatingSalary
                          ? null
                          : _handleSalaryVisibility,

                  icon:
                      _isAuthenticatingSalary
                          ? SizedBox(
                              width:
                                  21,

                              height:
                                  21,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,

                                color:
                                    primaryColor,
                              ),
                            )
                          : Icon(
                              _showSalary
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,

                              color: Colors
                                  .grey
                                  .shade700,
                            ),
                ),
              ),
            ],
          ),

          if (paymentItems
              .isNotEmpty) ...[
            const SizedBox(
              height: 20,
            ),

            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 16,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF8F8FC,
                ),

                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children:
                    List.generate(
                  paymentItems.length,
                  (
                    int index,
                  ) {
                    final item =
                        paymentItems[
                            index];

                    return Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 5,
                        ),

                        decoration:
                            BoxDecoration(
                          border:
                              index > 0
                                  ? Border(
                                      left:
                                          BorderSide(
                                        color: Colors
                                            .grey
                                            .shade200,
                                      ),
                                    )
                                  : null,
                        ),

                        child: Column(
                          children: [
                            Text(
                              item.label,

                              textAlign:
                                  TextAlign
                                      .center,

                              style:
                                  TextStyle(
                                color: Colors
                                    .grey
                                    .shade600,

                                fontSize:
                                    13,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              _displayMoney(
                                item.value,
                              ),

                              textAlign:
                                  TextAlign
                                      .center,

                              maxLines: 1,

                              overflow:
                                  TextOverflow
                                      .ellipsis,

                              style:
                                  const TextStyle(
                                fontSize:
                                    14,

                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // BIỂU ĐỒ
  // =========================================================

  List<LuongThucLinhThangModel>
      _normalizeChartData(
    LuongProvider provider,
  ) {
    final List<
            LuongThucLinhThangModel>
        result = [];

    for (int month = 1;
        month <= 12;
        month++) {
      LuongThucLinhThangModel?
          found;

      for (final item
          in provider.thongKeNam) {
        if (item.thang ==
            month) {
          found = item;
          break;
        }
      }

      result.add(
        found ??
            LuongThucLinhThangModel(
              thang: month,
              nam:
                  provider.selectedYear,
              thuclinh: null,
              coDuLieu: false,
            ),
      );
    }

    return result;
  }

  Widget _buildSalaryChart(
    LuongProvider provider,
  ) {
    final List<
            LuongThucLinhThangModel>
        chartData =
        _normalizeChartData(
      provider,
    );

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        7,
        16,
        8,
      ),

      padding:
          const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        16,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              0.035,
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
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEAF4FC,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),

                child: Icon(
                  Icons
                      .show_chart_rounded,

                  color:
                      primaryColor,

                  size: 22,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Text(
                  'Lương thực nhận '
                  '12 tháng - '
                  '${provider.selectedYear}',

                  style:
                      const TextStyle(
                    fontSize: 16,

                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          if (provider
              .isLoadingThongKe)
            SizedBox(
              height: 175,

              child: Center(
                child:
                    CircularProgressIndicator(
                  color:
                      primaryColor,
                ),
              ),
            )

          else if (provider
                  .thongKeErrorMessage !=
              null)
            _buildChartError(
              provider,
            )

          else if (!_showSalary)
            _buildLockedChart()

          else
            _buildSalaryBars(
              chartData,
              provider,
            ),
        ],
      ),
    );
  }

  Widget _buildLockedChart() {
    return SizedBox(
      height: 175,

      child: Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Container(
              width: 58,
              height: 58,

              decoration:
                  const BoxDecoration(
                color:
                    Color(
                  0xFFF6F7FA,
                ),

                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                Icons.lock_rounded,

                size: 30,

                color:
                    Colors.grey,
              ),
            ),

            const SizedBox(
              height: 13,
            ),

            Text(
              'Xác thực để xem '
              'biểu đồ lương',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color: Colors
                    .grey.shade600,

                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartError(
    LuongProvider provider,
  ) {
    return SizedBox(
      height: 175,

      child: Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              Icons
                  .error_outline_rounded,

              color:
                  Colors.orange
                      .shade700,

              size: 35,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              provider
                      .thongKeErrorMessage ??
                  'Không thể tải '
                      'biểu đồ lương.',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color: Colors
                    .grey.shade600,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            TextButton.icon(
              onPressed: () {
                provider
                    .fetchThongKeNam();
              },

              icon:
                  const Icon(
                Icons.refresh,
                size: 18,
              ),

              label:
                  const Text(
                'Tải lại',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryBars(
  List<LuongThucLinhThangModel> chartData,
  LuongProvider provider,
) {
  final bool hasData =
      chartData.any(
    (
      LuongThucLinhThangModel item,
    ) =>
        item.coDuLieu,
  );

  if (!hasData) {
    return SizedBox(
      height: 175,
      child: Center(
        child: Text(
          'Chưa có dữ liệu thống kê '
          'năm ${provider.selectedYear}.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  double maxValue = 0;

  for (final item in chartData) {
    final double value =
        item.thuclinh?.abs() ?? 0;

    if (value > maxValue) {
      maxValue = value;
    }
  }

  if (maxValue <= 0) {
    maxValue = 1;
  }

  final DateTime now =
      DateTime.now();

  return SizedBox(
    height: 205,
    child: Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,
      children: chartData.map(
        (
          LuongThucLinhThangModel item,
        ) {
          final bool selected =
              item.thang ==
                  provider.selectedMonth;

          /*
           * Không cho chọn tháng tương lai.
           *
           * Ví dụ hiện tại 08/2026:
           * T9 -> T12 sẽ bị khóa.
           */
          final bool isFuture =
              item.nam > now.year ||
              (
                item.nam == now.year &&
                item.thang > now.month
              );

          final double value =
              item.thuclinh?.abs() ?? 0;

          double barHeight = 6;

          if (item.coDuLieu) {
            barHeight =
                18 +
                (
                  value / maxValue
                ) *
                    120;
          }

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),

                /*
                 * Cho phép bấm cả tháng
                 * có dữ liệu và chưa có dữ liệu.
                 *
                 * Nếu chưa có bảng lương:
                 * provider.data sẽ null
                 * và màn hình hiện empty state.
                 */
                onTap: isFuture ||
                        provider.isLoading
                    ? null
                    : () async {
                        /*
                         * Nếu đang ở đúng tháng đó
                         * thì không cần gọi lại.
                         */
                        if (provider.selectedMonth ==
                                item.thang &&
                            provider.selectedYear ==
                                item.nam) {
                          return;
                        }

                        /*
                         * Đổi kỳ lương thì
                         * che lại thông tin.
                         */
                        await provider.selectMonthYear(
                          DateTime(
                            item.nam,
                            item.thang,
                            1,
                          ),
                        );
                      },

                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 1,
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      /*
                       * CỘT BIỂU ĐỒ
                       */
                      Expanded(
                        child: Align(
                          alignment:
                              Alignment
                                  .bottomCenter,
                          child: Tooltip(
                            message:
                                item.coDuLieu
                                    ? 'Tháng '
                                        '${item.thang}: '
                                        '${_formatMoney(item.thuclinh)}'
                                    : 'Tháng '
                                        '${item.thang}: '
                                        'Chưa có dữ liệu',
                            child:
                                AnimatedContainer(
                              duration:
                                  const Duration(
                                milliseconds:
                                    250,
                              ),
                              width: 17,
                              height:
                                  barHeight,
                              decoration:
                                  BoxDecoration(
                                color:
                                    isFuture
                                        ? Colors
                                            .grey
                                            .shade100
                                        : selected
                                            ? primaryColor
                                            : item
                                                    .coDuLieu
                                                ? const Color(
                                                    0xFFBBDDF3,
                                                  )
                                                : Colors
                                                    .grey
                                                    .shade200,
                                borderRadius:
                                    const BorderRadius
                                        .vertical(
                                  top:
                                      Radius.circular(
                                    8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      /*
                       * T1, T2, T3...
                       */
                      Text(
                        'T${item.thang}',
                        style: TextStyle(
                          fontSize: 11,

                          color:
                              isFuture
                                  ? Colors
                                      .grey
                                      .shade300
                                  : selected
                                      ? primaryColor
                                      : Colors
                                          .grey
                                          .shade600,

                          fontWeight:
                              selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ).toList(),
    ),
  );
}

  // =========================================================
  // CHI TIẾT
  // =========================================================

  Widget _buildSalaryDetails(
    LuongThangModel data,
  ) {
    const Set<String>
        summaryFields = {
      'thuclinh',
      'ckdot1',
      'ckdot2',
      'tienmat',
    };

    final List<Widget> result =
        [];

    for (final section
        in data.nhomLuong) {
      final List<LuongFieldModel>
          fields =
          section.duLieu.where(
        (
          LuongFieldModel field,
        ) {
          /*
           * Null không hiển thị.
           * 0 vẫn hiển thị.
           */
          if (field.giaTri ==
              null) {
            return false;
          }

          /*
           * Những field đã nằm
           * trên card tổng quan.
           */
          if (section.maNhom
                  .toUpperCase() ==
              'LUONG_CHI_TIET') {
            return !summaryFields
                .contains(
              field.fieldName
                  .trim()
                  .toLowerCase(),
            );
          }

          return true;
        },
      ).toList();

      if (fields.isEmpty) {
        continue;
      }

      result.add(
        _buildDetailSection(
          section,
          fields,
        ),
      );
    }

    if (result.isEmpty) {
      return const SizedBox
          .shrink();
    }

    return Column(
      children: result,
    );
  }

  Widget _buildDetailSection(
    LuongSectionModel section,
    List<LuongFieldModel> fields,
  ) {
    final Color sectionColor =
        _getSectionColor(
      section.maNhom,
    );

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        6,
        16,
        6,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              0.025,
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

      child: Theme(
        data: Theme.of(context)
            .copyWith(
          dividerColor:
              Colors.transparent,
        ),

        child: ExpansionTile(
          initiallyExpanded: false,

          tilePadding:
              const EdgeInsets
                  .symmetric(
            horizontal: 16,
            vertical: 3,
          ),

          childrenPadding:
              const EdgeInsets.only(
            bottom: 8,
          ),

          leading: Container(
            width: 42,
            height: 42,

            decoration:
                BoxDecoration(
              color:
                  sectionColor
                      .withOpacity(
                0.09,
              ),

              borderRadius:
                  BorderRadius
                      .circular(
                11,
              ),
            ),

            child: Icon(
              _getSectionIcon(
                section.maNhom,
              ),

              color:
                  sectionColor,

              size: 22,
            ),
          ),

          title: Text(
            section.tenNhom,

            style:
                const TextStyle(
              fontSize: 15,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          subtitle: Text(
            '${fields.length} khoản',

            style:
                TextStyle(
              fontSize: 12,

              color:
                  Colors.grey.shade500,
            ),
          ),

          children:
              List.generate(
            fields.length,
            (
              int index,
            ) {
              final LuongFieldModel
                  field =
                  fields[index];

              final bool
                  isNegative =
                  field.giaTri !=
                          null &&
                      field.giaTri! <
                          0;

              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,

                      indent: 18,

                      endIndent:
                          18,

                      color: Colors
                          .grey
                          .shade200,
                    ),

                  Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Expanded(
                          flex: 6,

                          child: Text(
                            field
                                    .textHienThi
                                    .trim()
                                    .isNotEmpty
                                ? field
                                    .textHienThi
                                : field
                                    .fieldName,

                            style:
                                TextStyle(
                              color: Colors
                                  .grey
                                  .shade700,

                              fontSize:
                                  14,

                              height:
                                  1.3,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          flex: 4,

                          child: Text(
                            _displayFieldValue(
                              field,
                            ),

                            textAlign:
                                TextAlign
                                    .right,

                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,

                              fontSize:
                                  14,

                              color:
                                  _showSalary &&
                                          isNegative
                                      ? const Color(
                                          0xFFD94C4C,
                                        )
                                      : Colors
                                          .black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _buildEmptyState(
    LuongProvider provider,
  ) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 85,
      ),

      children: [
        Icon(
          Icons
              .receipt_long_outlined,

          size: 68,

          color:
              Colors.grey.shade300,
        ),

        const SizedBox(
          height: 18,
        ),

        Text(
          'Chưa có dữ liệu lương '
          'tháng ${provider.selectedMonth}'
          '/${provider.selectedYear}',

          textAlign:
              TextAlign.center,

          style:
              TextStyle(
            fontSize: 16,

            fontWeight:
                FontWeight.w600,

            color:
                Colors.grey.shade600,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          'Kéo xuống để tải lại dữ liệu.',

          textAlign:
              TextAlign.center,

          style:
              TextStyle(
            fontSize: 13,

            color:
                Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildErrorState(
    LuongProvider provider,
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

              color: Colors.red,

              size: 56,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              provider.errorMessage ??
                  'Không thể tải '
                      'dữ liệu lương.',

              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 16,
            ),

            ElevatedButton.icon(
              onPressed: () {
                provider.fetchAll();
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
                Icons.refresh,
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

  // =========================================================
  // CONTENT
  // =========================================================

  Widget _buildContent(
    LuongProvider provider,
  ) {
    if (provider.isLoading &&
        provider.data == null) {
      return Center(
        child:
            CircularProgressIndicator(
          color:
              primaryColor,
        ),
      );
    }

    if (provider.errorMessage !=
            null &&
        provider.data == null) {
      return _buildErrorState(
        provider,
      );
    }

    final LuongThangModel? data =
        provider.data;

    /*
     * Không có bảng lương tháng đó:
     * giữ đúng empty state.
     */
    if (data == null) {
      return RefreshIndicator(
        color:
            primaryColor,

        onRefresh:
            provider.refresh,

        child:
            _buildEmptyState(
          provider,
        ),
      );
    }

    return RefreshIndicator(
      color:
          primaryColor,

      onRefresh:
          provider.refresh,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.only(
          bottom: 35,
        ),

        children: [
          /*
           * THỰC NHẬN
           */
          _buildSalarySummary(
            data,
          ),

          /*
           * BIỂU ĐỒ
           */
          _buildSalaryChart(
            provider,
          ),

          /*
           * HEADER CHI TIẾT
           */
          Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              18,
              18,
              18,
              7,
            ),

            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,

                  decoration:
                      BoxDecoration(
                    color:
                        primaryColor,

                    borderRadius:
                        BorderRadius
                            .circular(
                      4,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 9,
                ),

                Text(
                  'CHI TIẾT BẢNG LƯƠNG',

                  style:
                      TextStyle(
                    color: Colors
                        .grey
                        .shade700,

                    fontSize: 13,

                    fontWeight:
                        FontWeight
                            .bold,

                    letterSpacing:
                        0.9,
                  ),
                ),
              ],
            ),
          ),

          /*
           * NHÓM CHI TIẾT
           */
          _buildSalaryDetails(
            data,
          ),
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
          backgroundColor,

      appBar: AppBar(
        title:
            const Text(
          'Thông tin lương',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,

            fontSize: 18,
          ),
        ),

        backgroundColor:
            primaryColor,

        foregroundColor:
            Colors.white,

        elevation: 0,

        centerTitle: true,
      ),

      body:
          Consumer<LuongProvider>(
        builder: (
          BuildContext context,
          LuongProvider provider,
          Widget? child,
        ) {
          return Column(
            children: [
              /*
               * KỲ LƯƠNG
               */
              _buildMonthSelector(
                provider,
              ),

              /*
               * LOADING KHI ĐỔI THÁNG
               */
              if (provider.isLoading &&
                  provider.data !=
                      null)
                LinearProgressIndicator(
                  color:
                      primaryColor,

                  backgroundColor:
                      Colors
                          .transparent,

                  minHeight: 2,
                ),

              /*
               * BODY
               */
              Expanded(
                child:
                    _buildContent(
                  provider,
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
// INTERNAL MODEL
// ===========================================================

class _SalaryPaymentItem {
  final String label;

  final double? value;

  const _SalaryPaymentItem({
    required this.label,
    required this.value,
  });
}