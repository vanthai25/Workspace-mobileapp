import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/nhan_vien_v2_models.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/nhan_vien_v2_service.dart';
import '../services/nhanvien_service.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String manv;

  const ProfileScreen({super.key, required this.manv});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryColor = Color(0xFF1274BC);

  static const Color bgColor = Color(0xFFF0F2F5);

  late final NhanVienV2Service _service;
  late final NhanvienService _legacyNhanVienService;
  Uint8List? _legacyAvatar;

  late Future<NhanVienProfileV2Model> _profileFuture;

  bool _initialized = false;
  bool _isMyProfile = false;

  @override
  void initState() {
    super.initState();

    _service = NhanVienV2Service(ApiClient().dio);
    _legacyNhanVienService = NhanvienService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    final currentManv = context.read<AuthProvider>().currentManv;

    _isMyProfile = _normalizeMaNv(currentManv) == _normalizeMaNv(widget.manv);

    _profileFuture = _loadProfile();

    _initialized = true;
  }

  String _normalizeMaNv(String? value) {
    return value?.trim().toUpperCase() ?? '';
  }

  Uint8List? _decodeAvatarBytes(Object? rawValue) {
    if (rawValue == null) return null;
    if (rawValue is Uint8List) return rawValue.isEmpty ? null : rawValue;

    String value = rawValue.toString().trim();
    if (value.isEmpty) return null;

    final int commaIndex = value.indexOf(',');
    if (value.toLowerCase().startsWith('data:') && commaIndex >= 0) {
      value = value.substring(commaIndex + 1);
    }

    value = value.replaceAll(RegExp(r'\s+'), '');
    if (value.isEmpty) return null;

    try {
      final bytes = base64Decode(base64.normalize(value));
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  Future<NhanVienProfileV2Model> _loadProfile() async {
    final NhanVienProfileV2Model profile;
    if (_isMyProfile) {
      profile = await _service.getMe();
    } else {
      profile = await _service.getHoSo(widget.manv);
    }

    _legacyAvatar = null;
    if (profile.avatarBytes == null) {
      try {
        final legacyEmployee = await _legacyNhanVienService.getNhanVienById(
          widget.manv,
        );
        _legacyAvatar = _decodeAvatarBytes(legacyEmployee?.anh);
      } catch (_) {
        // Hồ sơ vẫn hiển thị nếu nguồn ảnh nhân sự cũ không khả dụng.
      }
    }

    return profile;
  }

  Future<void> _reload() async {
    setState(() {
      _profileFuture = _loadProfile();
    });

    await _profileFuture;
  }

  static String formatDate(DateTime? value) {
    if (value == null) {
      return 'Chưa cập nhật';
    }

    if (value.year <= 1900) {
      return 'Chưa cập nhật';
    }

    return DateFormat('dd/MM/yyyy').format(value);
  }

  static String formatNumber(num? value) {
    if (value == null) {
      return 'Chưa cập nhật';
    }

    if (value is int || value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  static String textOrEmpty(String? value) {
    return value?.trim() ?? '';
  }

  static String joinText(Iterable<String?> values, {String separator = ' • '}) {
    return values
        .map((x) => x?.trim() ?? '')
        .where((x) => x.isNotEmpty)
        .join(separator);
  }

  static String? visibleJobTitle(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return null;

    final String comparison = normalized.toLowerCase();
    if (comparison == 'không' || comparison == 'khong') {
      return null;
    }

    return normalized;
  }

  static String gioiTinhText(bool? value) {
    if (value == null) {
      return 'Chưa cập nhật';
    }

    return value ? 'Nam' : 'Nữ';
  }

  String _titleCongTac(ViTriCongTacV2Model item) {
    final title = joinText([item.tenChucDanh, visibleJobTitle(item.tenChucVu)]);

    if (title.isNotEmpty) {
      return title;
    }

    return 'Vị trí công tác';
  }

  String _subtitleCongTac(ViTriCongTacV2Model item) {
    final result = joinText([item.tenKhoaPhong, item.tenToDoi]);

    return result.isEmpty ? 'Chưa cập nhật đơn vị' : result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<NhanVienProfileV2Model>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error);
          }

          final profile = snapshot.data;

          if (profile == null) {
            return _buildError('Không có dữ liệu nhân viên.');
          }

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildHeader(profile),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                    child: Column(
                      children: [
                        _buildThongTinCaNhan(profile),

                        const SizedBox(height: 16),

                        _buildThongTinLienLac(profile),

                        const SizedBox(height: 16),

                        _buildGiayTo(profile),

                        const SizedBox(height: 16),

                        _buildCongTacHienTai(profile),

                        const SizedBox(height: 16),

                        _buildViTriHienTai(profile),

                        const SizedBox(height: 16),

                        _buildBangCap(profile),

                        const SizedBox(height: 16),

                        _buildCchn(profile),

                        const SizedBox(height: 16),

                        _buildChungChiCme(profile),

                        const SizedBox(height: 16),

                        _buildChungChiKhac(profile),

                        const SizedBox(height: 16),
                        _buildDaoTaoNoiBo(profile),

                        const SizedBox(height: 16),

                        _buildHopDong(profile),

                        const SizedBox(height: 16),

                        _buildLichSuCongTac(profile),

                        const SizedBox(height: 16),

                        _buildThanNhan(profile),

                        if (_isMyProfile) ...[
                          const SizedBox(height: 16),

                          _buildNganHang(profile),
                        ],

                        const SizedBox(height: 40),
                      ],
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

  Widget _buildError(Object? error) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey),

              const SizedBox(height: 16),

              const Text(
                'Không thể tải hồ sơ nhân viên',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                error?.toString() ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _profileFuture = _loadProfile();
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildHeader(NhanVienProfileV2Model profile) {
    final avatar =
        profile.avatarBytes ??
        _legacyAvatar ??
        (_isMyProfile
            ? _decodeAvatarBytes(context.read<AuthProvider>().currentAvatar)
            : null);

    final positionText = joinText([
      profile.tenChucDanh,
      visibleJobTitle(profile.tenChucVu),
    ]);

    final departmentText = joinText([profile.tenKhoaPhong, profile.tenToDoi]);

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,

      actions: [
        if (_isMyProfile)
          IconButton(
            tooltip: 'Đổi mật khẩu',
            icon: const Icon(Icons.vpn_key_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
      ],

      title: Text(
        _isMyProfile ? 'Hồ sơ của tôi' : 'Hồ sơ nhân viên',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),

      centerTitle: true,

      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4FA5E5),
                    Color(0xFF1274BC),
                    Color(0xFF0A4E80),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            Positioned(
              top: -40,
              right: -40,
              child: CircleAvatar(
                radius: 110,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
              ),
            ),

            Positioned(
              top: 160,
              left: -30,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 54, 24, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.white,
                        backgroundImage: avatar != null
                            ? MemoryImage(avatar)
                            : null,
                        child: avatar == null
                            ? Text(
                                _firstLetter(profile.hoVaTen),
                                style: const TextStyle(
                                  fontSize: 38,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 11),

                    Text(
                      profile.hoVaTen?.trim().isNotEmpty == true
                          ? profile.hoVaTen!
                          : 'Chưa cập nhật tên',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Mã nhân viên: ${profile.maSo}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (positionText.isNotEmpty ||
                        departmentText.isNotEmpty) ...[
                      const SizedBox(height: 10),

                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          joinText([
                            positionText,
                            departmentText,
                          ], separator: '\n'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThongTinCaNhan(NhanVienProfileV2Model p) {
    return SectionCard(
      title: 'Thông tin cá nhân',
      icon: Icons.person_rounded,
      primaryColor: primaryColor,
      children: [
        InfoItem(
          label: 'Ngày sinh',
          value: formatDate(p.namSinh),
          icon: Icons.cake_rounded,
        ),

        InfoItem(
          label: 'Giới tính',
          value: gioiTinhText(p.gioiTinh),
          icon: Icons.wc_rounded,
        ),

        InfoItem(label: 'Dân tộc', value: p.danToc, icon: Icons.flag_rounded),

        InfoItem(
          label: 'Tôn giáo',
          value: p.tenTonGiao,
          icon: Icons.account_balance_rounded,
        ),

        InfoItem(
          label: 'Tình trạng hôn nhân',
          value: p.tenTinhTrangHonNhan,
          icon: Icons.favorite_rounded,
        ),

        InfoItem(
          label: 'Nơi sinh',
          value: p.noiSinh,
          icon: Icons.location_city_rounded,
        ),

        InfoItem(
          label: 'Quê quán',
          value: p.queQuan,
          icon: Icons.home_work_rounded,
        ),

        InfoItem(
          label: 'Trạng thái làm việc',
          value: p.isNghiViec == true ? 'Đã nghỉ việc' : 'Đang làm việc',
          icon: Icons.work_history_rounded,
        ),
      ],
    );
  }

  Widget _buildThongTinLienLac(NhanVienProfileV2Model p) {
    return SectionCard(
      title: 'Thông tin liên lạc',
      icon: Icons.contact_phone_rounded,
      primaryColor: primaryColor,
      children: [
        InfoItem(
          label: 'Số điện thoại',
          value: p.soDienThoai,
          icon: Icons.phone_android_rounded,
        ),

        InfoItem(
          label: 'Địa chỉ thường trú',
          value: p.diaChiThuongTru,
          icon: Icons.home_rounded,
        ),

        InfoItem(
          label: 'Nơi ở hiện tại',
          value: p.noiOHienTai,
          icon: Icons.location_on_rounded,
        ),
      ],
    );
  }

  Widget _buildGiayTo(NhanVienProfileV2Model p) {
    return SectionCard(
      title: 'Giấy tờ & thông tin nhân sự',
      icon: Icons.fingerprint_rounded,
      primaryColor: primaryColor,
      children: [
        InfoItem(
          label: 'CCCD / CMND',
          value: p.soCCCD,
          icon: Icons.credit_card_rounded,
        ),

        InfoItem(
          label: 'Ngày cấp CCCD',
          value: formatDate(p.ngayCapCCCD),
          icon: Icons.date_range_rounded,
        ),

        InfoItem(
          label: 'Nơi cấp CCCD',
          value: p.noiCapCCCD,
          icon: Icons.account_balance_wallet_rounded,
        ),

        InfoItem(
          label: 'Số BHXH',
          value: p.soBHXH,
          icon: Icons.health_and_safety_rounded,
        ),

        InfoItem(
          label: 'Mã BN Minh Lộ',
          value: p.maBNMinhLo,
          icon: Icons.local_hospital_rounded,
        ),

        InfoItem(
          label: 'ID tuyển dụng',
          value: p.idTuyenDung?.toString(),
          icon: Icons.how_to_reg_rounded,
        ),

        InfoItem(
          label: 'Loại nhân viên',
          value: p.loaiNhanVien?.toString(),
          icon: Icons.badge_rounded,
        ),
      ],
    );
  }

  Widget _buildCongTacHienTai(NhanVienProfileV2Model p) {
    return SectionCard(
      title: 'Công tác hiện tại',
      icon: Icons.work_rounded,
      primaryColor: primaryColor,
      children: [
        InfoItem(
          label: 'Khoa / Phòng',
          value: p.tenKhoaPhong,
          icon: Icons.corporate_fare_rounded,
        ),

        InfoItem(
          label: 'Tổ / Đội',
          value: p.tenToDoi,
          icon: Icons.group_work_rounded,
        ),

        InfoItem(
          label: 'Chức danh',
          value: p.tenChucDanh,
          icon: Icons.badge_rounded,
        ),

        if (visibleJobTitle(p.tenChucVu) != null)
          InfoItem(
            label: 'Chức vụ',
            value: visibleJobTitle(p.tenChucVu),
            icon: Icons.workspace_premium_rounded,
          ),
      ],
    );
  }

  Widget _buildViTriHienTai(NhanVienProfileV2Model p) {
    return ListSectionCard(
      title: 'Vị trí đang hiệu lực',
      icon: Icons.apartment_rounded,
      primaryColor: primaryColor,
      count: p.viTriCongTacHienTai.length,
      emptyText: 'Không có vị trí công tác đang hiệu lực.',
      children: p.viTriCongTacHienTai
          .map(
            (item) => ProfileRecordCard(
              icon: Icons.work_rounded,
              title: _titleCongTac(item),
              subtitle: _subtitleCongTac(item),
              rows: [
                ProfileRecordRow(
                  label: 'Ngày bắt đầu',
                  value: formatDate(item.ngayBatDau),
                ),
                ProfileRecordRow(
                  label: 'Ngày kết thúc',
                  value: item.ngayKetThuc == null
                      ? 'Không xác định'
                      : formatDate(item.ngayKetThuc),
                ),
                ProfileRecordRow(label: 'Tình trạng', value: item.tenTinhTrang),
                ProfileRecordRow(
                  label: 'Hình thức',
                  value: item.isKiemNhiem == true
                      ? 'Kiêm nhiệm'
                      : 'Vị trí chính',
                ),
                ProfileRecordRow(label: 'Tệp đính kèm', value: item.fileName),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildBangCap(NhanVienProfileV2Model p) {
    return ListSectionCard(
      title: 'Bằng cấp',
      icon: Icons.school_rounded,
      primaryColor: primaryColor,
      count: p.bangCap.length,
      emptyText: 'Chưa có thông tin bằng cấp.',
      children: p.bangCap.map((item) {
        final subtitle = joinText([item.tenTrinhDo, item.donViDaoTao]);

        return ProfileRecordCard(
          icon: Icons.school_rounded,
          title: item.tenBangCap.trim().isEmpty ? 'Bằng cấp' : item.tenBangCap,
          subtitle: subtitle,
          rows: [
            ProfileRecordRow(label: 'Trình độ', value: item.tenTrinhDo),
            ProfileRecordRow(label: 'Đơn vị đào tạo', value: item.donViDaoTao),
            ProfileRecordRow(
              label: 'Hình thức đào tạo',
              value: item.tenHinhThucDaoTao,
            ),
            ProfileRecordRow(label: 'Năm tốt nghiệp', value: item.namTotNghiep),
            ProfileRecordRow(label: 'Xếp loại', value: item.tenXepLoaiDaoTao),
            ProfileRecordRow(label: 'Tệp đính kèm', value: item.fileName),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCchn(NhanVienProfileV2Model p) {
    return ListSectionCard(
      title: 'Chứng chỉ hành nghề',
      icon: Icons.verified_rounded,
      primaryColor: primaryColor,
      count: p.cchn.length,
      emptyText: 'Chưa có chứng chỉ hành nghề.',
      children: p.cchn.map((item) {
        return ProfileRecordCard(
          icon: Icons.verified_user_rounded,
          title: textOrEmpty(item.soCchn).isEmpty
              ? 'Chứng chỉ hành nghề'
              : 'Số ${item.soCchn}',
          subtitle: item.vanBangChuyenMon,
          rows: [
            ProfileRecordRow(label: 'Số CCHN', value: item.soCchn),
            ProfileRecordRow(label: 'Nơi cấp', value: item.noiCap),
            ProfileRecordRow(
              label: 'Văn bằng chuyên môn',
              value: item.vanBangChuyenMon,
            ),
            ProfileRecordRow(
              label: 'Phạm vi hoạt động',
              value: item.phamViHoatDong,
            ),
            ProfileRecordRow(
              label: 'Ngày bắt đầu',
              value: formatDate(item.ngayBatDau),
            ),
            ProfileRecordRow(
              label: 'Ngày kết thúc',
              value: item.ngayKetThuc == null
                  ? 'Không xác định'
                  : formatDate(item.ngayKetThuc),
            ),
            ProfileRecordRow(
              label: 'Phạm vi bổ sung',
              value: item.isPhamViBoSung == true ? 'Có' : 'Không',
            ),
            ProfileRecordRow(label: 'Tệp đính kèm', value: item.fileName),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildChungChiCme(NhanVienProfileV2Model p) {
    return _buildChungChiSection(
      title: 'Chứng chỉ CME',
      icon: Icons.workspace_premium_rounded,
      items: p.chungChiCme,
    );
  }

  Widget _buildChungChiKhac(NhanVienProfileV2Model p) {
    return _buildChungChiSection(
      title: 'Chứng chỉ khác',
      icon: Icons.card_membership_rounded,
      items: p.chungChiKhac,
    );
  }
  Widget _buildDaoTaoNoiBo(
  NhanVienProfileV2Model p,
) {
  final items =
      p.daoTaoNoiVien;


  return ListSectionCard(
    title:
        'Đào tạo nội bộ',

    icon:
        Icons.cast_for_education_rounded,

    primaryColor:
        primaryColor,

    count:
        items.length,

    emptyText:
        'Chưa có thông tin đào tạo nội bộ.',

    children:
        items.map(
      (item) {
        // =====================================================
        // SUBTITLE
        // =====================================================

        String? thoiGianText;


        if (
          item.ngayBatDau != null &&
          item.ngayKetThuc != null
        ) {
          if (
            item.ngayBatDau!.year ==
                    item.ngayKetThuc!.year &&
            item.ngayBatDau!.month ==
                    item.ngayKetThuc!.month &&
            item.ngayBatDau!.day ==
                    item.ngayKetThuc!.day
          ) {
            thoiGianText =
                formatDate(
              item.ngayBatDau,
            );
          } else {
            thoiGianText =
                '${formatDate(item.ngayBatDau)}'
                ' - '
                '${formatDate(item.ngayKetThuc)}';
          }
        } else if (
          item.ngayBatDau != null
        ) {
          thoiGianText =
              formatDate(
            item.ngayBatDau,
          );
        }


        final subtitle =
            joinText(
          [
            thoiGianText,
            item.diaDiem,
          ],
        );


        // =====================================================
        // HÌNH THỨC HỌC
        // =====================================================

        final hinhThucHoc =
            item.isDangKyOnline
                ? 'Online'
                : 'Trực tiếp';


        // =====================================================
        // TÊN LỚP
        // =====================================================

        final tenLop =
            item.tenLopDaoTao
                    .trim()
                    .isEmpty
                ? 'Đào tạo nội bộ'
                : item.tenLopDaoTao;


        return ProfileRecordCard(
          icon:
              Icons.school_rounded,

          title:
              tenLop,

          subtitle:
              subtitle.isEmpty
                  ? null
                  : subtitle,

          rows: [
            // ===============================================
            // THỜI GIAN
            // ===============================================

            if (
              item.ngayBatDau != null
            )
              ProfileRecordRow(
                label:
                    'Ngày bắt đầu',

                value:
                    formatDate(
                  item.ngayBatDau,
                ),
              ),


            if (
              item.ngayKetThuc != null
            )
              ProfileRecordRow(
                label:
                    'Ngày kết thúc',

                value:
                    formatDate(
                  item.ngayKetThuc,
                ),
              ),


            // ===============================================
            // THỜI GIAN CHI TIẾT
            // ===============================================

            ProfileRecordRow(
              label:
                  'Thời gian',

              value:
                  item.thoiGianDetails,
            ),


            // ===============================================
            // SỐ TIẾT
            // ===============================================

            ProfileRecordRow(
              label:
                  'Số tiết',

              value:
                  item.soTiet == null
                      ? null
                      : formatNumber(
                          item.soTiet,
                        ),
            ),


            // ===============================================
            // BÁO CÁO VIÊN
            // ===============================================

            ProfileRecordRow(
              label:
                  'Báo cáo viên',

              value:
                  item.baoCaoVien,
            ),


            // ===============================================
            // ĐƠN VỊ GIẢNG DẠY
            // ===============================================

            ProfileRecordRow(
              label:
                  'Đơn vị giảng dạy',

              value:
                  item.donViGiangDay,
            ),


            // ===============================================
            // ĐƠN VỊ ĐÀO TẠO
            // ===============================================

            ProfileRecordRow(
              label:
                  'Đơn vị đào tạo',

              value:
                  item.donViDaoTao,
            ),


            // ===============================================
            // HÌNH THỨC / LOẠI HÌNH
            // ===============================================

            ProfileRecordRow(
              label:
                  'Hình thức đào tạo',

              value:
                  item.tenHinhThucDaoTao,
            ),


            ProfileRecordRow(
              label:
                  'Loại hình đào tạo',

              value:
                  item.tenLoaiHinhDaoTao,
            ),


            // ===============================================
            // HỌC ONLINE / TRỰC TIẾP
            // ===============================================

            ProfileRecordRow(
              label:
                  'Hình thức tham gia',

              value:
                  hinhThucHoc,
            ),


            // ===============================================
            // ĐỊA ĐIỂM
            // ===============================================

            ProfileRecordRow(
              label:
                  'Địa điểm',

              value:
                  item.diaDiem,
            ),


            // ===============================================
            // THÀNH PHẦN THAM DỰ
            // ===============================================

            ProfileRecordRow(
              label:
                  'Thành phần tham dự',

              value:
                  item.tpThamDu,
            ),


            // ===============================================
            // BỔ SUNG SAU
            // Chỉ hiện nếu có.
            // ===============================================

            ProfileRecordRow(
              label:
                  'Đăng ký',

              value:
                  item.isBoSungSau
                      ? 'Bổ sung sau'
                      : null,
            ),


            // ===============================================
            // GHI CHÚ
            // ===============================================

            ProfileRecordRow(
              label:
                  'Ghi chú',

              value:
                  item.ghiChu,
            ),
          ],
        );
      },
    ).toList(),
  );
}
  Widget _buildChungChiSection({
    required String title,
    required IconData icon,
    required List<ChungChiNhanVienV2Model> items,
  }) {
    return ListSectionCard(
      title: title,
      icon: icon,
      primaryColor: primaryColor,
      count: items.length,
      emptyText: 'Chưa có dữ liệu.',
      children: items.map((item) {
        final subtitle = joinText([item.soChungChi, item.donViDaoTao]);

        return ProfileRecordCard(
          icon: Icons.verified_rounded,
          title: textOrEmpty(item.tenChungChi).isEmpty
              ? 'Chứng chỉ'
              : item.tenChungChi!,
          subtitle: subtitle,
          rows: [
            ProfileRecordRow(label: 'Số chứng chỉ', value: item.soChungChi),
            ProfileRecordRow(label: 'Đơn vị đào tạo', value: item.donViDaoTao),
            ProfileRecordRow(
              label: 'Hình thức đào tạo',
              value: item.tenHinhThucDaoTao,
            ),
            ProfileRecordRow(
              label: 'Ngày bắt đầu',
              value: formatDate(item.ngayBatDau),
            ),
            ProfileRecordRow(
              label: 'Ngày kết thúc',
              value: formatDate(item.ngayKetThuc),
            ),
            ProfileRecordRow(
              label: 'Ngày cấp',
              value: formatDate(item.ngayCap),
            ),
            ProfileRecordRow(
              label: 'Ngày hết hạn',
              value: item.ngayHetHan == null
                  ? 'Không xác định'
                  : formatDate(item.ngayHetHan),
            ),
            ProfileRecordRow(
              label: 'Số tiết',
              value: formatNumber(item.soTiet),
            ),
            ProfileRecordRow(label: 'Tệp đính kèm', value: item.fileName),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHopDong(NhanVienProfileV2Model p) {
    return ListSectionCard(
      title: 'Hợp đồng lao động',
      icon: Icons.description_rounded,
      primaryColor: primaryColor,
      count: p.hopDongLaoDong.length,
      emptyText: 'Chưa có hợp đồng lao động.',
      children: p.hopDongLaoDong.map((item) {
        return ProfileRecordCard(
          icon: Icons.assignment_rounded,
          title: item.soHopDong.trim().isEmpty
              ? 'Hợp đồng lao động'
              : 'HĐ ${item.soHopDong}',
          subtitle: item.tenLoaiHopDong,
          rows: [
            ProfileRecordRow(label: 'Số hợp đồng', value: item.soHopDong),
            ProfileRecordRow(
              label: 'Loại hợp đồng',
              value: item.tenLoaiHopDong,
            ),
            ProfileRecordRow(label: 'Ngày ký', value: formatDate(item.ngayKy)),
            ProfileRecordRow(
              label: 'Ngày kết thúc',
              value: item.ngayKetThuc == null
                  ? 'Không xác định'
                  : formatDate(item.ngayKetThuc),
            ),
            ProfileRecordRow(label: 'Tệp đính kèm', value: item.fileName),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLichSuCongTac(NhanVienProfileV2Model p) {
    return ListSectionCard(
      title: 'Lịch sử công tác',
      icon: Icons.history_rounded,
      primaryColor: primaryColor,
      count: p.lichSuViTriCongTac.length,
      emptyText: 'Chưa có lịch sử công tác.',
      children: p.lichSuViTriCongTac.map((item) {
        return ProfileRecordCard(
          icon: Icons.timeline_rounded,
          title: _titleCongTac(item),
          subtitle: _subtitleCongTac(item),
          rows: [
            ProfileRecordRow(label: 'Khoa / Phòng', value: item.tenKhoaPhong),
            ProfileRecordRow(label: 'Tổ / Đội', value: item.tenToDoi),
            ProfileRecordRow(label: 'Chức danh', value: item.tenChucDanh),
            ProfileRecordRow(
              label: 'Chức vụ',
              value: visibleJobTitle(item.tenChucVu),
            ),
            ProfileRecordRow(
              label: 'Từ ngày',
              value: formatDate(item.ngayBatDau),
            ),
            ProfileRecordRow(
              label: 'Đến ngày',
              value: item.ngayKetThuc == null
                  ? 'Hiện tại'
                  : formatDate(item.ngayKetThuc),
            ),
            ProfileRecordRow(
              label: 'Kiêm nhiệm',
              value: item.isKiemNhiem == true ? 'Có' : 'Không',
            ),
            ProfileRecordRow(label: 'Tình trạng', value: item.tenTinhTrang),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildThanNhan(NhanVienProfileV2Model p) {
    return ListSectionCard(
      title: 'Thân nhân',
      icon: Icons.family_restroom_rounded,
      primaryColor: primaryColor,
      count: p.thanNhan.length,
      emptyText: 'Chưa có thông tin thân nhân.',
      children: p.thanNhan.map((item) {
        return ProfileRecordCard(
          icon: Icons.person_outline_rounded,
          title: item.tenThanNhan.trim().isEmpty
              ? 'Thân nhân'
              : item.tenThanNhan,
          subtitle: item.moiQuanHe,
          rows: [
            ProfileRecordRow(label: 'Mối quan hệ', value: item.moiQuanHe),
            ProfileRecordRow(label: 'CCCD', value: item.soCCCD),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildNganHang(NhanVienProfileV2Model p) {
    return SectionCard(
      title: 'Thông tin ngân hàng',
      icon: Icons.account_balance_rounded,
      primaryColor: primaryColor,
      children: [
        InfoItem(
          label: 'Số tài khoản',
          value: p.taiKhoanNH,
          icon: Icons.numbers_rounded,
        ),

        InfoItem(
          label: 'Tên tài khoản',
          value: p.tenTaiKhoanNH,
          icon: Icons.person_rounded,
        ),

        InfoItem(
          label: 'Ngân hàng',
          value: p.tenNH,
          icon: Icons.account_balance_rounded,
        ),
      ],
    );
  }

  static String _firstLetter(String? name) {
    final value = name?.trim();

    if (value == null || value.isEmpty) {
      return '?';
    }

    final parts = value
        .split(RegExp(r'\s+'))
        .where((x) => x.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    return parts.last.substring(0, 1).toUpperCase();
  }
}

// =============================================================
// SECTION CARD
// =============================================================

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;
  final List<Widget> children;
  final bool initiallyExpanded;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.primaryColor,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ExpandableProfileSection(
      title: title,
      icon: icon,
      primaryColor: primaryColor,
      initiallyExpanded: initiallyExpanded,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(children: children),
      ),
    );
  }
}

// =============================================================
// LIST SECTION
// =============================================================

class ListSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;
  final int count;
  final String emptyText;
  final List<Widget> children;
  final bool initiallyExpanded;

  const ListSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.primaryColor,
    required this.count,
    required this.emptyText,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ExpandableProfileSection(
      title: title,
      icon: icon,
      primaryColor: primaryColor,
      count: count,
      initiallyExpanded: initiallyExpanded,
      body: children.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.grey[400]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      emptyText,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(11, 11, 11, 2),
              child: Column(children: children),
            ),
    );
  }
}

class _ExpandableProfileSection extends StatefulWidget {
  const _ExpandableProfileSection({
    required this.title,
    required this.icon,
    required this.primaryColor,
    required this.body,
    required this.initiallyExpanded,
    this.count,
  });

  final String title;
  final IconData icon;
  final Color primaryColor;
  final Widget body;
  final bool initiallyExpanded;
  final int? count;

  @override
  State<_ExpandableProfileSection> createState() =>
      _ExpandableProfileSectionState();
}

class _ExpandableProfileSectionState extends State<_ExpandableProfileSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF23435B).withValues(alpha: 0.055),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: _toggle,
              child: Semantics(
                button: true,
                expanded: _isExpanded,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.primaryColor,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF234057),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (widget.count != null) ...[
                        Container(
                          constraints: const BoxConstraints(minWidth: 28),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${widget.count}',
                            style: TextStyle(
                              color: widget.primaryColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                      ],
                      Text(
                        _isExpanded ? '' : '',
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: widget.primaryColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFE7EDF2)),
                widget.body,
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 240),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

// =============================================================
// INFO ITEM
// =============================================================

class InfoItem extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;

  const InfoItem({
    super.key,
    required this.label,
    this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = value?.trim() ?? '';

    final missing = trimmed.isEmpty || trimmed == 'Chưa cập nhật';

    final displayValue = missing ? 'Chưa cập nhật' : trimmed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: Colors.grey[500], size: 20),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: missing ? Colors.grey[400] : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// RECORD
// =============================================================

class ProfileRecordRow {
  final String label;
  final String? value;

  const ProfileRecordRow({required this.label, this.value});
}

class ProfileRecordCard extends StatelessWidget {
  final IconData icon;

  final String title;
  final String? subtitle;

  final List<ProfileRecordRow> rows;

  const ProfileRecordCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final visibleRows = rows.where((row) {
      final value = row.value?.trim();

      return value != null && value.isNotEmpty && value != 'Chưa cập nhật';
    }).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1274BC), size: 20),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF243447),
                      ),
                    ),

                    if (subtitle?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),

                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (visibleRows.isNotEmpty) ...[
            const SizedBox(height: 12),

            const Divider(),

            const SizedBox(height: 4),

            ...visibleRows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 125,
                      child: Text(
                        row.label,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),

                    Expanded(
                      child: Text(
                        row.value!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF34495E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
