// class AppConstants {
//   static const String baseUrl = 'http://10.16.4.11:8082/api';
// }

// class AppConstants {
//   static const String baseUrl = 'https://apihrm.benhvienhungvuong.vn/api';
//   static String get authV2Url =>
//       '$baseUrl/v2/Auth';
// }

class AppConstants {
  static const String baseUrl =
      'https://apihrm.benhvienhungvuong.vn/api';

  static String get authV2Url =>
      '$baseUrl/v2/Auth';
}

// import 'package:flutter/foundation.dart';

// class AppConstants {
//   static const String _configuredBaseUrl = String.fromEnvironment(
//     'API_BASE_URL',
//   );
//   static const String _configuredPublicWebUrl = String.fromEnvironment(
//     'PUBLIC_WEB_URL',
//   );

//   static String get baseUrl {
//     if (_configuredBaseUrl.isNotEmpty) {
//       return _configuredBaseUrl;
//     }

//     return kIsWeb ? 'http://localhost:5078/api' : 'http://10.0.2.2:5078/api';
//   }

//   static String get authV2Url => '$baseUrl/v2/Auth';

//   static String get publicWebUrl {
//     final value = _configuredPublicWebUrl.isNotEmpty
//         ? _configuredPublicWebUrl
//         : (kIsWeb ? Uri.base.origin : '');
//     return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
//   }
// }
