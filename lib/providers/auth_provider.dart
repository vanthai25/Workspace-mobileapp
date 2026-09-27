import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_api_exception.dart';
import '../services/auth_interceptor.dart';
import '../services/auth_service.dart';
import '../services/nhan_vien_v2_service.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  // =========================================================
  // SESSION CODES
  // =========================================================

  static const Set<String> _terminalSessionCodes = {
    'SESSION_EXPIRED',
    'TOKEN_REUSED',
    'REFRESH_TOKEN_REQUIRED',
    'INVALID_REFRESH_TOKEN',
    'REFRESH_TOKEN_INVALID',
    'USER_NOT_FOUND',
    'INVALID_USER',
    'USER_LOCKED',
    'UNAUTHORIZED',
  };

  static const String _webVapidKey =
      'BCdITG3HVLcZ5fHUTGygyssquyuqfs3veJNofQOiMhL9diBXAfju0a5kkYXhOI4Q12nnBw5NR3LbeT9jb3NNGsk';

  final AuthService _authService = AuthService();

  late final NhanVienV2Service _nhanVienV2Service = NhanVienV2Service(
    ApiClient().dio,
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoading = false;

  AuthData? _authData;

  int? _currentUserId;
  String? _currentManv;
  String? _currentTenNV;
  String? _currentAvatar;
  String? _currentMaKhoa;

  List<int> _currentRoleIds = [];

  DateTime? _passwordExpiresAt;
  DateTime? _accessTokenExpiresAt;

  bool _mustChangePassword = false;

  String? _pendingPasswordChangeManv;
  bool _isFcmSetupRunning = false;
  String? _fcmSyncedManv;

  AuthProvider() {
    AuthInterceptor.authStateListener = _handleAuthStateFromInterceptor;

    AuthInterceptor.tokenRefreshedListener =
        _handleTokenRefreshedFromInterceptor;
  }

  String _getDeviceType() {
    if (kIsWeb) {
      return 'WEB';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'iOS';

      case TargetPlatform.android:
        return 'Android';

      default:
        return 'UNKNOWN';
    }
  }

  Future<String?> _getFcmToken() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    if (kIsWeb) {
      return messaging.getToken(vapidKey: _webVapidKey);
    }

    return messaging.getToken();
  }

  bool get isLoading => _isLoading;

  AuthData? get authData => _authData;

  int? get currentUserId => _currentUserId;

  String? get currentManv => _currentManv;

  String? get currentTenNV => _currentTenNV;

  String? get currentAvatar => _currentAvatar;

  String? get currentMaKhoa => _currentMaKhoa;

  List<int> get currentRoleIds => List<int>.unmodifiable(_currentRoleIds);

  String? get token => _authData?.token;

  bool get mustChangePassword => _mustChangePassword;

  String? get pendingPasswordChangeManv => _pendingPasswordChangeManv;

  bool _isTerminalSessionCode(String code) {
    return _terminalSessionCodes.contains(code.trim().toUpperCase());
  }

  void _handleAuthStateFromInterceptor(String code, String? manv) {
    _authData = null;
    _currentRoleIds = [];
    _currentUserId = null;
    _passwordExpiresAt = null;
    _accessTokenExpiresAt = null;

    if (code == 'PASSWORD_EXPIRED') {
      _mustChangePassword = true;
      _pendingPasswordChangeManv = manv;
      _currentManv = manv;
    } else {
      _mustChangePassword = false;
      _pendingPasswordChangeManv = null;

      _currentManv = null;
      _currentTenNV = null;
      _currentAvatar = null;
      _currentMaKhoa = null;
    }

    notifyListeners();
  }

  void _handleTokenRefreshedFromInterceptor(
    String accessToken,
    String refreshToken,
  ) {
    _parseTokenPayload(accessToken);

    _authData = AuthData(
      token: accessToken,
      refreshToken: refreshToken,
      expiresAt: _authData?.expiresAt,
      user: UserDTO(id: _currentUserId, manv: _currentManv),
    );

    notifyListeners();
  }

  void _parseTokenPayload(String token) {
    try {
      final List<String> parts = token.split('.');

      if (parts.length != 3) {
        throw const FormatException('JWT không đúng định dạng.');
      }

      final String normalized = base64Url.normalize(parts[1]);

      final String payloadString = utf8.decode(base64Url.decode(normalized));

      final dynamic decoded = jsonDecode(payloadString);

      if (decoded is! Map) {
        throw const FormatException('Payload JWT không hợp lệ.');
      }

      final Map<String, dynamic> payload = Map<String, dynamic>.from(decoded);

      _currentRoleIds = [];
      _passwordExpiresAt = null;
      _accessTokenExpiresAt = null;

      _currentUserId = int.tryParse(payload['userid']?.toString() ?? '');

      final String tokenManv = payload['manv']?.toString().trim() ?? '';

      if (tokenManv.isNotEmpty) {
        _currentManv = tokenManv;
      }

      final String tokenMaKhoa = payload['makhoa']?.toString().trim() ?? '';

      if (tokenMaKhoa.isNotEmpty) {
        _currentMaKhoa = tokenMaKhoa;
      }

      dynamic roles =
          payload['roleIds'] ??
          payload['role'] ??
          payload['roles'] ??
          payload['Roles'] ??
          payload['http://schemas.microsoft.com/'
              'ws/2008/06/identity/claims/role'];

      if (roles is String && roles.trim().startsWith('[')) {
        try {
          roles = jsonDecode(roles);
        } catch (_) {
          // Giữ nguyên roles dạng String.
        }
      }

      if (roles is List) {
        _currentRoleIds = roles
            .map((dynamic item) => int.tryParse(item.toString()))
            .whereType<int>()
            .where((int id) => id > 0)
            .toSet()
            .toList();
      } else if (roles != null) {
        final int? roleId = int.tryParse(roles.toString());

        if (roleId != null && roleId > 0) {
          _currentRoleIds = [roleId];
        }
      }

      final String passwordExpiry = payload['passex']?.toString().trim() ?? '';

      if (passwordExpiry.isNotEmpty) {
        _passwordExpiresAt = DateTime.tryParse(passwordExpiry)?.toLocal();
      }

      final int? expSeconds = int.tryParse(payload['exp']?.toString() ?? '');

      if (expSeconds != null) {
        _accessTokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(
          expSeconds * 1000,
          isUtc: true,
        ).toLocal();
      }

      debugPrint(
        'JWT: '
        'userId=$_currentUserId, '
        'manv=$_currentManv, '
        'makhoa=$_currentMaKhoa, '
        'roles=$_currentRoleIds',
      );
    } catch (e) {
      _currentRoleIds = [];
      _currentUserId = null;
      _passwordExpiresAt = null;
      _accessTokenExpiresAt = null;

      debugPrint('Lỗi giải mã JWT: $e');
    }
  }

  bool isPasswordExpired() {
    if (_passwordExpiresAt == null) {
      return false;
    }

    return !DateTime.now().isBefore(_passwordExpiresAt!);
  }

  bool _isAccessTokenExpired() {
    if (_accessTokenExpiresAt == null) {
      return true;
    }

    return !DateTime.now().isBefore(_accessTokenExpiresAt!);
  }

  void _restoreProfileFromPreferences(SharedPreferences prefs) {
    final String currentManv = _currentManv?.trim() ?? '';

    final String cachedProfileManv =
        prefs.getString('profile_manv')?.trim() ?? '';
    if (currentManv.isEmpty || cachedProfileManv != currentManv) {
      _currentTenNV = null;
      _currentAvatar = null;

      return;
    }

    _currentTenNV = prefs.getString('tennv');

    _currentAvatar = prefs.getString('avatar');

    _currentMaKhoa ??= prefs.getString('makhoa');
  }

  Future<void> _clearSessionTokens({bool clearProfileStorage = false}) async {
    AuthInterceptor.clearMemoryToken();

    await _secureStorage.delete(key: 'access_token');

    await _secureStorage.delete(key: 'refresh_token');

    _authData = null;
    _currentRoleIds = [];
    _currentUserId = null;
    _passwordExpiresAt = null;
    _accessTokenExpiresAt = null;

    if (clearProfileStorage) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.remove('manv');

      await prefs.remove('tennv');
      await prefs.remove('profile_manv');
      await prefs.remove('avatar');

      await prefs.remove('makhoa');

      await prefs.remove('pending_password_change_manv');

      _currentManv = null;
      _currentTenNV = null;
      _currentAvatar = null;
      _currentMaKhoa = null;

      _mustChangePassword = false;
      _pendingPasswordChangeManv = null;
    }
  }

  Future<void> _savePasswordChangePending(String manv) async {
    final String normalizedManv = manv.trim();

    if (normalizedManv.isEmpty) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _mustChangePassword = true;

    _pendingPasswordChangeManv = normalizedManv;

    _currentManv = normalizedManv;

    await prefs.setString('manv', normalizedManv);

    await prefs.setString('pending_password_change_manv', normalizedManv);
  }

  Future<bool> _activateLocalSession({
    required String accessToken,
    required String? refreshToken,
    required SharedPreferences prefs,
    bool clearPasswordPending = true,
    bool loadProfile = true,
    bool setupRemoteServices = true,
  }) async {
    _restoreProfileFromPreferences(prefs);

    if (_currentManv == null || _currentManv!.trim().isEmpty) {
      return false;
    }

    _authData = AuthData(
      token: accessToken,
      refreshToken: refreshToken,
      user: UserDTO(id: _currentUserId, manv: _currentManv),
    );

    AuthInterceptor.setMemoryToken(accessToken);

    if (clearPasswordPending) {
      _mustChangePassword = false;
      _pendingPasswordChangeManv = null;

      await prefs.remove('pending_password_change_manv');
    }

    await prefs.setString('manv', _currentManv!);
    if (loadProfile) {
      await _loadAndSaveProfile(prefs);
    }

    if (setupRemoteServices) {
      unawaited(_setupFirebaseAndSendToken(_currentManv!));
    }

    notifyListeners();

    return true;
  }

  Future<void> _setupFirebaseAndSendToken(String manv) async {
    final String normalizedManv = manv.trim();

    if (normalizedManv.isEmpty) {
      return;
    }

    if (_isFcmSetupRunning) {
      debugPrint(
        'FCM: Đang đồng bộ token, '
        'bỏ qua yêu cầu trùng.',
      );

      return;
    }

    // Trong cùng một phiên AuthProvider,
    // nhân viên này đã sync thành công rồi.
    if (_fcmSyncedManv == normalizedManv) {
      debugPrint(
        'FCM: Token đã được đồng bộ '
        'cho $normalizedManv.',
      );

      return;
    }

    _isFcmSetupRunning = true;

    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint(
          'FCM: Người dùng chưa cấp quyền '
          'thông báo.',
        );

        return;
      }

      final String? fcmToken = await _getFcmToken();

      if (fcmToken == null || fcmToken.trim().isEmpty) {
        debugPrint('FCM: Không lấy được token.');

        return;
      }

      final String deviceType = _getDeviceType();

      if (deviceType == 'UNKNOWN') {
        debugPrint(
          'FCM: Không xác định được '
          'loại thiết bị.',
        );

        return;
      }

      final String tokenPreview = fcmToken.length > 20
          ? '${fcmToken.substring(0, 20)}...'
          : fcmToken;

      debugPrint('FCM: DeviceType=$deviceType');

      debugPrint('FCM: Token=$tokenPreview');

      final response = await ApiClient().dio.post(
        '${AppConstants.baseUrl}'
        '/User/update-fcm-token',
        data: {
          'manv': normalizedManv,
          'fcmToken': fcmToken.trim(),
          'deviceType': deviceType,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Đánh dấu đã sync thành công.
        _fcmSyncedManv = normalizedManv;

        debugPrint(
          'FCM: Đã lưu token lên máy chủ '
          '($deviceType).',
        );
      } else {
        debugPrint(
          'FCM: Máy chủ trả về '
          '${response.statusCode}.',
        );
      }
    } catch (e) {
      debugPrint('FCM: Không thể cập nhật token: $e');
    } finally {
      _isFcmSetupRunning = false;
    }
  }

  Future<void> exitPasswordChangeToLogin() async {
    _isLoading = true;

    notifyListeners();

    try {
      await _clearSessionTokens(clearProfileStorage: true);

      await _secureStorage.delete(key: 'bio_manv');

      await _secureStorage.delete(key: 'bio_pass');

      await _secureStorage.write(key: 'bio_enabled', value: 'false');

      _mustChangePassword = false;
      _pendingPasswordChangeManv = null;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<bool> login(String manv, String passwordHash) async {
    final String normalizedManv = manv.trim();

    _isLoading = true;

    notifyListeners();

    try {
      final AuthData loginData = await _authService.login(
        normalizedManv,
        passwordHash,
      );

      final String accessToken = loginData.token?.trim() ?? '';

      final String refreshToken = loginData.refreshToken?.trim() ?? '';

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        await _clearSessionTokens(clearProfileStorage: true);

        throw const AuthApiException(
          code: 'TOKEN_MISSING',
          message:
              'Máy chủ không trả đủ '
              'access token và refresh token.',
        );
      }

      _authData = loginData;

      _currentManv = normalizedManv;

      await _secureStorage.write(key: 'access_token', value: accessToken);

      await _secureStorage.write(key: 'refresh_token', value: refreshToken);

      AuthInterceptor.setMemoryToken(accessToken);

      _parseTokenPayload(accessToken);

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('manv', _currentManv!);

      await prefs.remove('pending_password_change_manv');

      _mustChangePassword = false;
      _pendingPasswordChangeManv = null;

      await _loadAndSaveProfile(prefs);

      unawaited(_setupFirebaseAndSendToken(_currentManv!));

      return true;
    } on AuthApiException catch (e) {
      if (e.code == 'PASSWORD_EXPIRED') {
        await _clearSessionTokens();

        await _savePasswordChangePending(normalizedManv);
      } else if (e.code == 'USER_LOCKED') {
        await _clearSessionTokens(clearProfileStorage: true);
      }

      rethrow;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // =========================================================
  // LOAD PROFILE
  // =========================================================

  Future<void> _loadAndSaveProfile(SharedPreferences prefs) async {
    final String manv = _currentManv?.trim() ?? '';

    if (manv.isEmpty) {
      return;
    }

    final String cachedProfileManv =
        prefs.getString('profile_manv')?.trim() ?? '';

    // Nếu cache thuộc user khác,
    // xóa ngay trước khi gọi API.
    if (cachedProfileManv != manv) {
      _currentTenNV = null;
      _currentAvatar = null;

      await prefs.remove('tennv');

      await prefs.remove('avatar');

      await prefs.remove('profile_manv');
    }

    try {
      final profile = await _nhanVienV2Service.getMe();

      // Chặn trường hợp API trả nhầm user.
      if (profile.maSo.trim() != manv) {
        throw Exception(
          'Hồ sơ trả về không khớp '
          'nhân viên đang đăng nhập.',
        );
      }

      final String name = profile.hoVaTen?.trim() ?? '';

      final String avatar = profile.anhBase64?.trim() ?? '';

      _currentTenNV = name.isNotEmpty ? name : manv;

      _currentAvatar = avatar.isNotEmpty ? avatar : null;

      await prefs.setString('profile_manv', manv);

      await prefs.setString('tennv', _currentTenNV!);

      if (_currentAvatar != null) {
        await prefs.setString('avatar', _currentAvatar!);
      } else {
        // RẤT QUAN TRỌNG:
        // người mới không có ảnh thì phải
        // xóa ảnh của user trước.
        await prefs.remove('avatar');
      }

      // currentMaKhoa vẫn ưu tiên JWT.
      if (_currentMaKhoa != null && _currentMaKhoa!.trim().isNotEmpty) {
        await prefs.setString('makhoa', _currentMaKhoa!);
      }

      debugPrint(
        'PROFILE V2: '
        '$manv - $_currentTenNV',
      );
    } catch (e) {
      debugPrint(
        'Không tải được hồ sơ V2 '
        'cho $manv: $e',
      );

      // Không bao giờ giữ tên/avatar
      // của người khác.
      if (cachedProfileManv != manv) {
        _currentTenNV = manv;
        _currentAvatar = null;
      }
    }
  }

  // =========================================================
  // AUTO LOGIN
  // =========================================================

  Future<bool> tryAutoLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      final String? pendingManv = prefs.getString(
        'pending_password_change_manv',
      );

      String accessToken =
          (await _secureStorage.read(key: 'access_token'))?.trim() ?? '';

      String refreshToken =
          (await _secureStorage.read(key: 'refresh_token'))?.trim() ?? '';

      if (accessToken.isEmpty) {
        if (pendingManv != null && pendingManv.trim().isNotEmpty) {
          _mustChangePassword = true;

          _pendingPasswordChangeManv = pendingManv.trim();

          _currentManv = pendingManv.trim();

          notifyListeners();
        }

        return false;
      }

      _parseTokenPayload(accessToken);

      _restoreProfileFromPreferences(prefs);

      if (_isAccessTokenExpired()) {
        if (refreshToken.isEmpty) {
          await _clearSessionTokens(clearProfileStorage: true);

          notifyListeners();

          return false;
        }

        try {
          final AuthData refreshed = await _authService.refreshAccessToken(
            refreshToken,
          );

          final String newAccessToken = refreshed.token?.trim() ?? '';

          final String newRefreshToken = refreshed.refreshToken?.trim() ?? '';

          if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
            throw const AuthApiException(
              code: 'REFRESH_DATA_MISSING',
              message:
                  'Máy chủ không trả đủ '
                  'cặp token mới.',
            );
          }

          accessToken = newAccessToken;

          refreshToken = newRefreshToken;

          await _secureStorage.write(key: 'access_token', value: accessToken);

          await _secureStorage.write(key: 'refresh_token', value: refreshToken);

          AuthInterceptor.setMemoryToken(accessToken);

          _parseTokenPayload(accessToken);

          debugPrint('Tự động làm mới phiên thành công.');
        } on AuthApiException catch (e) {
          final String code = e.code.trim().toUpperCase();

          if (code == 'PASSWORD_EXPIRED') {
            final String targetManv =
                _currentManv ?? prefs.getString('manv') ?? '';

            await _clearSessionTokens();

            if (targetManv.trim().isNotEmpty) {
              await _savePasswordChangePending(targetManv);
            }

            notifyListeners();

            return false;
          }

          if (_isTerminalSessionCode(code)) {
            await _clearSessionTokens(clearProfileStorage: true);

            notifyListeners();

            return false;
          }

          debugPrint(
            'Không thể refresh do lỗi tạm thời: '
            '${e.code} - ${e.message}',
          );

          final bool restored = await _activateLocalSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            prefs: prefs,
            clearPasswordPending: false,
            loadProfile: false,
            setupRemoteServices: false,
          );

          return restored;
        }
      }

      final bool activated = await _activateLocalSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        prefs: prefs,
        clearPasswordPending: true,
        loadProfile: true,
        setupRemoteServices: true,
      );

      if (!activated) {
        await _clearSessionTokens(clearProfileStorage: true);

        notifyListeners();

        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Lỗi tự động đăng nhập: $e');

      final String accessToken =
          (await _secureStorage.read(key: 'access_token'))?.trim() ?? '';

      final String refreshToken =
          (await _secureStorage.read(key: 'refresh_token'))?.trim() ?? '';

      if (accessToken.isNotEmpty) {
        _parseTokenPayload(accessToken);

        final bool restored = await _activateLocalSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          prefs: prefs,
          clearPasswordPending: false,
          loadProfile: false,
          setupRemoteServices: false,
        );

        if (restored) {
          return true;
        }
      }

      notifyListeners();

      return false;
    }
  }

  // =========================================================
  // CHANGE PASSWORD
  // =========================================================

  Future<bool> changePassword(
    String oldPassword,
    String newPassword, {
    String? manv,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String targetManv =
        (manv ??
                _pendingPasswordChangeManv ??
                _currentManv ??
                prefs.getString('pending_password_change_manv') ??
                prefs.getString('manv') ??
                '')
            .trim();

    if (targetManv.isEmpty) {
      throw const AuthApiException(
        code: 'MANV_REQUIRED',
        message:
            'Không tìm thấy mã nhân viên '
            'cần đổi mật khẩu.',
      );
    }

    _isLoading = true;

    notifyListeners();

    try {
      final bool success = await _authService.changePassword(
        targetManv,
        oldPassword,
        newPassword,
      );

      if (!success) {
        return false;
      }

      await prefs.remove('pending_password_change_manv');

      _mustChangePassword = false;
      _pendingPasswordChangeManv = null;

      await _clearSessionTokens(clearProfileStorage: true);

      await _secureStorage.delete(key: 'bio_manv');

      await _secureStorage.delete(key: 'bio_pass');

      await _secureStorage.write(key: 'bio_enabled', value: 'false');

      return true;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // =========================================================
  // REGISTER
  // =========================================================

  Future<bool> register(
    String manv,
    String password,
    String email,
    String role,
  ) async {
    _isLoading = true;

    notifyListeners();

    try {
      return await _authService.register(manv, password, email, role);
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // =========================================================
  // LOGOUT
  //
  // Mobile vẫn dùng getToken() như cũ thông qua
  // _getFcmToken().
  //
  // Web dùng đúng VAPID key để lấy token hiện tại.
  // =========================================================

  Future<void> logout() async {
    final int? tempUserId = _currentUserId;

    final String? bioEnabled = await _secureStorage.read(key: 'bio_enabled');

    final String? bioManv = await _secureStorage.read(key: 'bio_manv');

    final String? bioPass = await _secureStorage.read(key: 'bio_pass');

    try {
      if (tempUserId != null) {
        final String? fcmToken = await _getFcmToken();

        await _authService.logoutApi(tempUserId, fcmToken: fcmToken);
      }

      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Lỗi gọi API đăng xuất: $e');
    } finally {
      AuthInterceptor.clearMemoryToken();

      await _secureStorage.deleteAll();

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.clear();

      // Giữ nguyên hành vi sinh trắc học
      // của app mobile hiện tại.
      if (bioEnabled == 'true' && bioManv != null && bioPass != null) {
        await _secureStorage.write(key: 'bio_enabled', value: bioEnabled);

        await _secureStorage.write(key: 'bio_manv', value: bioManv);

        await _secureStorage.write(key: 'bio_pass', value: bioPass);
      }

      _authData = null;
      _currentUserId = null;
      _fcmSyncedManv = null;
      _isFcmSetupRunning = false;
      _currentManv = null;
      _currentTenNV = null;
      _currentAvatar = null;
      _currentMaKhoa = null;
      _currentRoleIds = [];
      _passwordExpiresAt = null;
      _accessTokenExpiresAt = null;
      _mustChangePassword = false;
      _pendingPasswordChangeManv = null;

      notifyListeners();
    }
  }

  // =========================================================
  // BIOMETRIC
  //
  // Web không sử dụng local_auth.
  //
  // Android/iOS giữ nguyên hành vi cũ.
  // =========================================================

  Future<bool> isBiometricSupported() async {
    if (kIsWeb) return false;

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleBiometric(
    bool isEnable,
    String manv,
    String password,
  ) async {
    if (kIsWeb) {
      return false;
    }

    if (isEnable) {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason:
            'Quét vân tay hoặc khuôn mặt '
            'để kích hoạt',
        biometricOnly: true,
      );

      if (!authenticated) {
        return false;
      }

      await _secureStorage.write(key: 'bio_manv', value: manv);

      await _secureStorage.write(key: 'bio_pass', value: password);

      await _secureStorage.write(key: 'bio_enabled', value: 'true');

      return true;
    }

    await _secureStorage.delete(key: 'bio_manv');

    await _secureStorage.delete(key: 'bio_pass');

    await _secureStorage.write(key: 'bio_enabled', value: 'false');

    return true;
  }

  Future<bool> loginWithBiometric() async {
    if (kIsWeb) {
      throw const AuthApiException(
        code: 'BIOMETRIC_NOT_SUPPORTED',
        message:
            'Đăng nhập sinh trắc học '
            'không hỗ trợ trên phiên bản Web.',
      );
    }

    final String? isEnabled = await _secureStorage.read(key: 'bio_enabled');

    if (isEnabled != 'true') {
      throw const AuthApiException(
        code: 'BIOMETRIC_NOT_ENABLED',
        message:
            'Tài khoản chưa bật đăng nhập '
            'bằng sinh trắc học.',
      );
    }

    final bool authenticated = await _localAuth.authenticate(
      localizedReason:
          'Xác thực để đăng nhập '
          'vào My HungVuong',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );

    if (!authenticated) {
      return false;
    }

    final String? savedManv = await _secureStorage.read(key: 'bio_manv');

    final String? savedPassword = await _secureStorage.read(key: 'bio_pass');

    if (savedManv == null ||
        savedManv.trim().isEmpty ||
        savedPassword == null ||
        savedPassword.isEmpty) {
      throw const AuthApiException(
        code: 'BIOMETRIC_DATA_INVALID',
        message:
            'Dữ liệu đăng nhập sinh trắc học '
            'không hợp lệ. Vui lòng đăng nhập '
            'bằng mật khẩu.',
      );
    }

    return login(savedManv, savedPassword);
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    AuthInterceptor.authStateListener = null;

    AuthInterceptor.tokenRefreshedListener = null;

    super.dispose();
  }
}
