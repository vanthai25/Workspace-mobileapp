import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/su_kien_model.dart';
import '../../providers/su_kien_provider.dart';

class TaoDangKySuKienScreen
    extends StatefulWidget {
  const TaoDangKySuKienScreen({
    super.key,
  });

  @override
  State<TaoDangKySuKienScreen>
      createState() =>
          _TaoDangKySuKienScreenState();
}

class _TaoDangKySuKienScreenState
    extends State<TaoDangKySuKienScreen> {
  final Color primaryColor =
      const Color(0xFF1274BC);

  final TextEditingController
      _ghiChuController =
      TextEditingController();

  final TextEditingController
      _soLuongController =
      TextEditingController(
    text: '1',
  );

  SuKienModel? _selectedSuKien;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      context
          .read<SuKienProvider>()
          .fetchSuKienDangMo();
    });
  }

  @override
  void dispose() {
    _ghiChuController.dispose();
    _soLuongController.dispose();

    super.dispose();
  }

  // =========================================================
  // SEARCHABLE SELECT
  // =========================================================

  Future<void>
      _chonSuKien() async {
    final provider =
        context.read<SuKienProvider>();

    final List<SuKienModel> source =
        provider.suKienCoTheDangKy;

    final SuKienModel? result =
        await showModalBottomSheet<
            SuKienModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return _SuKienSearchSheet(
          items: source,
        );
      },
    );

    if (result == null ||
        !mounted) {
      return;
    }

    setState(() {
      _selectedSuKien =
          result;

      // Sự kiện không cho sửa SL:
      // luôn mặc định = 1.
      if (!result.isEditSoLuong) {
        _soLuongController.text =
            '1';
      }
    });
  }

  // =========================================================
  // SUBMIT
  // =========================================================

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final SuKienModel? suKien =
        _selectedSuKien;

    if (suKien == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn sự kiện.',
          ),
        ),
      );

      return;
    }

    int soLuong = 1;

    if (suKien.isEditSoLuong) {
      soLuong =
          int.tryParse(
            _soLuongController.text
                .trim(),
          ) ??
          0;

      if (soLuong < 1) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Số lượng phải lớn hơn hoặc bằng 1.',
            ),
          ),
        );

        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    final bool success =
        await context
            .read<SuKienProvider>()
            .dangKy(
      masukien:
          suKien.masukien,
      soLuong:
          soLuong,
      ghiChu:
          _ghiChuController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!success) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Đăng ký sự kiện thành công.',
        ),
      ),
    );

    Navigator.pop(
      context,
      true,
    );
  }

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
          'Đăng ký sự kiện',
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
      ),

      body:
          Consumer<SuKienProvider>(
        builder: (
          context,
          provider,
          child,
        ) {
          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              16,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                // =============================================
                // CHỌN SỰ KIỆN
                // =============================================

                const Text(
                  'Sự kiện đăng ký',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                InkWell(
                  onTap:
                      provider
                              .isLoadingDangMo
                          ? null
                          : _chonSuKien,
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                  child: Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(
                      15,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                      border:
                          Border.all(
                        color:
                            Colors.grey
                                .shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons
                              .event_available_rounded,
                          color:
                              primaryColor,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Text(
                            _selectedSuKien
                                    ?.tentiec ??
                                'Chọn sự kiện...',
                            style:
                                TextStyle(
                              color: _selectedSuKien ==
                                      null
                                  ? Colors
                                      .grey
                                      .shade500
                                  : Colors
                                      .black87,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),

                        const Icon(
                          Icons
                              .search_rounded,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_selectedSuKien !=
                    null) ...[
                  const SizedBox(
                    height: 10,
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
                          Colors.blue
                              .withOpacity(
                        0.06,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                    child: Text(
                      _selectedSuKien!
                              .isEditSoLuong
                          ? 'Sự kiện này cho phép đăng ký số lượng lớn hơn 1.'
                          : 'Sự kiện này mặc định số lượng đăng ký là 1.',
                      style:
                          TextStyle(
                        color:
                            primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],

                const SizedBox(
                  height: 20,
                ),

                // =============================================
                // SỐ LƯỢNG
                // =============================================

                TextFormField(
                  controller:
                      _soLuongController,
                  enabled:
                      _selectedSuKien
                              ?.isEditSoLuong ??
                          false,
                  keyboardType:
                      TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,
                  ],
                  decoration:
                      InputDecoration(
                    labelText:
                        'Số lượng',
                    prefixIcon:
                        const Icon(
                      Icons
                          .people_alt_outlined,
                    ),
                    helperText:
                        _selectedSuKien ==
                                null
                            ? 'Chọn sự kiện trước'
                            : _selectedSuKien!
                                    .isEditSoLuong
                                ? 'Có thể nhập số lượng lớn hơn 1'
                                : 'Số lượng cố định là 1',
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =============================================
                // GHI CHÚ
                // =============================================

                TextFormField(
                  controller:
                      _ghiChuController,
                  minLines: 3,
                  maxLines: 5,
                  decoration:
                      InputDecoration(
                    labelText:
                        'Ghi chú',
                    hintText:
                        'Nhập ghi chú nếu có...',
                    prefixIcon:
                        const Padding(
                      padding:
                          EdgeInsets.only(
                        bottom: 55,
                      ),
                      child: Icon(
                        Icons
                            .notes_rounded,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _isSubmitting
                            ? null
                            : _submit,
                    icon:
                        _isSubmitting
                            ? const SizedBox(
                                width:
                                    18,
                                height:
                                    18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .send_rounded,
                              ),
                    label:
                        const Text(
                      'ĐĂNG KÝ',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          primaryColor,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================
// SEARCH SHEET
// ===========================================================

class _SuKienSearchSheet
    extends StatefulWidget {
  final List<SuKienModel> items;

  const _SuKienSearchSheet({
    required this.items,
  });

  @override
  State<_SuKienSearchSheet>
      createState() =>
          _SuKienSearchSheetState();
}

class _SuKienSearchSheetState
    extends State<_SuKienSearchSheet> {
  String keyword = '';

  @override
  Widget build(
    BuildContext context,
  ) {
    final String search =
        keyword
            .trim()
            .toLowerCase();

    final items =
        widget.items.where(
      (e) {
        final String text =
            '${e.masukien} '
            '${e.tentiec ?? ''}'
                .toLowerCase();

        return search.isEmpty ||
            text.contains(search);
      },
    ).toList();

    return Container(
      height:
          MediaQuery.of(context)
                  .size
                  .height *
              0.72,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        20,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
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

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Chọn sự kiện',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          TextField(
            autofocus: true,
            onChanged: (value) {
              setState(() {
                keyword = value;
              });
            },
            decoration:
                InputDecoration(
              hintText:
                  'Tìm tên sự kiện...',
              prefixIcon:
                  const Icon(
                Icons.search,
              ),
              filled: true,
              fillColor:
                  const Color(
                0xFFF3F5F7,
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

          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'Không có sự kiện phù hợp.',
                    ),
                  )
                : ListView.separated(
                    itemCount:
                        items.length,
                    separatorBuilder:
                        (_, __) =>
                            const Divider(
                      height: 1,
                    ),
                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final item =
                          items[index];

                      return ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons
                                .celebration_rounded,
                          ),
                        ),
                        title:
                            Text(
                          item.tentiec ??
                              'Sự kiện ${item.masukien}',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        subtitle:
                            Text(
                          item.isEditSoLuong
                              ? 'Có thể đăng ký nhiều người'
                              : 'Số lượng: 1',
                        ),
                        trailing:
                            const Icon(
                          Icons
                              .chevron_right,
                        ),
                        onTap: () {
                          Navigator.pop(
                            context,
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