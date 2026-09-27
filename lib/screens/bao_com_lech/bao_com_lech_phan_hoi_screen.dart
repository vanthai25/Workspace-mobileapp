import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/bao_com_lech_model.dart';
import '../../providers/bao_com_lech_provider.dart';
import '../../utils/helpers.dart';

class BaoComLechPhanHoiScreen
    extends StatefulWidget {
  final BaoComLechModel item;

  const BaoComLechPhanHoiScreen({
    super.key,
    required this.item,
  });

  @override
  State<BaoComLechPhanHoiScreen>
      createState() =>
          _BaoComLechPhanHoiScreenState();
}

class _BaoComLechPhanHoiScreenState
    extends State<
        BaoComLechPhanHoiScreen> {
  final Color primaryColor =
      const Color(0xFF1274BC);

  final ImagePicker _picker =
      ImagePicker();

  late final TextEditingController
      _phanHoiController;

  XFile? _selectedImage;

  bool _xoaAnhCu = false;

  @override
  void initState() {
    super.initState();

    _phanHoiController =
        TextEditingController(
      text:
          widget.item.phanHoi ??
              '',
    );
  }

  @override
  void dispose() {
    _phanHoiController.dispose();

    super.dispose();
  }

  bool get _isEdit =>
      widget.item.keToanDuyet ==
      1;

  // =========================================================
  // PICK IMAGE
  // =========================================================

  Future<void>
      _showImageSource() async {
    final ImageSource? source =
        await showModalBottomSheet<
            ImageSource>(
      context: context,
      builder: (
        BuildContext context,
      ) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading:
                    const Icon(
                  Icons
                      .photo_library_outlined,
                ),
                title:
                    const Text(
                  'Chọn từ thư viện',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    ImageSource.gallery,
                  );
                },
              ),

              ListTile(
                leading:
                    const Icon(
                  Icons
                      .photo_camera_outlined,
                ),
                title:
                    const Text(
                  'Chụp ảnh',
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    ImageSource.camera,
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final XFile? image =
        await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1800,
    );

    if (image == null ||
        !mounted) {
      return;
    }

    setState(() {
      _selectedImage = image;

      /*
       * Chọn ảnh mới thì không
       * cần xóa ảnh cũ riêng.
       */
      _xoaAnhCu = false;
    });
  }

  // =========================================================
  // VIEW OLD IMAGE
  // =========================================================

  Future<void>
      _viewOldImage() async {
    final Future<Uint8List?> future =
        context
            .read<
                BaoComLechProvider>()
            .getHinhAnh(
      widget.item.id,
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
                  height: 250,
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
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // SUBMIT
  // =========================================================

  Future<void> _submit() async {
    final String noiDung =
        _phanHoiController
            .text
            .trim();

    if (noiDung.isEmpty) {
      AppHelpers.showSnackBar(
        'Vui lòng nhập nội dung phản hồi.',
        isError: true,
      );

      return;
    }

    final BaoComLechProvider
        provider =
        context.read<
            BaoComLechProvider>();

    final bool success =
        await provider.savePhanHoi(
      id: widget.item.id,
      noiDung: noiDung,
      hinhAnhPath:
          _selectedImage?.path,
      xoaHinhAnh:
          _xoaAnhCu,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      AppHelpers.showSnackBar(
        provider.errorMessage ??
            'Không thể gửi phản hồi.',
        isError: true,
      );

      return;
    }

    AppHelpers.showSnackBar(
      _isEdit
          ? 'Cập nhật phản hồi thành công.'
          : 'Gửi phản hồi thành công.',
      isError: false,
    );

    Navigator.pop(
      context,
      true,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final BaoComLechProvider
        provider =
        context.watch<
            BaoComLechProvider>();

    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF4F7FB,
      ),

      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'Sửa phản hồi'
              : 'Phản hồi lệch cơm',
        ),
        backgroundColor:
            primaryColor,
        foregroundColor:
            Colors.white,
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            // =================================================
            // THÔNG TIN LỆCH
            // =================================================

            Container(
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
                    BorderRadius
                        .circular(
                  16,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  const Text(
                    'NỘI DUNG LỆCH',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.blueGrey,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    widget.item
                            .noiDung ??
                        'Không có nội dung.',
                    style:
                        const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // PHẢN HỒI
            // =================================================

            const Text(
              'Nội dung phản hồi',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            TextField(
              controller:
                  _phanHoiController,

              minLines: 4,
              maxLines: 8,

              decoration:
                  InputDecoration(
                hintText:
                    'Nhập nội dung phản hồi...',

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
              height: 18,
            ),

            // =================================================
            // IMAGE
            // =================================================

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ảnh đính kèm',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed:
                      _showImageSource,

                  icon:
                      const Icon(
                    Icons
                        .add_photo_alternate_outlined,
                  ),

                  label:
                      const Text(
                    'Chọn ảnh',
                  ),
                ),
              ],
            ),

            if (_selectedImage !=
                null)
              Container(
                width:
                    double.infinity,

                margin:
                    const EdgeInsets
                        .only(
                  top: 8,
                ),

                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),

                      child:
                          Image.file(
                        File(
                          _selectedImage!
                              .path,
                        ),

                        width:
                            double.infinity,

                        height: 220,

                        fit:
                            BoxFit.cover,
                      ),
                    ),

                    Positioned(
                      top: 8,
                      right: 8,

                      child:
                          CircleAvatar(
                        backgroundColor:
                            Colors
                                .black54,

                        child:
                            IconButton(
                          icon:
                              const Icon(
                            Icons.close,
                            color:
                                Colors.white,
                          ),

                          onPressed:
                              () {
                            setState(
                              () {
                                _selectedImage =
                                    null;
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )

            else if (_isEdit &&
                widget.item
                    .coHinhAnh &&
                !_xoaAnhCu)
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
                      Colors.white,

                  borderRadius:
                      BorderRadius
                          .circular(
                    12,
                  ),

                  border:
                      Border.all(
                    color: Colors
                        .grey
                        .shade200,
                  ),
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons
                          .image_outlined,
                      color:
                          primaryColor,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    const Expanded(
                      child: Text(
                        'Đã có ảnh đính kèm',
                      ),
                    ),

                    TextButton(
                      onPressed:
                          _viewOldImage,

                      child:
                          const Text(
                        'Xem',
                      ),
                    ),

                    IconButton(
                      tooltip:
                          'Xóa ảnh',

                      onPressed: () {
                        setState(() {
                          _xoaAnhCu =
                              true;
                        });
                      },

                      icon:
                          const Icon(
                        Icons
                            .delete_outline,
                        color:
                            Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

            if (_xoaAnhCu)
              Padding(
                padding:
                    const EdgeInsets
                        .only(
                  top: 8,
                ),

                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ảnh cũ sẽ được xóa.',
                        style:
                            TextStyle(
                          color:
                              Colors.red,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          _xoaAnhCu =
                              false;
                        });
                      },

                      child:
                          const Text(
                        'Hoàn tác',
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(
              height: 28,
            ),

            SizedBox(
              width:
                  double.infinity,

              height: 50,

              child:
                  ElevatedButton.icon(
                onPressed:
                    provider.isProcessing
                        ? null
                        : _submit,

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
                      12,
                    ),
                  ),
                ),

                icon:
                    provider.isProcessing
                        ? const SizedBox(
                            width:
                                20,
                            height:
                                20,
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

                label: Text(
                  _isEdit
                      ? 'CẬP NHẬT PHẢN HỒI'
                      : 'GỬI PHẢN HỒI',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}