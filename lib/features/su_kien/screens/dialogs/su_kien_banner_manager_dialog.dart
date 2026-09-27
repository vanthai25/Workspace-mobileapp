import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/su_kien_v2_models.dart';
import '../../../../providers/su_kien_v2_provider.dart';
import 'su_kien_banner_form_dialog.dart';


class SuKienBannerManagerDialog
    extends StatelessWidget {
  final SuKienV2Model event;

  const SuKienBannerManagerDialog({
    super.key,
    required this.event,
  });


  SuKienV2Model _currentEvent(
    SuKienV2Provider provider,
  ) {
    for (final item
        in provider.items) {
      if (item.idSuKien ==
          event.idSuKien) {
        return item;
      }
    }

    return event;
  }


  Future<void> _openForm(
    BuildContext context,
    SuKienV2Provider provider, {
    SuKienBannerV2Model? banner,
  }) async {
    await showDialog<bool>(
      context:
          context,

      barrierDismissible:
          false,

      builder:
          (_) =>
              ChangeNotifierProvider.value(
        value:
            provider,

        child:
            SuKienBannerFormDialog(
          idSuKien:
              event.idSuKien,

          banner:
              banner,
        ),
      ),
    );
  }


  Future<void> _delete(
    BuildContext context,
    SuKienV2Provider provider,
    SuKienBannerV2Model banner,
  ) async {
    final confirm =
        await showDialog<bool>(
      context:
          context,

      builder:
          (dialogContext) =>
              AlertDialog(
        title:
            const Text(
          'Xóa banner?',
        ),

        content:
            Text(
          'Bạn có chắc muốn xóa '
          '"${banner.tieuDe?.trim().isNotEmpty == true ? banner.tieuDe : banner.fileName ?? 'Banner'}"?',
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

          FilledButton.icon(
            style:
                FilledButton.styleFrom(
              backgroundColor:
                  const Color(
                0xFFC43C35,
              ),
            ),

            onPressed:
                () =>
                    Navigator.pop(
              dialogContext,
              true,
            ),

            icon:
                const Icon(
              Icons.delete_outline,
            ),

            label:
                const Text(
              'Xóa',
            ),
          ),
        ],
      ),
    );

    if (confirm != true ||
        !context.mounted) {
      return;
    }

    final ok =
        await provider
            .deleteBanner(
      idSuKien:
          event.idSuKien,

      idBanner:
          banner.idBanner,
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          ok
              ? 'Đã xóa banner.'
              : provider
                      .bannerErrorMessage ??
                  'Không thể xóa banner.',
        ),

        backgroundColor:
            ok
                ? const Color(
                    0xFF14845E,
                  )
                : const Color(
                    0xFFC43C35,
                  ),
      ),
    );
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    return Consumer<
        SuKienV2Provider>(
      builder:
          (
        context,
        provider,
        child,
      ) {
        final current =
            _currentEvent(
          provider,
        );

        final banners =
            [...current.banners]
              ..sort(
                (a, b) {
                  final order =
                      a.thuTu.compareTo(
                    b.thuTu,
                  );

                  if (order != 0) {
                    return order;
                  }

                  return a.idBanner
                      .compareTo(
                    b.idBanner,
                  );
                },
              );

        return Dialog(
          insetPadding:
              const EdgeInsets.all(
            28,
          ),

          child:
              SizedBox(
            width:
                1080,

            height:
                720,

            child:
                Column(
              children: [
                _header(
                  context,
                  provider,
                  current,
                ),

                const Divider(
                  height:
                      1,
                ),

                Expanded(
                  child:
                      banners.isEmpty
                          ? _empty(
                              context,
                              provider,
                            )
                          : GridView.builder(
                              padding:
                                  const EdgeInsets.all(
                                18,
                              ),

                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent:
                                    520,

                                mainAxisExtent:
                                    330,

                                crossAxisSpacing:
                                    16,

                                mainAxisSpacing:
                                    16,
                              ),

                              itemCount:
                                  banners.length,

                              itemBuilder:
                                  (
                                context,
                                index,
                              ) {
                                return _bannerCard(
                                  context,
                                  provider,
                                  banners[index],
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
  }


  Widget _header(
    BuildContext context,
    SuKienV2Provider provider,
    SuKienV2Model current,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        16,
        14,
        16,
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
                0xFFEAF5FC,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                const Icon(
              Icons.photo_library_outlined,

              color:
                  Color(
                0xFF1274BC,
              ),
            ),
          ),

          const SizedBox(
            width:
                12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Quản lý banner',

                  style:
                      TextStyle(
                    fontSize:
                        18,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height:
                      2,
                ),

                Text(
                  '${current.tenSuKien} • ${current.banners.length} banner',

                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF6D7F8E,
                    ),

                    fontSize:
                        11.5,
                  ),
                ),
              ],
            ),
          ),

          FilledButton.icon(
            onPressed:
                provider.isSavingBanner
                    ? null
                    : () =>
                        _openForm(
                          context,
                          provider,
                        ),

            icon:
                const Icon(
              Icons.add_photo_alternate_outlined,
            ),

            label:
                const Text(
              'Thêm banner',
            ),
          ),

          const SizedBox(
            width:
                8,
          ),

          IconButton(
            tooltip:
                'Đóng',

            onPressed:
                () =>
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
    );
  }


  Widget _empty(
    BuildContext context,
    SuKienV2Provider provider,
  ) {
    return Center(
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          const Icon(
            Icons.image_not_supported_outlined,

            size:
                62,

            color:
                Color(
              0xFFB2BEC8,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          const Text(
            'Sự kiện chưa có banner.',

            style:
                TextStyle(
              fontSize:
                  15,

              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height:
                5,
          ),

          const Text(
            'Tải ảnh lên để banner xuất hiện trên trang chủ.',

            style:
                TextStyle(
              color:
                  Color(
                0xFF718394,
              ),
            ),
          ),

          const SizedBox(
            height:
                16,
          ),

          FilledButton.icon(
            onPressed:
                () =>
                    _openForm(
              context,
              provider,
            ),

            icon:
                const Icon(
              Icons.add_photo_alternate_outlined,
            ),

            label:
                const Text(
              'Thêm banner đầu tiên',
            ),
          ),
        ],
      ),
    );
  }


  Widget _bannerCard(
    BuildContext context,
    SuKienV2Provider provider,
    SuKienBannerV2Model banner,
  ) {
    return Container(
      clipBehavior:
          Clip.antiAlias,

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          15,
        ),

        border:
            Border.all(
          color:
              const Color(
            0xFFE0E8EF,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black
                    .withValues(
              alpha:
                  .04,
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
          SizedBox(
            height:
                175,

            width:
                double.infinity,

            child:
                FutureBuilder<
                    Uint8List?>(
              future:
                  provider
                      .loadBannerImage(
                banner.idBanner,
              ),

              builder:
                  (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                        ConnectionState
                            .waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final bytes =
                    snapshot.data;

                if (bytes == null ||
                    bytes.isEmpty) {
                  return Container(
                    color:
                        const Color(
                      0xFFF2F5F7,
                    ),

                    alignment:
                        Alignment.center,

                    child:
                        const Icon(
                      Icons.broken_image_outlined,

                      size:
                          42,

                      color:
                          Color(
                        0xFF9BA9B4,
                      ),
                    ),
                  );
                }

                return Image.memory(
                  bytes,

                  fit:
                      BoxFit.cover,

                  width:
                      double.infinity,
                );
              },
            ),
          ),

          Expanded(
            child:
                Padding(
              padding:
                  const EdgeInsets.all(
                13,
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            Text(
                          banner.tieuDe
                                      ?.trim()
                                      .isNotEmpty ==
                                  true
                              ? banner.tieuDe!
                              : banner.fileName ??
                                  'Banner',

                          maxLines:
                              1,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            fontSize:
                                13,

                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),

                      _activeBadge(
                        banner.isActive,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height:
                        6,
                  ),

                  Text(
                    'Thứ tự: ${banner.thuTu}'
                    '  •  '
                    '${_actionText(banner.actionType)}',

                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF6E8190,
                      ),

                      fontSize:
                          11,
                    ),
                  ),

                  if (banner.moTa
                          ?.trim()
                          .isNotEmpty ==
                      true) ...[
                    const SizedBox(
                      height:
                          5,
                    ),

                    Text(
                      banner.moTa!,

                      maxLines:
                          2,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF6E8190,
                        ),

                        fontSize:
                            11,
                      ),
                    ),
                  ],

                  const Spacer(),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,

                    children: [
                      OutlinedButton.icon(
                        onPressed:
                            () =>
                                _openForm(
                          context,
                          provider,
                          banner:
                              banner,
                        ),

                        icon:
                            const Icon(
                          Icons.edit_outlined,

                          size:
                              17,
                        ),

                        label:
                            const Text(
                          'Sửa',
                        ),
                      ),

                      const SizedBox(
                        width:
                            8,
                      ),

                      IconButton(
                        tooltip:
                            'Xóa banner',

                        onPressed:
                            provider.deletingBannerId ==
                                    banner.idBanner
                                ? null
                                : () =>
                                    _delete(
                                      context,
                                      provider,
                                      banner,
                                    ),

                        icon:
                            provider.deletingBannerId ==
                                    banner.idBanner
                                ? const SizedBox(
                                    width:
                                        18,
                                    height:
                                        18,

                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline,

                                    color:
                                        Color(
                                      0xFFC43C35,
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
    );
  }


  Widget _activeBadge(
    bool active,
  ) {
    final color =
        active
            ? const Color(
                0xFF14845E,
              )
            : const Color(
                0xFF7B8791,
              );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            8,
        vertical:
            4,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha:
              .1,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child:
          Text(
        active
            ? 'Đang bật'
            : 'Đang tắt',

        style:
            TextStyle(
          color:
              color,

          fontSize:
              10,

          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }


  String _actionText(
    String? action,
  ) {
    switch (
        action?.toLowerCase()) {
      case 'url':
        return 'Mở URL';

      case 'screen':
        return 'Mở màn hình';

      case 'pdf':
        return 'Mở PDF';

      case 'article':
        return 'Bài viết';

      default:
        return 'Không hành động';
    }
  }
}