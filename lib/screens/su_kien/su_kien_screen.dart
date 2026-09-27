import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/su_kien_model.dart';
import '../../providers/su_kien_provider.dart';

class SuKienScreen extends StatefulWidget {
  const SuKienScreen({
    super.key,
  });

  @override
  State<SuKienScreen> createState() =>
      _SuKienScreenState();
}

class _SuKienScreenState
    extends State<SuKienScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor =
      Color(0xFF1274BC);

  late final TabController _tabController;

  final TextEditingController
      _searchChuaDangKyController =
      TextEditingController();

  final TextEditingController
      _searchDaDangKyController =
      TextEditingController();

  String _searchChuaDangKy = '';
  String _searchDaDangKy = '';

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();

    _searchChuaDangKyController.dispose();
    _searchDaDangKyController.dispose();

    super.dispose();
  }

  // =========================================================
  // LOAD DATA
  // =========================================================

  Future<void> _loadData() async {
    final provider =
        context.read<SuKienProvider>();

    await provider.fetchSuKienDangMo();

    if (!mounted) {
      return;
    }

    await provider.fetchDangKyCuaToi();
  }

  // =========================================================
  // SEARCH KHÔNG DẤU
  // =========================================================

  String _normalizeText(
    String value,
  ) {
    String text =
        value.trim().toLowerCase();

    text = text.replaceAll(
      RegExp(
        r'[àáạảãâầấậẩẫăằắặẳẵ]',
      ),
      'a',
    );

    text = text.replaceAll(
      RegExp(
        r'[èéẹẻẽêềếệểễ]',
      ),
      'e',
    );

    text = text.replaceAll(
      RegExp(
        r'[ìíịỉĩ]',
      ),
      'i',
    );

    text = text.replaceAll(
      RegExp(
        r'[òóọỏõôồốộổỗơờớợởỡ]',
      ),
      'o',
    );

    text = text.replaceAll(
      RegExp(
        r'[ùúụủũưừứựửữ]',
      ),
      'u',
    );

    text = text.replaceAll(
      RegExp(
        r'[ỳýỵỷỹ]',
      ),
      'y',
    );

    text = text.replaceAll(
      'đ',
      'd',
    );

    return text;
  }

  // =========================================================
  // ĐĂNG KÝ
  // =========================================================

  Future<void> _dangKySuKien(
    SuKienModel item,
  ) async {
    final provider =
        context.read<SuKienProvider>();

    // =======================================================
    // KHÔNG CÓ NGHIỆP VỤ ĂN
    //
    // Bấm đăng ký -> tham gia luôn.
    // =======================================================

    if (!item.isAnOrKhongAn) {
      // =======================================================
      // XÁC NHẬN TRƯỚC KHI ĐĂNG KÝ
      // =======================================================

      final bool confirm =
          await _confirmDangKyThamGia(
        item,
      );

      if (!confirm ||
          !mounted) {
        return;
      }

      // =======================================================
      // GỌI API
      // =======================================================

      final bool success =
          await provider.dangKy(
        masukien: item.masukien,
        coAn: null,
        soLuong: null,
        ghiChu: null,
      );

      if (!mounted) {
        return;
      }

      if (success) {
        _showSuccess(
          'Đăng ký tham gia sự kiện thành công.',
        );

        _tabController.animateTo(1);
      }

      return;
    }

    // =======================================================
    // CÓ NGHIỆP VỤ ĂN
    // =======================================================

    final Map<String, dynamic>? result =
        await _showDangKyDialog(
      item,
    );

    if (result == null ||
        !mounted) {
      return;
    }

    final bool success =
        await provider.dangKy(
      masukien: item.masukien,
      coAn:
          result['coAn'] as bool?,
      soLuong:
          result['soLuong'] as int?,
      ghiChu:
          result['ghiChu'] as String?,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _showSuccess(
        'Đăng ký tham gia sự kiện thành công.',
      );

      _tabController.animateTo(1);
    }
  }

  // =========================================================
  // SHOW DIALOG
  //
  // Dialog tự quản lý Controller,
  // không tạo Controller ở Screen nữa.
  // =========================================================

  Future<Map<String, dynamic>?>
      _showDangKyDialog(
    SuKienModel item,
  ) {
    return showDialog<
        Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _DangKySuKienDialog(
          item: item,
        );
      },
    );
  }

  // =========================================================
  // HỦY ĐĂNG KÝ
  // =========================================================
  Future<bool> _confirmDangKyThamGia(
  SuKienModel item,
) async {
  final bool? result =
      await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (
      dialogContext,
    ) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),

        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor
                    .withOpacity(
                  0.10,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: const Icon(
                Icons
                    .celebration_rounded,
                color:
                    primaryColor,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            const Expanded(
              child: Text(
                'Xác nhận tham gia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              item.tentiec
                          ?.trim()
                          .isNotEmpty ==
                      true
                  ? item.tentiec!
                      .trim()
                  : 'Sự kiện',
              style: const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            if (item
                    .ngayketthucdky !=
                null) ...[
              const SizedBox(
                height: 6,
              ),

              Text(
                'Hạn đăng ký: '
                '${DateFormat('dd/MM/yyyy HH:mm').format(item.ngayketthucdky!)}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ],

            const SizedBox(
              height: 18,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration: BoxDecoration(
                color: primaryColor
                    .withOpacity(
                  0.07,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons
                        .info_outline_rounded,
                    color:
                        primaryColor,
                    size: 20,
                  ),

                  SizedBox(
                    width: 9,
                  ),

                  Expanded(
                    child: Text(
                      'Bạn có chắc chắn muốn đăng ký tham gia sự kiện này?',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child: const Text(
              'Không',
            ),
          ),

          ElevatedButton.icon(
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  primaryColor,
              foregroundColor:
                  Colors.white,
            ),
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            icon: const Icon(
              Icons.check_rounded,
              size: 18,
            ),
            label: const Text(
              'Đăng ký',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    },
  );

  return result == true;
}
  Future<void> _confirmDelete(
    SuKienDangKyModel item,
  ) async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              SizedBox(
                width: 8,
              ),
              Text(
                'Hủy đăng ký',
              ),
            ],
          ),
          content: Text(
            'Bạn có chắc muốn hủy đăng ký '
            '"${item.tentiec ?? 'sự kiện này'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Không',
              ),
            ),
            ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
              label: const Text(
                'Hủy đăng ký',
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

    final bool success =
        await context
            .read<SuKienProvider>()
            .huyDangKy(
      item.id,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _showSuccess(
        'Đã hủy đăng ký sự kiện.',
      );
    }
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void _showSuccess(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
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
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF4F7FB,
      ),

      appBar: AppBar(
        title: const Text(
          'Sự kiện',
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

        bottom: TabBar(
          controller:
              _tabController,
          indicatorColor:
              Colors.white,
          indicatorWeight: 3,
          labelColor:
              Colors.white,
          unselectedLabelColor:
              Colors.white70,
          labelStyle:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
          tabs: const [
            Tab(
              icon: Icon(
                Icons
                    .event_available_rounded,
              ),
              text:
                  'Chưa đăng ký',
            ),
            Tab(
              icon: Icon(
                Icons
                    .fact_check_rounded,
              ),
              text:
                  'Đã đăng ký',
            ),
          ],
        ),
      ),

      body:
          Consumer<SuKienProvider>(
        builder: (
          context,
          provider,
          child,
        ) {
          return TabBarView(
            controller:
                _tabController,
            children: [
              _buildChuaDangKyTab(
                provider,
              ),
              _buildDaDangKyTab(
                provider,
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // TAB 1 - CHƯA ĐĂNG KÝ
  // =========================================================

  Widget _buildChuaDangKyTab(
    SuKienProvider provider,
  ) {
    if (provider.isLoadingDangMo &&
        provider
            .suKienDangMo
            .isEmpty) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              primaryColor,
        ),
      );
    }

    // API đã chỉ trả sự kiện còn hạn.
    // Flutter chỉ lọc những sự kiện
    // người dùng chưa đăng ký.
    final List<SuKienModel>
        source =
        provider.suKienDangMo
            .where(
              (item) =>
                  !item.daDangKy,
            )
            .toList();

    final String keyword =
        _normalizeText(
      _searchChuaDangKy,
    );

    final List<SuKienModel>
        data =
        source.where(
      (item) {
        if (keyword.isEmpty) {
          return true;
        }

        return _normalizeText(
          item.tentiec ?? '',
        ).contains(
          keyword,
        );
      },
    ).toList();

    return Column(
      children: [
        _buildSearchBox(
          controller:
              _searchChuaDangKyController,
          hint:
              'Tìm sự kiện chưa đăng ký...',
          onChanged: (
            value,
          ) {
            setState(() {
              _searchChuaDangKy =
                  value;
            });
          },
          onClear: () {
            _searchChuaDangKyController
                .clear();

            setState(() {
              _searchChuaDangKy =
                  '';
            });
          },
        ),

        if (provider
            .isLoadingDangMo)
          const LinearProgressIndicator(
            minHeight: 2,
            color:
                primaryColor,
          ),

        Expanded(
          child: data.isEmpty
              ? _buildEmpty(
                  icon:
                      Icons
                          .event_available_outlined,
                  title:
                      keyword.isEmpty
                          ? 'Không có sự kiện cần đăng ký'
                          : 'Không tìm thấy sự kiện',
                  subtitle:
                      keyword.isEmpty
                          ? 'Bạn đã đăng ký hết hoặc hiện không có sự kiện đang mở.'
                          : 'Thử tìm với tên sự kiện khác.',
                  onRefresh:
                      provider
                          .fetchSuKienDangMo,
                )
              : RefreshIndicator(
                  color:
                      primaryColor,
                  onRefresh:
                      provider
                          .fetchSuKienDangMo,
                  child:
                      ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      12,
                      12,
                      12,
                      30,
                    ),
                    itemCount:
                        data.length,
                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      return _buildChuaDangKyCard(
                        data[index],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // =========================================================
  // CARD TAB 1
  // =========================================================

  Widget _buildChuaDangKyCard(
    SuKienModel item,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
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
          18,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 10,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
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
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color:
                      primaryColor
                          .withOpacity(
                    0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .celebration_rounded,
                  color:
                      primaryColor,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Text(
                  item.tentiec
                              ?.trim()
                              .isNotEmpty ==
                          true
                      ? item.tentiec!
                          .trim()
                      : 'Sự kiện',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
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
            height: 14,
          ),

          // =================================================
          // HẠN ĐĂNG KÝ
          // =================================================

          if (item
                  .ngayketthucdky !=
              null)
            _buildInfoRow(
              'Hạn đăng ký',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(
                item
                    .ngayketthucdky!,
              ),
            ),

          // =================================================
          // THÔNG TIN SỰ KIỆN
          // =================================================

          if (item.ghichu != null &&
              item.ghichu!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 6,
            ),

            _buildInfoRow(
              'Thông tin',
              item.ghichu!
                  .trim(),
            ),
          ],

          const SizedBox(
            height: 12,
          ),

          // =================================================
          // TAG PHÂN LOẠI
          // =================================================

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (!item
                  .isAnOrKhongAn)
                _buildTag(
                  Icons
                      .event_available_rounded,
                  'Không có tiệc/suất ăn',
                  primaryColor,
                ),

              if (item
                  .isAnOrKhongAn)
                _buildTag(
                  Icons
                      .restaurant_rounded,
                  'Có tiệc/suất ăn',
                  Colors.orange,
                ),

              if (item
                      .isAnOrKhongAn &&
                  item
                      .isEditSoLuong)
                _buildTag(
                  Icons.groups_rounded,
                  'Báo tiệc/suất ăn theo số lượng',
                  Colors.green,
                ),

              if (item
                      .isAnOrKhongAn &&
                  !item
                      .isEditSoLuong)
                _buildTag(
                  Icons.person_rounded,
                  'Báo tiệc/suất ăn cá nhân',
                  Colors.green,
                ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          // =================================================
          // BUTTON ĐĂNG KÝ
          // =================================================

          SizedBox(
            width:
                double.infinity,
            child:
                ElevatedButton.icon(
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    primaryColor,
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              onPressed: () {
                _dangKySuKien(
                  item,
                );
              },
              icon: const Icon(
                Icons
                    .how_to_reg_rounded,
              ),
              label: const Text(
                'Đăng ký tham gia',
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 2 - ĐÃ ĐĂNG KÝ
  // =========================================================

  Widget _buildDaDangKyTab(
    SuKienProvider provider,
  ) {
    if (provider.isLoading &&
        provider
            .dangKyCuaToi
            .isEmpty) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              primaryColor,
        ),
      );
    }

    final String keyword =
        _normalizeText(
      _searchDaDangKy,
    );

    final List<
            SuKienDangKyModel>
        data =
        provider.dangKyCuaToi
            .where(
      (item) {
        if (keyword.isEmpty) {
          return true;
        }

        return _normalizeText(
          item.tentiec ?? '',
        ).contains(
          keyword,
        );
      },
    ).toList();

    return Column(
      children: [
        _buildSearchBox(
          controller:
              _searchDaDangKyController,
          hint:
              'Tìm sự kiện đã đăng ký...',
          onChanged: (
            value,
          ) {
            setState(() {
              _searchDaDangKy =
                  value;
            });
          },
          onClear: () {
            _searchDaDangKyController
                .clear();

            setState(() {
              _searchDaDangKy =
                  '';
            });
          },
        ),

        if (provider.isLoading)
          const LinearProgressIndicator(
            minHeight: 2,
            color:
                primaryColor,
          ),

        Expanded(
          child: data.isEmpty
              ? _buildEmpty(
                  icon:
                      Icons
                          .fact_check_outlined,
                  title:
                      keyword.isEmpty
                          ? 'Bạn chưa đăng ký sự kiện nào'
                          : 'Không tìm thấy sự kiện',
                  subtitle:
                      keyword.isEmpty
                          ? 'Các sự kiện bạn đã đăng ký sẽ hiển thị tại đây.'
                          : 'Thử tìm với tên sự kiện khác.',
                  onRefresh:
                      provider
                          .fetchDangKyCuaToi,
                )
              : RefreshIndicator(
                  color:
                      primaryColor,
                  onRefresh:
                      provider
                          .fetchDangKyCuaToi,
                  child:
                      ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      12,
                      12,
                      12,
                      30,
                    ),
                    itemCount:
                        data.length,
                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      return _buildDaDangKyCard(
                        data[index],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // =========================================================
  // CARD TAB 2
  // =========================================================

  Widget _buildDaDangKyCard(
    SuKienDangKyModel item,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
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
          18,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.04,
            ),
            blurRadius: 10,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
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
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(
                  color:
                      primaryColor
                          .withOpacity(
                    0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .celebration_rounded,
                  color:
                      primaryColor,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Text(
                  item.tentiec
                              ?.trim()
                              .isNotEmpty ==
                          true
                      ? item.tentiec!
                          .trim()
                      : 'Sự kiện',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              _buildStatus(
                item.conHanDangKy,
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // =================================================
          // HẠN
          // =================================================

          if (item
                  .ngayketthucdky !=
              null)
            _buildInfoRow(
              'Hạn đăng ký',
              DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(
                item
                    .ngayketthucdky!,
              ),
            ),

          const SizedBox(
            height: 6,
          ),

          // =================================================
          // CÓ NGHIỆP VỤ ĂN
          // =================================================

          if (item
              .isAnOrKhongAn) ...[
            _buildInfoRow(
              'Đăng ký ăn',
              item.coAn == true
                  ? 'Có ăn'
                  : 'Không ăn',
              bold: true,
            ),

            if (item.coAn ==
                true) ...[
              const SizedBox(
                height: 6,
              ),

              _buildInfoRow(
                'Số lượng suất ăn',
                '${item.soLuong ?? 1}',
                bold: true,
              ),
            ],
          ]

          // =================================================
          // KHÔNG CÓ NGHIỆP VỤ ĂN
          // =================================================

          else
            _buildInfoRow(
              'Hình thức',
              'Tham gia sự kiện',
              bold: true,
            ),

          // =================================================
          // GHI CHÚ
          // =================================================

          if (item.ghichu != null &&
              item.ghichu!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 6,
            ),

            _buildInfoRow(
              'Ghi chú',
              item.ghichu!
                  .trim(),
            ),
          ],

          // =================================================
          // HỦY
          // =================================================

          if (item
              .conHanDangKy) ...[
            const SizedBox(
              height: 14,
            ),

            Divider(
              color:
                  Colors.grey
                      .shade200,
            ),

            Align(
              alignment:
                  Alignment.centerRight,
              child:
                  TextButton.icon(
                onPressed: () {
                  _confirmDelete(
                    item,
                  );
                },
                icon: const Icon(
                  Icons
                      .delete_outline_rounded,
                  color:
                      Colors.redAccent,
                ),
                label: const Text(
                  'Hủy đăng ký',
                  style:
                      TextStyle(
                    color:
                        Colors.redAccent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // SEARCH BOX
  // =========================================================

  Widget _buildSearchBox({
    required TextEditingController
        controller,
    required String hint,
    required ValueChanged<String>
        onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      color:
          Colors.white,
      padding:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        10,
      ),
      child:
          TextField(
        controller:
            controller,
        textInputAction:
            TextInputAction.search,
        onChanged:
            onChanged,
        decoration:
            InputDecoration(
          hintText:
              hint,
          prefixIcon:
              const Icon(
            Icons.search_rounded,
          ),
          suffixIcon:
              controller
                      .text
                      .isEmpty
                  ? null
                  : IconButton(
                      onPressed:
                          onClear,
                      icon:
                          const Icon(
                        Icons
                            .close_rounded,
                      ),
                    ),
          filled:
              true,
          fillColor:
              const Color(
            0xFFF3F5F7,
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
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                BorderSide.none,
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                const BorderSide(
              color:
                  primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _buildInfoRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return RichText(
      text:
          TextSpan(
        style:
            const TextStyle(
          color:
              Color(
            0xFF444444,
          ),
          fontSize: 13,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text:
                '$label: ',
          ),
          TextSpan(
            text:
                value,
            style:
                TextStyle(
              fontWeight:
                  bold
                      ? FontWeight.bold
                      : FontWeight.normal,
              color:
                  const Color(
                0xFF25282D,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TAG
  // =========================================================

  Widget _buildTag(
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(
          0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            text,
            style:
                TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STATUS
  // =========================================================

  Widget _buildStatus(
    bool conHan,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            conHan
                ? Colors.green.shade50
                : Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
      child: Text(
        conHan
            ? 'Còn hạn'
            : 'Đã hết hạn',
        style:
            TextStyle(
          color:
              conHan
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
          fontSize: 10.5,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
    required Future<void> Function()
        onRefresh,
  }) {
    return RefreshIndicator(
      color:
          primaryColor,
      onRefresh:
          onRefresh,
      child:
          ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 25,
        ),
        children: [
          const SizedBox(
            height: 120,
          ),

          Icon(
            icon,
            size: 68,
            color:
                Colors.grey
                    .shade300,
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.grey
                      .shade700,
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            subtitle,
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.grey
                      .shade500,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// DIALOG ĐĂNG KÝ SỰ KIỆN
//
// TÁCH THÀNH STATEFULWIDGET RIÊNG
// ĐỂ CONTROLLER ĐƯỢC DISPOSE ĐÚNG LIFECYCLE.
// ===========================================================

class _DangKySuKienDialog
    extends StatefulWidget {
  final SuKienModel item;

  const _DangKySuKienDialog({
    required this.item,
  });

  @override
  State<_DangKySuKienDialog>
      createState() =>
          _DangKySuKienDialogState();
}

class _DangKySuKienDialogState
    extends State<_DangKySuKienDialog> {
  static const Color primaryColor =
      Color(0xFF1274BC);

  late final TextEditingController
      _soLuongController;

  late final TextEditingController
      _ghiChuController;

  bool? _coAn;

  String? _errorText;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _soLuongController =
        TextEditingController(
      text: '1',
    );

    _ghiChuController =
        TextEditingController();
  }

  // =========================================================
  // DISPOSE
  //
  // Flutter tự gọi khi Dialog thực sự
  // bị remove khỏi Widget Tree.
  // =========================================================

  @override
  void dispose() {
    _soLuongController.dispose();
    _ghiChuController.dispose();

    super.dispose();
  }

  // =========================================================
  // GHI CHÚ BẮT BUỘC?
  // =========================================================

  bool get _batBuocGhiChu {
    return _coAn == true &&
        widget.item.isEditSoLuong;
  }

  // =========================================================
  // SUBMIT
  // =========================================================

  void _submit() {
    // =======================================================
    // CHƯA CHỌN ĂN / KHÔNG ĂN
    // =======================================================

    if (_coAn == null) {
      setState(() {
        _errorText =
            'Vui lòng chọn Có ăn hoặc Không ăn.';
      });

      return;
    }

    int? soLuong;

    // =======================================================
    // CÓ ĂN
    // =======================================================

    if (_coAn == true) {
      // =====================================================
      // ĐƯỢC NHẬP SỐ LƯỢNG
      // =====================================================

      if (widget
          .item.isEditSoLuong) {
        soLuong =
            int.tryParse(
          _soLuongController
              .text
              .trim(),
        );

        if (soLuong == null ||
            soLuong < 1) {
          setState(() {
            _errorText =
                'Vui lòng nhập số lượng hợp lệ, tối thiểu là 1.';
          });

          return;
        }

        // ===================================================
        // KHI ĐƯỢC BÁO NHIỀU NGƯỜI
        // BẮT BUỘC NHẬP GHI CHÚ.
        // ===================================================

        if (_ghiChuController
            .text
            .trim()
            .isEmpty) {
          setState(() {
            _errorText =
                'Vui lòng nhập ghi chú để làm rõ nội dung đăng ký.';
          });

          return;
        }
      }

      // =====================================================
      // KHÔNG ĐƯỢC NHẬP SỐ LƯỢNG
      // => MẶC ĐỊNH 1 SUẤT
      // =====================================================

      else {
        soLuong = 1;
      }
    }

    // =======================================================
    // KHÔNG ĂN
    //
    // Gửi soLuong = null.
    // Backend đọc CoAn=false và lưu SoLuong=0.
    // =======================================================

    else {
      soLuong = null;
    }

    final String ghiChu =
        _ghiChuController
            .text
            .trim();

    Navigator.of(context).pop(
      <String, dynamic>{
        'coAn':
            _coAn!,
        'soLuong':
            soLuong,
        'ghiChu':
            ghiChu.isEmpty
                ? null
                : ghiChu,
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final SuKienModel item =
        widget.item;

    final double screenWidth =
        MediaQuery.of(context)
            .size
            .width;

    return Dialog(
      // Popup rộng đều.
      insetPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 24,
      ),

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      clipBehavior:
          Clip.antiAlias,

      child:
          ConstrainedBox(
        constraints:
            BoxConstraints(
          maxWidth:
              screenWidth - 24,
          maxHeight:
              MediaQuery.of(context)
                      .size
                      .height *
                  0.88,
        ),

        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            14,
          ),

          child:
              Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =============================================
              // HEADER
              // =============================================

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration:
                        BoxDecoration(
                      color:
                          primaryColor
                              .withOpacity(
                        0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons
                          .celebration_rounded,
                      color:
                          primaryColor,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  const Expanded(
                    child: Text(
                      'Đăng ký tham gia',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              // =============================================
              // TÊN
              // =============================================

              Text(
                item.tentiec
                            ?.trim()
                            .isNotEmpty ==
                        true
                    ? item.tentiec!
                        .trim()
                    : 'Sự kiện',
                style:
                    const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(
                    0xFF25282D,
                  ),
                ),
              ),

              if (item
                      .ngayketthucdky !=
                  null) ...[
                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Hạn đăng ký: '
                  '${DateFormat('dd/MM/yyyy HH:mm').format(item.ngayketthucdky!)}',
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey
                            .shade600,
                  ),
                ),
              ],

              const SizedBox(
                height: 20,
              ),

              // =============================================
              // CHỌN ĂN
              // =============================================

              const Text(
                'Bạn có đăng ký ăn không?',
                style:
                    TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        _buildLuaChon(
                      title:
                          'Có ăn',
                      icon:
                          Icons
                              .restaurant_rounded,
                      selected:
                          _coAn == true,
                      color:
                          Colors.green,
                      onTap: () {
                        setState(() {
                          _coAn =
                              true;

                          _errorText =
                              null;

                          if (_soLuongController
                              .text
                              .trim()
                              .isEmpty) {
                            _soLuongController
                                    .text =
                                '1';
                          }
                        });
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                        _buildLuaChon(
                      title:
                          'Không ăn',
                      icon:
                          Icons
                              .no_food_rounded,
                      selected:
                          _coAn ==
                              false,
                      color:
                          Colors.orange,
                      onTap: () {
                        setState(() {
                          _coAn =
                              false;

                          _errorText =
                              null;
                        });
                      },
                    ),
                  ),
                ],
              ),

              // =============================================
              // ERROR
              // =============================================

              if (_errorText !=
                  null) ...[
                const SizedBox(
                  height: 9,
                ),

                Text(
                  _errorText!,
                  style:
                      const TextStyle(
                    color:
                        Colors.red,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],

              // =============================================
              // CÓ ĂN + CHO NHẬP SL
              // =============================================

              if (_coAn == true &&
                  item
                      .isEditSoLuong) ...[
                const SizedBox(
                  height: 16,
                ),

                // ===========================================
                // HƯỚNG DẪN
                // ===========================================

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        primaryColor
                            .withOpacity(
                      0.07,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    border:
                        Border.all(
                      color:
                          primaryColor
                              .withOpacity(
                        0.18,
                      ),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons
                            .info_outline_rounded,
                        color:
                            primaryColor,
                        size: 20,
                      ),

                      SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child: Text(
                          'Sự kiện này được phép nhập số lượng người '
                          'tham gia dự tiệc (báo hộ hoặc báo cho cả '
                          'khoa/phòng, ...). Vui lòng nhập số lượng '
                          'tương ứng và nhập ghi chú nội dung.',
                          style:
                              TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                // ===========================================
                // SỐ LƯỢNG
                // ===========================================

                TextField(
                  controller:
                      _soLuongController,
                  keyboardType:
                      TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,
                  ],
                  decoration:
                      InputDecoration(
                    labelText:
                        'Số lượng người tham gia *',
                    hintText:
                        'Nhập số lượng',
                    prefixIcon:
                        const Icon(
                      Icons.groups_rounded,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
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
                            Colors.grey
                                .shade300,
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
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              ],

              // =============================================
              // CÓ ĂN + SL = 1
              // =============================================

              if (_coAn == true &&
                  !item
                      .isEditSoLuong) ...[
                const SizedBox(
                  height: 16,
                ),

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.green
                            .shade50,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .restaurant_menu_rounded,
                        size: 20,
                        color:
                            Colors.green
                                .shade700,
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child: Text(
                          'Bạn đăng ký tham gia và sử dụng 1 suất ăn.',
                          style:
                              TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                Colors.green
                                    .shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // =============================================
              // KHÔNG ĂN
              // =============================================

              if (_coAn ==
                  false) ...[
                const SizedBox(
                  height: 16,
                ),

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.orange
                            .shade50,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons
                            .info_outline_rounded,
                        size: 20,
                        color:
                            Colors.orange
                                .shade700,
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child: Text(
                          'Bạn vẫn tham gia sự kiện nhưng không đăng ký suất ăn.',
                          style:
                              TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color:
                                Colors.orange
                                    .shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // =============================================
              // GHI CHÚ
              // =============================================

              const SizedBox(
                height: 16,
              ),

              TextField(
                controller:
                    _ghiChuController,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration:
                    InputDecoration(
                  labelText:
                      _batBuocGhiChu
                          ? 'Ghi chú *'
                          : 'Ghi chú',

                  hintText:
                      _batBuocGhiChu
                          ? 'Ví dụ: Báo 5 suất cho Khoa Nội...'
                          : 'Nhập ghi chú nếu có',

                  helperText:
                      _batBuocGhiChu
                          ? 'Bắt buộc khi đăng ký số lượng người tham gia'
                          : null,

                  helperStyle:
                      TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey
                            .shade600,
                  ),

                  alignLabelWithHint:
                      true,

                  prefixIcon:
                      const Padding(
                    padding:
                        EdgeInsets.only(
                      bottom: 40,
                    ),
                    child:
                        Icon(
                      Icons.notes_rounded,
                    ),
                  ),

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
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
                          Colors.grey
                              .shade300,
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
                      width: 1.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // =============================================
              // ACTION
              // =============================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop();
                    },
                    child: const Text(
                      'Hủy',
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  ElevatedButton.icon(
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          primaryColor,
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                      ),
                    ),
                    onPressed:
                        _submit,
                    icon: const Icon(
                      Icons
                          .check_rounded,
                      size: 18,
                    ),
                    label:
                        const Text(
                      'Đăng ký',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CARD CHỌN ĂN / KHÔNG ĂN
  // =========================================================

  Widget _buildLuaChon({
    required String title,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child:
            AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 160,
          ),
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 8,
          ),
          decoration:
              BoxDecoration(
            color:
                selected
                    ? color.withOpacity(
                        0.10,
                      )
                    : Colors.white,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            border:
                Border.all(
              color:
                  selected
                      ? color
                      : Colors.grey
                          .shade300,
              width:
                  selected
                      ? 1.6
                      : 1,
            ),
          ),
          child:
              Column(
            children: [
              Icon(
                icon,
                size: 26,
                color:
                    selected
                        ? color
                        : Colors.grey
                            .shade500,
              ),

              const SizedBox(
                height: 7,
              ),

              Text(
                title,
                style:
                    TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      selected
                          ? color
                          : Colors.grey
                              .shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}