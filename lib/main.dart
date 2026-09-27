import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'providers/auth_provider.dart';
import 'providers/bao_com_lech_provider.dart';
import 'providers/cham_cong_phep_provider.dart';
import 'providers/cham_cong_tang_ca_provider.dart';
import 'providers/cham_truc_provider.dart';
import 'providers/cme_provider.dart';
import 'providers/luong_provider.dart';
import 'providers/su_kien_provider.dart';
import 'providers/su_kien_v2_provider.dart';
import 'screens/bao_com_lech/bao_com_lech_screen.dart';
import 'screens/cham_truc/cham_truc_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/luong/luong_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/thuc_hanh/thuc_hanh_public_screen.dart';
import 'screens/thuc_hanh/thuc_hanh_lookup_screen.dart';
import 'services/api_client.dart';
import 'services/su_kien_v2_service.dart';
import 'utils/helpers.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// 1. TẠO "TRẠM GỬI ĐỒ" (Biến toàn cục lưu dữ liệu thông báo khi app tắt)
Map<String, dynamic>? pendingNotificationPayload;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Đã nhận thông báo ngầm: ${message.messageId}");
  // TUYỆT ĐỐI KHÔNG GỌI show popup ở đây vì Hệ điều hành tự hiện rồi
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // XỬ LÝ 1: Khi app ĐÃ TẮT HẲN và được mở lên từ thông báo
  RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initialMessage != null) {
    pendingNotificationPayload = initialMessage.data;
    debugPrint(
      "Đã cất thông báo vào trạm gửi đồ (Terminated): ${initialMessage.data}",
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    // Trả lại chữ settings: ở đây
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        try {
          pendingNotificationPayload = jsonDecode(response.payload!);
          debugPrint('User bấm thông báo (Foreground): ${response.payload}');
        } catch (e) {
          debugPrint("Lỗi đọc payload thông báo: $e");
        }
      }
    },
  );

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('User bấm thông báo (Background): ${message.data}');
    pendingNotificationPayload = message.data;
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('🔥 TING TING! CÓ THÔNG BÁO KHI APP ĐANG MỞ!');

    RemoteNotification? notification = message.notification;

    if (notification != null &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      flutterLocalNotificationsPlugin.show(
        id: notification.hashCode, // Trả lại chữ id:
        title: notification.title ?? 'Thông báo hệ thống',
        body: notification.body ?? 'Bạn có một thông báo mới',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChamCongPhepProvider()),
        ChangeNotifierProvider(create: (_) => ChamCongTangCaProvider()),
        ChangeNotifierProvider(create: (_) => LuongProvider()),
        ChangeNotifierProvider(create: (_) => BaoComLechProvider()),
        ChangeNotifierProvider(create: (_) => ChamTrucProvider()),
        ChangeNotifierProvider(create: (_) => SuKienProvider()),
        ChangeNotifierProvider(create: (_) => CmeProvider()),
        ChangeNotifierProvider(
        create: (_) =>
            SuKienV2Provider(
          SuKienV2Service(
            ApiClient().dio,
          ),
        ),
      ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: AppHelpers.messengerKey,
      title: 'My HungVuong',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1274BC)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      locale: const Locale('vi', 'VN'),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/luong': (_) => const LuongScreen(),
        '/bao-com-lech': (_) => const BaoComLechScreen(),
        '/cham-truc': (_) => const ChamTrucScreen(),
      },
      onGenerateRoute: (RouteSettings settings) {
        final String routeName = settings.name ?? '';
        if (routeName == '/dang-ky-thuc-hanh') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const ThucHanhPublicScreen(),
          );
        }
        if (routeName.startsWith('/dang-ky-thuc-hanh/')) {
          final String token = routeName
              .substring('/dang-ky-thuc-hanh/'.length)
              .split('?')
              .first;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => ThucHanhPublicScreen(publicToken: token),
          );
        }
        if (routeName.startsWith('/tra-cuu-thuc-hanh/')) {
          final String lookupCode = routeName
              .substring('/tra-cuu-thuc-hanh/'.length)
              .split('?')
              .first;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => ThucHanhLookupScreen(lookupCode: lookupCode),
          );
        }
        if (settings.name == '/change-password') {
          final dynamic rawArguments = settings.arguments;

          final Map<String, dynamic> arguments;

          if (rawArguments is Map<String, dynamic>) {
            arguments = rawArguments;
          } else if (rawArguments is Map) {
            arguments = Map<String, dynamic>.from(rawArguments);
          } else {
            arguments = <String, dynamic>{};
          }

          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => ChangePasswordScreen(
              isForced: arguments['isForced'] == true,
              manv: arguments['manv']?.toString(),
            ),
          );
        }

        return null;
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLogin();
    });
  }

  Future<void> _checkLogin() async {
    final AuthProvider authProvider = context.read<AuthProvider>();

    bool loggedIn = false;

    try {
      loggedIn = await authProvider.tryAutoLogin();
    } catch (e) {
      debugPrint('Lỗi kiểm tra phiên đăng nhập: $e');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoggedIn = loggedIn;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<AuthProvider>(
      builder:
          (BuildContext context, AuthProvider authProvider, Widget? child) {
            /*
         * Bắt buộc kiểm tra trường hợp
         * đổi mật khẩu trước đăng nhập.
         */
            if (authProvider.mustChangePassword) {
              return ChangePasswordScreen(
                isForced: true,
                manv: authProvider.pendingPasswordChangeManv,
              );
            }

            if (_isLoggedIn && authProvider.authData != null) {
              return const WelcomeScreen();
            }

            return const LoginScreen();
          },
    );
  }
}
