import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../models/dao_tao_v2_models.dart';
import '../../../../../../providers/dao_tao_v2_provider.dart';
import 'dao_tao_design.dart';

class BoSungHocVienDaoTaoDialog
    extends StatefulWidget {
  final LopDaoTaoV2Model item;

  const BoSungHocVienDaoTaoDialog({
    super.key,
    required this.item,
  });

  @override
  State<BoSungHocVienDaoTaoDialog>
      createState() =>
          _BoSungHocVienDaoTaoDialogState();
}


class _BoSungHocVienDaoTaoDialogState
    extends State<BoSungHocVienDaoTaoDialog>
    with SingleTickerProviderStateMixin {
  late final TabController
      _tabController;


  // ==========================================================
  // TAB 1
  // ĐÃ ĐĂNG KÝ TRƯỚC
  // MaSo -> trạng thái muốn lưu IsHopLeDaoTao
  // ==========================================================

  final Map<String, bool>
      _hopLeValues = {};

  final TextEditingController
      _registeredSearchController =
      TextEditingController();


  // ==========================================================
  // TAB 2
  // CHƯA ĐĂNG KÝ
  // MaSo -> IsDangKyOnline
  // ==========================================================

  final Map<String, bool>
      _selected = {};

  final TextEditingController
      _searchController =
      TextEditingController();


  // ==========================================================
  // TAB 3
  // THAM GIA HỢP LỆ
  //
  // Những người được tích ở đây sẽ bị chuyển:
  // IsHopLeDaoTao = false
  // ==========================================================

  final Set<String>
      _selectedRemoveHopLe = {};

  final TextEditingController
      _validSearchController =
      TextEditingController();


  int _currentTab =
      0;


  @override
  void initState() {
    super.initState();

    _tabController =
        TabController(
      length: 3,
      vsync: this,
    );

    _tabController.addListener(
      _handleTabChanged,
    );


    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) async {
        if (!mounted) {
          return;
        }

        await _loadRegistered();

        if (!mounted) {
          return;
        }

        await _search();
      },
    );
  }


  @override
  void dispose() {
    _tabController.removeListener(
      _handleTabChanged,
    );

    _tabController.dispose();

    _registeredSearchController
        .dispose();

    _searchController.dispose();

    _validSearchController.dispose();

    super.dispose();
  }


  // ==========================================================
  // TAB CHANGE
  // ==========================================================

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    if (!mounted) {
      return;
    }

    if (_currentTab ==
        _tabController.index) {
      return;
    }

    setState(() {
      _currentTab =
          _tabController.index;
    });
  }


  // ==========================================================
  // LẤY TRẠNG THÁI ONLINE MỚI NHẤT CỦA LỚP
  // ==========================================================

  bool _lopHoTroOnline(
    DaoTaoV2Provider provider,
  ) {
    final id =
        widget.item.idLopDaoTao;

    for (final item
        in provider.danhSach) {
      if (item.idLopDaoTao ==
          id) {
        return item.isOnline;
      }
    }

    for (final item
        in provider.lopCuaToi) {
      if (item.idLopDaoTao ==
          id) {
        return item.isOnline;
      }
    }

    return widget.item.isOnline;
  }


  // ==========================================================
  // LOAD DANH SÁCH ĐÃ ĐĂNG KÝ
  // ==========================================================

  Future<void> _loadRegistered() async {
    final provider =
        context.read<
            DaoTaoV2Provider>();

    final items =
        await provider
            .loadXacNhanHocVien(
      widget.item.idLopDaoTao,
    );


    if (!mounted) {
      return;
    }


    setState(() {
      _hopLeValues.clear();


      // ================================================
      // Chỉ tạo checkbox xác nhận cho những người
      // CHƯA nằm trong tab Tham gia hợp lệ.
      //
      // IsHopLeDaoTao == true
      // sẽ được chuyển sang tab 3.
      // ================================================

      for (final item
          in items.where(
        (x) =>
            x.isHopLeDaoTao !=
            true,
      )) {
        _hopLeValues[
                item.maSo] =
            item.macDinhHopLe;
      }


      // ================================================
      // Xóa selection tab 3 nếu sau reload
      // người đó không còn hợp lệ nữa.
      // ================================================

      final validCodes =
          items
              .where(
                (x) =>
                    x.isHopLeDaoTao ==
                    true,
              )
              .map(
                (x) =>
                    x.maSo,
              )
              .toSet();

      _selectedRemoveHopLe
          .removeWhere(
        (maSo) =>
            !validCodes.contains(
              maSo,
            ),
      );
    });
  }


  // ==========================================================
  // SEARCH CHƯA ĐĂNG KÝ
  // ==========================================================

  Future<void> _search() async {
    await context
        .read<DaoTaoV2Provider>()
        .loadNhanVienChuaDangKy(
          widget.item.idLopDaoTao,

          keyword:
              _searchController.text,
        );
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final provider =
        context.watch<
            DaoTaoV2Provider>();


    return AlertDialog(
      insetPadding:
          const EdgeInsets.all(
        24,
      ),

      title:
          Row(
        children: [
          const Icon(
            Icons.groups_2_rounded,
            color:
                DaoTaoColors.primary,
          ),

          const SizedBox(
            width: 10,
          ),

          const Expanded(
            child: Text(
              'Bổ sung / xác nhận học viên',
            ),
          ),

          IconButton(
            tooltip:
                'Đóng',

            onPressed:
                _isBusy(provider)
                    ? null
                    : () =>
                        Navigator.pop(
                          context,
                        ),

            icon:
                const Icon(
              Icons.close_rounded,
            ),
          ),
        ],
      ),

      content:
          SizedBox(
        width: 940,
        height: 680,

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              widget.item
                  .tenLopDaoTao,

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w800,

                color:
                    DaoTaoColors.text,

                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 14,
            ),


            // ================================================
            // 3 TAB
            // ================================================

            Container(
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF4F7FA,
                ),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child:
                  TabBar(
                controller:
                    _tabController,

                tabs:
                    const [
                  Tab(
                    icon:
                        Icon(
                      Icons
                          .how_to_reg_rounded,
                    ),

                    text:
                        'Đã đăng ký trước',
                  ),

                  Tab(
                    icon:
                        Icon(
                      Icons
                          .person_add_alt_1_rounded,
                    ),

                    text:
                        'Chưa đăng ký',
                  ),

                  Tab(
                    icon:
                        Icon(
                      Icons
                          .verified_user_rounded,
                    ),

                    text:
                        'Tham gia hợp lệ',
                  ),
                ],
              ),
            ),


            const SizedBox(
              height: 12,
            ),


            Expanded(
              child:
                  TabBarView(
                controller:
                    _tabController,

                children: [
                  _buildRegisteredTab(
                    provider,
                  ),

                  _buildUnregisteredTab(
                    provider,
                  ),

                  _buildValidTab(
                    provider,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),


      // ======================================================
      // ACTION
      // ======================================================

      actions: [
        TextButton(
          onPressed:
              _isBusy(provider)
                  ? null
                  : () =>
                      Navigator.pop(
                        context,
                      ),

          child:
              const Text(
            'Đóng',
          ),
        ),


        // ====================================================
        // TAB 1
        // ====================================================

        if (_currentTab == 0)
          FilledButton.icon(
            onPressed:
                provider
                            .isSavingXacNhanHocVien ||
                        provider
                            .isLoadingXacNhanHocVien ||
                        _hopLeValues
                            .isEmpty
                    ? null
                    : _saveXacNhan,

            icon:
                provider
                        .isSavingXacNhanHocVien
                    ? const SizedBox(
                        width: 16,
                        height: 16,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .verified_user_rounded,
                      ),

            label:
                const Text(
              'Lưu xác nhận',
            ),
          ),


        // ====================================================
        // TAB 2
        // ====================================================

        if (_currentTab == 1)
          FilledButton.icon(
            onPressed:
                provider
                            .isBoSungNguoiDangKy ||
                        _selected
                            .isEmpty
                    ? null
                    : _saveBoSung,

            icon:
                provider
                        .isBoSungNguoiDangKy
                    ? const SizedBox(
                        width: 16,
                        height: 16,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .person_add_alt_1_rounded,
                      ),

            label:
                Text(
              'Bổ sung ${_selected.length} người',
            ),
          ),


        // ====================================================
        // TAB 3
        // ====================================================

        if (_currentTab == 2)
          FilledButton.icon(
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  const Color(
                0xFFB42318,
              ),
            ),

            onPressed:
                provider
                            .isSavingXacNhanHocVien ||
                        _selectedRemoveHopLe
                            .isEmpty
                    ? null
                    : _removeHopLe,

            icon:
                provider
                        .isSavingXacNhanHocVien
                    ? const SizedBox(
                        width: 16,
                        height: 16,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons
                            .remove_circle_outline_rounded,
                      ),

            label:
                Text(
              'Xóa khỏi hợp lệ '
              '(${_selectedRemoveHopLe.length})',
            ),
          ),
      ],
    );
  }


  // ==========================================================
  // TAB 1 - ĐÃ ĐĂNG KÝ TRƯỚC
  // ==========================================================

  Widget _buildRegisteredTab(
    DaoTaoV2Provider provider,
  ) {
    final keyword =
        _registeredSearchController
            .text
            .trim()
            .toLowerCase();


    // ========================================================
    // Những người IsHopLeDaoTao == true
    // KHÔNG còn hiện ở tab này.
    //
    // Họ đã sang tab Tham gia hợp lệ.
    // ========================================================

    final items =
        provider.xacNhanHocVien
            .where(
              (item) =>
                  item.isHopLeDaoTao !=
                  true,
            )
            .where(
              (item) =>
                  _matchesSearch(
                item.maSo,
                item.hoVaTen,
                item.tenKhoaPhong,
                keyword,
              ),
            )
            .toList();


    final selectedCount =
        items.where(
      (item) =>
          _hopLeValues[
                  item.maSo] ==
              true,
    ).length;


    final allSelected =
        items.isNotEmpty &&
        selectedCount ==
            items.length;


    final noneSelected =
        selectedCount == 0;


    return Column(
      children: [
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
                const Color(
              0xFFEFF8FD,
            ),

            borderRadius:
                BorderRadius.circular(
              10,
            ),

            border:
                Border.all(
              color:
                  const Color(
                0xFFC6E5F4,
              ),
            ),
          ),

          child:
              const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Icon(
                Icons
                    .info_outline_rounded,

                color:
                    DaoTaoColors.primary,

                size: 20,
              ),

              SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  'Người "Đăng ký đủ" được tích hợp lệ mặc định. '
                  'Người "Đăng ký thiếu" hoặc Online có thể được '
                  'người quản lý xác nhận thủ công.',

                  style:
                      TextStyle(
                    height: 1.4,
                    color:
                        DaoTaoColors.text,
                    fontSize:
                        12.5,
                  ),
                ),
              ),
            ],
          ),
        ),


        const SizedBox(
          height: 12,
        ),


        TextField(
          controller:
              _registeredSearchController,

          onChanged:
              (_) {
            setState(() {});
          },

          decoration:
              const InputDecoration(
            hintText:
                'Tìm trong danh sách đã đăng ký...',

            prefixIcon:
                Icon(
              Icons.search_rounded,
            ),

            border:
                OutlineInputBorder(),
          ),
        ),


        const SizedBox(
          height: 8,
        ),


        // ====================================================
        // TÍCH TẤT CẢ TAB 1
        // ====================================================

        Row(
          children: [
            Checkbox(
              tristate:
                  true,

              value:
                  allSelected
                      ? true
                      : noneSelected
                          ? false
                          : null,

              onChanged:
                  items.isEmpty
                      ? null
                      : (_) {
                          setState(() {
                            final newValue =
                                !allSelected;

                            for (final item
                                in items) {
                              _hopLeValues[
                                      item.maSo] =
                                  newValue;
                            }
                          });
                        },
            ),

            InkWell(
              onTap:
                  items.isEmpty
                      ? null
                      : () {
                          setState(() {
                            final newValue =
                                !allSelected;

                            for (final item
                                in items) {
                              _hopLeValues[
                                      item.maSo] =
                                  newValue;
                            }
                          });
                        },

              child:
                  const Text(
                'Tích tất cả',

                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),

            const Spacer(),

            Text(
              'Đang tích: '
              '$selectedCount / '
              '${items.length}',

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,

                color:
                    DaoTaoColors.primary,
              ),
            ),
          ],
        ),


        const Divider(),


        Expanded(
          child:
              provider
                      .isLoadingXacNhanHocVien
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : items.isEmpty
                      ? const Center(
                          child: Text(
                            'Không còn học viên chờ xác nhận.',
                          ),
                        )
                      : ListView.separated(
                          itemCount:
                              items.length,

                          separatorBuilder:
                              (_, _) =>
                                  const Divider(
                            height: 1,
                          ),

                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            return _registeredTile(
                              items[index],
                            );
                          },
                        ),
        ),
      ],
    );
  }


  Widget _registeredTile(
    DaoTaoXacNhanHocVienV2Model item,
  ) {
    final checked =
        _hopLeValues[
                item.maSo] ??
            item.macDinhHopLe;


    return CheckboxListTile(
      value:
          checked,

      controlAffinity:
          ListTileControlAffinity.leading,

      onChanged:
          (value) {
        setState(() {
          _hopLeValues[
                  item.maSo] =
              value ?? false;
        });
      },

      title:
          Row(
        children: [
          Expanded(
            child: Text(
              '${item.maSo} - '
              '${item.hoVaTen ?? ''}',

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          if (item.isBoSungSau)
            _smallBadge(
              'Bổ sung sau',
              const Color(
                0xFF7C3AED,
              ),
            ),
        ],
      ),

      subtitle:
          Padding(
        padding:
            const EdgeInsets.only(
          top: 6,
        ),

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              item.tenKhoaPhong ??
                  'Chưa xác định khoa/phòng',
            ),

            const SizedBox(
              height: 7,
            ),

            Wrap(
              spacing: 6,
              runSpacing: 5,

              children: [

                if (!item.isBoSungSau)
                  _chamCongBadge(
                    item,
                  ),


                // =============================================
                // TRỰC TIẾP / ONLINE
                // =============================================

                _smallBadge(
                  item.isDangKyOnline
                      ? 'Online'
                      : 'Trực tiếp',

                  item.isDangKyOnline
                      ? const Color(
                          0xFF2563EB,
                        )
                      : const Color(
                          0xFF475569,
                        ),
                ),


                // =============================================
                // Nếu trước đây đã xác nhận FALSE
                // thì báo riêng.
                // =============================================

                if (item.isHopLeDaoTao ==
                    false)
                  _smallBadge(
                    'Đã xác nhận không hợp lệ',
                    const Color(
                      0xFFB91C1C,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // ==========================================================
  // BADGE CHẤM CÔNG
  // ==========================================================

Widget _chamCongBadge(
  DaoTaoXacNhanHocVienV2Model item,
) {
  if (item.isBoSungSau) {
    return const SizedBox.shrink();
  }

  if (item.duChamCong) {
    return _smallBadge(
      'Đăng ký trước/chấm công đủ',
      const Color(
        0xFF15803D,
      ),
    );
  }

  return _smallBadge(
    'Đăng ký trước/chấm công thiếu',
    const Color(
      0xFFB45309,
    ),
  );
}


  // ==========================================================
  // TAB 2 - CHƯA ĐĂNG KÝ
  // ==========================================================

  Widget _buildUnregisteredTab(
    DaoTaoV2Provider provider,
  ) {
    final items =
        provider.nhanVienChuaDangKy;

    final lopHoTroOnline =
        _lopHoTroOnline(
      provider,
    );


    final selectedVisible =
        items.where(
      (item) =>
          _selected.containsKey(
        item.maSo,
      ),
    ).length;


    final allSelected =
        items.isNotEmpty &&
        selectedVisible ==
            items.length;


    final noneSelected =
        selectedVisible == 0;


    return Column(
      children: [
        TextField(
          controller:
              _searchController,

          onSubmitted:
              (_) =>
                  _search(),

          decoration:
              InputDecoration(
            hintText:
                'Tìm theo mã nhân viên hoặc họ tên...',

            prefixIcon:
                const Icon(
              Icons.search_rounded,
            ),

            suffixIcon:
                IconButton(
              tooltip:
                  'Tìm',

              onPressed:
                  _search,

              icon:
                  const Icon(
                Icons
                    .manage_search_rounded,
              ),
            ),

            border:
                const OutlineInputBorder(),
          ),
        ),


        const SizedBox(
          height: 8,
        ),


        // ====================================================
        // TÍCH TẤT CẢ TAB 2
        // ====================================================

        Row(
          children: [
            Checkbox(
              tristate:
                  true,

              value:
                  allSelected
                      ? true
                      : noneSelected
                          ? false
                          : null,

              onChanged:
                  items.isEmpty
                      ? null
                      : (_) {
                          setState(() {
                            if (allSelected) {
                              for (final item
                                  in items) {
                                _selected.remove(
                                  item.maSo,
                                );
                              }
                            } else {
                              for (final item
                                  in items) {
                                // Mặc định trực tiếp.
                                _selected[
                                        item.maSo] =
                                    false;
                              }
                            }
                          });
                        },
            ),

            InkWell(
              onTap:
                  items.isEmpty
                      ? null
                      : () {
                          setState(() {
                            if (allSelected) {
                              for (final item
                                  in items) {
                                _selected.remove(
                                  item.maSo,
                                );
                              }
                            } else {
                              for (final item
                                  in items) {
                                _selected[
                                        item.maSo] =
                                    false;
                              }
                            }
                          });
                        },

              child:
                  const Text(
                'Tích tất cả',

                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),

            const Spacer(),

            Text(
              'Đã chọn: '
              '${_selected.length} người',

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            if (_selected.isNotEmpty) ...[
              const SizedBox(
                width: 8,
              ),

              TextButton(
                onPressed:
                    () {
                  setState(() {
                    _selected.clear();
                  });
                },

                child:
                    const Text(
                  'Bỏ chọn tất cả',
                ),
              ),
            ],
          ],
        ),


        const Divider(),


        Expanded(
          child:
              provider
                      .isLoadingNhanVienChuaDangKy
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : items.isEmpty
                      ? const Center(
                          child: Text(
                            'Không tìm thấy nhân viên chưa đăng ký.',
                          ),
                        )
                      : ListView.separated(
                          itemCount:
                              items.length,

                          separatorBuilder:
                              (_, _) =>
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

                            final selected =
                                _selected
                                    .containsKey(
                              item.maSo,
                            );

                            final online =
                                _selected[
                                        item.maSo] ??
                                    false;


                            return Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 4,
                              ),

                              child:
                                  Row(
                                children: [
                                  Checkbox(
                                    value:
                                        selected,

                                    onChanged:
                                        (value) {
                                      setState(() {
                                        if (value ==
                                            true) {
                                          _selected[
                                                  item.maSo] =
                                              false;
                                        } else {
                                          _selected.remove(
                                            item.maSo,
                                          );
                                        }
                                      });
                                    },
                                  ),


                                  const SizedBox(
                                    width: 4,
                                  ),


                                  Expanded(
                                    child:
                                        InkWell(
                                      onTap:
                                          () {
                                        setState(() {
                                          if (selected) {
                                            _selected.remove(
                                              item.maSo,
                                            );
                                          } else {
                                            _selected[
                                                    item.maSo] =
                                                false;
                                          }
                                        });
                                      },

                                      child:
                                          Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),

                                        child:
                                            Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                          children: [
                                            Text(
                                              '${item.maSo} - '
                                              '${item.hoVaTen ?? ''}',

                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),

                                            const SizedBox(
                                              height: 3,
                                            ),

                                            Text(
                                              item.tenKhoaPhong ??
                                                  'Chưa xác định khoa/phòng',

                                              style:
                                                  const TextStyle(
                                                color:
                                                    DaoTaoColors.muted,

                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),


                                  // =================================
                                  // TRỰC TIẾP / ONLINE
                                  // =================================

                                  if (selected &&
                                      lopHoTroOnline) ...[
                                    const SizedBox(
                                      width: 12,
                                    ),

                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),

                                      decoration:
                                          BoxDecoration(
                                        color:
                                            const Color(
                                          0xFFF8FAFC,
                                        ),

                                        borderRadius:
                                            BorderRadius.circular(
                                          9,
                                        ),

                                        border:
                                            Border.all(
                                          color:
                                              DaoTaoColors.border,
                                        ),
                                      ),

                                      child:
                                          DropdownButtonHideUnderline(
                                        child:
                                            DropdownButton<bool>(
                                          value:
                                              online,

                                          items:
                                              const [
                                            DropdownMenuItem<bool>(
                                              value:
                                                  false,

                                              child:
                                                  Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_rounded,
                                                    size: 17,
                                                  ),

                                                  SizedBox(
                                                    width: 6,
                                                  ),

                                                  Text(
                                                    'Trực tiếp',
                                                  ),
                                                ],
                                              ),
                                            ),

                                            DropdownMenuItem<bool>(
                                              value:
                                                  true,

                                              child:
                                                  Row(
                                                children: [
                                                  Icon(
                                                    Icons.video_camera_front_rounded,
                                                    size: 17,
                                                  ),

                                                  SizedBox(
                                                    width: 6,
                                                  ),

                                                  Text(
                                                    'Online',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],

                                          onChanged:
                                              (value) {
                                            if (value ==
                                                null) {
                                              return;
                                            }

                                            setState(() {
                                              _selected[
                                                      item.maSo] =
                                                  value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }


  // ==========================================================
  // TAB 3 - THAM GIA HỢP LỆ
  // ==========================================================

  Widget _buildValidTab(
    DaoTaoV2Provider provider,
  ) {
    final keyword =
        _validSearchController
            .text
            .trim()
            .toLowerCase();


    final items =
        provider.xacNhanHocVien
            .where(
              (item) =>
                  item.isHopLeDaoTao ==
                  true,
            )
            .where(
              (item) =>
                  _matchesSearch(
                item.maSo,
                item.hoVaTen,
                item.tenKhoaPhong,
                keyword,
              ),
            )
            .toList();


    final selectedCount =
        items.where(
      (item) =>
          _selectedRemoveHopLe
              .contains(
        item.maSo,
      ),
    ).length;


    final allSelected =
        items.isNotEmpty &&
        selectedCount ==
            items.length;


    final noneSelected =
        selectedCount == 0;


    return Column(
      children: [
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
                const Color(
              0xFFF0FDF4,
            ),

            borderRadius:
                BorderRadius.circular(
              10,
            ),

            border:
                Border.all(
              color:
                  const Color(
                0xFFBBF7D0,
              ),
            ),
          ),

          child:
              const Row(
            children: [
              Icon(
                Icons
                    .verified_user_rounded,

                color:
                    Color(
                  0xFF15803D,
                ),
              ),

              SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  'Danh sách này chỉ gồm những người '
                  'tham gia hợp lệ. '
                  'Tích người cần loại rồi bấm '
                  '"Xóa khỏi hợp lệ".',

                  style:
                      TextStyle(
                    color:
                        DaoTaoColors.text,

                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),


        const SizedBox(
          height: 12,
        ),


        TextField(
          controller:
              _validSearchController,

          onChanged:
              (_) {
            setState(() {});
          },

          decoration:
              const InputDecoration(
            hintText:
                'Tìm trong danh sách tham gia hợp lệ...',

            prefixIcon:
                Icon(
              Icons.search_rounded,
            ),

            border:
                OutlineInputBorder(),
          ),
        ),


        const SizedBox(
          height: 8,
        ),


        // ====================================================
        // TÍCH TẤT CẢ TAB 3
        // ====================================================

        Row(
          children: [
            Checkbox(
              tristate:
                  true,

              value:
                  allSelected
                      ? true
                      : noneSelected
                          ? false
                          : null,

              onChanged:
                  items.isEmpty
                      ? null
                      : (_) {
                          setState(() {
                            if (allSelected) {
                              for (final item
                                  in items) {
                                _selectedRemoveHopLe
                                    .remove(
                                  item.maSo,
                                );
                              }
                            } else {
                              for (final item
                                  in items) {
                                _selectedRemoveHopLe
                                    .add(
                                  item.maSo,
                                );
                              }
                            }
                          });
                        },
            ),

            InkWell(
              onTap:
                  items.isEmpty
                      ? null
                      : () {
                          setState(() {
                            if (allSelected) {
                              for (final item
                                  in items) {
                                _selectedRemoveHopLe
                                    .remove(
                                  item.maSo,
                                );
                              }
                            } else {
                              for (final item
                                  in items) {
                                _selectedRemoveHopLe
                                    .add(
                                  item.maSo,
                                );
                              }
                            }
                          });
                        },

              child:
                  const Text(
                'Tích tất cả',

                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),

            const Spacer(),

            Text(
              'Hợp lệ: '
              '${provider.xacNhanHocVien.where(
                    (x) =>
                        x.isHopLeDaoTao ==
                        true,
                  ).length}'
              ' • Đang chọn xóa: '
              '${_selectedRemoveHopLe.length}',

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,

                color:
                    Color(
                  0xFF15803D,
                ),
              ),
            ),
          ],
        ),


        const Divider(),


        Expanded(
          child:
              provider
                      .isLoadingXacNhanHocVien
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : items.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có học viên tham gia hợp lệ.',
                          ),
                        )
                      : ListView.separated(
                          itemCount:
                              items.length,

                          separatorBuilder:
                              (_, _) =>
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

                            final selected =
                                _selectedRemoveHopLe
                                    .contains(
                              item.maSo,
                            );


                            return CheckboxListTile(
                              value:
                                  selected,

                              controlAffinity:
                                  ListTileControlAffinity.leading,

                              onChanged:
                                  (value) {
                                setState(() {
                                  if (value ==
                                      true) {
                                    _selectedRemoveHopLe
                                        .add(
                                      item.maSo,
                                    );
                                  } else {
                                    _selectedRemoveHopLe
                                        .remove(
                                      item.maSo,
                                    );
                                  }
                                });
                              },

                              title:
                                  Text(
                                '${item.maSo} - '
                                '${item.hoVaTen ?? ''}',

                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),

                              subtitle:
                                  Padding(
                                padding:
                                    const EdgeInsets.only(
                                  top: 6,
                                ),

                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      item.tenKhoaPhong ??
                                          'Chưa xác định khoa/phòng',
                                    ),

                                    const SizedBox(
                                      height: 7,
                                    ),

                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 5,

                                      children: [
                                        // Kết quả chấm công vẫn giữ nguyên.
                                        _chamCongBadge(
                                          item,
                                        ),

                                        _smallBadge(
                                          item.isDangKyOnline
                                              ? 'Online'
                                              : 'Trực tiếp',

                                          item.isDangKyOnline
                                              ? const Color(
                                                  0xFF2563EB,
                                                )
                                              : const Color(
                                                  0xFF475569,
                                                ),
                                        ),

                                        _smallBadge(
                                          'Tham gia hợp lệ',
                                          const Color(
                                            0xFF15803D,
                                          ),
                                        ),

                                        if (item.isBoSungSau)
                                          _smallBadge(
                                            'Bổ sung sau',
                                            const Color(
                                              0xFF7C3AED,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }


  // ==========================================================
  // SAVE TAB 1
  // ==========================================================

  Future<void> _saveXacNhan() async {
    final provider =
        context.read<
            DaoTaoV2Provider>();


    final ok =
        await provider
            .saveXacNhanHocVien(
      idLopDaoTao:
          widget.item.idLopDaoTao,

      nhanViens:
          Map<String, bool>.from(
        _hopLeValues,
      ),
    );


    if (!mounted) {
      return;
    }


    if (!ok) {
      _message(
        provider.errorMessage ??
            'Không thể lưu xác nhận học viên.',
      );

      return;
    }


    await _loadRegistered();


    if (!mounted) {
      return;
    }


    _message(
      'Đã lưu xác nhận tham gia đào tạo.',
    );
  }


  // ==========================================================
  // SAVE TAB 2
  // ==========================================================

  Future<void> _saveBoSung() async {
    final provider =
        context.read<
            DaoTaoV2Provider>();


    final result =
        await provider
            .boSungNguoiDangKy(
      idLopDaoTao:
          widget.item.idLopDaoTao,

      nhanViens:
          Map<String, bool>.from(
        _selected,
      ),
    );


    if (!mounted) {
      return;
    }


    if (result == null) {
      _message(
        provider.errorMessage ??
            'Không thể bổ sung học viên.',
      );

      return;
    }


    if (result.soNguoiBoSung >
        0) {
      setState(() {
        for (final maSo
            in result.daBoSung) {
          _selected.remove(
            maSo,
          );
        }
      });


      await _loadRegistered();


      if (!mounted) {
        return;
      }


      _message(
        'Đã bổ sung '
        '${result.soNguoiBoSung} người vào lớp.',
      );
    } else {
      _message(
        'Không có nhân viên nào được bổ sung.',
      );
    }
  }


  // ==========================================================
  // TAB 3
  // XÓA KHỎI THAM GIA HỢP LỆ
  //
  // IsHopLeDaoTao true -> false
  // ==========================================================

  Future<void> _removeHopLe() async {
    if (_selectedRemoveHopLe
        .isEmpty) {
      return;
    }


    final confirm =
        await showDialog<bool>(
      context: context,

      builder:
          (dialogContext) =>
              AlertDialog(
        title:
            const Text(
          'Xóa khỏi tham gia hợp lệ?',
        ),

        content:
            Text(
          'Bạn đang chọn '
          '${_selectedRemoveHopLe.length} người.\n\n'
          'Sau khi xác nhận, '
          'IsHopLeDaoTao sẽ được chuyển thành False.',
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

          FilledButton(
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  const Color(
                0xFFB42318,
              ),
            ),

            onPressed:
                () =>
                    Navigator.pop(
              dialogContext,
              true,
            ),

            child:
                const Text(
              'Xác nhận xóa',
            ),
          ),
        ],
      ),
    );


    if (confirm !=
        true) {
      return;
    }


    if (!mounted) {
      return;
    }


    final provider =
        context.read<
            DaoTaoV2Provider>();


    final values =
        <String, bool>{
      for (final maSo
          in _selectedRemoveHopLe)
        maSo: false,
    };


    final ok =
        await provider
            .saveXacNhanHocVien(
      idLopDaoTao:
          widget.item.idLopDaoTao,

      nhanViens:
          values,
    );


    if (!mounted) {
      return;
    }


    if (!ok) {
      _message(
        provider.errorMessage ??
            'Không thể xóa học viên khỏi danh sách hợp lệ.',
      );

      return;
    }


    setState(() {
      _selectedRemoveHopLe
          .clear();
    });


    await _loadRegistered();


    if (!mounted) {
      return;
    }


    _message(
      'Đã cập nhật danh sách tham gia hợp lệ.',
    );
  }


  // ==========================================================
  // SEARCH HELPER
  // ==========================================================

  bool _matchesSearch(
    String maSo,
    String? hoVaTen,
    String? tenKhoaPhong,
    String keyword,
  ) {
    if (keyword.isEmpty) {
      return true;
    }

    return maSo
            .toLowerCase()
            .contains(
              keyword,
            )
        ||
        (hoVaTen ?? '')
            .toLowerCase()
            .contains(
              keyword,
            )
        ||
        (tenKhoaPhong ?? '')
            .toLowerCase()
            .contains(
              keyword,
            );
  }


  // ==========================================================
  // BADGE
  // ==========================================================

  Widget _smallBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.10,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),

        border:
            Border.all(
          color:
              color.withValues(
            alpha: 0.25,
          ),
        ),
      ),

      child:
          Text(
        text,

        style:
            TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }


  // ==========================================================
  // BUSY
  // ==========================================================

  bool _isBusy(
    DaoTaoV2Provider provider,
  ) {
    return provider
            .isSavingXacNhanHocVien
        ||
        provider
            .isBoSungNguoiDangKy;
  }


  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _message(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          message,
        ),
      ),
    );
  }
}