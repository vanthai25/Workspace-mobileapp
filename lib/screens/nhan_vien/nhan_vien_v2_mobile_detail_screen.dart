import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/nhan_vien_mobile_v2_models.dart';
import '../../services/nhan_vien_mobile_v2_service.dart';

class NhanVienV2MobileDetailScreen
    extends StatefulWidget {
  final String maSo;

  final NhanVienMobileV2Service
      service;

  const NhanVienV2MobileDetailScreen({
    super.key,
    required this.maSo,
    required this.service,
  });

  @override
  State<NhanVienV2MobileDetailScreen>
      createState() =>
          _NhanVienV2MobileDetailScreenState();
}

class _NhanVienV2MobileDetailScreenState
    extends State<
        NhanVienV2MobileDetailScreen> {
  static const Color _primary =
      Color(0xFF1274BC);

  static const Color _background =
      Color(0xFFF4F7FB);

  static const Color _border =
      Color(0xFFE1E8EF);

  static const Color _muted =
      Color(0xFF66788A);

  NhanVienMobileDetailV2Model?
      _profile;

  Uint8List? _avatarBytes;

  bool _loading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results =
          await Future.wait([
        widget.service.getChiTiet(
          widget.maSo,
        ),
        widget.service.getAvatar(
          widget.maSo,
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile =
            results[0]
                as NhanVienMobileDetailV2Model;

        _avatarBytes =
            results[1] as Uint8List?;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            e.toString();

        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _background,
      appBar: AppBar(
        title:
            const Text(
          'Thông tin nhân viên',
        ),
        backgroundColor:
            Colors.white,
        surfaceTintColor:
            Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(
            color: _border,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null ||
        _profile == null) {
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
                Icons.error_outline,
                size: 44,
                color:
                    Color(
                  0xFFC43C35,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _errorMessage ??
                    'Không tải được thông tin nhân viên.',
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(
                height: 14,
              ),
              OutlinedButton.icon(
                onPressed:
                    _load,
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

    final p =
        _profile!;

    final accent =
        _chucVuColor(
      p.sttChucVu,
    );

    return RefreshIndicator(
      onRefresh:
          _load,
      child:
          SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          14,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            _profileHeader(
              p,
              accent,
            ),

            const SizedBox(
              height: 12,
            ),

            _section(
              title:
                  'Thông tin cơ bản',
              icon:
                  Icons.person_outline,
              children: [
                _infoRow(
                  'Mã nhân viên',
                  p.maSo,
                  Icons.badge_outlined,
                ),
                _infoRow(
                  'Ngày sinh',
                  _date(
                    p.namSinh,
                  ),
                  Icons.cake_outlined,
                ),
                _infoRow(
                  'Giới tính',
                  p.gioiTinh == null
                      ? null
                      : p.gioiTinh!
                          ? 'Nam'
                          : 'Nữ',
                  Icons.wc_outlined,
                ),
                _infoRow(
                  'Số điện thoại',
                  p.soDienThoai,
                  Icons.phone_outlined,
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            _section(
              title:
                  'Thông tin công tác',
              icon:
                  Icons.work_outline,
              children: [
                _infoRow(
                  'Khoa / Phòng',
                  p.tenKhoaPhong,
                  Icons.apartment_outlined,
                ),
                _infoRow(
                  'Tổ / Đội',
                  p.tenToDoi,
                  Icons.groups_outlined,
                ),
                _infoRow(
                  'Chức danh',
                  p.tenChucDanh,
                  Icons.badge_outlined,
                ),
                _infoRow(
                  'Chức vụ',
                  p.tenChucVu,
                  Icons.military_tech_outlined,
                  valueColor:
                      accent,
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            _section(
              title:
                  'Thông tin khác',
              icon:
                  Icons.location_on_outlined,
              children: [
                _infoRow(
                  'Quê quán',
                  p.queQuan,
                  Icons.home_work_outlined,
                ),
                _infoRow(
                  'Nơi ở hiện tại',
                  p.noiOHienTai,
                  Icons.home_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(
    NhanVienMobileDetailV2Model p,
    Color accent,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: .04,
            ),
            blurRadius:
                14,
            offset:
                const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.all(
              3,
            ),
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              border:
                  Border.all(
                color:
                    accent,
                width:
                    2.5,
              ),
            ),
            child:
                CircleAvatar(
              radius:
                  45,
              backgroundColor:
                  accent.withValues(
                alpha: .12,
              ),
              backgroundImage:
                  _avatarBytes !=
                          null
                      ? MemoryImage(
                          _avatarBytes!,
                        )
                      : null,
              child: _avatarBytes ==
                      null
                  ? Text(
                      _initials(
                        p.hoVaTen,
                      ),
                      style:
                          TextStyle(
                        color:
                            accent,
                        fontWeight:
                            FontWeight.w800,
                        fontSize:
                            22,
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            p.hoVaTen ??
                p.maSo,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(
                0xFF172B3E,
              ),
              fontSize:
                  19,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          if (_hasText(
            p.tenChucVu,
          )) ...[
            const SizedBox(
              height: 8,
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    12,
                vertical:
                    6,
              ),
              decoration:
                  BoxDecoration(
                color:
                    accent.withValues(
                  alpha:
                      .11,
                ),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child:
                  Text(
                p.tenChucVu!,
                style:
                    TextStyle(
                  color:
                      accent,
                  fontSize:
                      11,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],

          if (_hasText(
            p.tenChucDanh,
          )) ...[
            const SizedBox(
              height: 7,
            ),
            Text(
              p.tenChucDanh!,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    _muted,
                fontSize:
                    12.5,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],

          if (_hasText(
            p.tenKhoaPhong,
          )) ...[
            const SizedBox(
              height: 5,
            ),
            Text(
              p.tenKhoaPhong!,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    _muted,
                fontSize:
                    11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget>
        children,
  }) {
    return Container(
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
          color: _border,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              14,
              13,
              14,
              11,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size:
                      19,
                  color:
                      _primary,
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xFF243C50,
                    ),
                    fontSize:
                        13,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height:
                1,
            color:
                _border,
          ),

          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String? value,
    IconData icon, {
    Color? valueColor,
  }) {
    final hasValue =
        _hasText(value);

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            14,
        vertical:
            11,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width:
                32,
            height:
                32,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF1F6FA,
              ),
              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),
            child:
                Icon(
              icon,
              size:
                  16,
              color:
                  const Color(
                0xFF6D899D,
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    color:
                        _muted,
                    fontSize:
                        10.5,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  hasValue
                      ? value!
                      : '-',
                  style:
                      TextStyle(
                    color:
                        hasValue
                            ? valueColor ??
                                const Color(
                                  0xFF263F54,
                                )
                            : const Color(
                                0xFF9CAAB6,
                              ),
                    fontSize:
                        12.5,
                    fontWeight:
                        FontWeight.w600,
                    height:
                        1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _chucVuColor(
    int? stt,
  ) {
    if (stt == null) {
      return const Color(
        0xFF607D8B,
      );
    }

    if (stt <= 1) {
      return const Color(
        0xFFB42318,
      );
    }

    if (stt == 2) {
      return const Color(
        0xFFD97706,
      );
    }

    if (stt <= 4) {
      return const Color(
        0xFF7C3AED,
      );
    }

    if (stt <= 6) {
      return const Color(
        0xFF1274BC,
      );
    }

    if (stt <= 10) {
      return const Color(
        0xFF00897B,
      );
    }

    return const Color(
      0xFF607D8B,
    );
  }

  bool _hasText(
    String? value,
  ) =>
      value != null &&
      value.trim().isNotEmpty;

  String? _date(
    DateTime? value,
  ) {
    if (value == null) {
      return null;
    }

    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _initials(
    String? name,
  ) {
    if (name == null ||
        name.trim().isEmpty) {
      return '?';
    }

    final words =
        name
            .trim()
            .split(
              RegExp(
                r'\s+',
              ),
            )
            .where(
              (e) =>
                  e.isNotEmpty,
            )
            .toList();

    if (words.isEmpty) {
      return '?';
    }

    if (words.length ==
        1) {
      return words.first[0]
          .toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'
        .toUpperCase();
  }
}